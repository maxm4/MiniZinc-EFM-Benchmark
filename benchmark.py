from minizinc import Instance, Model, Result, Solver, Status

from contextlib import redirect_stdout

from efm_checker import EFMChecker

import shutil, os, io, pprint, warnings, time, numpy as np

minizinc_solvers = ["chuffed", "coin-bc", "cplex", "gecode", "gist", "gurobi", "highs", "sat", "scip"]

outname = 'result_file.txt'
fname = 'efm.mzn'
inname = 'covert_palsson_int.dzn' #'efm_instance.dzn'
efmcheckfile = 'covert_palsson_int.efmc' # for EFMChecker

solver_params = {minizinc_solver: "" for minizinc_solver in minizinc_solvers} 

with open(fname, 'r') as f:
    fcontent = f.read()
    
with open(inname, 'r') as f:
    instance_content = f.read()
    
def get_program_no_floats(fcontent, mode):
    words = get_program(fcontent, mode)
    words = words.replace('float', 'int') 
    return words
    
def no_flattening_error(fcontent):
    words_lines_to_remove = '% flattening error'  
    return '\n'.join(list(filter(lambda x: words_lines_to_remove not in x, fcontent.split('\n'))))
    
def minimize_error(fcontent, minimize_error):
    words_lines_to_remove = '%%% if minimize error' if minimize_error else '%%% if not minimize error'  
    return '\n'.join(list(filter(lambda x: words_lines_to_remove not in x, fcontent.split('\n'))))
    
def get_program(fcontent, mode):
    words_lines_to_remove = '% float flux' if mode == 'int' else '% integer flux' # else mode == 'float' 
    return '\n'.join(list(filter(lambda x: words_lines_to_remove not in x, fcontent.split('\n'))))
    
def to_mz_list(ls):
    ls_str = str(ls)
    lower_ls = ','.join(map(lambda x: x.lower(), ls_str[1:-1].split(',')))
    ls_str = ls_str[0] + lower_ls + ls_str[-1]
    return ls_str
    
def support(ls):
    return np.nonzero(ls)[0]
  
os.makedirs("outputs/", exist_ok=True)

ind_constr = ["-D", "fIndConstr=true", "-D", "fMIPdomains=false", "--allow-unbounded-vars"]

cplex_params = ["--cplex-dll",  "/opt/ibm/ILOG/CPLEX_Studio221/cplex/bin/x86-64_linux/libcplex2210.so", "--intTol", "1e-6"]

xpress_params = None #["--xpress-dll", "/opt/xpressmp/lib/libxprl.so", "--xpress-password", "/opt/xpressmp/community-xpauth.xpr"]

highs_params = ["--highs-dll", "/home/maxime/Téléchargements/HiGHS/build/lib/libhighs.so"]

mips = ['gurobi', 'scip', 'cplex']

unimplemented = [x + '_float' for x in minizinc_solvers if x not in mips] 

# unimplemented.extend([x + '_min' for x in minizinc_solvers if x not in mips])

scip_params = ["--scip-dll", "/home/maxime/Téléchargements/scipoptsuite-9.0.0/build/lib/libscip.so"]

params = {'chuffed_int': None,
 'coin-bc_int': None,
 'cplex_float': cplex_params + ind_constr,
 'cplex_int': cplex_params,
 'gecode_int': None,
 'gist_int': None,
 'gurobi_float': ind_constr,
 'gurobi_int': None,
 'highs_int': highs_params,
 'sat_int': None,
 'scip_float': scip_params + ind_constr,
 'scip_int': scip_params}

NO_FLOAT_SUPPORT = 'no_float_support'
FLATTENING_ERROR = 'flattening_error'
MINIMIZE_ERROR = 'minimize_error'
NUMBER_OUT_OF_LIMITS = 'flattening_error'
NO_INDICATOR_CONSTRAINTS_SUPPORT = 'flattening_error'
TIME_OUT = 'time_out'
 
