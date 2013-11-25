-module(server).
-export([server_start/0,loop/0]).

server_start() ->
	spawn (server,loop,[]).

send(Msg, replyKey) ->%% S -> A {N_A, K_AB, B, {K_AB, A}K_BS}K_AS
	{From, Tar, Nonce} = Msg,
	From ! {self(),{Nonce,key_gen(From,Tar),Tar,{key_gen(From,Tar),From}},replyKey},
	io:format("Server's message sent back!~n",[]).

loop() ->
	receive
		{From, Msg} ->
            io:format("~p ~s~n",[From, Msg]),
            loop();
        {_, Msg, needKey} ->  %% A -> S: A, B, N_A        	
			send(Msg, replyKey), 
			loop()
	end.

key_gen(_, _) ->
	101.
	%% need to record from,tar,key
