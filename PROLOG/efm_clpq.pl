% REQUIREMENTS
:- use_module(library(clpq)).
:- use_module(library(clpfd)).
:- use_module(subset_minimal_labeling).

% PARSING JSON DATA
:- use_module(library(http/json)).

get_dict_from_json_file(FPath, Dicty) :-
  open(FPath, read, Stream), json_read_dict(Stream, Dicty), close(Stream).
  
% BEGIN CODE

test_entailed([], []).

test_entailed([V|TailV], [Z|TailZ]) :- 
                       (entailed(V = 0) -> Z = 0 ; true), 
                       (entailed(V > 0) -> Z = 1 ; true),
                       test_entailed(TailV, TailZ).
                                          
% Test entailed but only neighbours                    
                       
new_test_entailed([], [], []).

new_test_entailed([V|TailV], [Z|TailZ], [Vr|TailVr]) :- 
                       ((Vr = 1, entailed(V = 0)) -> Z = 0 ; true), 
                       ((Vr = 1, entailed(V > 0)) -> Z = 1 ; true),
                       new_test_entailed(TailV, TailZ, TailVr).
                       
constraint_fluxval(Z, V) :- (Z = 0 -> {V = 0}; true), 
                            (Z = 1 -> {V > 0}; true).

efms(FPath, Vs, Zs) :-
        %% Inputs and initializations
        get_dict_from_json_file(FPath, Dict),
        Rs = Dict.reactions,
        Revs = Dict.rmatrix,
        Ss = Dict.smatrix,
        Vrs = Dict.neighbours,
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
        support_flux(Zs, Vs, Zs, Vs, Vrs),
        %% Subset-minimal enumeration of Zs
        time(subset_minimal_labeling([ff], Zs)).
        
timed_efms(FPath, Vs, Zs) :-
    time((efms(FPath, Vs, Zs), writeln((Zs)), fail)).
      
support_flux([], _Vtail, _Zs, _Vs, _Vrs).      
        
support_flux([Z|TailZ], [V|TailV], Zs, Vs, [Vr|TailVr]) :-
    freeze(Z, (constraint_fluxval(Z, V), 
               new_test_entailed(Vs, Zs, Vr))),
    support_flux(TailZ, TailV, Zs, Vs, TailVr). 

% PREDICATES FOR GENERALIZING CONSTRAINTS

real_matrix_vector_multiplication([], _, _).
real_matrix_vector_multiplication([M | Ms], Vs, Bnd) :-
    real_vector_multiplication(M, Vs, R), 
    {R = Bnd},
    real_matrix_vector_multiplication(Ms, Vs, Bnd).    

real_vector_multiplication([], [], 0).
real_vector_multiplication([X | Xs], [Y | Ys], R) :-
    {R = X*Y + Rsum},
    real_vector_multiplication(Xs, Ys, Rsum).
   
real_domain([], 0).
real_domain([V | Vs], LB) :-
    {V >= LB},
    real_domain(Vs, LB).
    
bool_domain([]).
bool_domain([Z | Zs]) :-
    Z in 0..1,
    bool_domain(Zs).
    
matrix_vector_multiplication([], _, _).
matrix_vector_multiplication([S | Ss], Zs, Bnd) :-
    vector_multiplication(S, Zs, R), 
    R #= Bnd,
    matrix_vector_multiplication(Ss, Zs, Bnd). 
    
reversibility_constraint([], _).
reversibility_constraint([Rev | Revs], Zs) :-
    vector_multiplication(Rev, Zs, R), % clpfd
    R #=< 1, % bwd + fwd <= 1
    reversibility_constraint(Revs, Zs). 
    
vector_multiplication([], [], 0).
vector_multiplication([X | Xs], [Y | Ys], R) :-
    R #= X*Y + Rs,
    vector_multiplication(Xs, Ys, Rs).


