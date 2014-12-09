package constraints
{
	import scenes.game.display.Node;
	import scenes.game.display.World;

	public class ClauseConstraint extends Constraint
	{
		public function ClauseConstraint(_lhs:ConstraintVar, _rhs:ConstraintVar, _scoring:ConstraintScoringConfig)
		{
			super(Constraint.CLAUSE, _lhs, _rhs, _scoring);
			lhs.lhsConstraints.push(this);
			rhs.rhsConstraints.push(this);
		}
		
		public override function isSatisfied():Boolean
		{
			return isClauseSatisfied("", false);
		}
		
		public function isClauseSatisfied(varIdChanged:String, newPropValue:Boolean):Boolean
		{
			//there must be a better way, but I need to find the node associated with the clause end of this constraint,
			// and see if it's satisfied or not
			var clauseID:String;
			if(lhs.id.indexOf('c') != -1)
				clauseID = lhs.id;
			else
				clauseID = rhs.id;
			
			var clause:Node = World.m_world.active_level.nodeLayoutObjs[clauseID];
			if(clause)
				return clause.isSatisfied(varIdChanged, newPropValue);
			
			return false; //it's an error to get here
		}
	}
}