package
{
	public class GameConfig {
		private static const CONFIG_STUDY:uint = 0;
		private static const CONFIG_MTURK:uint = 1;
		private static const CONFIG:uint = CONFIG_MTURK;
		
		/** which solver brushes to be enabled */
		public static const ENABLE_SOLVER1_BRUSH:Boolean          = true;
		public static const ENABLE_SOLVER2_BRUSH:Boolean          = true;
		public static const ENABLE_SOLVER_LEVELS:Boolean          = true;
		
		/** level skipping */
		public static const ENABLE_SKIP_TUTORIAL:Boolean          = (CONFIG != CONFIG_MTURK);
		public static const ENABLE_SKIP_GAMEPLAY:Boolean          = true;
		public static const ENABLE_SKIP_TO_END_GAMEPLAY:Boolean   = (CONFIG == CONFIG_MTURK);

		/** level scaling */
		public static const ENABLE_SCALE_LEVEL_LAYOUT:Boolean     = false;
		
		/** run HIT with or without requiring player to play for a specified amount of time */
		public static const ENABLE_TIME_CONSTRAINT:Boolean = false;
		
		/** run with player and level ratings displayed along with current game mode */
		public static const ENABLE_DEBUG_DISPLAY:Boolean = false;
	}
}
