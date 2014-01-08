package constraints 
{

	public class SubtypeConstraint extends TwoSidedConstraint 
	{
		public function SubtypeConstraint(_lhs:ConstraintSide, _rhs:ConstraintSide, _customScoring:ConstraintScoringConfig = null) 
		{
			super(Constraint.SUBTYPE, _lhs, _rhs, _customScoring);
		}
		
		public override function isSatisfied():Boolean
		{
			//trace(lhs + " <= " + rhs + " ? " + (lhs.getValue().val <= rhs.getValue().val));
			return lhs.getValue().val <= rhs.getValue().val;
		}
	}

}