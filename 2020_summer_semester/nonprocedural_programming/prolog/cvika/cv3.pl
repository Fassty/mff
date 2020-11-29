%prolog

pridejz(X, S, [X|S]).

member(X, [X|_]).
member(X, [A|T]) :- member(X, T), X \= A.

acka_becka([],[]).
acka_becka([a|X], [b|Y]) :- acka_becka(X,Y).

zip([], [], []).
zip([X|Xs], [Y|Ys], [X,Y|Zs]) :- zip(Xs, Ys, Zs).

prefix([], _).
% could be prefix([], X) :- is_list(X).
prefix([X|Xs], [X|Ys]) :- prefix(Xs, Ys).

append_list([],X,[X]).
append_list([H|X], T, [H|L]) :- append_list(X,T,L).

reverse([], []).
reverse([H|T], R) :- reverse(T, R1), append_list(R1, H, R).

reverseAcc([],Z,Z).
reverseAcc([H|T],Z,Acc) :- reverseAcc(T,Z,[H|Acc]).

prostredni(X, [X]).
prostredni(A, [_|XS]) :- append_list([_], YS, XS), prostredni(A, YS).


