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
