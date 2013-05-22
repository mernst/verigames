package scenes.game.display
{
	import events.BallTypeChangeEvent;
	import events.EdgeSetChangeEvent;
	import events.MoveEvent;
	import graph.NodeTypes;
	import graph.SubnetworkPort;
	
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
	import scenes.login.LoginHelper;
	
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
		
		private var edgeDictionary:Dictionary = new Dictionary;
		private var edgeSetDictionary:Dictionary = new Dictionary;
		
		private var selectedComponents:Vector.<GameComponent>;
		
		private var marqueeRect:starling.display.Shape = new starling.display.Shape;
		
		public static var LEVEL_SELECTED:String = "level_selected";
		public static var COMPONENT_SELECTED:String = "component_selected";
		public static var COMPONENT_UNSELECTED:String = "component_unselected";
		public static var GROUP_SELECTED:String = "group_selected";
		public static var GROUP_UNSELECTED:String = "group_unselected";
		public static var MOVE_EVENT:String = "move_event";
		public static var SCORE_CHANGED:String = "score_changed";
		public static var CENTER_ON_COMPONENT:String = "center_on_component";
		
		public static var SAVE_LAYOUT:String = "save_layout";
		public static var SET_NEW_LAYOUT:String = "set_new_layout";
		public static var SUBMIT_SCORE:String = "submit_score";
		public static var SAVE_LOCALLY:String = "save_locally";
		
		private var m_levelLayoutXML:XML;
		private var m_levelConstraintsXML:XML;
		
		private var boxDictionary:Dictionary;
		private var jointDictionary:Dictionary;
		private var edgeContainerDictionary:Dictionary;
		
		private var m_nodeList:Vector.<GameNode>;
		private var m_edgeList:Vector.<GameEdgeContainer>;
		private var m_jointList:Vector.<GameJointNode>;
		
		private var m_boundingBox:Rectangle;
		
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
		public function Level( _name:String, _levelNodes:LevelNodes, _levelLayoutXML:XML, _levelConstraintsXML:XML)
		{
			UNLOCK_ALL_LEVELS_FOR_DEBUG = PipeJamGame.DEBUG_MODE;
			level_name = _name;
			levelNodes = _levelNodes;
			m_levelLayoutXML = _levelLayoutXML;
			m_levelConstraintsXML = _levelConstraintsXML;
			color_index = 0;
			level_has_been_solved_before = false;
			levels_that_depend_on_this_level = new Vector.<Level>();
			levels_that_this_level_depends_on = new Vector.<Level>();
			
			initialize();
			setConstraints();
			
			addEventListener(Event.ADDED_TO_STAGE, onAddedToStage);	
			addEventListener(Event.REMOVED_FROM_STAGE, onRemovedFromStage);	
		}
		
		protected function initialize():void
		{
			m_edgeList = new Vector.<GameEdgeContainer>;
			selectedComponents = new Vector.<GameComponent>;
			
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
			
			var minX:Number, minY:Number, maxX:Number, maxY:Number;
			minX = minY = maxX = maxY = 0;
			
			//create node for sets
			m_nodeList = new Vector.<GameNode>(); 
			boxDictionary = new Dictionary();
			edgeContainerDictionary = new Dictionary();

			// Process <box> 's
			for each(var boxLayoutXML:XML in m_levelLayoutXML.box)
			{
				var boxEdgeSetId:String = boxLayoutXML.@id;
				var gameNode:GameNode;
				if (!edgeSetDictionary.hasOwnProperty(boxEdgeSetId)) {
					// TODO: If we have another level with this subboard, produce a link here:
					if (boxEdgeSetId.indexOf(Constants.XML_ANNOT_EXT) == 0) {
						// Found a reference to an external SUBBOARD, create fixed node
						var isWide:Boolean = true; // TODO: get this from the defaultWidth property of the subboard port
						var isStarting:Boolean = false;
						if (boxEdgeSetId.indexOf(Constants.XML_ANNOT_EXT_OUT) > -1) {
							isWide = false;
							isStarting = true;
						}
						gameNode = new GameNodeFixed(boxLayoutXML, isWide, isStarting);
					} else {
						throw new Error("Couldn't find edge set for box id: " + boxLayoutXML.@id);
					}
				} else {
					var edgeSet:EdgeSetRef = edgeSetDictionary[boxEdgeSetId];
					//grab an example edge for it's attributes FIX - use constraints xml file
					var edgeSetEdges:Vector.<Edge> = new Vector.<Edge>();
					for each (var myEdgeId:String in edgeSet.edge_ids) {
						edgeSetEdges.push(edgeDictionary[myEdgeId]);
					}
					gameNode = new GameNode(boxLayoutXML, edgeSet, edgeSetEdges);
				}
				m_nodeList.push(gameNode);
				boxDictionary[boxEdgeSetId] = gameNode;
				
				minX = Math.min(minX, gameNode.m_boundingBox.left);
				minY = Math.min(minY, gameNode.m_boundingBox.top);
				maxX = Math.max(maxX, gameNode.m_boundingBox.right);
				maxY = Math.max(maxY, gameNode.m_boundingBox.bottom);
				
			}
			trace("gamenodeset count = " + m_nodeList.length);
			
			m_jointList = new Vector.<GameJointNode>();
			jointDictionary = new Dictionary();
			// Process <joint> 's
			for each(var jointLayoutXML:XML in m_levelLayoutXML.joint)
			{
				var jointID:String = jointLayoutXML.@id;
				var foundNode:Node = levelNodes.getNode(jointLayoutXML.@id);
				var inIndx:int = jointID.indexOf(Constants.XML_ANNOT_IN);
				var outIndx:int = jointID.indexOf(Constants.XML_ANNOT_OUT);
				var foundPort:Port;
				if (inIndx > -1) {
					foundNode = levelNodes.getNode(jointID.substring(0, inIndx));
					var inPortID:String = jointID.substring(inIndx + Constants.XML_ANNOT_IN.length);
					if (foundNode) {
						for each (var inport:Port in foundNode.incoming_ports) {
							if (inport.port_id == inPortID) {
								foundPort = inport;
								break;
							}
						}
					}
				} else if (outIndx > -1) {
					foundNode = levelNodes.getNode(jointID.substring(0, outIndx));
					var outPortID:String = jointID.substring(outIndx + Constants.XML_ANNOT_OUT.length);
					if (foundNode) {
						for each (var outport:Port in foundNode.outgoing_ports) {
							if (outport.port_id == outPortID) {
								foundPort = outport;
								break;
							}
						}
					}
				}
				
				if (foundNode) {
					// Check for INCOMING/OUTGOING/END/START_PIPE_DEPENDENT_BALL nodes, skip these
					switch (foundNode.kind) {
						case NodeTypes.INCOMING:
						case NodeTypes.START_PIPE_DEPENDENT_BALL:
						case NodeTypes.OUTGOING:
						case NodeTypes.END:
							continue;
					}
				}
				
				var joint:GameJointNode = new GameJointNode(jointLayoutXML, foundNode, foundPort);
				m_jointList.push(joint);
				jointDictionary[joint.m_id] = joint;
				
				minX = Math.min(minX, joint.m_boundingBox.left);
				minY = Math.min(minY, joint.m_boundingBox.top);
				maxX = Math.max(maxX, joint.m_boundingBox.right);
				maxY = Math.max(maxY, joint.m_boundingBox.bottom);
			}
			
			// Process <line> 's
			for each(var edgeXML:XML in m_levelLayoutXML.line)
			{
				var boundingBox:Rectangle = createLine(edgeXML);
				if (boundingBox) {
					minX = Math.min(minX, boundingBox.x);
					minY = Math.min(minY, boundingBox.y);
					maxX = Math.max(maxX, boundingBox.x+boundingBox.width);
					maxY = Math.max(maxY, boundingBox.y + boundingBox.height);
				}
			}
			//		trace("edge count = " + m_edgeVector.length);
			//set bounds based on largest x, y found in boxes, joints, edges
			m_boundingBox = new Rectangle(minX, minY, maxX - minX, maxY - minY);
			
			addEventListener(EdgeSetChangeEvent.EDGE_SET_CHANGED, onEdgeSetChange);
			addEventListener(Level.COMPONENT_SELECTED, onComponentSelection);
			addEventListener(Level.COMPONENT_UNSELECTED, onUnselectComponent);
			addEventListener(Level.GROUP_SELECTED, onGroupSelection);
			addEventListener(Level.GROUP_UNSELECTED, onGroupUnselection);
			addEventListener(Level.MOVE_EVENT, onMoveEvent);
		}
		
		public function setConstraints():void
		{
			for each(var boxConstraint:XML in m_levelConstraintsXML.box)
			{
				var gameNode:GameNode = boxDictionary[boxConstraint.@id];
				if(boxConstraint.@width == "narrow")
					gameNode.m_isWide = false;
				else
					gameNode.m_isWide = true;
			}
		}
		
		protected function createLine(edgeXML:XML, useExistingLines:Boolean = false):Rectangle
		{
			var edgeFromBox:XML = edgeXML.frombox[0];
			var edgeToJoint:XML = edgeXML.tojoint[0];
			var edgeFromJoint:XML = edgeXML.fromjoint[0];
			var edgeToBox:XML = edgeXML.tobox[0];
			var myNode:GameNode;
			var myJoint:GameJointNode;
			var dir:String;
			var boxId:String, jointId:String;
			if (edgeFromBox && edgeToJoint) {
				dir = GameEdgeContainer.DIR_BOX_TO_JOINT;
				boxId = edgeFromBox.@id;
				jointId = edgeToJoint.@id;
				myNode = boxDictionary[boxId];
				myJoint = jointDictionary[jointId];
			} else if (edgeFromJoint && edgeToBox) {
				dir = GameEdgeContainer.DIR_JOINT_TO_BOX;
				boxId = edgeToBox.@id;
				jointId = edgeFromJoint.@id;
				myNode = boxDictionary[boxId];
				myJoint = jointDictionary[jointId];
			} else {
				throw new Error("Level.as: Line found with unsupported to/from, must be from a joint to a box or vice-versa");
			}
			
			var edgeContainerID:String = edgeXML.@id;
			var index:int = edgeContainerID.indexOf('__');
			var edgeID:String = edgeContainerID.substring(0, index);
			var newEdge:Edge = this.edgeDictionary[edgeID];
			if (newEdge) {
				// Check for INCOMING/OUTGOING/END/START_PIPE_DEPENDENT_BALL nodes, skip these
				if (dir == GameEdgeContainer.DIR_JOINT_TO_BOX) {
					switch (newEdge.from_node.kind) {
						case NodeTypes.INCOMING:
						case NodeTypes.START_PIPE_DEPENDENT_BALL:
							//trace("Skip line id:" + edgeContainerID + " from:" + newEdge.from_node.kind + " to:" + newEdge.to_node.kind);
							return null;
					}
				} else {
					switch (newEdge.to_node.kind) {
						case NodeTypes.OUTGOING:
						case NodeTypes.END:
							//trace("Skip line id:" + edgeContainerID + " from:" + newEdge.from_node.kind + " to:" + newEdge.to_node.kind);
							return null;
					}
				}
			}
			
			//normalize edge Array, and then slide game edge to right x,y value
			var minXedge:Number = Number.POSITIVE_INFINITY;
			var minYedge:Number = Number.POSITIVE_INFINITY;
			var maxXedge:Number = Number.NEGATIVE_INFINITY;
			var maxYedge:Number = Number.NEGATIVE_INFINITY;
			
			//create edge array
			var edgeArray:Array = new Array;
			
			var edgePoints:XMLList = edgeXML.point;
			

			for each(var pointXML:XML in edgePoints)
			{
				var pt:Point = new Point(pointXML.@x, pointXML.@y);
				edgeArray.push(pt);
			}
			
			//we need to adjust array if we are just using start and end points
			if(!useExistingLines)
			{
				var newStartPt:Point = edgeArray[0];
				var newEndPt:Point = edgeArray[edgeArray.length-1];
				edgeArray = new Array;
				
				//adjust ends to make up for dot not quite aligning lines and boxes. As such we only
				//need to do this when using the starter layout, not ones chosen from the layout menu
				//TODO: make sure starter layout doesn't show in layout menu...
				if(dir == GameEdgeContainer.DIR_BOX_TO_JOINT)
				{
					newStartPt.y = myNode.m_boundingBox.y + myNode.m_boundingBox.height;
					newEndPt.y = myJoint.m_boundingBox.y;
				}
				else
				{
					newStartPt.y = myJoint.m_boundingBox.y + myJoint.m_boundingBox.height;
					newEndPt.y = myNode.m_boundingBox.y;
				}
				edgeArray.push(newStartPt);
				edgeArray.push(newEndPt);
			}
			
			var startPt:Point = edgeArray[0];
			var endPt:Point = edgeArray[edgeArray.length-1];
			//get bounding box points, using start and end points as reference
			if(startPt.x < endPt.x)
			{
				minXedge = startPt.x;
				maxXedge = endPt.x;
			}
			else
			{
				minXedge = endPt.x;
				maxXedge = startPt.x;
				
			}
			
			if(startPt.y < endPt.y)
			{
				minYedge = startPt.y;
				maxYedge = endPt.y;
			}
			else
			{
				minYedge = endPt.y;
				maxYedge = startPt.y;
			}
			
			//adjust by min
			for(var i:int = 0; i<edgeArray.length; i++)
			{
				edgeArray[i].x -= minXedge;
				edgeArray[i].y -= minYedge;
			}
			
			var lineID:String = edgeXML.@id;
			
			var bb:Rectangle = new Rectangle(minXedge, minYedge, (maxXedge-minXedge), (maxYedge-minYedge));
			var newGameEdge:GameEdgeContainer;
			// get editable property from related edge or end segment/joint
			
			var edgeIsCopy:Boolean = (edgeContainerID.indexOf(Constants.XML_ANNOT_COPY) > -1);
			if (dir == GameEdgeContainer.DIR_BOX_TO_JOINT) {
				newGameEdge = new GameEdgeContainer(edgeXML.@id, edgeArray, bb, myNode, myJoint, dir, newEdge, useExistingLines, edgeIsCopy);
			} else {
				newGameEdge = new GameEdgeContainer(edgeXML.@id, edgeArray, bb, myJoint, myNode, dir, newEdge, useExistingLines, edgeIsCopy);
			}
			m_edgeList.push(newGameEdge);
			
			edgeContainerDictionary[edgeContainerID] = newGameEdge;
			
			return bb;
		}
		
		public function takeSnapshot():LevelNodes
		{
			return levelNodes.clone();
		}
		
		protected function onAddedToStage(event:starling.events.Event):void
		{
			removeEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
			
			setDisplayData();
			
			draw();
			
			dispatchEvent(new starling.events.Event(LEVEL_SELECTED, true, this));
			trace(m_levelLayoutXML.@id);
			takeSnapshot();
		}	
		
		public function onSaveLayoutFile(event:starling.events.Event):void
		{
			updateLayoutXML();
			
			m_levelLayoutXML.@id = "Layout" + (Math.round(Math.random()*1000));
			LoginHelper.getLoginHelper().saveLayoutFile(m_levelLayoutXML);	
		}
		
		
		public function onSubmitScore(event:starling.events.Event):void
		{
			updateConstraintXML();
			m_levelLayoutXML.@id = "Layout" + (Math.round(Math.random()*1000));
			var currentScore:int = 300;
			LoginHelper.getLoginHelper().saveConstraintFile(m_levelConstraintsXML, currentScore);	
		}
		
		public function onSaveLocally(event:starling.events.Event):void
		{

		}
		
		protected function onRemovedFromStage(event:starling.events.Event):void
		{
			//disposeChildren();
		}
		
		public function setNewLayout(event:starling.events.Event, useExistingLines:Boolean = false):void
		{
			m_levelLayoutXML = event.data as XML;
			m_edgeList = new Vector.<GameEdgeContainer>;
			
			var minX:Number, minY:Number, maxX:Number, maxY:Number;
			minX = minY = maxX = maxY = 0;
			
			var children:XMLList = m_levelLayoutXML.children();
			//set box and joint positions first
			for each(var child:XML in children)
			{
				var childName:String = child.localName();
				var gameNode:GameNodeBase = null;
				if(childName.indexOf("box") != -1)
				{
					var boxID:String = child.@id;
					gameNode = boxDictionary[boxID];
				}
				else if(childName.indexOf("joint") != -1)
				{
					var jointID:String = child.@id;
					gameNode = jointDictionary[jointID];
				}
				
				if(gameNode)
				{
					gameNode.m_boundingBox.x = child.@x - gameNode.m_boundingBox.width/2;
					gameNode.m_boundingBox.y = child.@y - gameNode.m_boundingBox.height/2;
					
					minX = Math.min(minX, gameNode.m_boundingBox.left);
					minY = Math.min(minY, gameNode.m_boundingBox.top);
					maxX = Math.max(maxX, gameNode.m_boundingBox.right);
					maxY = Math.max(maxY, gameNode.m_boundingBox.bottom);
				}
			}
			//update lines
			edgeContainerDictionary = new Dictionary();
			for each(var edge:XML in m_levelLayoutXML.line)
			{
				var boundingBox:Rectangle = createLine(edge, useExistingLines);
					
				minX = Math.min(minX, boundingBox.x);
				minY = Math.min(minY, boundingBox.y);
				maxX = Math.max(maxX, boundingBox.x+boundingBox.width);
				maxY = Math.max(maxY, boundingBox.y+boundingBox.height);

			}
			m_boundingBox = new Rectangle(minX, minY, maxX - minX, maxY - minY);
			
			draw();
		}
		
		public function updateLayoutXML():void
		{
			var children:XMLList = m_levelLayoutXML.children();
			for each(var child:XML in children)
			{
				var childName:String = child.localName();
				if(childName.indexOf("box") != -1)
				{
					var boxID:String = child.@id;
					var edgeSet:GameNode = boxDictionary[boxID];
					child.@x = edgeSet.x + m_boundingBox.x + edgeSet.m_boundingBox.width/2;
					child.@y = edgeSet.y + m_boundingBox.y + edgeSet.m_boundingBox.height/2;
				}
				else if(childName.indexOf("joint") != -1)
				{
					var jointID:String = child.@id;
					var joint:GameJointNode = jointDictionary[jointID];
					child.@x = joint.x + m_boundingBox.x + joint.m_boundingBox.width/2;
					child.@y = joint.y + m_boundingBox.y + joint.m_boundingBox.height/2;
				}
				else if(childName.indexOf("line") != -1)
				{
					//remember first point to compare later
					var oldPoint:Point = new Point(child.point[2].@x, child.point[2].@y);
					//remove all current points, and then add new ones
					delete child.point;
					
					var lineID:String = child.@id;
					var edgeContainer:GameEdgeContainer = edgeContainerDictionary[lineID];
					if(edgeContainer.m_jointPoints.length != 6)
						trace("Wrong number of joint points");
					for(var i:int = 0; i<edgeContainer.m_jointPoints.length; i++)
					{
						var pt:Point = edgeContainer.m_jointPoints[i];
						var ptXML:XML = <point></point>;
						ptXML.@x = pt.x + edgeContainer.m_boundingBox.x;
						ptXML.@y = pt.y + edgeContainer.m_boundingBox.y;
						
						var ptt:Point = edgeContainer.localToGlobal(pt);
						var pttt:Point = globalToLocal(ptt);
					
						child.appendChild(ptXML);
					}
				}
			}
		}
		
		
		public function updateConstraintXML():void
		{
			delete m_levelConstraintsXML.box;
			
			for each(var node:GameNode in m_nodeList)
			{
				var id:String = node.m_id;
				var width:Boolean = node.m_isWide;
				var widthString:String = (width == true) ? "wide" : "narrow";
				
				var child:XML = <box/>;
				child.@id = id;
				child.@width = widthString;
					
				m_levelConstraintsXML.appendChild(child);
			}
		}
		

		
		override public function dispose():void
		{
			if (m_disposed) {
				return;
			}
			
			disposeChildren();
			
			removeEventListener(EdgeSetChangeEvent.EDGE_SET_CHANGED, onEdgeSetChange);
			removeEventListener(Level.COMPONENT_SELECTED, onComponentSelection);
			removeEventListener(Level.COMPONENT_UNSELECTED, onUnselectComponent);
			removeEventListener(Level.GROUP_SELECTED, onGroupSelection);
			removeEventListener(Level.GROUP_UNSELECTED, onGroupUnselection);
			removeEventListener(Level.MOVE_EVENT, onMoveEvent);
			
			for each(var gameNodeSet:GameNode in m_nodeList) {
				gameNodeSet.removeFromParent(true);
			}
			
			m_nodeList = null;
			boxDictionary = null;
			
			for each(var gameEdge:GameEdgeContainer in m_edgeList) {
				gameEdge.removeFromParent(true);
			}
			
			m_edgeList = null;
			
			super.dispose();
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
		private function onEdgeSetChange(evt:EdgeSetChangeEvent):void
		{
			var edgeSetID:String = evt.edgeSetChanged.m_id;
			var edgeSet:EdgeSetRef = edgeSetDictionary[edgeSetID];
			for each (var edgeID:String in edgeSet.edge_ids)
			{
				var edge:Edge = this.edgeDictionary[edgeID];
				if(edge != null)
				{
					edge.is_wide = !edge.is_wide;
				}
				//var outID:String = edgeID + "__OUT__";
				//var outgoingGameEdgeContainer:GameEdgeContainer = edgeContainerDictionary[outID];
				//if(outgoingGameEdgeContainer)
					//outgoingGameEdgeContainer.setIncomingWidth(edge.is_wide);
				//var inID:String = edgeID+"__IN__";
				//var incomingGameEdgeContainer:GameEdgeContainer = edgeContainerDictionary[inID];
				//if(incomingGameEdgeContainer)
					//incomingGameEdgeContainer.setIncomingWidth(edge.is_wide);
			}
			dispatchEvent(new EdgeSetChangeEvent(EdgeSetChangeEvent.LEVEL_EDGE_SET_CHANGED, evt.edgeSetChanged, this));
		}
		
		//data object should be in final selected/unselected state
		private function onComponentSelectionChanged(component:GameNodeBase):void
		{		
			if(component.m_isSelected)
			{
				if(selectedComponents.indexOf(component) == -1)
					selectedComponents.push(component);
				//push any connecting edges that have both connected nodes selected
				for each(var edge:GameEdgeContainer in component.m_incomingEdges)
				{
					var fromComponent:GameNodeBase = edge.m_fromComponent;
					if(selectedComponents.indexOf(fromComponent) != -1)
					{
						if(selectedComponents.indexOf(edge) == -1)
							selectedComponents.push(edge);
						edge.componentSelected(true);
					}
				}
				for each(var edge1:GameEdgeContainer in component.m_outgoingEdges)
				{
					var toComponent:GameNodeBase = edge1.m_toComponent;
					if(selectedComponents.indexOf(toComponent) != -1)
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
			var component:GameNodeBase = e.data as GameNodeBase;
			if(component)
				onComponentSelectionChanged(component);
		}
		
		private function onUnselectComponent(e:starling.events.Event):void
		{
			var component:GameNodeBase = e.data as GameNodeBase;
			if(component)
				onComponentSelectionChanged(component);
		}
		
		private function onGroupSelection(e:starling.events.Event):void
		{
			var component:GameNodeBase = e.data as GameNodeBase;
			var groupDictionary:Dictionary = new Dictionary;
			component.findGroup(groupDictionary);
			
			for each(var comp:GameComponent in groupDictionary)
			{
				if(selectedComponents.indexOf(comp) == -1)
				{
					comp.componentSelected(true);
					if(comp is GameNodeBase)
						onComponentSelectionChanged(comp as GameNodeBase);
				}
			}
		}
		
		private function onGroupUnselection(e:starling.events.Event):void
		{
			var component:GameNodeBase = e.data as GameNodeBase;
			var groupDictionary:Dictionary = new Dictionary;
			component.findGroup(groupDictionary);
			
			for each(var comp:GameComponent in groupDictionary)
			{
				comp.componentSelected(false);
				if(comp is GameNodeBase)
					onComponentSelectionChanged(comp as GameNodeBase);
			}
		}
		
		public function unselectAll():void
		{
			while(selectedComponents.length > 0)
			{
				var comp:GameComponent = selectedComponents[0];
				comp.componentSelected(false);
				if(comp is GameNodeBase)
					onComponentSelectionChanged(comp as GameNodeBase);
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
			//don't dispose as we are immediately re-adding them
			removeChildren();
			//add two quads at opposite corners to cause the size to be right
			var p:Quad = new Quad(.1, .1, 0xff0000);
			var q:Quad = new Quad(.1, .1, 0xff0000);
			p.x = 0;
			p.y = 0;
			q.x = (m_boundingBox.width-.1);
			q.y = (m_boundingBox.height-.1);
			
			addChild(p);
			addChild(q);
			trace("Bounding Box " + m_boundingBox.width + "  " + m_boundingBox.height);
			
			var maxX:Number = Number.NEGATIVE_INFINITY;
			var maxY:Number = Number.NEGATIVE_INFINITY;
			
			var nodeCount:int = 0;
			for each(var gameNode:GameNode in m_nodeList)
			{
				gameNode.x = gameNode.m_boundingBox.x - m_boundingBox.x;
				gameNode.y = gameNode.m_boundingBox.y - m_boundingBox.y;
				gameNode.m_isDirty = true;
				addChild(gameNode);
				nodeCount++;
			}
			
			var jointCount:int = 0;
			for each(var gameJoint:GameJointNode in m_jointList)
			{
				gameJoint.x = gameJoint.m_boundingBox.x - m_boundingBox.x;
				gameJoint.y = gameJoint.m_boundingBox.y - m_boundingBox.y;
				gameJoint.m_isDirty = true;
				addChild(gameJoint);
				jointCount++;
			}
			
			var edgeCount:int = 0;
			for each(var gameEdge:GameEdgeContainer in m_edgeList)
			{
				gameEdge.draw();
				addChild(gameEdge);
				gameEdge.x = (gameEdge.m_boundingBox.x - m_boundingBox.x);
				gameEdge.y = (gameEdge.m_boundingBox.y - m_boundingBox.y);
				edgeCount++;
			}
			trace("Nodes " + nodeCount + " NodeJoints " + jointCount + " Edges " + edgeCount);
		}
		
		
		protected function setDisplayData():void
		{
		//	var displayNode
		}
		
		
		
		public function findEdgeSetLayoutInfo(name:String):XML
		{
			var boxList:XMLList = m_levelLayoutXML.box;
			for each(var layout:XML in boxList)
			{
				var levelName:String = layout.@id;
				
				if(levelName == name)
				{
					boxList = null;
					return layout;
				}
			}
			boxList = null;
			return null;
		}
		
		public function handleMarquee(startingPoint:Point, currentPoint:Point):void
		{
			if(startingPoint != null)
			{
				marqueeRect.removeChildren();
				marqueeRect.graphics.lineStyle(.1, 0xffffff);
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
		
		public function getNodes():Vector.<GameNode>
		{
			return m_nodeList;
		}
	}
}