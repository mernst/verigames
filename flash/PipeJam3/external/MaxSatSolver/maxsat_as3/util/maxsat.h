#ifndef ALG_DPLL
typedef void(*CallbackFunction)(int * vars, int nvars, int unsat_weight);

void
run(int algorithm, int * clauses, int nclauses, int * initvars, int ninitvars, int intermediate_callbacks, CallbackFunction callback);

extern void runMaxSatz(int * clauses, int nclauses, CallbackFunction callback);

#endif