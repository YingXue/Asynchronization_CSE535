-module(client).
-export([client_start/0,loop/0]).

client_start() ->
	PID = spawn (client,loop,[]),
	PID.



%% for sending messages between processes
%% A-> S : A,B, N_A for reaching B
send(Server, Tar, send2Server) ->  
	%% A -> S: A, B, N_A
	%% msg format: {from, content, type}
	Msg = {self(), Tar, nonce_gen(self())},  %% A,B, N_A
	Server! {self(),Msg, needKey},  	
	io:format("~p Message ~p sent to server!~n",[self(),Msg]);

%% A -> B formard msg from S to B for authentication req
send(Tar, Msg, needAuth) -> 
	{_, _, _, Forward} = Msg, 
	%%{N_A, K_AB, B, {K_AB, A}K_BS}K_AS
	%% msg format: {from, content, type}
	Tar! {self(), Forward, needAuth}, %% formard msg from S to B
	io:format("~p forwarded message ~p to ~p, need authentication reply!~n",[self(),Forward,Tar]);

%% B -> A with B's nonce indicating authentication complete
send(Tar, Msg, replyAuth) -> 
	{K_AB,_,Timestamp} = Msg,
	{M1, S1, MM1 } = Timestamp,
	{M2, S2, MM2 } = erlang:now(),
	Elapse = (M1 - M2) *1000000 + S1 - S2 + (MM1 - MM2)*0.000001,
	
	if Elapse < 50 -> % check if timestamp is fresh
		ets:insert(my_table,{{self(),Tar}, K_AB}), %% B record K_AB
		ets:insert(my_table,{{Tar,self()}, K_AB}),
		Nonce = nonce_gen(self()),%% Nonce_B
		Nonce_enc = encrypt({Nonce}, K_AB, sharedKey),	%%{N_B}K_AB
		Tar ! {self(), Nonce_enc , replyAuth},
		io:format("~p replied ~p to ~p. Authentication complete!~n",[self(),Nonce_enc,Tar]);
		true -> %% not fresh timestamp, refuse to continue
		io:format("Timestamp expired~n",[])
	end;

%% A -> B with a -1 for B's nonce for varify completion
send(Tar, Msg, varify) -> 
	[{_,K_AB}] = ets:lookup(my_table, {self(),Tar}),
	Msg_tuple = decrypt(Msg, K_AB,varify),
	io:format("~p decrypt ~p's message ~p~n",[self(),Tar,Msg_tuple]),
	{Nonce} = Msg_tuple,
	Msg_enc = encrypt({Nonce-1},K_AB,sharedKey),
	Tar! {self(), Msg_enc, varify},
	io:format("~p sends back ~p showing she's alive!~n",[self(),Msg_enc]);

%%  protocol done, processes' are talking
send(Tar, Msg, ok) ->
	[{_,K_AB}] = ets:lookup(my_table, {self(),Tar}),
	Tar! {self(), encrypt({Msg}, K_AB, sharedKey), talk},
	io:format("~p sends hello to ~p~n",[self(), Tar]).

%% loop to receive message from other processes
loop() ->
	receive
		{create_key_table} ->
			io:format("~p~n",[self()]),
			loop();
		{Server, Tar, send2Server} -> %% receive A -> S req
			send(Server,Tar,send2Server),
			loop();
		{_, Msg, replyKey} -> %% receive S -> A
			io:format("Received server's reply ~p to ~p!~n",[Msg,self()]),
			Msg_tuple = decrypt(Msg, replyKey),  %% decrypt msg from S
			io:format("~p decrypted Server's message: ~p~n",[self(),Msg_tuple]),
			{_, K_AB, Tar, _} = Msg_tuple,	
			ets:insert(my_table,{{self(),Tar}, K_AB}), %% A record K_AB
			ets:insert(my_table,{{Tar,self()}, K_AB}),
			send(Tar, Msg_tuple, needAuth),
			loop();
		{From, Msg, needAuth} -> %% receive A -> B authentication msg
			Msg_tuple = decrypt(Msg, needAuth),  %% decrypt forwarded msg of S from A
			io:format("~p decrypted ~p's message ~p~n",[self(), From, Msg_tuple]),
			send(From, Msg_tuple, replyAuth),
			loop();
		{From, Msg, replyAuth} -> %% receive B->A 
			send(From, Msg, varify),
			loop();
		{From, Msg, varify} -> %% complete, ready to communicate.
			[{_,K_AB}] = ets:lookup(my_table, {self(),From}),		
			{New_nonce} = decrypt(Msg, K_AB,varify),
			io:format("~p decrypted ~p's message ~p and verify nonce~n",[self(),From,New_nonce]),
			[{_,Old_nonce}] = ets:lookup(my_table, self()),
			if 
				New_nonce + 1 == Old_nonce ->
					send(From, "hello", ok);
				true ->
					true
			end,
			[{_,Driver}] = ets:lookup(my_table,driver),
			Driver ! endProtocol,
			loop()
	end.

%% generate random nonce
nonce_gen(PID) -> 
	random:seed(erlang:now()),
	Nonce = random:uniform(),
	ets:insert(my_table,{PID, Nonce}),
	Nonce.
%% decrypt message using AES provided by ERLANG crypto module
decrypt(Msg, replyKey) -> %% decrypt msg from S
	Key = <<"alicealicealicek">>, %% Key_A : hard coded
	IV  = <<"1234567887654321">>, %% IV_A
	Msg_binary= crypto:aes_cfb_128_decrypt(Key, IV, Msg), %%string format of msg
	Msg_list = binary_to_term(Msg_binary),
	Msg_tuple = list_to_tuple(Msg_list),
	Msg_tuple;

decrypt(Msg, needAuth) -> %% decrypt forwarded msg of S from A
	Key = <<"bobkeybobkeybobk">>, %% Key_B
	IV  = <<"1234567887654321">>, %% IV_B
	Msg_binary= crypto:aes_cfb_128_decrypt(Key, IV, Msg), %%string format of msg
	Msg_list = binary_to_term(Msg_binary),
	Msg_tuple = list_to_tuple(Msg_list),
	Msg_tuple.

decrypt(Msg, Key, varify) ->
	IV  = <<"1234567887654321">>, %% IV_B
	Msg_binary= crypto:aes_cfb_128_decrypt(Key, IV, Msg), %%string format of msg
	Msg_list = binary_to_term(Msg_binary),
	Msg_tuple = list_to_tuple(Msg_list),
	Msg_tuple.

%% encrypt message using AES provided by ERLANG crypto module
encrypt(Msg, Key, sharedKey) ->
	IV  = <<"1234567887654321">>, %% IV_Tar
	%% encrypt msg with Key_AB
	Msg_list = tuple_to_list(Msg),
	Msg_binary = term_to_binary(Msg_list),
	Msg_encrypt = crypto:aes_cfb_128_encrypt(Key, IV, Msg_binary),
	Msg_encrypt.








