#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <time.h>

#include <sys/times.h>
#include <sys/types.h>
#include <limits.h>

#include <unistd.h>

#include "maxsat.h"

char* algNames[2] = {"Borchars", "Maxsatz"};

static CallbackFunction callback_function = 0;
static int callback_use_intermediate = 0;
static int callback_need_call_best = 0;
static double callback_last_time = 0.0;
static const double CALLBACK_SPACING = 1.0;

int algType;

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
		for (i = 0; i < num_vars; i++) {
		  if (best_soln[i] == FALSE) {
			output[i] = 0;
		  } else {
			output[i] = 1;
		  }
		}
	}
	else
	{
		for (i = 0; i < num_vars; i++) {
		  if (var_best_value[i] == FALSE) {
			output[i] = 0;
		  } else {
			output[i] = 1;
		  }
		}
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

  error = init_problem(NULL, ninitvars, nvars);
  if (error) {
    printf("Error in problem setup: %s\n", error);
    return;
  }

  if (algorithm == ALG_DPLL) {
    dp();
  } else {
    runMaxSatz(clauses, nclauses, callback);
  }
  if (callback_need_call_best) {
    do_callback_now(0);
  }
}

int setupMaxSatz(char* input_file)
{
	int i;
  long begintime, endtime, mess;
  struct tms *a_tms;
  FILE *fp_time;
  
  callback_function = callbackFunction;
  
  a_tms = ( struct tms *) malloc( sizeof (struct tms));
  mess=times(a_tms); begintime = a_tms->tms_utime;

  printf("c ----------------------------\n");
  printf("c - Weighted Partial MaxSATZ -\n");
  printf("c ----------------------------\n");
#ifdef DEBUG
  printf("c DEBUG mode ON\n");
#endif
  
  build_simple_sat_instance(input_file);
  UB = HARD_WEIGHT;
    printf("o %lli\n", UB);
      init();
      dpl();
	  do_callback(0);
    
  mess=times(a_tms); endtime = a_tms->tms_utime;
  
  printf("c Learned clauses = %i\n", INIT_BASE_NB_CLAUSE - BASE_NB_CLAUSE);
  printf("c NB_MONO= %lli, NB_BRANCHE= %lli, NB_BACK= %lli \n", 
	 NB_MONO, NB_BRANCHE, NB_BACK);
  if (UB >= HARD_WEIGHT) {
    printf("s UNSATISFIABLE\n");
  } else {
    printf("s OPTIMUM FOUND\nc Optimal Solution = %lli\n", UB);
    printf("v");
    for (i = 0; i < NB_VAR; i++) {
      if (var_best_value[i] == FALSE)
	printf(" -%i", i + 1);
      else
	printf(" %i", i + 1);
    }
    printf(" 0\n");
  }

  printf ("Program terminated in %5.3f seconds.\n",
	  ((double)(endtime-begintime)/CLK_TCK));

  fp_time = fopen("resulttable", "a");
  fprintf(fp_time, "wpmsz-2.5 %s %5.3f %lld %lld %lld %d %d %d %d\n", 
	  input_file, ((double)(endtime-begintime)/CLK_TCK), 
	  NB_BRANCHE, NB_BACK,  
	  UB, NB_VAR, INIT_NB_CLAUSE, NB_CLAUSE-INIT_NB_CLAUSE, CMTR[0]+CMTR[1]);
  printf("wpmsz-2.5 %s %5.3f %lld %lld %lld %d %d %d %d\n", 
	 	 input_file, ((double)(endtime-begintime)/CLK_TCK), 
	 NB_BRANCHE, NB_BACK,
	 UB, NB_VAR, INIT_NB_CLAUSE, NB_CLAUSE-INIT_NB_CLAUSE, CMTR[0]+CMTR[1]);
  fclose(fp_time);
}

int setupBorchers(char* input_file)
{
     int             max_tries;
     int             max_flips;
     int             seed;
     int             i;

     /*
      * Take the first argument as the name of the problem file to read.
      * Call read_prob() to read in the problem.
      */
     num_vars = read_prob(input_file);

     printf("The total weight of all clauses is %d \n", total_weight);

     /*
      * Now, call the slm routine to try to solve the problem.
      */
     max_tries = 10;
     max_flips = 100 * num_vars;
     printf("max_tries %d \n ", max_tries);
     printf("max_flips %d \n", max_flips);

     /*
      * Get a random number seed.
      */
     printf("Random number seed=1 \n");
     seed = 1;
     srand(seed);
printf("ddd");
     for (i = 1; i <= max_tries; i++) {printf("sss");
	  rand_soln();
	  slm(max_flips);
	  printf("Best weight of satisfied clauses is %d \n", best_num_sat);
	  if (best_num_sat > best_best_num_sat) {
	       best_best_num_sat = best_num_sat;
          };
	  if (best_best_num_sat == total_weight) {
	       break;
          };
     };
     /*
      * Next, print out information about the solution.
      */
     printf("Best GSAT solution: weight %d of satisfied clauses, out of a possible %d \n", best_best_num_sat, total_weight);

     /*
      * Now, call the Davis-Putnam routine.
      */

     dp();

     printf("Done with Davis-Putnam.  The current solution is optimal!\n");
     printf("The best solution had weight %d of unsatisfied clauses \n", ub);
     printf("The solution took %d backtracks \n", btrackcount);
     exit(0);

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
