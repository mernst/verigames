package scenes.game.display
{
	import events.MoveEvent;
	
	import flash.display.Shape;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.Dictionary;
	
	import graph.BoardNodes;
	import graph.Edge;
	import graph.EdgeSetRef;
	import graph.LevelNodes;
	import graph.Node;
	import graph.Port;
	
	import scenes.BaseComponent;
	import scenes.game.components.WorldMapLevelImage;
	
	import starling.display.Quad;
	import starling.events.Event;
	import starling.events.Touch;
	import starling.events.TouchEvent;
	import starling.events.TouchPhase;
	
	/**
	 * Level contains multiple boards that each contain multiple pipes
	 */
	public class Level extends BaseComponent
	{
		
		/** True to allow user to navigate to any level regardless of whether levels below it are solved for debugging */
		public static var UNLOCK_ALL_LEVELS_FOR_DEBUG:Boolean = false;
		
		/** True if the balls should be dropped when the level has been solved, rather than displaying fireworks right away */
		public static const DROP_WHEN_SUCCEEDED:Boolean = false;
				
		/** Name of this level */
		public var level_name:String;
				
		/** True if not all boards on this level have succeeded */
		public var failed:Boolean = true;
		
		/** The array that describes which color corresponds to a given edge set index */
		private static var set_index_colors:Dictionary = new Dictionary();// set_index_colors[id] = 0xXXXXX (i.e. 0xFFFF00)
		
		/** Index indicating the next color to be used when assigning to an edge set index */
		public static var color_index:uint = 0;
		
		/** True if this level has been solves and fireworks displayed, setting this will prevent euphoria from being displayed more than once */
		public var level_has_been_solved_before:Boolean = false;
		
		/** All levels that contain a copy of a board from this level as a subboard on a board on that level */
		public var levels_that_depend_on_this_level:Vector.<Level>;
		
		/** All levels containing boards that appear as subboards on any boards in this level */
		public var levels_that_this_level_depends_on:Vector.<Level>;
		
		/** True if the levels that this level depends on have been solved, and the user can visit this level */
		public var unlocked:Boolean = true;
		
		/** Rank refers to have many levels of dependency this level has. If no dependencies: rank = 0, if this level 
		 * depends one level (contains a subboard from another level) that also depends on a level (contains a 
		 * subboard from another level) then rank = 2, etc. 
		 * This will correspond to how high up the level should be on the world map (0 = low, towards Start) */
		public var rank:uint = 0;
		
		/** Index of this level within the overall rank, i.e. the 2nd level of rank = 5 has rank_index = 1, this may equate to 
		 * an X coordinate on the world map */
		public var rank_index:uint = 0;
		
		
		/** The icon associated with this level on the world map */
		public var level_icon:WorldMapLevelImage;
						
		/** Node collection used to create this level, including name obfuscater */
		public var levelNodes:LevelNodes;
		
		private var m_edgeSetLayoutXML:XML;
		private var m_edgeVector:Vector.<GameEdgeContainer>;

		protected var edgeDictionary:Dictionary = new Dictionary;
		protected var edgeSetDictionary:Dictionary = new Dictionary;
				
		private var selectedComponents:Vector.<GameComponent>;
		
		protected var marqueeRect:starling.display.Shape = new starling.display.Shape;
		
		
		public static var LEVEL_SELECTED:String = "level_selected";
		public static var COMPONENT_SELECTED:String = "component_selected";
		public static var COMPONENT_UNSELECTED:String = "component_unselected";
		public static var GROUP_SELECTED:String = "group_selected";
		public static var GROUP_UNSELECTED:String = "group_unselected";
		public static var EDGE_SET_CHANGED:String = "edge_set_changed";
		public static var MOVE_EVENT:String = "move_event";
		public static var SCORE_CHANGED:String = "score_changed";
		public static var CENTER_ON_NODE:String = "center_on_node";
		
		public var m_levelLayoutXML:XML;
		private var m_gameNodeDictionary:Dictionary;
		public var m_nodeList:Vector.<GameNode>;
		public var m_boundingBox:Rectangle;
		
		/**
		 * Level contains multiple boards that each contain multiple pipes
		 * @param	_x X coordinate, this is currently unused
		 * @param	_y Y coordinate, this is currently unused
		 * @param	_width Width, this is currently unused
		 * @param	_height Height, this is currently unused
		 * @param	_name Name of the level
		 * @param	_world The parent world that contains this level
		 * @param  _levelNodes The node objects used to create this level (including name obfuscater)
		 */
		public function Level( _name:String, _levelNodes:LevelNodes, _levelLayoutXML:XML)
		{
			UNLOCK_ALL_LEVELS_FOR_DEBUG = PipeJamGame.DEBUG_MODE;
			level_name = _name;
			levelNodes = _levelNodes;
			m_levelLayoutXML = _levelLayoutXML;
			color_index = 0;
			level_has_been_solved_before = false;
			levels_that_depend_on_this_level = new Vector.<Level>();
			levels_that_this_level_depends_on = new Vector.<Level>();
				
		}
		
		public function initialize():void
		{

			m_edgeVector = new Vector.<GameEdgeContainer>;
			setDisplayData();
			
			addEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
			addEventListener(Event.REMOVED_FROM_STAGE, onRemovedFromStage);			
		}
		
		protected function onAddedToStage(event:starling.events.Event):void
		{
			selectedComponents = new Vector.<GameComponent>;
			var count:int = 0;
			var maxCount:int = 150;
			for each(var boardNode:BoardNodes in levelNodes.boardNodesDictionary)
			{
				for each(var node:Node in boardNode.nodeDictionary)
				{
					//collect all the edges and edge sets
					for each(var port:Port in node.outgoing_ports)
					{
						var edge:Edge = port.edge;
						edgeDictionary[edge.edge_id] = edge;
						edgeSetDictionary[edge.linked_edge_set.id] = edge.linked_edge_set;
					}
				}
			}
			trace(m_levelLayoutXML.@id);
			//find bounding box, to set scale
			m_boundingBox = findBoundingBox(m_levelLayoutXML);
			
			//create node for sets
			m_nodeList = new Vector.<GameNode>; 
			var gameNodeSetDictionary:Dictionary = new Dictionary;
			for each(var edgeSet:EdgeSetRef in edgeSetDictionary)
			{
				//find the layout information for the node
				var edgeSetLayoutXML:XML = findEdgeSetLayoutInfo(edgeSet.id);
				if(edgeSetLayoutXML == null)
					trace("missing edgeSetLayoutXML " + edgeSet.id);
				
				//grab an example edge for it's attributes FIX - use constraints xml file
				var sampleEdge:Edge = edgeDictionary[edgeSet.edge_ids[0]];
				var gameNodeSet:GameNode = new GameNode(edgeSetLayoutXML, edgeSet, sampleEdge);
				m_nodeList.push(gameNodeSet);
				gameNodeSetDictionary[edgeSet.id] = gameNodeSet;
				
				trace(gameNodeSet.boundingBox.x + " " + gameNodeSet.boundingBox.y);
				count++;
			//	if(count >20)
			//		break;
			}
			
			trace("gamenodeset count = " + m_nodeList.length);
	
			var edgeXMLList:XMLList = m_levelLayoutXML.edge;
			

			for each(var edgeXML:XML in edgeXMLList)
			{
				var fromEdgeID:String = edgeXML.@from;
				var toEdgeID:String = edgeXML.@to;
				var fromEdgeSetID:String = edgeSetDictionary[fromEdgeID].id;
				var toEdgeSetID:String = edgeSetDictionary[toEdgeID].id;

				//normalize edge Array, and then slide game edge to right x,y value
				var minX:Number = Number.POSITIVE_INFINITY;
				var minY:Number = Number.POSITIVE_INFINITY;
				
				//create edge array
				var edgeArray:Array = new Array;
				
				var edgePoints:XMLList = edgeXML.point;
				for each(var pointXML:XML in edgePoints)
				{
					var pt:Point = new Point(pointXML.@x, pointXML.@y);
					edgeArray.push(pt);
				}
				//find min values, and then adjust by that
				for(var index:int = 0; index<edgeArray.length; index++)
				{
					if(minX > edgeArray[index].x)
						minX = edgeArray[index].x;
					if(minY > edgeArray[index].y)
						minY = edgeArray[index].y;
				}
				
				for(var i:int = 0; i<edgeArray.length; i++)
				{
					edgeArray[i].x -= minX;
					edgeArray[i].y -= minY;
				}
				
				var fromNodeSet:GameNode = gameNodeSetDictionary[fromEdgeSetID];
				var toNodeSet:GameNode = gameNodeSetDictionary[toEdgeSetID];
				
				var newGameEdge:GameEdgeContainer = new GameEdgeContainer(edgeArray, fromNodeSet, toNodeSet);
				newGameEdge.globalPosition = new Point(minX, minY);
				m_edgeVector.push(newGameEdge);
				fromNodeSet.setOutgoingEdge(newGameEdge);
				toNodeSet.setIncomingEdge(newGameEdge);
			}				
			
			draw();
			addEventListener(Level.EDGE_SET_CHANGED, onEdgeSetChange);
			addEventListener(Level.COMPONENT_SELECTED, onComponentSelection);
			addEventListener(Level.COMPONENT_UNSELECTED, onUnselectComponent);
			addEventListener(Level.GROUP_SELECTED, onGroupSelection);
			addEventListener(Level.GROUP_UNSELECTED, onGroupUnselection);
			addEventListener(Level.MOVE_EVENT, onMoveEvent);
			dispatchEvent(new starling.events.Event(LEVEL_SELECTED, true, this));
			
		}	
		
		protected function onRemovedFromStage(event:starling.events.Event):void
		{
			removeEventListener(Level.EDGE_SET_CHANGED, onEdgeSetChange);
			removeEventListener(Level.COMPONENT_SELECTED, onComponentSelection);
			removeEventListener(Level.COMPONENT_UNSELECTED, onUnselectComponent);
			removeEventListener(Level.GROUP_SELECTED, onGroupSelection);
			removeEventListener(Level.GROUP_UNSELECTED, onGroupUnselection);
			removeEventListener(Level.MOVE_EVENT, onMoveEvent);
			
			for each(var gameNodeSet:GameNode in m_nodeList)
			gameNodeSet.removeFromParent(true);
			
			m_nodeList = null;
			m_gameNodeDictionary = null;
			
			for each(var gameEdge:GameEdgeContainer in m_edgeVector)
			gameEdge.removeFromParent(true);
			
			m_edgeVector = null;
			this.removeChildren();
		}
		
		
		private function onTouch(event:TouchEvent):void
		{
			var touches:Vector.<Touch> = event.touches;
			if(event.getTouches(this, TouchPhase.MOVED).length){
				if (touches.length == 1)
				{
					// one finger touching -> move
					var x:int = 3;
				}
			}
		}
	
		//assume this only generates on toggle width events
		private function onEdgeSetChange(e:starling.events.Event):void
		{
			var edgeSet:EdgeSetRef = e.data as EdgeSetRef;
			
			for each (var edgeID:String in edgeSet.edge_ids)
			{
				var edge:Edge = this.edgeDictionary[edgeID];
				if(edge != null)
				{
					edge.is_wide = !edge.is_wide;
				}
			}
			dispatchEvent(new Event(Level.SCORE_CHANGED, true, this));
		}
		
		//data object should be in final selected/unselected state
		private function onComponentSelectionChanged(component:GameNode):void
		{		
			if(component.m_isSelected)
			{
				if(selectedComponents.indexOf(component) == -1)
					selectedComponents.push(component);
				//push any connecting edges that have both connected nodes selected
				for each(var edge:GameEdgeContainer in component.m_incomingEdges)
				{
					var connectedNode:GameNode = edge.m_fromNode;
					if(selectedComponents.indexOf(connectedNode) != -1)
					{
						if(selectedComponents.indexOf(edge) == -1)
							selectedComponents.push(edge);
						edge.componentSelected(true);
					}
				}
				for each(var edge1:GameEdgeContainer in component.m_outgoingEdges)
				{
					var connectedNode1:GameNode = edge1.m_toNode;
					if(selectedComponents.indexOf(connectedNode1) != -1)
					{
						if(selectedComponents.indexOf(edge1) == -1)
							selectedComponents.push(edge1);
						edge1.componentSelected(true);
					}
				}
			}
			else
			{
				var index:int = selectedComponents.indexOf(component);
				if(index != -1)
					selectedComponents.splice(index, 1);
				
				for each(var edge2:GameEdgeContainer in component.m_incomingEdges)
				{
					if(selectedComponents.indexOf(edge2) != -1)
					{
						var edgeIndex:int = selectedComponents.indexOf(edge2);
						selectedComponents.splice(edgeIndex, 1);
						edge2.componentSelected(false);
					}
				}
				for each(var edge3:GameEdgeContainer in component.m_outgoingEdges)
				{
					if(selectedComponents.indexOf(edge3) != -1)
					{
						var edgeIndex1:int = selectedComponents.indexOf(edge3);
						selectedComponents.splice(edgeIndex1, 1);
						edge3.componentSelected(false);
					}
				}
			}
		}
		
		private function onComponentSelection(e:starling.events.Event):void
		{
			var component:GameNode = e.data as GameNode;
			if(component)
				onComponentSelectionChanged(component);
		}
		
		private function onUnselectComponent(e:starling.events.Event):void
		{
			var component:GameNode = e.data as GameNode;
			if(component)
				onComponentSelectionChanged(component);
		}
		
		private function onGroupSelection(e:starling.events.Event):void
		{
			var component:GameNode = e.data as GameNode;
			var groupDictionary:Dictionary = new Dictionary;
			component.findGroup(groupDictionary);
			
			for each(var comp:GameComponent in groupDictionary)
			{
				if(selectedComponents.indexOf(comp) == -1)
				{
					comp.componentSelected(true);
					if(comp is GameNode)
						onComponentSelectionChanged(comp as GameNode);
				}
			}
		}
		
		private function onGroupUnselection(e:starling.events.Event):void
		{
			var component:GameNode = e.data as GameNode;
			var groupDictionary:Dictionary = new Dictionary;
			component.findGroup(groupDictionary);
			
			for each(var comp:GameComponent in groupDictionary)
			{
				comp.componentSelected(false);
				if(comp is GameNode)
					onComponentSelectionChanged(comp as GameNode);
			}
		}
		
		public function unselectAll():void
		{
			while(selectedComponents.length > 0)
			{
				var comp:GameComponent = selectedComponents[0];
				comp.componentSelected(false);
				if(comp is GameNode)
					onComponentSelectionChanged(comp as GameNode);
			}
		}
		
		private function onMoveEvent(e:starling.events.Event):void
		{
			var touch:Touch = e.data as Touch;
			
			var currentMoveLocation:Point = touch.getLocation(this);
			var previousLocation:Point = touch.getPreviousLocation(this);
			var delta:Point = currentMoveLocation.subtract(previousLocation);
			
			for each(var component:GameComponent in selectedComponents)
				component.componentMoved(delta);
		}
		
		//to be called once to set everything up 
		//to move/update objects use update events
		public function draw():void
		{
			//add two quads at opposite corners to cause the size to be right
			var p:Quad = new Quad(1, 1, 0xff0000);
			var q:Quad = new Quad(1, 1, 0xff0000);
			p.x = 0;
			p.y = 0;
			q.x = m_boundingBox.width-1;
			q.y = m_boundingBox.height-1;
			
			addChild(p);
			addChild(q);
			
//			//bound out temp boundaries
//			//add two lines at opposite corners to cause the size to be right
//			var p1:Quad = new Quad(2*m_boundingBox.width, 1, 0xff0000);
//			var q1:Quad = new Quad(2*m_boundingBox.width, 1, 0xff0000);
//			p1.x = -0.5*m_boundingBox.width;
//			p1.y = -0.5*m_boundingBox.height;
//			q1.x = -0.5*m_boundingBox.width;
//			q1.y = 1.5*m_boundingBox.height;
//			
//			addChild(q1);
//			addChild(p1);
			

			
			var maxX:Number = Number.NEGATIVE_INFINITY;
			var maxY:Number = Number.NEGATIVE_INFINITY;
			
			var count:int = 1
			for each(var gameNodeSet:GameNode in m_nodeList)
			{
				gameNodeSet.x = gameNodeSet.globalPosition.x - m_boundingBox.x;
				gameNodeSet.y = gameNodeSet.globalPosition.y - m_boundingBox.y;
				addChild(gameNodeSet);
				gameNodeSet.addedToStage = true;
				count++;
			}

			for each(var gameEdge:GameEdgeContainer in m_edgeVector)
			{
			//	if(gameEdge.m_fromNode.m_outgoingEdges.indexOf(gameEdge) > 2)
				{
					gameEdge.x = gameEdge.globalPosition.x - m_boundingBox.x;
					gameEdge.y = gameEdge.globalPosition.y - m_boundingBox.y;
					addChild(gameEdge);
					count++;
				}
			}
		}
		
		
		protected function setDisplayData():void
		{
		//	var displayNode
		}
		
		
		
		public function findEdgeSetLayoutInfo(name:String):XML
		{
			var edgeSetList:XMLList = m_levelLayoutXML.edgeset;
			for each(var layout:XML in edgeSetList)
			{
				//contains the name, and it's at the end to avoid matches like level_name1
				var levelName:String = layout.@id;
				
				if(levelName == name)
				{
					edgeSetList = null;
					return layout;
				}
			}
			edgeSetList = null;
			return null;
		}
		
		public function handleMarquee(startingPoint:Point, currentPoint:Point):void
		{
			if(startingPoint != null)
			{
				marqueeRect.removeChildren();
				marqueeRect.graphics.lineStyle(1, 0xffffff);
				marqueeRect.graphics.moveTo(0,0);
				var pt1:Point = globalToLocal(startingPoint);
				var pt2:Point = globalToLocal(currentPoint);
				marqueeRect.graphics.lineTo(pt2.x-pt1.x, 0);
				marqueeRect.graphics.lineTo(pt2.x-pt1.x, pt2.y-pt1.y);
				marqueeRect.graphics.lineTo(0, pt2.y-pt1.y);
				marqueeRect.graphics.lineTo(0, 0);
				marqueeRect.x = pt1.x;
				marqueeRect.y = pt1.y;
				//do here to make sure we are on top
				addChild(marqueeRect);
			}
			else
			{
				
				for each(var node:GameNode in m_nodeList)
				{
					var bottomRight:Point = globalToLocal(node.bounds.bottomRight);
					var topLeft:Point = globalToLocal(node.bounds.topLeft);
					var topRight:Point = globalToLocal(new Point(node.bounds.right, node.bounds.top));
					var bottomLeft:Point = globalToLocal(new Point(node.bounds.left, node.bounds.bottom));
					var mbottomLeft:Point = globalToLocal(new Point(marqueeRect.x, marqueeRect.y));

					if((marqueeRect.bounds.left < node.bounds.left && marqueeRect.bounds.right > node.bounds.left) || 
						(marqueeRect.bounds.left < node.bounds.right && marqueeRect.bounds.right > node.bounds.right))
					{
						if((marqueeRect.bounds.top < node.bounds.bottom && marqueeRect.bounds.bottom > node.bounds.bottom) || 
							(marqueeRect.bounds.top < node.bounds.top && marqueeRect.bounds.bottom > node.bounds.top))
						{
							node.componentSelected(!node.m_isSelected);
							var event:Event = new Event("temp", false, node);
							this.onComponentSelection(event);
						}
					}
					
				}
				removeChild(marqueeRect);
			}
			
			
		}
	}
}