flags = {'chuffed_int': NO_FLOAT_SUPPORT,
 'coin-bc_int': FLATTENING_ERROR,
 'cplex_float': FLATTENING_ERROR,
 'cplex_int': FLATTENING_ERROR,
 'gecode_int': FLATTENING_ERROR, # can run without flattening but bugs
 'gist_int': FLATTENING_ERROR, # can run without flattening but bugs
 'gurobi_float': FLATTENING_ERROR,
 'gurobi_int': FLATTENING_ERROR,
 'highs_int': MINIMIZE_ERROR,
 'sat_int': NO_FLOAT_SUPPORT,
 'scip_float': FLATTENING_ERROR,
 'scip_int': FLATTENING_ERROR}
 
 
def solver_get_program(fcontent, config, flag):
    if flag == NO_FLOAT_SUPPORT:
        return get_program_no_floats(fcontent, config)
    else:
        return get_program(fcontent, config)
        if flag == FLATTENING_ERROR:
            return program
        return no_flattening_error(program)
        
def solver_get_instance(fcontent, config, flag):
    if flag == NO_FLOAT_SUPPORT:
        return instance_content.replace('.0', '')
    else:
        return instance_content
        
def str_support(sol, rs):
    return [r for i, r in enumerate(rs) if sol[i]] 

efm_checker = EFMChecker(efmcheckfile)
benchmark = {}
for config in ['int', 'float']:
    for solver_name in minizinc_solvers:
        solve_time = 0
        solveig = solver_name + '_' + config
        if solveig in unimplemented:
            continue
        print(f"=== {solveig} ===")
        iofile = io.StringIO()
        with redirect_stdout(iofile):
            try:
                # Run and Instance definition
                solver = Solver.lookup(solver_name)
                m = Model()
                m.add_string(solver_get_program(fcontent, config, flags[solveig]))
                m.add_string(solver_get_instance(instance_content, config, flags[solveig]))
                inst = Instance(solver, m)
                # Init Solving
                inst._global_cmd_params = params[solveig]
                deb = time.time()
                res: Result = inst.solve()
                end = time.time()
                solve_time += end - deb
                print(res.solution)
                Rs = eval(str(res.solution).split('\n')[0])
                # Init Nogood addition
                nb_sol = 0
                prev_sols = []
                while res.status == Status.SATISFIED or res.status == Status.OPTIMAL_SOLUTION:
                    nb_sol += 1
                    with inst.branch() as child:
                        child._global_cmd_params = params[solveig]
                        for prev_sol in prev_sols:
                            child.add_string(prev_sol)
                        Sol = res["Zs"]
                        rsupport = str_support(Sol, Rs) 
                        new_sol = f"Sols{nb_sol} = {to_mz_list(Sol)};\n"   
                        new_sol += f"array[Reactions] of bool:  Sols{nb_sol};\n" 
                        new_sol += f"constraint sum(j in Reactions)(Zs[j] * Sols{nb_sol}[j]) < {len(support(Sol))};\n"
                        print(new_sol)
                        child.add_string(new_sol)
                        if efm_checker.is_efm(rsupport):
                            print("efm", rsupport)
                        deb = time.time()    
                        res = child.solve()
                        end = time.time()
                        solve_time += end - deb
                        if res.solution is not None:
                            print(res.solution)
                    prev_sols.append(new_sol)
                # End Solving
                res_time = round(solve_time, 3)
                benchmark[solveig] = {'time': res_time, 'nb': nb_sol}
            except Exception as e:
                #raise e
                pprint.pprint(e)
                benchmark[solveig] = {}
        with open(f"outputs/output_{solveig}.txt", 'w') as fd:
            iofile.seek(0)
            shutil.copyfileobj(iofile, fd)
        print(iofile.getvalue())
            
with open(outname, 'w') as f:
    f.write(pprint.pformat(benchmark))
