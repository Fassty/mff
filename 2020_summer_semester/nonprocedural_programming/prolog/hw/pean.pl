%prolog

numeral(0).
numeral(s(X)) :- numeral(X).

lessThan(0, s(X)) :- numeral(X).
lessThan(s(X), s(Y)) :- lessThan(X, Y), X \= Y.

subtract(X, 0, X) :- numeral(X).
subtract(s(X), s(Y), Z) :- subtract(X, Y, Z),
							numeral(X),
							numeral(Y),
							numeral(Z).

divide(X, Y, 0, X) :- lessThan(X, Y).
divide(X, Y, s(Result), Reminder) :-
    subtract(X, Y, X1),
    divide(X1, Y, Result, Reminder).
