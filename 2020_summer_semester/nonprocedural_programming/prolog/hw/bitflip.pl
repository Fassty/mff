%prolog

flipBit(1,0).
flipBit(0,1).


flipLast2([X1, X2], [InverseX1, InverseX2]) :- flipBit(X1, InverseX1), flipBit(X2, InverseX2).
flipLast2([H | Xs], [H | Result]) :- flipLast2(Xs, Result).
flipLast([X], [InverseX]) :- flipBit(X, InverseX).
flipLast([H | Xs], [H | Result]) :- flipLast(Xs, Result).

flip3inner([X1, X2, X3 | Xs], [InverseX1, InverseX2, InverseX3 | Xs]) :-
	flipBit(X1, InverseX1),
	flipBit(X2, InverseX2),
	flipBit(X3, InverseX3).
flip3inner([H | Xs], [H | Result]) :- flip3inner(Xs, Result).

flip3outer([X1 | Xs], [InverseX1 | Result]) :- flipBit(X1, InverseX1), flipLast2(Xs, Result).
flip3outer([X1, X2 | Xs], [InverseX1, InverseX2 | Result]) :-
	flipBit(X1, InverseX1),
	flipBit(X2, InverseX2),
	flipLast(Xs, Result).

flip3(X, Result) :- flip3inner(X, Result); flip3outer(X, Result).

hrana(V1, V2) :- flip3(V1, V2).

zeros([], []).
zeros([_|Xs], [0|Zeros]) :- zeros(Xs, Zeros).

konce([],[]).
konce([[X|_]|Xss],[X|NoveVrcholy]) :- konce(Xss, NoveVrcholy).


bfs(Start, Cil, Cesta) :-
	bfs1([[Start]], Cil, [], CestaR),
	reverse(CestaR, Cesta).

bfs1([Xs|_], Cil, _ ,Xs) :- Xs = [Cil|_].
bfs1([[X|Xs]|Xss], Cil, Navstivene, CestaR) :-
    findall([Y, X|Xs],(hrana(X,Y),\+member(Y,[X|Xs]),\+member(Y,Navstivene)), NoveCesty),
    konce(NoveCesty, NyniNavstivene),
    append(NyniNavstivene, Navstivene, NoveNavstivene),
    append(Xss, NoveCesty, NovaFronta),!,
    bfs1(NovaFronta, Cil,NoveNavstivene, CestaR).

flipBits(Start, Cesta) :-
    zeros(Start, Zeros),
    bfs(Start, Zeros, Cesta).

