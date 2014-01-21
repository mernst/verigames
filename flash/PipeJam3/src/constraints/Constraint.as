package constraints 
{
	
	public class Constraint 
	{
		public static const SUBTYPE:String = "subtype";
		public static const EQUALITY:String = "equality";
		public static const MAP_GET:String = "map.get";
		public static const IF_NODE:String = "selection_check";
		public static const GENERICS_NODE:String = "enabled_check";
		
		public var type:String;
		public var lhs:ConstraintVar;
		public var rhs:ConstraintVar;
		public var customScoring:ConstraintScoringConfig;
		
		public function Constraint(_type:String, _lhs:ConstraintVar, _rhs:ConstraintVar, _customScoring:ConstraintScoringConfig = null) 
		{
			type = _type;
			lhs = _lhs;
			rhs = _rhs;
			lhs.constraint = this;
			rhs.constraint = this;
			customScoring = _customScoring;
		}
		
		public function isSatisfied():Boolean
		{
			/* Implemented by children */
			return false;
		}
		
	}

}