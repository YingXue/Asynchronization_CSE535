-module(client).
-export([client_start/0,loop/0]).

client_start() ->
	spawn (client,loop,[]).

send(Server, Tar, send2Server) ->  %% A-> S
	%% A -> S: A, B, N_A
	%% msg format: {from, msg, type}
	Server! {self(),{self(), Tar, nounce_gen()}, needKey},  	
	io:format("Message sent to server!~n",[]);
send(Tar, Msg, needAuth) -> %% A -> B t1
	{_, K_AB, _, Forward} = Msg, 
	%%{N_A, K_AB, B, {K_AB, A}K_BS}K_AS
	%% msg format: {from, msg, type}
	Tar! {self(), Forward, needAuth},
	io:format("Message forwarded to client, need authentication reply!~n",[]);
send(Tar, Msg, replyAuth) ->
	{K_AB,_} = Msg,
	Tar ! {self(), {nounce_gen()}, replyAuth},
	io:format("Authentication complete!~n",[]).

loop() ->
	receive
		{Server, Tar, send2Server} -> %% receive A -> S req
			send(Server,Tar,send2Server),
			loop();
		{_, Msg, replyKey} -> %% receive S -> A
			{_, _, Tar, _} = Msg,
			send(Tar, Msg, needAuth),
			loop();
		{From, Msg, needAuth} -> %% receive A -> B t1
			send(From, Msg, replyAuth),
			loop();
		{From, Msg, replyAuth} -> %% receive B->A 
			loop()
	end.

nounce_gen() ->
	001.
