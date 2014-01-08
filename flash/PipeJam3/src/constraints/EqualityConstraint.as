package constraints 
{

	public class EqualityConstraint extends TwoSidedConstraint 
	{
		public function EqualityConstraint(_lhs:ConstraintSide, _rhs:ConstraintSide, _customScoring:ConstraintScoringConfig = null) 
		{
			super(Constraint.EQUALITY, _lhs, _rhs, _customScoring);
		}
		
		public override function isSatisfied():Boolean
		{
			//trace(lhs + " == " + rhs + " ? " + (lhs.getValue().val == rhs.getValue().val));
			return lhs.getValue().val == rhs.getValue().val;
		}
	}

}