typedef void(*CallbackFunction)(int * vars, int nvars, int unsat_weight);

extern const int ALG_DPLL;
extern const int ALG_RAND;

void
run(int algorithm, int * clauses, int nclauses, int * initvars, int ninitvars, int intermediate_callbacks, CallbackFunction callback);
