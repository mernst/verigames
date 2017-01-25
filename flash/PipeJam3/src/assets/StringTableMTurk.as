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
			}
			return super.doLookup(key);
		}
	}
}
