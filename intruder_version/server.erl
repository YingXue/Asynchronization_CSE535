-module(server).
-export([server_start/0,loop/0]).

server_start() ->
	spawn (server,loop,[]).

%% server reply shared key 
send(Msg, replyKey) ->%% S -> A {N_A, K_AB, B, {K_AB, A}K_BS}K_AS
	{From, Tar, Nonce} = Msg,
	K_From_Tar = key_gen(From, Tar),
	Msg_new = {Nonce, K_From_Tar, Tar, {K_From_Tar, From, erlang:now()}},
	From ! {self(), encrypt(Msg_new, From, Tar, replyKey), replyKey}.

%% loop to receive messages from processes
loop() ->
	receive
		{From, Msg} ->
            io:format("~p ~s~n",[From, Msg]),
            loop();
        {_, Msg, needKey} ->  %% A -> S: A, B, N_A        	
			send(Msg, replyKey), 
			loop()
	end.

%% generate a shared random key
key_gen(_, _) ->
	random:seed(erlang:now()), %% generate fresh random K_AB
	Nonce = random:uniform(),
	Key_String = string:left(lists:flatten(io_lib:format("~p", [Nonce])),16), %% use 16 bit as key
	Key_Binary = list_to_binary(Key_String),
	Key_Binary.

%% encrypt key using AES provided by ERLANG crypto module
encrypt(Msg, _, _, replyKey) ->
	Key_From = <<"alicealicealicek">>, %% Key_From: assume get it from server's key_table
	IV_From  = <<"1234567887654321">>, %% IV_From	

	Key_Tar  = <<"bobkeybobkeybobk">>, %% Key_Tar
	IV_Tar   = <<"1234567887654321">>, %% IV_Tar

	%% encrypt Target's msg with Key_Tar
	{Nonce, K_From_Tar, Tar, TarMsg} = Msg,
	TarMsg_list = tuple_to_list(TarMsg),
	TarMsg_binary = term_to_binary(TarMsg_list),
	TarMsg_encrypt = crypto:aes_cfb_128_encrypt(Key_Tar, IV_Tar, TarMsg_binary),

	%% encrypy the whole msg with Key_From
	FromMsg = {Nonce, K_From_Tar, Tar, TarMsg_encrypt},
	FromMsg_list = tuple_to_list(FromMsg),
	FromMsg_binary = term_to_binary(FromMsg_list),
	FromMsg_encrypt = crypto:aes_cfb_128_encrypt(Key_From, IV_From, FromMsg_binary),

	FromMsg_encrypt.