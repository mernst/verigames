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
			}
			return super.doLookup(key);
		}
	}
}
