:- module(subset_minimal_labeling,
	  [
	   subset_minimal_label/1,
	   subset_minimal_label/2,
	   subset_minimal_labeling/2,
	   subset_minimal_labeling/3,
	   show_solution/1,
	   not_subset/2,
	   op_rel/5,
	   true/1
	  ]).

/** <module> subset_minimal_labeling

  Sets are represented by list of Boolean values (1 means in the subset, 0 means out).

  subset_minimal_label/2 enumerates the minimal subsets of a list Boolean variables and applies a goal to each solution.

  subset_minimal_labeling/3 adds labeling options except the up option which is enforced.

==
?- length(L, 5), L ins 0..1, sum(L, #>=, 2), subset_minimal_label(L).
1 [0,0,0,1,1]
2 [0,0,1,0,1]
3 [0,0,1,1,0]
4 [0,1,0,0,1]
5 [0,1,0,1,0]
6 [0,1,1,0,0]
7 [1,0,0,0,1]
8 [1,0,0,1,0]
9 [1,0,1,0,0]
10 [1,1,0,0,0]
false.
==

*/

:- reexport(library(clpfd)).

test(L):-
    length(L, 5),
    L ins 0..1,
    sum(L, #>=, 2),
    subset_minimal_label(L, writeln).


%! subset_minimal_label(+Booleans)
%
% enumerates the minimal subsets of a list Boolean variables and prints each solution with its number.

subset_minimal_label(Booleans):-
    subset_minimal_labeling([], Booleans, show_solution).

%! subset_minimal_label(+Booleans, +Goal)
%
% enumerates the minimal subsets of a list Boolean variables and applies a goal to each solution found.

subset_minimal_label(Booleans, Goal):-
    subset_minimal_labeling([], Booleans, Goal).


%! subset_minimal_label(+Options, +Booleans)
%
% adds labeling options except the up option which is enforced.

subset_minimal_labeling(Options, Booleans):-
    nb_setval(subset_minimal, 0),
    subset_minimal_loop([up | Options], Booleans, show_solution).


%! subset_minimal_label(+Options, +Booleans, +Goal)
%
% adds labeling options except the up option which is enforced.

subset_minimal_labeling(Options, Booleans, Goal):-
    nb_setval(subset_minimal, 0),
    subset_minimal_loop([up | Options], Booleans, Goal).


subset_minimal_loop(Options, Booleans, Goal):-
    nb_getval(subset_minimal, I),
    I1 is I+1,
    nb_setval(subset_minimal, I1),
    catch(satisfy(Options, Booleans, Goal),
	  solution(Solution),
	  true),
    not_subset(Solution, Booleans),
    subset_minimal_loop(Options, Booleans, Goal).


satisfy(Options, Booleans, Goal):-
    labeling(Options, Booleans),
    call(Goal, Booleans),
    throw(solution(Booleans)).

%! show_solution(+List).
%
% prints List with the solution (default goal passed to subset_minimal_label/1 goals).

show_solution(List):-
    nb_getval(subset_minimal, I),
    format("~w ~w\n", [I, List]).

    
%! not_subset(+BooleanList1, +BooleanList2)
%
% constrains BolleanList1 to be not a subset of BooleanList2.

not_subset(A, B):-
    sum(A, #=, K),
    op_rel(A, *, B, #=, C),
    sum(C, #<, K).

%! op_rel(Term1, Operation, Term2, Relation, Term3)
%
% applies Operation to Term1 and Term2, and compares the results with Relation to Term3.
% If one term is a list, the Operation is applied element-wise.

op_rel(AA, Op, AB, Rel, AC):-
    %writeln(op_rel(AA, Op, AB, Rel, AC)),
    ((is_list(AA) ; is_list(AB) ; is_list(AC))
    ->
     (AA=[A | As] -> true ; A=AA, As=AA),
     (AB=[B | Bs] -> true ; B=AB, Bs=AB),
     (AC=[C | Cs] -> true ; C=AC, Cs=AC),
     op_rel(A, Op, B, Rel, C),
     ((tail(As) ; tail(Bs); tail(Cs))
     ->
      op_rel(As, Op, Bs, Rel, Cs)
     ;
      (var(As), As\==A -> As=[] ; true),
      (var(Bs), Bs\==B -> Bs=[] ; true),
      (var(Cs), Cs\==C -> Cs=[] ; true)
     )
    ;
     Term =.. [Op, AA, AB],
     %writeln(call(Rel, Term, AC)),
     call(Rel, Term, AC)
    ).

tail(T):-
    is_list(T),
    T \= [].



%! true(?Term)
%
% true for any Term.

true(_).


