package scenes.game.display
{
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.Dictionary;
	
	import constraints.ConstraintGraph;
	import constraints.ConstraintVar;
	
	import graph.PropDictionary;


	public class Node extends GridChild
	{
		public var graphVar:ConstraintVar;
		public var filterIsDirty:Boolean = false;
		
		public function Node(_layoutObject:Object, _id:String, _bb:Rectangle, _graphVar:ConstraintVar, _parentGrid:GridSquare)
		{
			super(_layoutObject, _id, _bb, _parentGrid);
			graphVar = _graphVar;
			isNarrow = graphVar.getProps().hasProp(PropDictionary.PROP_NARROW);
			isEditable = !graphVar.constant;
		}
		
		public override function select(selectedNodes:Dictionary):void
		{
			super.select(selectedNodes);
			//if (skin) createSkin();
			filterIsDirty = true;
			parentGrid.isDirty = (skin != null);
		}
		
		public override function unselect(selectedNodes:Dictionary):void
		{
			super.unselect(selectedNodes);
			//if (skin) createSkin();
			filterIsDirty = true;
			parentGrid.isDirty = (skin != null);
		}
		
		public override function createSkin():void
		{
			super.createSkin();
			var newSkin:NodeSkin = NodeSkin.getNextSkin();
			newSkin.setNode(this);
			newSkin.draw();
			skin = newSkin;
			
			skin.x = centerPoint.x - gridOffset.x - 0.5 * skin.width;
			skin.y = centerPoint.y - gridOffset.y - 0.5 * skin.height;
			
			filterIsDirty = false;
			setDirty(true);
		}
		
		public override function removeSkin():void
		{
			super.removeSkin();
			if (skin) (skin as NodeSkin).disableSkin();
		}
		
		public override function updateSelectionAssignment(_isWide:Boolean, levelGraph:ConstraintGraph):void
		{
			super.updateSelectionAssignment(_isWide, levelGraph);
			if(isEditable)
			{
				var constraintVar:ConstraintVar = levelGraph.variableDict[id];
				if (constraintVar.getProps().hasProp(PropDictionary.PROP_NARROW) == _isWide) constraintVar.setProp(PropDictionary.PROP_NARROW, !_isWide);
			}
		}
		
		//looks at each edge, and if there's a conflict, returns true
		public override function hasError():Boolean
		{
			for each(var gameEdgeID:String in connectedEdgeIds)
			{
				var edgeObj:Object = World.m_world.active_level.edgeLayoutObjs[gameEdgeID];
				var toNodeID:String = edgeObj["to_var_id"];
				var toNodeObj:Object = World.m_world.active_level.nodeLayoutObjs[toNodeID];
				var fromNodeID:String = edgeObj["from_var_id"];
				var fromNodeObj:Object = World.m_world.active_level.nodeLayoutObjs[fromNodeID];
				
				//error?
				if(!fromNodeObj.isNarrow && toNodeObj.isNarrow)
					return true;
			}
			return false;
		}
	}
}