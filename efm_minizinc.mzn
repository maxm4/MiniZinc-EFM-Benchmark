% input data (initialized in .dzn file)
int: n; % nb of reactions
int: m; % nb of metabolites
int: k; % nb of reversible reactions

enum Reactions = _(1..n);
enum Metabolites = _(1..m);
enum Reversibles = _(1..k);

array[Reactions] of string: Rs;        % reactions
array[Metabolites] of string: Ms;        % metabolites
array[Metabolites, Reactions] of int: S; % stoichiometry matrix
array[Reversibles, Reactions] of int: Revs; % reversibles indicators

% intermediate variables
% efm values
array[Reactions] of var float: Vs;  % mode value
array[Reactions] of var bool: Zs;  % support indicator

% constraints
% exclude trivial all-zeros solution 
constraint bool_clause(Zs, []);  
% mode values are all positive
constraint forall(j in Reactions)  (Vs[j] >= 0); 
% Zs is support of Vs [Zs <=> Vs > 0]
constraint forall(j in Reactions)  ((Vs[j] > 0) <-> (Zs[j] == true));     
% Sv = 0, steady-state
constraint forall(i in Metabolites) 
           (sum(j in Reactions)(Vs[j] * S[i,j]) = 0);
% Respecting reversibilities
constraint forall(i in Reversibles) 
           (sum(j in Reactions)(Zs[j] * Revs[i,j]) <= 1);  

solve :: bool_search(Zs, first_fail, indomain_min, complete)
     minimize sum(Zs);

output [
  show(Rs), "\n",
  show(Vs), "\n",
  show(Zs), "\n",
];
