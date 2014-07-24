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
		
		public function selectNode(selectedNodes:Dictionary):void
		{
			isSelected = true;
			if (skin) skin.draw(); //setNodeDirty(false);
			parentGrid.isDirty = (skin != null);
			parentGrid.NumNodesSelected++;
			selectedNodes[id] = this;
		}
		
		public function unselectNode(selectedNodes:Dictionary):void
		{
			isSelected = false;
			parentGrid.NumNodesSelected--;
			if (skin) skin.draw(); //setNodeDirty(false);
			parentGrid.isDirty = (skin != null);
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
					var edgeObj:Object = World.m_world.active_level.edgeLayoutObjs[gameEdgeID];
					edgeObj.isDirty = true;
				}
			}
		}
		
		public function updateSelectionAssignment(_isWide:Boolean, levelGraph:ConstraintGraph):void
		{
			if(isEditable)
			{
				isNarrow = !_isWide;
				isDirty = true;
				var constraintVar:ConstraintVar = levelGraph.variableDict[id];
				if (constraintVar.getProps().hasProp(PropDictionary.PROP_NARROW) == _isWide) constraintVar.setProp(PropDictionary.PROP_NARROW, !_isWide);
			}
		}
		
		//looks at each edge, and if there's a conflict, returns true
		public function hasError():Boolean
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