package assets 
{
	/**
	 * String table for the game.
	 */
	public class StringTable
	{
		public static const SPLASH_TUTORIAL:int           =  0;
		public static const SPLASH_CHALLENGE:int          =  1;
		public static const SPLASH_DONE:int               =  2;
		public static const SPLASH_BEGIN:int              =  3;
		public static const SPLASH_CONTINUE:int           =  4;
		public static const SPLASH_SURVEY:int             =  5;
		public static const INTRO_VARIABLES:int           =  6;
		public static const SELECTOR_UNLOCKED:int         =  7;
		public static const ELIMINATE_PARADOX:int         =  8;
		public static const INTRO_SOLVER1_BRUSH:int       =  9;
		public static const INTRO_SOLVER2_BRUSH:int       =  10;
		public static const FUNCTION_SOLVER1_BRUSH:int    =  11;
		public static const FUNCTION_SOLVER2_BRUSH:int    =  12;
		public static const BOTH_BRUSHES_ENABLED:int      =  13;
		public static const INFORM_LIMITS:int             =  14;
		public static const INTRO_SELECTION_AREAS:int     =  15;
		public static const INTRO_ZOOM:int                =  16;
		public static const MINIMAP:int                   =  17;
		public static const TIP_VARIABLE:int              =  18;
		public static const TIP_CONSTRAINT:int            =  19;
		public static const TIP_PARADOX:int               =  20;
		public static const TIP_PARADOX_CONSTRAINT:int    =  21;
		public static const TIP_PARADOX_REMOVAL:int       =  22;
		public static const TIP_PARADOX_REMOVED:int       =  23;
		public static const APPRECIATE:int                =  24;
		public static const TIP_SELECT_FROM:int           =  25;
		public static const TIP_SELECT_TO:int             =  26;
		public static const TIP_SELECT_CLUSTER:int        =  27;
		public static const TOOLTIP_WIDE:int              =  28;
		public static const TOOLTIP_NARROW:int            =  29;
		public static const TOOLTIP_SOLVER1:int           =  30;
		public static const TOOLTIP_SOLVER2:int           =  31;
		
		
		
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
