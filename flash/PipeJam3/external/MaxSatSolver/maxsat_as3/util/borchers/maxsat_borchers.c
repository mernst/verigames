#include "../maxsat.h"

static CallbackFunction callback_function = 0;
void do_callback(int new_best);

const int ALG_DPLL = 1;
const int ALG_RAND = 2;

int m_alg;

#include "wmaxsat.c"

static int callback_use_intermediate = 0;
static int callback_need_call_best = 0;

//static struct timeval callback_last_time = {0, 0};
static double callback_last_time = 0.0;

static const double CALLBACK_SPACING = 1.0;

#ifndef CUSTOM_GET_TIME

#include <sys/time.h>

double
get_time()
{
  struct timeval tv = {0, 0};
  gettimeofday(&tv, NULL);
  return (double)tv.tv_sec + (double)tv.tv_usec / 1000000.0;
}
#endif

void
do_callback_now(int new_best)
{
  if (!callback_function) {
    return;
  }

  if (new_best || callback_need_call_best) {
    int i;
    int output[MAX_VARS];
    for (i = 0; i < num_vars; i++) {
      if (best_soln[i] == FALSE) {
	output[i] = 0;
      } else {
	output[i] = 1;
      }
    }

    callback_need_call_best = 0;
    callback_function(output, num_vars, ub);
  } else if (callback_use_intermediate) {
    callback_function(NULL, 0, 0);
  }
}

void
do_callback(int new_best)
{
  if (new_best) {
    callback_need_call_best = 1;
  }

  if (!callback_function) {
    return;
  }

  double this_time = get_time();
  if (this_time - callback_last_time >= CALLBACK_SPACING) {
    callback_last_time = this_time;

    do_callback_now(new_best);
  }
}

// need to check that problem has each variable used in at least one clause, and there are not duplicated literals
const char *
check_problem(const int * clauses_ptr, int nclauses, int * nvars)
{
  *nvars = 0;

  if (nclauses > MAX_CLAUSES) {
    return "Too many clauses.";
  }

  char used[MAX_VARS];
  int i, j;

  for (i = 0; i < MAX_VARS; ++ i) {
    used[i] = 0;
  }

  const int * clauses_curr = clauses_ptr;
  int is_weight = 1;
  int clauses_proc = 0;

  int this_clause[MAX_VARS];
  int this_clause_len = 0;

  while (clauses_proc < nclauses) {
    int this_var = abs(*clauses_ptr);

    if (this_var == 0) {
      ++ clauses_proc;
      is_weight = 1;
      this_clause_len = 0;
    } else if (is_weight) {
      is_weight = 0;
    } else {
      used[this_var - 1] = 1;
      if (this_var > *nvars) {
	*nvars = this_var;
      }

      // check for duplicate literals in clause
      for (j = 0; j < this_clause_len; ++ j) {
	if (this_clause[j] == *clauses_ptr) {
	  return "Duplicate literal in clause.";
	}
      }
      this_clause[this_clause_len] = *clauses_ptr;
      ++ this_clause_len;
    }

    ++ clauses_ptr;
  }

  if (*nvars > MAX_VARS) {
    return "Too many variables.";
  }

  // check all variables were used
  for (i = 0; i < *nvars; ++ i) {
    if (!used[i]) {
      return "Not all variables used.";
    }
  }

  return NULL;
}

