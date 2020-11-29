%prolog

jesudy(X) :- 0 is mod(X, 2).
nadruhou(X, Y) :- Y is X*X.

jesudypole([]).
jesudypole([X|Xs]) :- jesudy(X), jesudypole(Xs).

pow(_,0,1) :- !.
pow(X,Y,Z) :- Y1 is Y - 1,
              pow(X,Y1,Z1), Z is Z1*X.

max(X, Y, X) :- X > Y.
max(X, Y, Y) :- X =< Y.

delka([], 0).
delka([_|Xs], Y) :- delka(Xs, Y1), Y is Y1 + 1.

maxPole([X], X) :- !.
maxPole([X|Xs], Y) :- maxPole(Xs, Z), max(X, Z, Y).

delkaAk([], Vys, Vys).
delkaAk([_,T], Vys, Ak) :-
	VetsiAk is Ak + 1,
	delkaAk(T, Vys, VetsiAk).
delkaAk(Sez, Vys) :- delkaAk(Sez, Vys, 0).

accMax([H|T],A,Max)  :-
         H  >  A,
         accMax(T,H,Max).
accMax([H|T],A,Max)  :-
         H  =<  A,
         accMax(T,A,Max).
accMax([],A,A).

maxAk([], Max, Max).
maxAk([H|T], Max, ProzatimMax) :-
	max(ProzatimMax, H, NovyMax),
	maxAk(T, Max, NovyMax).
maxAk([H|T], Max) :- maxAk(T, Max, H).
