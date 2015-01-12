package scenes.game.display
{
	import flash.geom.Rectangle;
	
	import constraints.ConstraintVar;
	import utils.PropDictionary;
	
	public class VariableNode extends Node
	{
		
		public function VariableNode(_layoutObject:Object, _id:String, _bb:Rectangle, _graphVar:ConstraintVar, _parentGrid:GridSquare)
		{
			super(_layoutObject, _id, _bb, _graphVar, _parentGrid);
			//this is only intesting for non-clause Nodes
			isNarrow = graphVar.getProps().hasProp(PropDictionary.PROP_NARROW);
			isEditable = !graphVar.constant;
		}
		
		public function get graphVar():ConstraintVar { return graphConstraintSide as ConstraintVar; }
		
	}
}