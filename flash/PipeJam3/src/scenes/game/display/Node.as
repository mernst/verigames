package scenes.game.display
{
	import flash.geom.Rectangle;
	import flash.utils.Dictionary;
	
	import constraints.ConstraintGraph;
	import constraints.ConstraintSide;
	import constraints.ConstraintVar;
	
	import starling.events.Event;
	
	import utils.PropDictionary;
	
	public class Node extends GridChild
	{
		public var graphConstraintSide:ConstraintSide;
		public var isClause:Boolean = false;
		public var solved:Boolean = false;
		public var solverSelected:Boolean;
		public var solverSelectedColor:int;
		
		public function Node(_id:String, _bb:Rectangle, _graphConstraintSide:ConstraintSide)
		{
			super(_id, _bb);
			graphConstraintSide = _graphConstraintSide;
		}
		
		public override function select():void
		{
			super.select();
			setDirty();
		}
		
		public override function unselect():void
		{
			super.unselect();
			setDirty();
		}
		
		public override function createSkin():void
		{
			super.createSkin();
			skin = NodeSkin.getNextSkin();
			if (skin == null) return;
			skin.setNode(this);
			skin.x = centerPoint.x - 0.5 * skin.width;
			skin.y = centerPoint.y - 0.5 * skin.height;
			
			setEdgesDirty(true);
		}
		
		public override function removeSkin():void
		{
			super.removeSkin();
			if (skin) (skin as NodeSkin).disableSkin();
			for each(var gameEdgeID:String in connectedEdgeIds)
			{
				var edgeObj:Object = World.m_world.active_level.edgeLayoutObjs[gameEdgeID];
				if (edgeObj) edgeObj.isDirty = true;
			}
		}
		
		// TODO: move to VariableNode
		public override function updateSelectionAssignment(_isWide:Boolean, levelGraph:ConstraintGraph, setEdgesDirty:Boolean = false):void
		{
			super.updateSelectionAssignment(_isWide, levelGraph);
			setDirty(setEdgesDirty);
			var constraintVar:ConstraintVar = levelGraph.variableDict[id];
			if (constraintVar.getProps().hasProp(PropDictionary.PROP_NARROW) == _isWide) constraintVar.setProp(PropDictionary.PROP_NARROW, !_isWide);
		}
		
		public function setDirty(dirtyEdges:Boolean = false, flashChange:Boolean = false):void
		{
			super.setEdgesDirty(dirtyEdges);
			
			if(!isClause && flashChange)
			{
				if(skin)
					skin.flash();
			}
		}
	}
}