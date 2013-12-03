%% @doc This is the driver program.
-module(driver).
-export([setup_env/0]).

%% @doc Start processes: Alice, Bob and Server.
%% ```
%% In the setup_env(), it would call function: process_neg()
%%
%% 		It would output PID for each process
%%
%% 		Alice would start the connection by sending a message to server asking to connect Bob
%%
%% 		In the intruder version, it will additionally mimic an intruder process starting by let Alice send a message to intruder 
%% '''
%% @spec setup_env() -> ok
setup_env() ->
	%% setup clients
	Alice = client:client_start(),
	Bob = client:client_start(),
	%% setup server
	Server = server:server_start(),
	%% setup key table
	ets:new(my_table,[named_table,public]),
	ets:insert(my_table,{driver, self()}),
	%% protocol starts
	process_neg(Alice, Bob, Server),
	receive
		endProtocol ->
			ets:delete(my_table)
	end.

process_neg(Alice, Bob, Server) ->
	io:format("Alice:~p ~n",[Alice]),
	io:format("Bob:~p ~n",[Bob]),
	io:format("Server:~p ~n",[Server]),
	Alice ! {Server, Bob, send2Server},  %% ask Alice to contact Server for reaching Bob
	ok.