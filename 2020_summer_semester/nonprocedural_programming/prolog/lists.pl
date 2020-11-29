% prolog


double(0, 0).
double(s(X), s(s(Y))) :- double(X,Y).

max(X, Y, X) :- X > Y.
max(X, Y, Y) :- Y >= X.

