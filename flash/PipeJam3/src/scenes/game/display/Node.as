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
		
		public var isSelected:Boolean;
		public var isEditable:Boolean;
		public var isNarrow:Boolean;
		public var isLocked:Boolean;
		public var isDirty:Boolean;
		
		public var startingSelectionState:Boolean;
		
		public var skin:NodeSkin;
		
		public var gridID:String;
		public var parentGrid:GridSquare;
		
		public var connectedEdgeIds:Vector.<String>;
		public var unused:Boolean;
		
		public function Node(_layoutObject:Object)
		{
			layoutObject = _layoutObject;
			x = layoutObject["x"];
			y = layoutObject["y"];
			unused = true;
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
				constraintVar.setProp(PropDictionary.PROP_NARROW, !_isWide);
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