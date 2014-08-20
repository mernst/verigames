package scenes.game.display
{
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.Dictionary;
	
	import constraints.ConstraintGraph;
	import constraints.ConstraintVar;
	
	import graph.PropDictionary;


	public class Node
	{
		public var id:String;
		
		public var layoutObject:Object;
		public var x:Number;
		public var y:Number;
		
		public var graphVar:ConstraintVar;
		
		public var bb:Rectangle;
		public var centerPoint:Point;
		
		public var isSelected:Boolean = false;
		public var isEditable:Boolean;
		public var isNarrow:Boolean;
		public var isLocked:Boolean = false;
		public var isDirty:Boolean = false;
		
		public var startingSelectionState:Boolean = false;
		
		public var skin:NodeSkin;
		
		public var parentGrid:GridSquare;
		
		public var connectedEdgeIds:Vector.<String> = new Vector.<String>();
		public var unused:Boolean = true;
		
		public function Node(_layoutObject:Object, _id:String, _bb:Rectangle, _graphVar:ConstraintVar, _parentGrid:GridSquare)
		{
			layoutObject = _layoutObject;
			id = _id;
			bb = _bb;
			graphVar = _graphVar;
			parentGrid = _parentGrid;
			
			x = layoutObject["x"];
			y = layoutObject["y"];
			//calculate center point
			var xCenter:Number = bb.x + bb.width * .5;
			var yCenter:Number = bb.y + bb.height * .5;
			centerPoint = new Point(xCenter, yCenter);
			isNarrow = graphVar.getProps().hasProp(PropDictionary.PROP_NARROW);
			isEditable = !graphVar.constant;
			
			isDirty = true;
		}
		
		public function updateNode():void
		{
			if (skin) {
				skin.removeFromParent();
				skin.disableSkin();
			}
			
			skin = NodeSkin.getNextSkin();
			skin.setNode(this);
			skin.draw();
			
			skin.x = centerPoint.x - parentGrid.componentXDisplacement - 0.5 * skin.width;
			skin.y = centerPoint.y - parentGrid.componentYDisplacement - 0.5 * skin.height;
			
			setNodeDirty(true);
		}
		
		public function selectNode(selectedNodes:Dictionary):void
		{
			isSelected = true;
			setNodeDirty(false);
			parentGrid.NumNodesSelected++;
			selectedNodes[id] = this;
		}
		
		public function unselectNode(selectedNodes:Dictionary):void
		{
			isSelected = false;
			parentGrid.NumNodesSelected--;
			setNodeDirty(false);
			delete selectedNodes[id];
		}
		
		public function lockNode():void
		{
			if(isLocked == false)
			{
				isLocked = true;
				setNodeDirty(false);
			}
		}
		
		public function unlockNode():void
		{
			if(isLocked == true)
			{
				isLocked = false;
				setNodeDirty(false);
			}
		}
		
		
		public function setNodeDirty(dirtyEdges:Boolean = false):void
		{
			//set self dirty also
			parentGrid.isDirty = true;
			isDirty = true;
			if(dirtyEdges)
			{
				for each(var gameEdgeID:String in connectedEdgeIds)
				{
					var edge:Edge = World.m_world.active_level.edgeLayoutObjs[gameEdgeID];
					edge.isDirty = true;
				}
			}
		}
		
		public function updateSelectionAssignment(_isWide:Boolean, levelGraph:ConstraintGraph, setEdgesDirty:Boolean = false):void
		{
			if(isEditable)
			{
				isNarrow = !_isWide;
				setNodeDirty(setEdgesDirty);
				var constraintVar:ConstraintVar = levelGraph.variableDict[id];
				if (constraintVar.getProps().hasProp(PropDictionary.PROP_NARROW) == _isWide) constraintVar.setProp(PropDictionary.PROP_NARROW, !_isWide);
			}
		}
		
		//looks at each edge, and if there's a conflict, returns true
		public function hasError():Boolean
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