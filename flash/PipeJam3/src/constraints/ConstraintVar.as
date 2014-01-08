package constraints 
{
	
	public class ConstraintVar extends ConstraintSide
	{
		
		public var id:String;
		public var val:ConstraintValue;
		public var defaultVal:ConstraintValue;
		public var scoringConfig:ConstraintScoringConfig;
		public var possibleKeyfors:Vector.<String>;
		public var keyforVals:Vector.<String>;
		
		public function ConstraintVar(_id:String, _val:ConstraintValue, _defaultVal:ConstraintValue, _scoringConfig:ConstraintScoringConfig = null, _possibleKeyfors:Vector.<String> = null, _keyforVals:Vector.<String> = null)
		{
			id = _id;
			val = _val;
			defaultVal = _defaultVal;
			scoringConfig = _scoringConfig;
			possibleKeyfors = (_possibleKeyfors == null) ? (new Vector.<String>()) : _possibleKeyfors;
			keyforVals = (_keyforVals == null) ? (new Vector.<String>()) : _keyforVals;
		}
		
		public override function getValue():ConstraintValue
		{
			return val;
		}
		
		public function toString():String
		{
			return "var:" + id + "(=" + val.verbose + ")";
		}
	}

}