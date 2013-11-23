- module (tut).
-export([double/1,fac/1,mult/2]).
-export([convert/1]).
-export([list_length/1]).

double(X) -> 
	2* X.

fac(1) ->
	1;
fac(N) ->
	N * fac(N-1).

mult(X,Y) ->	
	io:format("~w~n",[X * Y]).

convert({centimeter,X}) ->
	{inch, X/2.54};
convert({inch,Y}) ->
	{centimeter, Y*2.54}.

list_length([]) ->
	0;
list_length([First|Rest]) ->
	1 + list_length(Rest).