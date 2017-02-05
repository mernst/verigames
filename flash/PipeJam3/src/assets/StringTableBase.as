package assets 
{
	public class StringTableBase extends StringTable
	{
		protected override function doLookup(key:int):String
		{
			switch(key) {
				case SPLASH_TUTORIAL: return "The first set of levels introduces how to play.";
				case SPLASH_CHALLENGE: return "Use the skills you have learnt to play the upcoming levels.";
				case SPLASH_DONE: return "Thank you for playing!";
				case SPLASH_BEGIN: return "Begin";
				case SPLASH_CONTINUE: return "Continue";
				case SPLASH_SURVEY: return "Continue to Survey";
				
				case INTRO_ZOOM: return "Use the arrow keys or right-click and drag to pan. Use +/- to zoom.";
				case MINIMAP: return "For larger levels use on the minimap in the top right to navigate.";
				
				case TIP_SELECT_FROM: return "Try selecting\nfrom here";
				case TIP_SELECT_TO: return "To here";
				case TIP_SELECT_CLUSTER: return "To here and this\nwhole cluster";
				
				case TOOLTIP_WIDE: return "Make dark";
				case TOOLTIP_NARROW: return "Make light";
				case TOOLTIP_SOLVER1: return "Try combinations";
				case TOOLTIP_SOLVER2: return "Try combinations";
			}
			return super.doLookup(key);
		}
	}
}
