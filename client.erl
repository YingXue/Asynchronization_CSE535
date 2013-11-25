-module(client).
-export([client_start/0,loop/0]).

client_start() ->
	spawn (client,loop,[]).


%% send
send(Server, Tar, send2Server) ->  %% A-> S
	%% A -> S: A, B, N_A
	%% msg format: {from, content, type}
	Msg = {self(), Tar, nonce_gen()},  %% A,B, N_A
	Server! {self(),Msg, needKey},  	
	io:format("~p Message ~p sent to server!~n",[self(),Msg]);

send(Tar, Msg, needAuth) -> %% A -> B for authentication
	{_, K_AB, _, Forward} = Msg, 
	%%{N_A, K_AB, B, {K_AB, A}K_BS}K_AS
	%% msg format: {from, content, type}
	Tar! {self(), Forward, needAuth}, %% formard msg from S to B
	io:format("~p forwarded message ~p to ~p, need authentication reply!~n",[self(),Forward,Tar]);

send(Tar, Msg, replyAuth) -> %% B -> A
	{K_AB,_} = Msg,
	Nonce = nonce_gen(),
	Tar ! {self(), {Nonce}, replyAuth},
	io:format("~p replied ~p to ~p Authentication complete!~n",[self(),Nonce,Tar]);

send(Tar, Msg, varify) -> %% A -> B t2
	{Nonce} = Msg,
	Tar! {self(), Nonce-1, varify},
	io:format("Varify ~p, ready to communicate!~n",[Nonce-1]).

%% loop to receive
loop() ->
	receive
		{Server, Tar, send2Server} -> %% receive A -> S req
			send(Server,Tar,send2Server),
			loop();
		{_, Msg, replyKey} -> %% receive S -> A
			io:format("Server replied ~p to ~p!~n",[Msg,self()]),
			Msg_tupple = decrypt(Msg, replyKey),  %% decrypt msg from S
			{_, _, Tar, _} = Msg_tupple,			
			send(Tar, Msg_tupple, needAuth),
			loop();
		{From, Msg, needAuth} -> %% receive A -> B authentication msg
			Msg_tupple = decrypt(Msg, needAuth),  %% decrypt forwarded msg of S from A
			send(From, Msg_tupple, replyAuth),
			loop();
		{From, Msg, replyAuth} -> %% receive B->A 
			send(From, Msg, varify),
			loop();
		{_, _, complete} -> %% complete, ready to communicate.
			loop()
	end.

%% generate
nonce_gen() -> 
	random:seed(erlang:now()),
	random:uniform().

decrypt(Msg, replyKey) -> %% decrypt msg from S
	Key = <<"alicealicealicek">>, %% Key_A : hard coded
	IV  = <<"alicealicealicev">>, %% IV_A
	Msg_binary= crypto:aes_cfb_128_decrypt(Key, IV, Msg), %%string format of msg
	Msg_list = binary_to_term(Msg_binary),
	Msg_tuple = list_to_tuple(Msg_list),
	Msg_tuple;

decrypt(Msg, needAuth) -> %% decrypt forwarded msg of S from A
	Key = <<"bobkeybobkeybobk">>, %% Key_B
	IV  = <<"bobivvbobivvbobv">>, %% IV_B
	Msg_binary= crypto:aes_cfb_128_decrypt(Key, IV, Msg), %%string format of msg
	Msg_list = binary_to_term(Msg_binary),
	Msg_tuple = list_to_tuple(Msg_list),
	Msg_tuple.











