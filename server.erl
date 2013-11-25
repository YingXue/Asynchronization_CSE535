-module(server).
-export([server_start/0,loop/0]).

server_start() ->
	spawn (server,loop,[]).

send(Msg, replyKey) ->%% S -> A {N_A, K_AB, B, {K_AB, A}K_BS}K_AS
	{From, Tar, Nonce} = Msg,
	Msg_new = {Nonce,key_gen(From,Tar),Tar,{key_gen(From,Tar),From}},
	%% need encrypt, share IV and key
	From ! {self(), encrypt(Msg_new,From,replyKey), replyKey},
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

encrypt(Msg,_,replyKey) ->
	Key = <<"abcdefghabcdefgh">>,  %% Key_AS
	IV = <<"1234abcdabcdefgh">>,
	Msg_list = tuple_to_list(Msg),
	Msg_binary = term_to_binary(Msg_list),
	Msg_encrypt = crypto:aes_cfb_128_encrypt(Key, IV, Msg_binary),
	Msg_encrypt.