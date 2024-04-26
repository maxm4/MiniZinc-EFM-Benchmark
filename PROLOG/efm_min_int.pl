% REQUIREMENTS
:- use_module(library(clpfd)).
:- use_module(subset_minimal_labeling).

% PARSING JSON DATA
:- use_module(library(http/json)).

get_dict_from_json_file(FPath, Dict) :-
    setup_call_cleanup(
        open(FPath, read, Stream),
        json_read_dict(Stream, Dict),
        close(Stream)
    ).

% BEGIN CODE

efms(FPath, Vs, Zs) :-
    %% Inputs and initializations
    get_dict_from_json_file(FPath, Dict),
    Rs = Dict.reactions,
    Revs = Dict.rmatrix,
    Ss = Dict.smatrix,
    writeln(Rs),
    length(Rs, N),
    length(Vs, N),
    length(Zs, N),
    %% Logic-linear program
    % Domain for irreversible reaction fluxes
    real_domain(Vs, 0),
    % Stoichiometry
    real_matrix_vector_multiplication(Ss, Vs, 0),
    % Domain for boolean indicator variables
    bool_domain(Zs),
    % Reversibility
    reversibility_constraint(Revs, Zs), % ZR1b + ZR1f #=< 1,
    % Triviality
    sum(Zs, #>=, 1),
    % Pending constraints: compute support from flux
    support_flux(Zs, Vs),
    %% writeln(Vs),
    %% Subset-minimal enumeration of Zs
    time(subset_minimal_label(Zs, label_and_show(Vs))).


label_and_show(Vs, Zs) :-
    sum(Zs, #=, Sz),
    labeling([min(Sz)], Vs),
    show_solution(Zs).


support_flux([], []).

support_flux([Z | TZ], [V | TV]) :-
    Z #<==> V #> 0,
    support_flux(TZ, TV).

% PREDICATES FOR GENERALIZING CONSTRAINTS

real_matrix_vector_multiplication([], _, _).
real_matrix_vector_multiplication([M | Ms], Vs, Bnd) :-
    maplist(to_integer, M, MI),
    scalar_product(MI, Vs, #=, Bnd),
    real_matrix_vector_multiplication(Ms, Vs, Bnd).


to_integer(X, Y) :-
    Y is integer(X).


real_domain(L, LB) :-
    L ins LB..50.


bool_domain(L) :-
    L ins 0..1.


reversibility_constraint([], _).
reversibility_constraint([Rev | Revs], Zs) :-
    scalar_product(Rev, Zs, #=<, 1), % bwd + fwd <= 1
    reversibility_constraint(Revs, Zs).
