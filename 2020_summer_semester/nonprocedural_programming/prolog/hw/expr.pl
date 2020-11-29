%prolog

% Init number of steps and a stack with first two operands
gen(Vars, Ops, Exp) :-
    Vars = [A, B | Rest],
    length(Vars, N),
	Iter is 2*N - 3,
    gen(Rest, Ops, Exp, Iter, [B, A]).

% If Iter > 0 generate next expression
gen(Vars, Ops, Exp, Iter, Stack) :-
(	Iter > 0,
	Iter1 is Iter - 1, !,
    gen2(Vars, Ops, Exp, Iter1, Stack)
  ;
	Stack = [Exp]
).

% Push to a stack
push([X|Xs], S0, Xs, [X|S0]).

% Pop two items from stack, turn them into infix expression and push the expression back to the stack
% Reverse the order of operands as they were pushed to the stack in different order
apply_op([A,B|Stack], Op, [X|Stack]) :-
    X =.. [Op, B, A].

% Push an operand to a stack
gen2(Vars, Ops, Exp, Iter, Stack) :-
    push(Vars, Stack, VarsNew, StackNew),
    gen(VarsNew, Ops, Exp, Iter, StackNew).

% Apply a binary operator to the top of the stack
gen2(Vars, Ops, Exp, Iter, Stack) :-
    member(Op, Ops),
    apply_op(Stack, Op, StackNew),
    gen(Vars, Ops, Exp, Iter, StackNew).


% Evaluate expression and assign to Result, handle zero division error
safe_is(Expression, Result) :-
	catch(Result is Expression,
		  _,
		  fail).

gen_result(Vars, Result, Expression) :-
	gen(Vars, [+,-,*,/], Expression),
	safe_is(Expression, Result).
