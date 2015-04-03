#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <time.h>

#include <sys/times.h>
#include <sys/types.h>
#include <limits.h>

#include <unistd.h>

#include "../borchers.h"

static CallbackFunction callback_function = 0;
void do_callback(int new_best);

const int ALG_DPLL = 1;
const int ALG_RAND = 2;

int m_alg;

static int callback_use_intermediate = 0;
static int callback_need_call_best = 0;

//static struct timeval callback_last_time = {0, 0};
static double callback_last_time = 0.0;

static const double CALLBACK_SPACING = 1.0;



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

     runBorchers();

     printf("Done with Davis-Putnam.  The current solution is optimal!\n");
     printf("The best solution had weight %d of unsatisfied clauses \n", ub);
     printf("The solution took %d backtracks \n", btrackcount);
     exit(0);

}

