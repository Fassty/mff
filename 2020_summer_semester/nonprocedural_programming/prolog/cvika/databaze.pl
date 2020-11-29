% prolog
muz(emil).
muz(jirka).
muz(martin).
zena(sebastian).
zena(jolanda).

miluje(sebastian, emil).
miluje(emil, sebastian).
miluje(sebastian, martin).
miluje(jirka, emil).
% miluje(jolanda, emil).
miluje(jolanda, X) :-
	vlasy(X, hnedy);
	X = emil.

svatba(X,Y) :- miluje(X,Y), miluje(Y,X).

vlasy(emil, hnedy).
vlasy(sebastian, hnedy).

trojuhelnik(X, Y, Z) :- miluje(X,Y), miluje(Y,Z), miluje(Z,X).

cesta2(X,Y) :- miluje(X,Z), miluje(Z,Y).

cesta(X,Y) :- cesta2(X,Y).
cesta(X,Y) :- miluje(X, Mid), cesta(Mid, Y).

vyhodnot(ano, ano).
vyhodnot(ne, ne).

vyhodnot(X, ano) :- X = neg(ne).
% vyhodnot(X, ano) :- X = neg(ano).
vyhodnot(neg(ano), ne).

vyhodnot(and(X, Y), V) :-
	vyhodnot(X, HodnotaX), vyhodnot(Y, HodnotaY),
	((HodnotaX = ano, HodnotaY = ano, V = ano);
	(HodnotaX = ano, HodnotaY = ne, V = ne);
	(HodnotaX = ne, HodnotaY = ano, V = ne);
	(HodnotaX = ne, HodnotaY = ne, V = ne)).

vyhodnot(nebo(X, Y), V) :-
	vyhodnot(X, HodnotaX), vyhodnot(Y, HodnotaY),
	((HodnotaX = ano, V = ano);
	(HodnotaY = ano, V = ano);
	(HodnotaX = ne, HodnotaY = ne, V = ne)).

