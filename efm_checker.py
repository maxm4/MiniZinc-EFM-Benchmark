import pickle
import re, time
import numpy as np

def is_kernel_dimension_one(matrix):
    """
    Checks if the kernel of a matrix is of dimension one
    Uses SVD to calculate the rank of the matrix

    Params:
        matrix: stoichiometric matrix

    Returns:
        boolean: True if the kernel is of dimension one, else False
    """
    # utilise SVD à la place de Gaussian Elimination (Klamt, 2005)
    rank = np.linalg.matrix_rank(matrix)
    # print("forme matrice", matrix.shape, "rang", rank)
    if (rank <= matrix.shape[1] - 1):  # nb columns aka nb reactions
        if (rank == matrix.shape[1] - 1):
            return True # efm
        return None # subset of efm
    return False # superset of efm


def possible_efm_according_to_kernel(matrix, unbound):
    """
    Checks if an efm is possible according to the kernel rank

    Params:
        matrix: stoichiometric matrix

    Returns:
        boolean: True if the kernel is of dimension one, else False
    """
    # utilise SVD à la place de Gaussian Elimination (Klamt, 2005)
    rank = np.linalg.matrix_rank(matrix)
    # print("forme matrice", matrix.shape, "rang", rank)
    if (rank <= matrix.shape[1] - 1):  # nb columns aka nb reactions
        if (rank == matrix.shape[1] - 1):
            return True # efm
        if (unbound > 0) and (rank >= (matrix.shape[1] - 1) - unbound):
            print("Not actually filtered", rank, matrix.shape[1] - 1, rank - (matrix.shape[1] - 1), unbound)
            return True # subset of efm
    if SHOW_SUPERSETS:
        print("MCFM of level", rank, matrix.shape[1] - 1, rank - (matrix.shape[1] - 1), unbound)
    return False # superset of efm


def support_as_boolean(support, reacidx):
    """
    Converts support to a boolean table matching the network file matrix

    Params:
        support: set of string names, support of the reaction, from clingoLP output
        reacidx: hash map associating reaction names to indices, from network file

    Returns:
        booltable: table of booleans:
                   True if the reaction is in the support, else False
    """
    booltable = []
    itersup = support.copy()
    for val in reacidx: # for each reaction name
        match = val in itersup # boolean
        booltable.append(match)
        if match:
            itersup.remove(val)
    return booltable


def is_efm(support, reacidx, matrix):
    """
    Checks if a support reaction names set is an elementary flux mode

    Params:
        fluxv: a flux vector returned by clingo[LP], as pandas dataframe
        reacidx: Python Dict of reaction names corresponding to matrix indices
        matrix: original matrix, to check flux vectors minimality

    Returns:
        status: boolean, true if it is an efm else false
    """
    boolsupp = support_as_boolean(support, reacidx)
    submatrix = matrix[:,boolsupp]
    return is_kernel_dimension_one(submatrix)

class EFMChecker():

    def __init__(self, efm_checker_file):
        
        with open(efm_checker_file, 'rb') as f:
            config = pickle.load(f)

        self.matrix = config.matrix
        self.rindex = {k[2:]: v for k, v in config.rindex.items()} # config.rindex
        self.time = 0

    def is_efm(self, support):
        deb = time.time()
        smart_remove_revs = lambda x: x[:-4] if x.endswith('_rev') else x
        support = set(list(map(smart_remove_revs, support)))
        test = is_efm(support, self.rindex, self.matrix)
        end = time.time()
        self.time += end - deb
        return test
        
        
        
        
