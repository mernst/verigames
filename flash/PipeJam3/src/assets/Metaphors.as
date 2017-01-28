package assets 
{
	/**
	 * ...
	 * @author ...
	 */
	public class Metaphors extends StringTable
	{
		public static function HelpText(key:int):String { 
			
			switch(GameConfig.GAME_METAPHOR){ 
				case GameConfig.ORIGINAL_METAPHOR : return OriginalText.lookupText(key);
				case GameConfig.POWERPLANT_METAPHOR : return PowerPlantText.lookupText(key);
			}
			return "";
		}
	}	
}