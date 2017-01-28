package assets 
{
	/**
	 * String table for the game.
	 */
	public class StringTable
	{
		public static const SPLASH_TUTORIAL:int        =  0;
		public static const SPLASH_CHALLENGE:int       =  1;
		public static const SPLASH_DONE:int            =  2;
		public static const SPLASH_BEGIN:int           =  3;
		public static const SPLASH_CONTINUE:int        =  4;
		public static const SPLASH_SURVEY:int          =  5;
		public static const INTRO_VARIABLES:int 	   =  6;
		public static const SELECTOR_UNLOCKED:int 	   =  7;
		public static const ELIMINATE_PARADOX:int 	   =  8;
		public static const INTRO_SOLVER1_BRUSH:int    =  9;
		public static const INTRO_SOLVER2_BRUSH:int    =  10;
		public static const FUNCTION_SOLVER1_BRUSH:int    =  11;
		public static const FUNCTION_SOLVER2_BRUSH:int    =  12;
		public static const BOTH_BRUSHES_ENABLED:int    =  13;
		public static const INFORM_LIMITS:int    =  14;
		public static const INTRO_SELECTION_AREAS:int    =  15;
		public static const INTRO_ZOOM:int    =  16;
		public static const MINIMAP:int    =  17;
		
		
		private static var m_instance:StringTable = null;
		
		public static function setInstance(newInstance:StringTable):void
		{
			m_instance = newInstance;
		}

		public static function lookup(key:int):String
		{
			if (m_instance) {
				return m_instance.doLookup(key);
			} else {
				return "--";
			}
		}
		
		protected function doLookup(key:int):String
		{
			return "--";
		}
	}
}
