-module(testcase).
-export([start/1]).

start(N) ->
	ets:new(time_table,[named_table,public]),
	ets:insert(time_table,{start_time, erlang:now()}),
	ets:insert(time_table,{times, N}),
	run(N).

run(N) when N>0 ->
	driver:setup_env(),
	run(N-1);
run(0)-> 
	io:format("done~n"),
	%%io:format("~p~n",[Timestamp]),
	[{_, Timestamp}] = ets:lookup(time_table,start_time ),
	{M1, S1, MM1 } = Timestamp,
	{M2, S2, MM2 } = erlang:now(),
	Elapse = (M2 - M1) *1000000 + S2 - S1 + (MM2 - MM1)*0.000001,
	io:format("Time has totally elapsed ~p seconds~n",[Elapse]),
	[{_, Times}] = ets:lookup(time_table,times ),
	io:format("Time for running the protocol once is ~p seconds~n",[Elapse/Times]),
	ets:delete(time_table),
	ok.
