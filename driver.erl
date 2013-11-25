-module(driver).
-export([setup_env/0]).

setup_env() ->
	%% setup clients
	Alice = client:client_start(),
	Bob = client:client_start(),
	%% setup server
	Server = server:server_start(),
	%% protocol starts
	process_neg(Alice, Bob, Server).

process_neg(Alice, Bob, Server) ->
	io:format("Alice:~p ~n",[Alice]),
	io:format("Bob:~p ~n",[Bob]),
	io:format("Server:~p ~n",[Server]),
	Alice ! {Server, Bob, send2Server}.  %% ask Alice to contact Server for reaching Bob