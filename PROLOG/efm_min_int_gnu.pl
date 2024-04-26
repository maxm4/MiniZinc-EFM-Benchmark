% EFM CODE IS AT END OF FILE

% Code to launch efms(V, Z, K).
% No input file needed - data written in program.
  
% SUBSET MINIMAL LIBRARY / NOT USED SINCE SWI AND NOT GNU

% enumerates the minimal subsets of a list Boolean variables and prints each solution with its number.

subset_minimal_label(Booleans):-
    subset_minimal_fd_labeling([], Booleans, show_solution).

subset_minimal_label(Booleans, Goal):-
    subset_minimal_fd_labeling([], Booleans, Goal).


subset_minimal_fd_labeling(Booleans, Options):-
    g_assign(subset_minimal, 0),
    subset_minimal_loop(Booleans, Options, show_solution).

subset_minimal_fd_labeling(Options, Booleans, Goal):-
    g_assign(subset_minimal, 0),
    subset_minimal_loop(Booleans, Options, Goal).


subset_minimal_loop(Booleans, Options, Goal):-
    g_read(subset_minimal, I),
    I1 is I+1,
    g_assign(subset_minimal, I1),
    catch(satisfy(Booleans, Options, Goal),
	  solution(Solution),
	  true),
    not_subset(Solution, Booleans),
    subset_minimal_loop(Booleans, Options, Goal).


satisfy(Booleans, Options, Goal):-
    fd_labeling(Booleans, Options),
    call(Goal, Booleans),
    throw(solution(Booleans)).

%! show_solution(+List).
%
% prints List with the solution (default goal passed to subset_minimal_label/1 goals).

show_solution(List):-
    g_read(subset_minimal, I),
    format("~w ~w\n", [I, List]).

    
%! not_subset(+BooleanList1, +BooleanList2)
%
% constrains BolleanList1 to be not a subset of BooleanList2.

not_subset(A, B):-
    new_sum_list(A, K),
    op_rel(A, *, B, #=#, C),
    new_sum_list(C, S),
    S #<# K.

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

%%%% CODE FOR EFMs

support_flux([], []).
support_flux([Z | TZ], [V | TV]) :-
    %print(V),
    (Z) #<=> (V #> 0),
    support_flux(TZ, TV).

real_matrix_vector_multiplication([], _, _).
real_matrix_vector_multiplication([M | Ms], Vs, Bnd) :-
    scalar_product(M, Vs, S),
    S #=# Bnd,
    real_matrix_vector_multiplication(Ms, Vs, Bnd).

reversibility_constraint([], _).
reversibility_constraint([Rev | Revs], Zs) :-
    scalar_product(Rev, Zs, S),
    S #=<# 1, % bwd + fwd <= 1
    reversibility_constraint(Revs, Zs).

scalar_product([], [], 0).
scalar_product([X | Xs], [Y | Ys], R) :-
    R = X*Y + Rs,
    scalar_product(Xs, Ys, Rs).
    
new_sum_list([], 0).
new_sum_list([X | Xs], R) :-
    R = X + Rs,
    new_sum_list(Xs, Rs).

efms(Vs, Zs) :-
    Rs = ["Growth", "R1", "R2", "R2_rev", "R3", "R4", "R5a", "R5b", "R6", "R7", "R8", "R8_rev", "Rres", "Tc1", "Tc2", "Td", "Te", "Tf", "Th", "To2"],
    Revs = [[0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0], [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0]],
    Ss = [[0, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0], [-8, -1, 2, -2, 0, 0, 0, 0, 2, 0, -1, 1, 1, 0, 0, 0, 0, 0, 0, 0], [0, 1, -1, 1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0], [-1, 0, 1, -1, 0, -1, 1, 1, -1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0], [0, 0, 0, 0, 0, 0, 0, 0, 3, 0, 0, 0, 0, 0, 0, -1, 0, 0, 0, 0], [0, 0, 0, 0, 0, 0, 0, 0, 0, 3, 0, 0, 0, 0, 0, 0, -1, 0, 0, 0], [-1, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0], [0, 0, 0, 0, 0, 1, -1, -1, 0, 0, -1, 1, 0, 0, 0, 0, 0, 0, 0, 0], [-1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, -1, 0, 0, 0, 0, 0, 0, 1, 0], [0, 0, 2, -2, 0, 0, 2, 2, 0, -4, -2, 2, -1, 0, 0, 0, 0, 0, 0, 0], [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, 0, 0, 0, 0, 0, 0, 1]],
    length(Rs, N),
    length(Vs, N),
    length(Zs, N),
    %writeq(Rs),
    %format("~w\n", Vs),
    %format("~w\n", Zs),
    %% Logic-linear program
    % Domain for irreversible reaction fluxes
    fd_domain(Vs, 0, 50),
    % Stoichiometry
    real_matrix_vector_multiplication(Ss, Vs, 0),
    % Domain for boolean indicator variables
    fd_domain_bool(Zs),
    % Reversibility
    reversibility_constraint(Revs, Zs), % ZR1b + ZR1f #=< 1,
    % Triviality
    fd_at_least_one(Zs),
    % Pending constraints: compute support from flux
    support_flux(Zs, Vs),
    %% writeln(Vs),
    %% Subset-minimal enumeration of Zs
    %fd_labeling(Vs, [value_method(bisect)]),
    subset_minimal_label(Zs, label_and_show(Vs)).
    
    
label_and_show(Vs, Zs) :-
    %%% fd_labeling(Zs, [variable_method(ff)]), % fd_minimize(Goal, K)
    fd_labeling(Vs, [value_method(bisect)]),
    show_solution(Zs).


