//#define borchers
#define MAXSATZ2009
//#define BUILD_LIB

extern const int ALG_DPLL;
extern const int ALG_RAND;

typedef int(*CallbackFunction)(int * vars, int nvars, int unsat_weight);
extern int callbackFunction(int * vars, int nvars, int unsat_weight);

//for maxsatz
typedef signed char my_type;
typedef unsigned char my_unsigned_type;

typedef long long int lli_type;

#define tab_variable_size  30000
#define tab_clause_size 1000000
#define INIT_BASE_NB_CLAUSE (tab_clause_size / 2)
extern int BASE_NB_CLAUSE;
extern int INIT_NB_CLAUSE;
extern int NB_VAR;
extern int NB_CLAUSE;
extern lli_type UB;
extern lli_type NB_MONO;
extern lli_type NB_BRANCHE;
extern lli_type NB_BACK;
extern my_type var_best_value[tab_variable_size]; // Best assignment of variables
extern int instance_type;
extern int partial;
extern lli_type HARD_WEIGHT;
extern int *sat[tab_clause_size]; // Clauses [clause][literal]
extern int *var_sign[tab_clause_size]; // Clauses [clause][var,sign]
extern lli_type clause_weight[tab_clause_size]; // Clause weights
extern lli_type ini_clause_weight[tab_clause_size]; // Initial clause weights
extern my_type clause_state[tab_clause_size]; // Clause status
extern int clause_length[tab_clause_size]; // Clause length
extern int CMTR[2];
/*
#define WORD_LENGTH 1024
#define TRUE 1
#define FALSE 0
#define NONE -1
#define NEGATIVE 0
#define POSITIVE 1
#define PASSIVE 0
#define ACTIVE 1

//for borchars
#define MAX_CLAUSES 50000
#define MAX_VARS    20000

typedef struct entry *entry_ptr;

struct entry {
     int             clause_num;
     int             var_num;
     int             sense;
     entry_ptr       next_in_var;
     entry_ptr       next_in_clause;
};

extern int             cur_soln[MAX_VARS];
extern entry_ptr       vars[MAX_VARS];
extern int             num_vars;
extern int             best_soln[MAX_VARS];
extern int             ub;
extern entry_ptr       clauses[MAX_CLAUSES];
extern int             num_clauses;
extern int             total_weight;
extern int             max_weight;
extern int             min_weight;
extern int             col_count[MAX_VARS];
extern int             row_count[MAX_CLAUSES];
extern int             clause_weights[MAX_CLAUSES];
extern int             num_improve[MAX_VARS];
extern int             best_list[MAX_VARS];
extern int             best_count;
extern int             best_improve;
extern int             best_num_sat;
extern int             best_best_num_sat;
extern int             pick_var_iter;


extern entry_ptr       clauses[MAX_CLAUSES];
extern int             num_clauses;
extern int             sat_count[MAX_CLAUSES];



extern int             pick_first[MAX_VARS];
extern int             btrackcount;

extern const char *
init_problem(int * initvars, int ninitvars, int nvars);
//general
extern void
run(int algorithm, int * clauses, int nclauses, int * initvars, int ninitvars, int intermediate_callbacks, CallbackFunction callback);
extern const char *
check_problem(const int * clauses_ptr, int nclauses, int * nvars);
extern void runMaxSatz(int * clauses, int nclauses, CallbackFunction callback);
extern void do_callback(int new_best);
*/