package assets 
{
	public class StringTableMTurk extends StringTableBase
	{
		protected override function doLookup(key:int):String
		{
			switch(key) {
				case SPLASH_TUTORIAL: return "The first set of levels introduces how to play.  You must play all levels for credit.";
				case SPLASH_CHALLENGE: 
					if (GameConfig.NO_SURVEY)
						return "Use the skills you have learnt to play the upcoming challenge levels. You now have the option to skip levels, or exit if you wish.";
					else
						return "Use the skills you have learnt to play the upcoming challenge levels. You now have the option to skip levels, or go to the survey if you wish.";
				case SPLASH_DONE: 
					if (GameConfig.NO_SURVEY)
						return "Click Continue to get the completion code.";
					else
						return "Complete the following survey for your completion code.";
				
				case INTRO_VARIABLES: return "Variables have different colors: light and dark.\nClick and drag to select variables.\nRelease the mouse to use your editor to change them.";
				case SELECTOR_UNLOCKED: return "New editor\nunlocked! Change\neditor by\nclicking on one\nof the editor\n    previews -->";
				case ELIMINATE_PARADOX: return "Eliminate as many red paradoxes as you can!";
				case INTRO_SOLVER1_BRUSH:return "New editor unlocked! The star editor will automatically adjust the\nselected variables to reduce the overall number of paradoxes.";
				case INTRO_SOLVER2_BRUSH:return "New editor unlocked! The diamond editor will automatically adjust the\nselected variables to reduce the overall number of paradoxes.\nThe diamond optimizer can run for a long time, click again if you need to stop it.";
				case FUNCTION_SOLVER1_BRUSH:return "The star editor will adjust the selected variables to reduce the\ntotal number of paradoxes. Eliminate as many red paradoxes as you can!";
				case FUNCTION_SOLVER2_BRUSH:return "The diamond editor will adjust the selected variables to reduce the\ntotal number of paradoxes. Eliminate as many red paradoxes as you can!";
				case BOTH_BRUSHES_ENABLED:return  "New editor unlocked! The diamond editor\nmay find different solutions from the star editor.\nThe diamond editor can work for a long time; click again if you need to stop it.";
				case INFORM_LIMITS:return "There is a limit to how many variables you can select. The numbers on the\nselection ring indicate how many you've selected and the selection limit.";
				case INTRO_SELECTION_AREAS:return "Different selections will create different solutions.\nSometimes many variables need to change to eliminate a paradox.";
				case TIP_VARIABLE:return "Variable";
				case TIP_CONSTRAINT:return "Constraint";
				case TIP_PARADOX:return "Paradox";
				case TIP_PARADOX_CONSTRAINT:return "Constraint\nwith\nparadox";
				case TIP_PARADOX_REMOVAL:return "To remove this paradox two others\nwould be created, so leaving this\nparadox is the best solution.";
				case TIP_PARADOX_REMOVED: return "Paradox\nremoved!";
				case APPRECIATE: return "Great work! The target score for this level was reached by\nremoving all the paradoxes. Move on to the next level to learn more!";
			}
			return super.doLookup(key);
		}
	}
}
