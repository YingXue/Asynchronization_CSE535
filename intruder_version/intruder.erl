-module(intruder).
-export([intruder_start/0,loop/0]).

intruder_start() ->
	PID = spawn (intruder,loop,[]),
	PID.

%% forward authentication message from Alice to Bob
send(_, Msg, needAuth) -> 
	{Tar, Forward} = Msg, 
	%%{N_A, K_AB, B, {K_AB, A}K_BS}K_AS
	%% msg format: {from, content, type}
	Tar! {self(), Forward, needAuth}, %% formard msg from S to B
	io:format("~p forwarded message ~p to ~p, need authentication reply!~n",[self(),Forward,Tar]).


%% loop to receive message from other processes
loop() ->
	receive
		{From, Msg, testIntruder} -> %% complete, ready to communicate.
			send(From, Msg, needAuth),
			loop()
	end.










