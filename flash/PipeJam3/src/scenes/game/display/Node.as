package scenes.game.display
{
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.Dictionary;
	
	import constraints.ConstraintGraph;
	import constraints.ConstraintVar;
	
	import graph.PropDictionary;
	
	import starling.display.Quad;
	import constraints.ClauseConstraint;


	public class Node extends GridChild
	{
		public var graphVar:ConstraintVar;
		public var isClause:Boolean = false;
		
		public var connectors:Vector.<Quad>;
		
		var hasErrorNow:Boolean = false;

		
		public function Node(_layoutObject:Object, _id:String, _bb:Rectangle, _graphVar:ConstraintVar, _parentGrid:GridSquare)
		{
			super(_layoutObject, _id, _bb, _parentGrid);
			graphVar = _graphVar;
			//this is only intesting for non-clause Nodes
			isNarrow = graphVar.getProps().hasProp(PropDictionary.PROP_NARROW);
			isEditable = !graphVar.constant;
			if(id.indexOf("c") != -1)
			{
				isEditable = false;
				isClause = true;
			}
			
			connectors = new Vector.<Quad>;
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
			
			setDirty(true);

		//	super.select(selectedNodes);
			if (skin) createSkin();
			parentGrid.isDirty = (skin != null);
		}
		
		public override function unselect(selectedNodes:Dictionary):void
		{
			super.unselect(selectedNodes);
			if (skin) createSkin();
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
		
		public function addConnector(edge:Edge):void
		{
			var toColor:int = NodeSkin.getColor(this, edge);
			var rot:Number = edge.skin.rotation;
			
	//		var dir:Number = edge.
			var q:Quad = new Quad(10,10,toColor);
			q.alpha = .8;
			q.x =  -5 * Math.cos(rot);
			q.y = - 5 * Math.sin(rot);
			trace("rotation", rot, q.x, q.y);
			connectors.push(q);

			
		}
		
		public function addError(addError:Boolean):void
		{
			if(isClause)
			{
				trace("add error "+ addError);
				hasErrorNow = addError;
				setDirty(true);
			}			
		}
		
		//used for clause type graphs
		public function isSatisfied():Boolean
		{
			var _isSatisfied:Boolean = false;
			for each(var gameEdgeID:String in connectedEdgeIds)
			{
				var edge:Edge = World.m_world.active_level.edgeLayoutObjs[gameEdgeID];
				var toNode:Node = edge.toNode; //this should be us
				var fromNode:Node = edge.fromNode;
				
				var fromNodeID:String = fromNode.id;
				//find conntecting clause which contains from node, check if that combination is satisfied
				var found:Boolean = false;
				for each(var clauseConstraint:ClauseConstraint in graphVar.rhsConstraints)
				{
					if(clauseConstraint.id.indexOf(fromNodeID) != -1)
					{
						found = true;
						//if on rhs we want incoming to be narrow
						if(fromNode.isNarrow)
						{
							trace(clauseConstraint.id + " happy");
							return true;
						}
						else
							trace(clauseConstraint.id + " not happy");
					}
				}
				//if we didn't find it, check the lhs constraints
				if(!found)
				{
					for each(var clauseConstraint:ClauseConstraint in graphVar.lhsConstraints)
					{
						if(clauseConstraint.id.indexOf(fromNodeID) != -1)
						{
							found = true;
							//if on lhs we want incoming to be wide
							if(!fromNode.isNarrow)
							{
								trace(clauseConstraint.id + " happy");
								return true;
							}
							else
								trace(clauseConstraint.id + " not happy");
						}
					}
				}
			}
			trace("sad");
			return false;
			
		}
	}
}