package assets 
{
	public class StringTableMTurk extends StringTableBase
	{
		protected override function doLookup(key:int):String
		{
			switch(key) {
				case SPLASH_TUTORIAL: return "The first set of levels introduces how to play.  You must play all levels for credit.";
				case SPLASH_CHALLENGE: return "Use the skills you have learnt to play the upcoming challenge levels. You now have the option to skip levels, or go to the survey if you wish.";
				case SPLASH_DONE: return "Complete the following survey for your completion code.";
				
				case INTRO_VARIABLES: return "Variables can change states. Click and drag to select variables.\nRelease the mouse to apply the state being selected.";
				case SELECTOR_UNLOCKED: return "New selector\n"+"unlocked! Change\n"+"selector by\n"+"clicking on one\n"+"of the selectors\n"+ "    previews -->";
				case ELIMINATE_PARADOX: return "Eliminate as many red paradoxes as you can!";
				case INTRO_SOLVER1_BRUSH:return "New selector unlocked! The star optimizer will automatically adjust the\nselected variables to reduce the overall number of paradoxes.";
				case INTRO_SOLVER2_BRUSH:return "New selector unlocked! The diamond optimizer will automatically adjust the\nselected variables to reduce the overall number of paradoxes.\nThe diamond optimizer can run for a long time, click again if you need to stop it.";
				case FUNCTION_SOLVER1_BRUSH:return "The star optimizer will adjust the selected variables to reduce the\ntotal number of paradoxes. Eliminate as many red paradoxes as you can!";
				case FUNCTION_SOLVER2_BRUSH:return "The diamond optimizer will adjust the selected variables to reduce the\ntotal number of paradoxes. Eliminate as many red paradoxes as you can!";
				case BOTH_BRUSHES_ENABLED:return  "New selector unlocked! The diamond optimizer\nmay find different solutions from the star optimizer.\nThe diamond optimizer can run for a long time, click again if you need to stop it.";
				case INFORM_LIMITS:return "There is a limit to how many things you select. The numbers on the\nselector indicate how many you've selected and the selection limit.";
				case INTRO_SELECTION_AREAS:return "Different selection areas will create different solutions.\nSometimes many items need to change to eliminate a paradox.";
				case TIP_VARIABLE:return "variable";
				case TIP_CONSTRAINT:return "constraint";
				case TIP_PARADOX:return "Paradox";
				case TIP_PARADOX_CONSTRAINT:return "constraint\nwith\nparadox";
				case TIP_PARADOX_REMOVAL:return "To remove this paradox two others\nwould be created, so leaving this\nparadox is the optimal solution";
				case TIP_PARADOX_REMOVED: return "paradox\nremoved!";
				case APPRECIATE: return "Great work! The target score for this level was reached by\n"+"satisfying all the constraints. Move on to the next level to learn more!";
			}
			return super.doLookup(key);
		}
	}
}
