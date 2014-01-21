package constraints 
{

	public class EqualityConstraint extends Constraint 
	{
		public function EqualityConstraint(_lhs:ConstraintVar, _rhs:ConstraintVar, _customScoring:ConstraintScoringConfig = null) 
		{
			super(Constraint.EQUALITY, _lhs, _rhs, _customScoring);
		}
		
		public override function isSatisfied():Boolean
		{
			//trace(lhs + " == " + rhs + " ? " + (lhs.getValue().intVal == rhs.getValue().intVal));
			return lhs.getValue().intVal == rhs.getValue().intVal;
		}
	}

}