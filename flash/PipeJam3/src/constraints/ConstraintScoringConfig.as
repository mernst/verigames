package constraints 
{
	import flash.utils.Dictionary;
	
	public class ConstraintScoringConfig 
	{
		public static const CONSTRAINT_VALUE_KEY:String = "constraints";
		public static const TYPE_0_VALUE_KEY:String = "type:0";
		public static const TYPE_1_VALUE_KEY:String = "type:1";
		
		private var m_scoringDict:Dictionary = new Dictionary();
		
		public function ConstraintScoringConfig() 
		{
		}
		
		public function updateScoringValue(key:String, val:Number):void
		{
			m_scoringDict[key] = val;
		}
		
		public function getScoringValue(key:String):Number
		{
			if (m_scoringDict.hasOwnProperty(key)) return m_scoringDict[key] as Number;
			return 0;
		}
		
		public function removeScoringValue(key:String):void
		{
			if (m_scoringDict.hasOwnProperty(key)) delete m_scoringDict[key];
		}
		
		public static function merge(parentScoringConfig:ConstraintScoringConfig, childScoringConfig:ConstraintScoringConfig):ConstraintScoringConfig
		{
			var mergedScoring:ConstraintScoringConfig = new ConstraintScoringConfig();
			for (var parentKey:String in parentScoringConfig) mergedScoring[parentKey] = parentScoringConfig[parentKey];
			// Child overrides parent values
			for (var childKey:String in childScoringConfig) mergedScoring[childKey] = childScoringConfig[childKey];
			return mergedScoring;
		}
	}

}