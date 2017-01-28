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
				
				case INTRO_VARIABLES : return Metaphors.HelpText(key);
				case SELECTOR_UNLOCKED : return Metaphors.HelpText(key);
				case ELIMINATE_PARADOX : return Metaphors.HelpText(key);
				case INTRO_SOLVER1_BRUSH: return Metaphors.HelpText(key);
				case INTRO_SOLVER2_BRUSH: return Metaphors.HelpText(key);
				case FUNCTION_SOLVER1_BRUSH:return Metaphors.HelpText(key);
				case FUNCTION_SOLVER2_BRUSH:return Metaphors.HelpText(key);
				case BOTH_BRUSHES_ENABLED:return Metaphors.HelpText(key);
				case INFORM_LIMITS:return Metaphors.HelpText(key);
				case INTRO_SELECTION_AREAS:return Metaphors.HelpText(key);
				case INTRO_ZOOM:return "Use the arrow keys or right-click and drag to pan. Use +/- to zoom.";
				case MINIMAP:"For larger levels use on the minimap in the top right to navigate.";
				
			}
			return super.doLookup(key);
		}
		
	}
}
