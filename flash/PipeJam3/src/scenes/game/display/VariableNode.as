package scenes.game.display
{
	import constraints.ConstraintSide;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.Dictionary;
	
	import constraints.ConstraintEdge;
	import constraints.ConstraintGraph;
	import constraints.ConstraintVar;
	
	import utils.PropDictionary;
	
	import starling.display.Image;
	import starling.display.Quad;


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