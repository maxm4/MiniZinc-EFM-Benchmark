% variables
int: n; %nb of reactions
int: m; %nb of metabolites
int: k; %nb of reversible reactions

enum Reactions = _(1..n);
enum Metabolites = _(1..m);
enum Reversibles = _(1..k);

array[Reactions] of string: Rs;        % reactions
array[Metabolites] of string: Ms;        % metabolites
array[Metabolites, Reactions] of float: S;         % stoichiometry matrix
array[Reversibles, Reactions] of int: Revs;        % reversibles indicators

% intermediate variables
% efm values
array[Reactions] of var float: Vs;  % float flux
array[Reactions] of var int: Vs;  % integer flux
% efm support
array[Reactions] of var bool: Zs;  % support

% minimal value for distance to zero
float: epsilon = 1.0; % float flux
int: epsilon = 1; % integer flux

constraint bool_clause(Zs, []);                  % exclude trivial solution of all-zeros
constraint forall(j in Reactions)  (Vs[j] >= 0);  % positive reals
constraint forall(j in Reactions)  (Vs[j] <= 50);  %% flattening error
constraint forall(j in Reactions)  ((Vs[j] > 0) <-> (Zs[j] == true));        % Zs is support of Vs [Zs <=> Vs > 0]
constraint forall(i in Metabolites) (sum(j in Reactions)(Vs[j] * S[i,j]) = 0);      % Sv = 0, steady-state
constraint forall(i in Reversibles) (sum(j in Reactions)(Zs[j] * Revs[i,j]) <= 1);  % Respecting reversibilities

solve :: bool_search(Zs, first_fail, indomain_min, complete)
     %:: restart_luby(60) % similar to standard clingo params
     satisfy;   %%% if not minimize % failback
     minimize sum(Zs); %%% if minimize

output [
  show(Rs), "\n",
  show(Vs), "\n",
  show(Zs), "\n",
];