void
setup_problem(const int * clauses_ptr, int nclauses, int nvars)
{
     int             temp;
     int             i;
     entry_ptr       ptr;

     num_vars = nvars;
     num_clauses = nclauses;

     /*
      * Initialize the arrays of pointers.
      */
     for (i = 0; i <= num_vars - 1; i++) {
	  vars[i] = (entry_ptr) NULL;
	  col_count[i] = 0;
     };
     for (i = 0; i <= num_clauses - 1; i++) {
	  clauses[i] = (entry_ptr) NULL;
	  row_count[i] = 0;
     };

     total_weight = 0;

     /*
      * Now, read in the clauses, one at a time.
      */
     for (i = 0; i <= num_clauses - 1; i++) {
	  clause_weights[i] = *(clauses_ptr ++);
	  if (clause_weights[i] > max_weight) {
	       max_weight = clause_weights[i];
          };
	  if (clause_weights[i] < min_weight) {
	       min_weight = clause_weights[i];
          };
	  total_weight = total_weight + clause_weights[i];
	  temp = *(clauses_ptr ++);
	  while (temp != 0) {

	    /*
	      Make sure that this literal isn't already in the clause.
	      If it is, then just ignore it- keeping it in causes problems 
	      with the gsat heuristic.
	      */

	    ptr=clauses[i];
	    while (ptr != (entry_ptr) NULL)
	      {
		if (ptr->var_num == abs(temp)-1)
		  {
		    if ((ptr->sense == 1) && (temp > 0))
		      goto NEXT_LITERAL;
		    if ((ptr->sense == 0) && (temp < 0))
		      goto NEXT_LITERAL;
		  };
		ptr=ptr->next_in_clause;
	      };



	       /*
	        * Allocate an entry for this literal.
	        */
	       ptr = (entry_ptr) malloc(sizeof(struct entry));
	       ptr->clause_num = i;
	       ptr->var_num = abs(temp) - 1;
	       col_count[ptr->var_num] = col_count[ptr->var_num] + 1;
	       if (temp > 0) {
		    ptr->sense = 1;
	       } else {
		    ptr->sense = 0;
	       };
	       /*
	        * Now, link it into the data structure.
	        */
	       ptr->next_in_clause = clauses[i];
	       clauses[i] = ptr;
	       row_count[i] = row_count[i] + 1;

	       ptr->next_in_var = vars[ptr->var_num];
	       vars[ptr->var_num] = ptr;

	       /*
	        * Finally, get the next number out of the file.
	        */
	  NEXT_LITERAL:
	       temp = *(clauses_ptr ++);
	  };
     };
}

const char *
init_problem(int * initvars, int ninitvars, int nvars)
{
  int ii;

  // important to reset upper bound!
  best_num_sat = best_best_num_sat = 0;
  pick_var_iter = 0;

  // initialize all the variables
  if (initvars) {
    if (ninitvars != nvars) {
      return "Mismatch in variable initialization count.";
    }

    for (ii = 0; ii < nvars; ++ ii) {
      cur_soln[ii] = initvars[ii];
      pick_first[ii] = initvars[ii];
    }
  } else {
    for (ii = 0; ii < nvars; ++ ii) {
      cur_soln[ii] = FALSE;
      pick_first[ii] = FALSE;
    }
  }

  // this call to slm() and the following initializes the upper bound
  slm(0);
  if (best_num_sat > best_best_num_sat) {
    best_best_num_sat = best_num_sat;
  };
  if (best_best_num_sat == total_weight) {
    return NULL; // nothing to do, could skip optimization
  };
  
  return NULL;
}

void
run(int algorithm, int * clauses, int nclauses, int * initvars, int ninitvars, int intermediate_callbacks, CallbackFunction callback)
{
  callback_function = callback;
  callback_use_intermediate = intermediate_callbacks;
  callback_need_call_best = 1;
  callback_last_time = get_time();

  const char * error = NULL;
  int nvars = 0;

  error = check_problem(clauses, nclauses, &nvars);
  if (error) {
    printf("Error in problem setup: %s\n", error);
    return;
  }

  setup_problem(clauses, nclauses, nvars);

  error = init_problem(initvars, ninitvars, nvars);
  if (error) {
    printf("Error in problem setup: %s\n", error);
    return;
  }

  m_alg = algorithm;
  if (algorithm == ALG_DPLL) {
    dp();
  } else {
    runMaxSatz(clauses, nclauses, callback);
  }

  if (callback_need_call_best) {
    do_callback_now(1);
  }
}

/*
int
main()
{
  int clauses[] = {
    76222, -1, 2, 0,
    76222, 1, -2, 0,
    41225, 2, 3, 0,
    41225, -2, -3, 0,
    50104, -3, 1, 0,
    50104, 3, -1, 0,
    125307, 4, 5, 0,
    125307, -4, -5, 0,
    51429, 5, 6, 0,
    51429, -5, -6, 0
  };
  int nclauses = 10;

  run(clauses, nclauses, NULL);

  return 0;
}
*/
