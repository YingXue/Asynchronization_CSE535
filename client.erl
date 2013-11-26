-module(client).
-export([client_start/0,loop/0]).

client_start() ->
	PID = spawn (client2,loop,[]),
	PID.



%% send
send(Server, Tar, send2Server) ->  %% A-> S for reaching B
	%% A -> S: A, B, N_A
	%% msg format: {from, content, type}
	Msg = {self(), Tar, nonce_gen()},  %% A,B, N_A
	Server! {self(),Msg, needKey},  	
	io:format("~p Message ~p sent to server!~n",[self(),Msg]);

send(Tar, Msg, needAuth) -> %% A -> B for authentication req
	{_, _, _, Forward} = Msg, 
	%%{N_A, K_AB, B, {K_AB, A}K_BS}K_AS
	%% msg format: {from, content, type}
	Tar! {self(), Forward, needAuth}, %% formard msg from S to B
	io:format("~p forwarded message ~p to ~p, need authentication reply!~n",[self(),Forward,Tar]);

send(Tar, Msg, replyAuth) -> %% B -> A for authentication complete
	{K_AB,_} = Msg,
	ets:insert(my_table,{k_ab, K_AB}), %% B record K_AB
	Nonce = nonce_gen(),%% Nonce_B
	%%{N_B}K_AB
	Nonce_enc = encrypt({Nonce}, K_AB, sharedKey),
	Tar ! {self(), Nonce_enc , replyAuth},
	io:format("~p replied ~p to ~p. Authentication complete!~n",[self(),Nonce_enc,Tar]);

send(Tar, Msg, varify) -> %% A -> B for varify completion
	[{_,K_AB}] = ets:lookup(my_table, k_ab),
	Msg_tuple = decrypt(Msg, K_AB,varify),
	io:format("~p decrypt ~p's message ~p~n",[self(),Tar,Msg_tuple]),
	{Nonce} = Msg_tuple,
	Msg_enc = encrypt({Nonce-1},K_AB,sharedKey),
	Tar! {self(), Msg_enc, varify},
	io:format("~p sends back ~p showing she's alive!~n",[self(),Msg_enc]).

%% loop to receive
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
			ets:insert(my_table,{k_ab, K_AB}), %% A record K_AB
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
			[{_,K_AB}] = ets:lookup(my_table, k_ab),
			Msg_tuple = decrypt(Msg, K_AB,varify),
			io:format("~p decrypted ~p's message ~p and verify nonce\n",[self(),From,Msg_tuple]),
			From! {self(), encrypt({"hello"}, K_AB, sharedKey), talk},
			io:format("~p sends hello to ~p",[self(), From]),
			loop()
	end.

%% generate random nonce
nonce_gen() -> 
	random:seed(erlang:now()),
	random:uniform().

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


encrypt(Msg, Key, sharedKey) ->
	IV  = <<"1234567887654321">>, %% IV_Tar
	%% encrypt msg with Key_AB
	Msg_list = tuple_to_list(Msg),
	Msg_binary = term_to_binary(Msg_list),
	Msg_encrypt = crypto:aes_cfb_128_encrypt(Key, IV, Msg_binary),
	Msg_encrypt.








