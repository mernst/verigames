package constraints 
{

	public class SubtypeConstraint extends Constraint 
	{
		public function SubtypeConstraint(_lhs:ConstraintVar, _rhs:ConstraintVar, _customScoring:ConstraintScoringConfig = null) 
		{
			super(Constraint.SUBTYPE, _lhs, _rhs, _customScoring);
		}
		
		public override function isSatisfied():Boolean
		{
			//trace(lhs + " <= " + rhs + " ? " + (lhs.getValue().intVal <= rhs.getValue().intVal));
			return lhs.getValue().intVal <= rhs.getValue().intVal;
		}
	}

}