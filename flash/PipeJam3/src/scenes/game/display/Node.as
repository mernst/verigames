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
			setDirty();
			parentGrid.isDirty = (skin != null);
		}
		
		public override function unselect(selectedNodes:Dictionary):void
		{
			super.unselect(selectedNodes);
			setDirty();
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
			
			setDirty(true);
		}
		
		public override function removeSkin():void
		{
			super.removeSkin();
			if (skin) (skin as NodeSkin).disableSkin();
			for each(var gameEdgeID:String in connectedEdgeIds)
			{
				var edgeObj:Object = World.m_world.active_level.edgeLayoutObjs[gameEdgeID];
				edgeObj.isDirty = true;
			}
		}
		
		public override function updateSelectionAssignment(_isWide:Boolean, levelGraph:ConstraintGraph, setEdgesDirty:Boolean = false):void
		{
			super.updateSelectionAssignment(_isWide, levelGraph);
			if(isEditable)
			{
				setDirty(setEdgesDirty);
				var constraintVar:ConstraintVar = levelGraph.variableDict[id];
				if (constraintVar.getProps().hasProp(PropDictionary.PROP_NARROW) == _isWide) constraintVar.setProp(PropDictionary.PROP_NARROW, !_isWide);
			}
		}
		
		//looks at each edge, and if there's a conflict, returns true
		public override function hasError():Boolean
		{
			for each(var gameEdgeID:String in connectedEdgeIds)
			{
				var edge:Edge = World.m_world.active_level.edgeLayoutObjs[gameEdgeID];
				var toNode:Node = edge.toNode;
				var fromNode:Node = edge.fromNode;
				
				//error?
				if(!fromNode.isNarrow && toNode.isNarrow)
					return true;
			}
			return false;
		}
		
		protected var visitedNodes:Dictionary;
		public function propagate(upstream:Boolean, visitedNodes:Dictionary):void
		{
			var gameEdgeID:String;
			var edgeObj:Edge;
			var toNodeID:String;
			var toNode:Node;
			var fromNodeID:String;
			var fromNode:Node;
						
			if(upstream)
			{
				for each(gameEdgeID in connectedEdgeIds)
				{
					edgeObj = World.m_world.active_level.edgeLayoutObjs[gameEdgeID];
					toNodeID = edgeObj.toNode.id;
					if(toNodeID == id)
					{
						fromNode = edgeObj.fromNode;
						fromNode.updateSelectionAssignment(!this.isNarrow, World.m_world.active_level.levelGraph, true);
						if(visitedNodes[fromNode.id] == null)
						{
							visitedNodes[fromNode.id] = fromNode;
							fromNode.propagate(upstream, visitedNodes);
						}
					}
				}
			}
			else
			{
				for each(gameEdgeID in connectedEdgeIds)
				{
					edgeObj = World.m_world.active_level.edgeLayoutObjs[gameEdgeID];
					toNodeID = edgeObj.toNode.id;
					fromNodeID = edgeObj.fromNode.id;
					if(fromNodeID == id)
					{
						toNode = edgeObj.toNode;
						if(visitedNodes[toNode.id] == null)
						{
							toNode.updateSelectionAssignment(!this.isNarrow, World.m_world.active_level.levelGraph, true);
							visitedNodes[toNode.id] = toNode;
							toNode.propagate(upstream, visitedNodes);
						}
					}
				}
			}
			
		}
	}
}