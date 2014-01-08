package constraints 
{

	public class TwoSidedConstraint extends Constraint 
	{
		public var lhs:ConstraintSide;
		public var rhs:ConstraintSide;
		public var customScoring:ConstraintScoringConfig;
		
		public function TwoSidedConstraint(_type:String, _lhs:ConstraintSide, _rhs:ConstraintSide, _customScoring:ConstraintScoringConfig = null) 
		{
			super(_type);
			lhs = _lhs;
			rhs = _rhs;
			customScoring = _customScoring;
		}
		
	}

}