#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <time.h>

#include <sys/times.h>
#include <sys/types.h>
#include <limits.h>

#include <unistd.h>

#include "main.h"

char* algNames[2] = {"Borchars", "Maxsatz"};

static CallbackFunction callback_function = 0;
static int callback_use_intermediate = 0;
static int callback_need_call_best = 0;
static double callback_last_time = 0.0;
static const double CALLBACK_SPACING = 1.0;

int algType;

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
do_callback_now(int  new_best)
{
  if (!callback_function) {
    return;
  }
 
    int i;
    int output[MAX_VARS];
	if(algType == 1)
	{
		getCurrentSolutionBorchers(output);
	}
	else if(algType == 2)
	{
		getCurrentSolutionMaxSatz(output);
	}
		
    callback_need_call_best = 0;
    callback_function(output, num_vars, ub);

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

	if (new_best || callback_need_call_best)
		do_callback_now(new_best);
	else if (callback_use_intermediate)
		callback_function(NULL, 0, 0);
  }
}


int callbackFunction(int * vars, int nvars, int unsat_weight)
{
	int i;
	for (i = 0; i < nvars; i++)
	{
		if(vars[i])
			printf("%d ", i);
		else
			printf("-%d ", i);
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


void run(int algorithm, int * clauses, int nclauses, int * initvars, int ninitvars, int intermediate_callbacks, CallbackFunction callback)
{
  callback_function = callback;
  callback_use_intermediate = intermediate_callbacks;
  callback_need_call_best = 1;
  callback_last_time = get_time();
  

  const char * error = NULL;
  int nvars = 0;

  error = check_problem(clauses, nclauses, &nvars);
  num_vars = nvars;
  if (error) {
    printf("Error in problem setup: %s\n", error);
    return;
  }

  setup_problem(clauses, nclauses, nvars);

  if (algorithm == ALG_DPLL) {
    runBorchers(ninitvars, nvars);
  } else {
    runMaxSatz(clauses, nclauses, callback);
  }
  if (callback_need_call_best) {
    do_callback_now(0);
  }
}

int callFromFile(int algType, char *inputFile) {
  char saved_input_file[WORD_LENGTH];
  //int i,  var;
  int i;

  for (i=0; i<WORD_LENGTH; i++)
    saved_input_file[i]=inputFile[i];

  if(algType == ALG_DPLL)
	  return setupMaxSatz(saved_input_file);
	else
		return setupBorchers(saved_input_file);
  
  return TRUE;
}

int
callRun(int algType)
{
	printf("Running alg %s from internal file\n", algNames[algType-1]);
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

  run(algType, clauses, nclauses, NULL, 0, 0, callbackFunction);

  return 0;
}

#ifndef BUILD_LIB
int
main(int argc, char *argv[])
{
    
  algType = strtol(argv[2], (char **)NULL, 10);
  
  if(strcmp(argv[1], "1") == 0)
	  callRun(algType);
  else
	  callFromFile(algType, argv[3]);

  return 0;
}
#endif
