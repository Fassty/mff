%prolog

rodic(boris, alfred).
rodic(boris, alex).

muz(alfred).
muz(alex).

bratr(X, Y) :- rodic(Z, X), rodic(Z, Y), X \= Y, muz(X).

numeral(0).
numeral(s(X)) :- numeral(X).
numeral(s(0)).

zdvoj(0, 0).
zdvoj(s(X), s(s(Y))) :- zdvoj(X, Y).

sudy(0).
sudy(s(s(X))) :- sudy(X).

sudy2(X) :- zdvoj(_, X).

%soucet(0, 0, 0).
%soucet(s(X), Y, s(Z)) :- soucet(X, Y, Z).

soucet(X, 0, X).
soucet(X, s(Y), s(Z)) :- soucet(X, Y, Z).

soucin(0, _, 0).
soucin(_, 0, 0).
soucin(s(X), Y, Z2) :- soucin(X, Y, Z1), soucet(Z1, Y, Z2).
