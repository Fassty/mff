%prolog

flip_bit(1,0).
flip_bit(0,1).

flip3inner([Bit1, Bit2, Bit3 | InputRest], [Flipped1, Flipped2, Flipped3 | InputRest]) :-
    flip_bit(Bit1, Flipped1),
    flip_bit(Bit2, Flipped2),
    flip_bit(Bit3, Flipped3).
flip3inner([Bit1 | InputRest], [Bit1 | Result]) :- flip3inner(InputRest, Result).

flip_last_2([Bit1, Bit2], [Flipped1, Flipped2]) :-
    flip_bit(Bit1, Flipped1),
    flip_bit(Bit2, Flipped2).
flip_last_2([Bit1 | InputRest], [Bit1 | Result]) :- flip_last_2(InputRest, Result).


flip_last_1([Bit1], [Flipped1]) :-
    flip_bit(Bit1, Flipped1).
flip_last_1([Bit1 | InputRest], [Bit1 | Result]) :- flip_last_1(InputRest, Result).

flip3outer([Bit1 |InputRest], [Flipped1 | Result]) :-
    flip_bit(Bit1, Flipped1),
    flip_last_2(InputRest, Result).

flip3outer([Bit1, Bit2 | InputRest], [Flipped1, Flipped2 | Result]) :-
    flip_bit(Bit1, Flipped1),
    flip_bit(Bit2, Flipped2),
    flip_last_1(InputRest, Result).

flip3(Input, Result) :-
    flip3inner(Input, Result);
    flip3outer(Input, Result).

edge(Vertex, Vertex2) :- flip3(Vertex, Vertex2).

zeros([], []).
zeros([_|Rest], [0|Zeros]) :- zeros(Rest, Zeros).

heads([],[]).
heads([[X|_]|RestPaths],[X|Heads]) :- heads(RestPaths, Heads).

bfs([Xs|_], Goal, _ ,Xs) :- Xs = [Goal|_].
bfs([[X|Xs]|Xss], Goal, Visited, SolutionRev) :-
    findall([Y, X|Xs],(edge(X,Y),\+member(Y,[X|Xs]),\+member(Y,Visited)), NewPaths),
    heads(NewPaths, StepVisited),
    append(StepVisited, Visited, NewVisited),
    append(Xss, NewPaths, NewQueue),!,
    bfs(NewQueue, Goal,NewVisited, SolutionRev).

flipBits(Start, Solution) :-
    zeros(Start, Zeros),
    bfs([[Start]], Zeros,[], SolutionRev),
    reverse(SolutionRev, Solution).







