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


	public class Node extends GridChild
	{
		public var graphConstraintSide:ConstraintSide;
		public var isClause:Boolean = false;
		
		public var connectors:Vector.<Quad>;
		
		public function Node(_layoutObject:Object, _id:String, _bb:Rectangle, _graphConstraintSide:ConstraintSide, _parentGrid:GridSquare)
		{
			super(_layoutObject, _id, _bb, _parentGrid);
			graphConstraintSide = _graphConstraintSide;
			
			connectors = new Vector.<Quad>;
		}
		
		public override function select():void
		{
			super.select();
			setDirty();
			parentGrid.isDirty = (skin != null);
		}
		
		public override function unselect():void
		{
			super.unselect();
			setDirty();
			parentGrid.isDirty = (skin != null);
		}
		
		public override function createSkin():void
		{
			super.createSkin();
			var newSkin:NodeSkin = NodeSkin.getNextSkin();
			if (newSkin == null) return;
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
				if (edgeObj) edgeObj.isDirty = true;
			}
		}
		
		override public function scaleSkin(newScaleX:Number, newScaleY:Number):void
		{
			// only used for ClauseNodes right now
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
		
		override public function setDirty(dirtyEdges:Boolean = false, flashChange:Boolean = false):void
		{
			super.setDirty(dirtyEdges);
			
			if(!isClause && flashChange)
			{
				if(skin)
					skin.flash();
			}
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
		
		public function addConnector(edge:Edge):void
		{
			var rot:Number = edge.skin.rotation;
			
	//		var dir:Number = edge.
			var connector:Image =  edge.skin.getConnectorTexture();
			connector.width = connector.height = 10;
			connector.alpha = .8;
			connector.x =  -5 * Math.cos(rot) + 5;
			connector.y = - 5 * Math.sin(rot) + 5;
			connectors.push(connector);
		}
		
	}
}