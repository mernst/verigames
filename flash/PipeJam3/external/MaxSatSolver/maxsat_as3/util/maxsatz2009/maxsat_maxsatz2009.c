#include "../maxsat.h"

static CallbackFunction callback_function = 0;
void do_callback();

#define MAXSATZ2009LIB
#include "maxsatz2009.c"

void
do_callback()
{
  if (!callback_function) {
    return;
  }

  int i;
  int output[tab_variable_size];
  for (i = 0; i < NB_VAR; i++) {
    if (var_best_value[i] == FALSE) {
      output[i] = 0;
    } else {
      output[i] = 1;
    }
  }

  callback_function(output, NB_VAR, UB);
}

void
run(int * clauses, int nclauses, CallbackFunction callback)
{
  callback_function = callback;

  int nclauses_processed = 0;
  const int * clauses_ptr = clauses;

  NB_VAR = 0;

  int next_is_weight = 1;
  while (nclauses_processed < nclauses) {
    int entry = *clauses_ptr;

    if (entry == 0) {
      next_is_weight = 1;
      ++ nclauses_processed;
    } else {
      if (next_is_weight) {
	next_is_weight = 0;
      } else {
	if (abs(entry) > NB_VAR) {
	  NB_VAR = abs(entry);
	}
      }
    }
    ++ clauses_ptr;
  }

  NB_CLAUSE = nclauses;

  if (NB_VAR > tab_variable_size ||
      NB_CLAUSE > tab_clause_size - INIT_BASE_NB_CLAUSE) {
    return;
  }

  NB_CLAUSE = NB_CLAUSE + BASE_NB_CLAUSE;
  INIT_NB_CLAUSE = NB_CLAUSE;

  instance_type = 1;
  partial = 0;



  int i = BASE_NB_CLAUSE;
  int j;
  int weight = 0;
  int lits[10000];
  int length = 0;

  nclauses_processed = 0;
  clauses_ptr = clauses;

  while (nclauses_processed < nclauses) {
    int entry = *clauses_ptr;

    if (entry == 0) {
      sat[i] = (int *)malloc((length+1) * sizeof(int));
      for (j=0; j<length; j++) {
	if (lits[j] < 0) 
	  sat[i][j] = abs(lits[j]) - 1 + NB_VAR;
	else 
	  sat[i][j] = lits[j]-1;
      }
      sat[i][length] = NONE;
      clause_length[i] = length;
      clause_weight[i] = weight;
      if (partial == 0)
	HARD_WEIGHT += weight;
      clause_state[i] = ACTIVE;

      ++ i;
      weight = 0;
      length = 0;
      ++ nclauses_processed;
    } else {
      if (weight == 0) {
	weight = entry;
      } else {
	lits[length] = entry;
	++ length;
      }
    }
    ++ clauses_ptr;
  }

  build_structure();
  eliminate_redundance();
  if (clean_structure() == FALSE) {
    return;
  }

  UB = HARD_WEIGHT;

  init();
  dpl();
}
