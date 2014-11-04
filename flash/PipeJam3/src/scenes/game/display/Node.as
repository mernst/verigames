package scenes.game.display
{
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.Dictionary;
	
	import constraints.ClauseConstraint;
	import constraints.ConstraintGraph;
	import constraints.ConstraintVar;
	
	import graph.PropDictionary;
	
	import starling.display.Image;
	import starling.display.Quad;


	public class Node extends GridChild
	{
		public var graphVar:ConstraintVar;
		public var isClause:Boolean = false;
		
		public var connectors:Vector.<Quad>;
		
		public var _hasError:Boolean = false;
		public var _hadError:Boolean = false;
		
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
		
		override public function scaleSkin(newScaleX:Number, newScaleY:Number):void
		{

			super.scaleSkin(newScaleX, newScaleY);
			
			//check to see if we have an error, and if so, scale our error marker at a lower rate
			if(_hasError)
			{
				var currentWidth:Number = skin.width;
				skin.scaleX = skin.scaleY = 1 / World.m_world.active_level.scaleX / World.m_world.active_level.parent.scaleX;
				var newWidth:Number = skin.width;
				skin.x -= (newWidth-currentWidth)/2;
				skin.y -= (newWidth-currentWidth)/2;
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
		
		override public function setDirty(dirtyEdges:Boolean = false, flashChange:Boolean = false):void
		{
			super.setDirty(dirtyEdges);
			
			if(!isClause && flashChange)
			{
				if(skin)
					skin.flash();
			}
		}
		
		public override function hasError():Boolean
		{
			return _hasError;
		}
		
		public function hadError():Boolean
		{
			return _hadError;
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
		
		public function addError(addError:Boolean):void
		{
			if(isClause)
			{
				_hasError = addError;
				setDirty(true);
			}			
		}
		
		//used for clause type graphs
		public function isSatisfied(varIdChanged:String, valueToCheck:Boolean):Boolean
		{
			var _isSatisfied:Boolean = false;
			var clauseConstraint:ClauseConstraint;
			var narrowValue:Boolean;
			
			for each(var gameEdgeID:String in connectedEdgeIds)
			{
				var edge:Edge = World.m_world.active_level.edgeLayoutObjs[gameEdgeID];
				var toNode:Node = edge.toNode; //this should be us
				var fromNode:Node = edge.fromNode;
				
				var fromNodeID:String = fromNode.id;
				//find conntecting clause which contains from node, check if that combination is satisfied
				var found:Boolean = false;
				for each(clauseConstraint in graphVar.rhsConstraints)
				{
					if(clauseConstraint.id.indexOf(fromNodeID) != -1)
					{
						found = true;
						narrowValue = fromNode.isNarrow;
						if(fromNode.id == varIdChanged)
							narrowValue = valueToCheck;
						//if on rhs we want incoming to be narrow
						if(narrowValue)
						{
							return true;
						}
					}
				}
				//if we didn't find it, check the lhs constraints
				if(!found)
				{
					for each(clauseConstraint in graphVar.lhsConstraints)
					{
						if(clauseConstraint.id.indexOf(fromNodeID) != -1)
						{
							found = true;
							narrowValue = fromNode.isNarrow;
							if(fromNode.id == varIdChanged)
								narrowValue = valueToCheck;
							//if on lhs we want incoming to be wide
							if(!narrowValue)
							{
								return true;
							}
						}
					}
				}
			}
			return false;
			
		}
	}
}