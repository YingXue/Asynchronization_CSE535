-module(driver_withIntruder).
-export([setup_env/0]).

setup_env() ->
	%% setup clients
	Alice = client_withIntruder:client_start(),
	Bob = client_withIntruder:client_start(),
	%% setup server
	Server = server_withIntruder:server_start(),
	%% setup key table
	Intruder = intruder:intruder_start(),
	%% seftup intruder
	ets:new(my_table,[named_table,public]),
	%% protocol starts
	process_neg(Alice, Bob, Server,Intruder).

process_neg(Alice, Bob, Server,Intruder) ->
	io:format("Alice:~p ~n",[Alice]),
	io:format("Bob:~p ~n",[Bob]),
	io:format("Server:~p ~n",[Server]),
	io:format("Intruder:~p ~n",[Intruder]),
	Alice ! {Server, Bob, send2Server},  %% ask Alice to contact Server for reaching Bob
	timer:sleep(20000),
	Alice ! {Intruder , Bob, testIntruder},
	ok.