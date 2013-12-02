-module(driver).
-export([setup_env/0]).

%% start processes
setup_env() ->
	%% setup clients
	Alice = client:client_start(),
	Bob = client:client_start(),
	%% setup server
	Server = server:server_start(),
	%% setup key table
	ets:new(my_table,[named_table,public]),
	%% protocol starts
	process_neg(Alice, Bob, Server).

%% let alice start the conection by sending a message to server
%% alice asking to communicate to Bob
process_neg(Alice, Bob, Server) ->
	io:format("Alice:~p ~n",[Alice]),
	io:format("Bob:~p ~n",[Bob]),
	io:format("Server:~p ~n",[Server]),
	Alice ! {Server, Bob, send2Server},  %% ask Alice to contact Server for reaching Bob
	ok.