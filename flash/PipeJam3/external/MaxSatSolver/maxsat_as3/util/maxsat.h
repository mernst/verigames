typedef void(*CallbackFunction)(int * vars, int nvars, int unsat_weight);

const int ALG_DPLL = 1;
const int ALG_RAND = 2;

void
run(int algorithm, int * clauses, int nclauses, int * initvars, int ninitvars, int intermediate_callbacks, CallbackFunction callback);
