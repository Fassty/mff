expr(Operands, Operators, E) :-
    Operands = [A, B|Rest],
    length(Operands, N),
    Steps is 2*N - 3,
    expr(Steps, Rest, [B, A], Operators, E).

expr(Steps, Operands, Stack, Operators, E) :-
    (   succ(Steps0, Steps) ->
        next(Steps0, Operands, Stack, Operators, E)
    ;   Stack = [E]
    ).

next(Steps, Operands, Stack, Operators, E) :-
    push(Operands, Stack, Operands_next, Stack_next),
    expr(Steps, Operands_next, Stack_next, Operators, E).
next(Steps, Operands, Stack, Operators, E) :-
    member(Op, Operators),
    reduce(Stack, Op, Stack_next),
    expr(Steps, Operands, Stack_next, Operators, E).

push([X|Xs], S0, Xs, [X|S0]).

reduce([A,B|Stack], Op, [X|Stack]) :-
    X =.. [Op, B, A].

equals_k(Numbers, K, E) :-
    expr(Numbers, [+,-,*,/], E),
    K is E.
