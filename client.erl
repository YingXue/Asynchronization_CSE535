-module(client).
-export([client_start/0,loop/0]).

client_start() ->
	spawn (client,loop,[]).

send(Server, Tar, send2Server) ->  %% A-> S
	%% A -> S: A, B, N_A
	%% msg format: {from, msg, type}
	Msg = {self(), Tar, nounce_gen()},
	Server! {self(),Msg, needKey},  	
	io:format("~p Message ~p sent to server!~n",[self(),Msg]);
send(Tar, Msg, needAuth) -> %% A -> B t1
	{_, K_AB, _, Forward} = Msg, 
	%%{N_A, K_AB, B, {K_AB, A}K_BS}K_AS
	%% msg format: {from, msg, type}
	Tar! {self(), Forward, needAuth},
	io:format("~p forwarded message ~p to ~p, need authentication reply!~n",[self(),Forward,Tar]);
send(Tar, Msg, replyAuth) -> %% B -> A
	{K_AB,_} = Msg,
	Nounce = nounce_gen(),
	Tar ! {self(), {Nounce}, replyAuth},
	io:format("~p replied ~p to ~p Authentication complete!~n",[self(),Nounce,Tar]);
send(Tar, Msg, varify) -> %% A -> B t2
	{Nounce} = Msg,
	Tar! {self(), Nounce-1, varify},
	io:format("Varify ~p, ready to communicate!~n",[Nounce-1]).

loop() ->
	receive
		{Server, Tar, send2Server} -> %% receive A -> S req
			send(Server,Tar,send2Server),
			loop();
		{_, Msg, replyKey} -> %% receive S -> A
			io:format("Server replied ~p to ~p!~n",[Msg,self()]),
			{_, _, Tar, _} = Msg,			
			send(Tar, Msg, needAuth),
			loop();
		{From, Msg, needAuth} -> %% receive A -> B t1
			send(From, Msg, replyAuth),
			loop();
		{From, Msg, replyAuth} -> %% receive B->A 
			send(From, Msg, varify),
			loop();
		{_, _, complete} -> %% complete, ready to communicate.
			loop()
	end.

nounce_gen() ->
	random:seed(erlang:now()),
	random:uniform().

