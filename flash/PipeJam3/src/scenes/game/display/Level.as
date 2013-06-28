package scenes.game.display
{
	import assets.AssetInterface;
	import assets.AssetsAudio;
	import assets.AssetsFont;
	import audio.AudioManager;
	import events.BallTypeChangeEvent;
	import events.EdgeSetChangeEvent;
	import events.MoveEvent;
	import starling.display.BlendMode;
	import starling.display.Image;
	import starling.display.Sprite;
	import starling.filters.BlurFilter;
	import starling.textures.Texture;
	
	import flash.display.Shape;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.Dictionary;
	
	import graph.BoardNodes;
	import graph.Edge;
	import graph.EdgeSetRef;
	import graph.LevelNodes;
	import graph.Node;
	import graph.NodeTypes;
	import graph.Port;
	import graph.SubnetworkPort;
	
	import scenes.BaseComponent;
	import scenes.game.components.WorldMapLevelImage;
	import scenes.login.LoginHelper;
	
	import starling.display.Quad;
	import starling.events.Event;
	import starling.events.Touch;
	import starling.events.TouchEvent;
	import starling.events.TouchPhase;
	
	import utils.XString;
	
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
		//stored for undo
		private var selectionChangedComponents:Vector.<GameComponent>;
		
		private var marqueeRect:starling.display.Shape = new starling.display.Shape;
		
		public static var LEVEL_SELECTED:String = "level_selected";
		public static var COMPONENT_SELECTED:String = "component_selected";
		public static var COMPONENT_UNSELECTED:String = "component_unselected";
		public static var GROUP_SELECTED:String = "group_selected";
		public static var GROUP_UNSELECTED:String = "group_unselected";
		public static var MOVE_EVENT:String = "move_event";
		public static var CENTER_ON_COMPONENT:String = "center_on_component";
		
		public static var SAVE_LAYOUT:String = "save_layout";
		public static var SET_NEW_LAYOUT:String = "set_new_layout";
		public static var SUBMIT_SCORE:String = "submit_score";
		public static var SAVE_LOCALLY:String = "save_locally";
		
		public static var ERROR_ADDED:String = "error_added";
		public static var ERROR_REMOVED:String = "error_removed";
		public static var ERROR_MOVED:String = "error_moved";
		public static var MOVE_TO_POINT:String = "move_to_point";
		
		//the level node and decendents
		private var m_levelLayoutXML:XML;
		//used when saving, as we need a parent graph element for the above level node
		public var m_levelLayoutXMLWrapper:XML;
		private var m_levelConstraintsXML:XML;
		public var m_levelConstraintsXMLWrapper:XML;
		private var m_levelText:String;
		private var m_targetScore:int;
		
		private var boxDictionary:Dictionary;
		private var jointDictionary:Dictionary;
		private var edgeContainerDictionary:Dictionary;
		
		private var m_nodeList:Vector.<GameNode>;
		private var m_edgeList:Vector.<GameEdgeContainer>;
		private var m_jointList:Vector.<GameJointNode>;
		
		private var m_edgesContainer:Sprite = new Sprite();
		private var m_nodesContainer:Sprite = new Sprite();
		private var m_jointsContainer:Sprite = new Sprite();
		private var m_errorContainer:Sprite = new Sprite();
		
		public var m_boundingBox:Rectangle;
		private var m_backgroundImage:Image;
		private static const BG_WIDTH:Number = 256;
		private static const MIN_BORDER:Number = 1000;
		private static const USE_TILED_BACKGROUND:Boolean = false; // true to include a background that scrolls with the view
		
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
			
			m_levelText = m_levelLayoutXML.attribute("text").toString();
			
			m_targetScore = int.MAX_VALUE;
			if ((m_levelConstraintsXML.attribute("targetScore") != undefined) && !isNaN(int(m_levelConstraintsXML.attribute("targetScore")))) {
				m_targetScore = int(m_levelConstraintsXML.attribute("targetScore"));
			}
			
			initialize();
			setConstraints();
			
			if (USE_TILED_BACKGROUND) {
				var background:Texture = AssetInterface.getTexture("Game", "BoxesGamePanelBackgroundImageClass");
				background.repeat = true;
				m_backgroundImage = new Image(background);
				m_backgroundImage.width = m_backgroundImage.height = 2 * MIN_BORDER;
				m_backgroundImage.x = m_backgroundImage.y = -MIN_BORDER;
				m_backgroundImage.blendMode = BlendMode.NONE;
				addChild(m_backgroundImage);
			}
			
			m_nodesContainer.filter = BlurFilter.createDropShadow(4.0, 0.78, 0x0, 0.85, 2, 1);
			addChild(m_nodesContainer);
			addChild(m_jointsContainer);
			addChild(m_edgesContainer);
			addChild(m_errorContainer);
			
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
			minX = minY = Number.POSITIVE_INFINITY;
			maxX = maxY = Number.NEGATIVE_INFINITY;
			
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
				
				if(boxLayoutXML.hasOwnProperty('@visible'))
					gameNode.visible = boxLayoutXML.@visible == "true" ? true : false;
				
				m_nodeList.push(gameNode);
				boxDictionary[boxEdgeSetId] = gameNode;
				
				minX = Math.min(minX, gameNode.m_boundingBox.left);
				minY = Math.min(minY, gameNode.m_boundingBox.top);
				maxX = Math.max(maxX, gameNode.m_boundingBox.right);
				maxY = Math.max(maxY, gameNode.m_boundingBox.bottom);
				
				trace("Level " + m_levelLayoutXML.@id + " node m_boundingBox = " + gameNode.m_boundingBox);
				
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
						foundPort = foundNode.getIncomingPort(inPortID);
					}
				} else if (outIndx > -1) {
					foundNode = levelNodes.getNode(jointID.substring(0, outIndx));
					var outPortID:String = jointID.substring(outIndx + Constants.XML_ANNOT_OUT.length);
					if (foundNode) {
						foundNode.getOutgoingPort(outPortID);
					}
				}
				
				if (foundNode) {
					// Check for INCOMING/OUTGOING/END/START_PIPE_DEPENDENT_BALL nodes, skip these
					switch (foundNode.kind) {
						case NodeTypes.INCOMING:
						case NodeTypes.START_PIPE_DEPENDENT_BALL:
						case NodeTypes.END:
							continue;
						case NodeTypes.OUTGOING:
							// Only create the joint for an outgoing node if other lines connect
							// to it (these lines are the SUBBOARD outgoing ports that correspond
							// to this OUTGOING edge)
							var numOutputs:Number = Number(jointLayoutXML.@outputs);
							if (isNaN(numOutputs) || (numOutputs == 0)) {
								continue;
							}
					}
				}
				
				var joint:GameJointNode = new GameJointNode(jointLayoutXML, foundNode, foundPort);
				if(jointLayoutXML.hasOwnProperty('@visible'))
					joint.visible = jointLayoutXML.@visible == "true" ? true : false;
				m_jointList.push(joint);
				jointDictionary[joint.m_id] = joint;
				
				minX = Math.min(minX, joint.m_boundingBox.left);
				minY = Math.min(minY, joint.m_boundingBox.top);
				maxX = Math.max(maxX, joint.m_boundingBox.right);
				maxY = Math.max(maxY, joint.m_boundingBox.bottom);
				trace("Level " + m_levelLayoutXML.@id + " joint m_boundingBox = " + joint.m_boundingBox);
			}
			
			// Process <line> 's
			var copyLines:Vector.<GameEdgeContainer> = new Vector.<GameEdgeContainer>();
			for each(var edgeXML:XML in m_levelLayoutXML.line)
			{
				var boundingBox:Rectangle = createLine(edgeXML, false, copyLines);
				if (boundingBox) {
					minX = Math.min(minX, boundingBox.x);
					minY = Math.min(minY, boundingBox.y);
					maxX = Math.max(maxX, boundingBox.x+boundingBox.width);
					maxY = Math.max(maxY, boundingBox.y + boundingBox.height);
					trace("Level " + edgeXML.@id + " edge m_boundingBox = " + boundingBox);
				}
			}
			// At this point, there may be multiple lines listening to the same port for trouble points,
			// fix at this point so that only one line is listening to that port
			for each (var copyLine:GameEdgeContainer in copyLines) {
				var lineID:String = copyLine.m_id;
				var cpyIndx:int = lineID.indexOf(Constants.XML_ANNOT_COPY);
				if (cpyIndx == -1) {
					throw new Error("Unexpected line id found for copy line: " + lineID);
				}
				var nonCopyID:String = lineID.substring(0, cpyIndx);
				var foundLine:GameEdgeContainer = edgeContainerDictionary[nonCopyID];
				if (!foundLine) {
					throw new Error("No line found for lineID: " + nonCopyID);
				}
				foundLine.removeDuplicatePortListeners(copyLine);
			}
			
			//		trace("edge count = " + m_edgeVector.length);
			//set bounds based on largest x, y found in boxes, joints, edges
			m_boundingBox = new Rectangle(minX, minY, maxX - minX, maxY - minY);
			trace("Level " + m_levelLayoutXML.@id + " m_boundingBox = " + m_boundingBox);
			
			addEventListener(EdgeSetChangeEvent.EDGE_SET_CHANGED, onEdgeSetChange);
			addEventListener(Level.COMPONENT_SELECTED, onComponentSelection);
			addEventListener(Level.COMPONENT_UNSELECTED, onComponentUnselection);
			addEventListener(Level.GROUP_SELECTED, onGroupSelection);
			addEventListener(Level.GROUP_UNSELECTED, onGroupUnselection);
			addEventListener(Level.MOVE_EVENT, onMoveEvent);
		}
		
		public function setConstraints():void
		{
			for each(var boxConstraint:XML in m_levelConstraintsXML.box)
			{
				var gameNode:GameNode = boxDictionary[String(boxConstraint.@id)];
				if (!gameNode) {
					throw new Error("Box node not found for id found in constraints file:" + boxConstraint.@id);
				}
				var constraintIsEditable:Boolean = XString.stringToBool(String(boxConstraint.@editable));
				var constraintIsWide:Boolean = (boxConstraint.@width == "wide");
				if (constraintIsEditable) {
					gameNode.m_isWide = constraintIsWide;
				} else {
					if (gameNode.isWide() != constraintIsWide) {
						gameNode.m_isWide = constraintIsWide;
						trace(gameNode.m_id, "Mismatch between constraints file isWide=" + constraintIsWide + " and loaded layout box isWide=" + gameNode.isWide());
					}
				}
				if (constraintIsEditable != gameNode.isEditable()) {
					gameNode.m_isEditable = constraintIsEditable;
					trace(gameNode.m_id, "Mismatch between constraints file editable=" + constraintIsEditable + " and loaded layout box editable=" + gameNode.isEditable());
				}
			}
		}
		
		protected function createLine(edgeXML:XML, useExistingLines:Boolean = false, copyLines:Vector.<GameEdgeContainer> = null):Rectangle
		{
			if (copyLines == null) {
				copyLines = new Vector.<GameEdgeContainer>();
			}
			var edgeFromBox:XML = edgeXML.frombox[0];
			var edgeToJoint:XML = edgeXML.tojoint[0];
			var edgeFromJoint:XML = edgeXML.fromjoint[0];
			var edgeToBox:XML = edgeXML.tobox[0];
			var myNode:GameNode;
			var myJoint:GameJointNode;
			var dir:String;
			var boxId:String, jointId:String;
			var fromPortID:String, toPortID:String;
			if (edgeFromBox && edgeToJoint) {
				dir = GameEdgeContainer.DIR_BOX_TO_JOINT;
				boxId = edgeFromBox.@id;
				jointId = edgeToJoint.@id;
				fromPortID = edgeFromBox.@port;
				toPortID =  edgeToJoint.@port;
				myNode = boxDictionary[boxId];
				myJoint = jointDictionary[jointId];
			} else if (edgeFromJoint && edgeToBox) {
				dir = GameEdgeContainer.DIR_JOINT_TO_BOX;
				boxId = edgeToBox.@id;
				jointId = edgeFromJoint.@id;
				fromPortID = edgeFromJoint.@port;
				toPortID =  edgeToBox.@port;
				myNode = boxDictionary[boxId];
				myJoint = jointDictionary[jointId];
			} else {
				throw new Error("Level.as: Line found with unsupported to/from, must be from a joint to a box or vice-versa");
			}
			var edgeContainerID:String = edgeXML.@id;
			var index:int = edgeContainerID.indexOf('__');
			var edgeID:String = edgeContainerID.substring(0, index);
			var newEdge:Edge = this.edgeDictionary[edgeID];
			if (!newEdge) {
				throw new Error("Attempting to create line with no graph edge found, line id:" + edgeContainerID);
			}
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
						// Only need to create outgoing joint if others come out of it,
						// if joint was not created, don't create the line
						if (!myJoint) {
							return null;
						}
						break;
					case NodeTypes.END:
						//trace("Skip line id:" + edgeContainerID + " from:" + newEdge.from_node.kind + " to:" + newEdge.to_node.kind);
						return null;
				}
			}
			if (!myJoint) {
				trace("Warning! Joint not found for jointId: " + jointId);
			}
			if (!myNode) {
				trace("Warning! Box not found for boxId: " + boxId);
			}
			
			
			//create edge array
			var edgeArray:Array = new Array;
			
			var edgePoints:XMLList = edgeXML.point;
			for each(var pointXML:XML in edgePoints)
			{
				var pt:Point = new Point(pointXML.@x * Constants.GAME_SCALE, pointXML.@y * Constants.GAME_SCALE);
				edgeArray.push(pt);
			}
			
			//we need to adjust array if we are just using start and end points
			if(edgeArray.length == 2)
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
			if(edgeArray.length < 2)
				return null;
			
			var bb:Rectangle = createEdgePointBoundingBox(edgeArray);
			
			var lineID:String = edgeXML.@id;
			var newGameEdge:GameEdgeContainer;
			// get editable property from related edge or end segment/joint
			var edgeIsCopy:Boolean = (edgeContainerID.indexOf(Constants.XML_ANNOT_COPY) > -1);
			if (dir == GameEdgeContainer.DIR_BOX_TO_JOINT) {
				newGameEdge = new GameEdgeContainer(edgeXML.@id, edgeArray, bb, myNode, myJoint, fromPortID, toPortID, dir, newEdge, useExistingLines, edgeIsCopy);
			} else {
				newGameEdge = new GameEdgeContainer(edgeXML.@id, edgeArray, bb, myJoint, myNode, fromPortID, toPortID, dir, newEdge, useExistingLines, edgeIsCopy);
			}
			if(edgeXML.hasOwnProperty('@visible'))
				newGameEdge.visible = edgeXML.@visible == "true" ? true : false;
			
			m_edgeList.push(newGameEdge);
			if (edgeIsCopy) {
				copyLines.push(newGameEdge);
			}
			edgeContainerDictionary[edgeContainerID] = newGameEdge;
			return bb;
		}
		
		//figures out edge point min and max values, creates bounding box, and then normalizes points
		public function createEdgePointBoundingBox(edgeArray:Array):Rectangle
		{
			//normalize edge Array, and then slide game edge to right x,y value
			var minXedge:Number = Number.POSITIVE_INFINITY;
			var minYedge:Number = Number.POSITIVE_INFINITY;
			var maxXedge:Number = Number.NEGATIVE_INFINITY;
			var maxYedge:Number = Number.NEGATIVE_INFINITY;
			
			var startPt:Point = edgeArray[0];
			var endPt:Point = edgeArray[edgeArray.length-1];
			
			if(startPt == null || endPt == null)
				return null;
			
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
			
			var bb:Rectangle = new Rectangle(minXedge, minYedge, (maxXedge-minXedge), (maxYedge-minYedge));
			
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
			
			//now that everything is attached and added to parents, update port position indexes, for both nodes and joints
			for each(var nodeElem:GameNodeBase in m_nodeList)
			{
				nodeElem.updatePortIndexes();
			}
			for each(var jointElem:GameNodeBase in m_jointList)
			{
				jointElem.updatePortIndexes();
			}
			
			dispatchEvent(new starling.events.Event(LEVEL_SELECTED, true, this));
			trace(m_levelLayoutXML.@id);
			takeSnapshot();
		}	
		
		public function onSaveLayoutFile(event:starling.events.Event):void
		{
			updateLayoutXML();
			
			if(LoginHelper.levelObject != null)
			{
				m_levelLayoutXMLWrapper.@id = event.data;
				LoginHelper.getLoginHelper().saveLayoutFile(m_levelLayoutXMLWrapper);	
			}
			else
			{
				//save locally?
			}
		}
		
		
		public function onSubmitScore(event:starling.events.Event, currentScore:int):void
		{
			updateConstraintXML();
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
			//we might have ended up with a 'world', just grab the first level
			if(m_levelLayoutXML.level != undefined)
				m_levelLayoutXML = m_levelLayoutXML.level[0];
			
			m_edgeList = new Vector.<GameEdgeContainer>;
			
			var minX:Number, minY:Number, maxX:Number, maxY:Number;
			minX = minY = Number.POSITIVE_INFINITY;
			maxX = maxY = Number.NEGATIVE_INFINITY;
			
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
					gameNode.m_boundingBox.x = child.@x * Constants.GAME_SCALE - gameNode.m_boundingBox.width/2;
					gameNode.m_boundingBox.y = child.@y * Constants.GAME_SCALE - gameNode.m_boundingBox.height/2;
					if(child.hasOwnProperty('@visible'))
						gameNode.visible = child.@visible == "true" ? true : false;
					
					minX = Math.min(minX, gameNode.m_boundingBox.left);
					minY = Math.min(minY, gameNode.m_boundingBox.top);
					maxX = Math.max(maxX, gameNode.m_boundingBox.right);
					maxY = Math.max(maxY, gameNode.m_boundingBox.bottom);
				}
			}
			//update lines
			
			if(useExistingLines == false)
			{
				//delete all existing edges, and recreate
				for each(var existingEdge:GameEdgeContainer  in m_edgeList)
					existingEdge.parent.removeChild(existingEdge);
				edgeContainerDictionary = new Dictionary();
				m_edgeList = new Vector.<GameEdgeContainer>;
			}
				
			for each(var edge:XML in m_levelLayoutXML.line)
			{
				var edgeID:String = edge.@id;
				var edgeContainer:GameEdgeContainer = edgeContainerDictionary[edgeID];
				if(useExistingLines == false && edgeContainer == null)
				{
					var boundingBox:Rectangle = createLine(edge, useExistingLines);
					
					if(boundingBox)
					{
						minX = Math.min(minX, boundingBox.left);
						minY = Math.min(minY, boundingBox.top);
						maxX = Math.max(maxX, boundingBox.right);
						maxY = Math.max(maxY, boundingBox.bottom);
					}
				}
				else
				{
					if(edgeContainer)
					{
						//create edge array
						var edgeArray:Array = new Array;
						
						var edgePoints:XMLList = edge.point;
						for each(var pointXML:XML in edgePoints)
						{
							var pt:Point = new Point(pointXML.@x * Constants.GAME_SCALE, pointXML.@y * Constants.GAME_SCALE);
							edgeArray.push(pt);
						}
						var boundingBox:Rectangle = createEdgePointBoundingBox(edgeArray);
						edgeContainer.createLine(edgeArray);
						edgeContainer.m_boundingBox = boundingBox;
						edgeContainer.x = edgeContainer.m_boundingBox.x - m_boundingBox.x;
						edgeContainer.y = edgeContainer.m_boundingBox.y - m_boundingBox.y;
					}
				}
			}
			trace("Level " + m_levelLayoutXML.attribute("name") + " m_boundingBox = " + m_boundingBox);
			m_boundingBox = new Rectangle(minX, minY, maxX - minX, maxY - minY);
			
			draw();
		}
		
		//update current layout info based on node/edge position
		public function updateLayoutXML():void
		{
			var children:XMLList = m_levelLayoutXML.children();
			for each(var child:XML in children)
			{
				var childName:String = child.localName();
				var x:Number, y:Number;
				if(childName.indexOf("box") != -1)
				{
					var boxID:String = child.@id;
					var edgeSet:GameNode = boxDictionary[boxID];
					x = (edgeSet.x + m_boundingBox.x + edgeSet.m_boundingBox.width/2) / Constants.GAME_SCALE;
					child.@x = x.toFixed(2);
					y = (edgeSet.y + m_boundingBox.y + edgeSet.m_boundingBox.height/2) / Constants.GAME_SCALE;
					child.@y = y.toFixed(2);
					child.@visible = edgeSet.visible;
				}
				else if(childName.indexOf("joint") != -1)
				{
					var jointID:String = child.@id;
					var joint:GameJointNode = jointDictionary[jointID];
					if(joint != null)
					{
						x = (joint.x + m_boundingBox.x + joint.m_boundingBox.width/2) / Constants.GAME_SCALE;
						child.@x = x.toFixed(2);
						y = (joint.y + m_boundingBox.y + joint.m_boundingBox.height/2) / Constants.GAME_SCALE;
						child.@y = y.toFixed(2);
						child.@visible = joint.visible;
					}
				}
				else if(childName.indexOf("line") != -1)
				{
					
					var lineID:String = child.@id;
					var edgeContainer:GameEdgeContainer = edgeContainerDictionary[lineID];
					if(edgeContainer != null)
					{
						child.@visible = edgeContainer.visible;
						
						//remove all current points, and then add new ones
						delete child.point;
						
						if(edgeContainer.m_jointPoints.length != 6)
							trace("Wrong number of joint points " + lineID);
						for(var i:int = 0; i<edgeContainer.m_jointPoints.length; i++)
						{
							var pt:Point = edgeContainer.m_jointPoints[i];
							var ptXML:XML = <point></point>;
							x = (pt.x + edgeContainer.m_boundingBox.x) / Constants.GAME_SCALE;
							ptXML.@x = x.toFixed(2);
							y = (pt.y + edgeContainer.m_boundingBox.y) / Constants.GAME_SCALE;
							ptXML.@y = y.toFixed(2);
							
							child.appendChild(ptXML);
						}
					}
				}
			}
			
			m_levelLayoutXMLWrapper = <graph id="world"/>;
			m_levelLayoutXMLWrapper.appendChild(m_levelLayoutXML);
		}
		
		//update current constraint info based on node constraints
		public function updateConstraintXML():void
		{
			delete m_levelConstraintsXML.box;
			
			for each(var node:GameNode in m_nodeList)
			{
				var id:String = node.m_id;
				var width:Boolean = node.m_isWide;
				var widthString:String = (width == true) ? "wide" : "narrow";
				
				//changed only in editor mode
				var editable:Boolean = node.m_isEditable;
				var editableString:String = (editable == true) ? "true" : "false";
				
				var child:XML = <box/>;
				child.@id = id;
				child.@width = widthString;
				child.@editable = editableString;
					
				m_levelConstraintsXML.appendChild(child);
			}
			m_levelConstraintsXMLWrapper = <graph id="world"/>;
			m_levelConstraintsXMLWrapper.appendChild(m_levelConstraintsXML);
		}
		

		
		override public function dispose():void
		{
			if (m_disposed) {
				return;
			}
			
			disposeChildren();
			
			removeEventListener(EdgeSetChangeEvent.EDGE_SET_CHANGED, onEdgeSetChange);
			removeEventListener(Level.COMPONENT_SELECTED, onComponentSelection);
			removeEventListener(Level.COMPONENT_UNSELECTED, onComponentSelection);
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
			if (evt.edgeSetChanged.isWide()) {
				AudioManager.getInstance().audioDriver().playSfx(AssetsAudio.SFX_LOW_BELT);
			} else {
				AudioManager.getInstance().audioDriver().playSfx(AssetsAudio.SFX_HIGH_BELT);
			}
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
		private function componentSelectionChanged(component:GameNodeBase):void
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
						{
							selectedComponents.push(edge);
						}
						edge.componentSelected(true);
					}
				}
				for each(var edge1:GameEdgeContainer in component.m_outgoingEdges)
				{
					var toComponent:GameNodeBase = edge1.m_toComponent;
					if(selectedComponents.indexOf(toComponent) != -1)
					{
						if(selectedComponents.indexOf(edge1) == -1)
						{
							selectedComponents.push(edge1);
						}
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
				componentSelectionChanged(component);
			
			selectionChangedComponents = new Vector.<GameComponent>();
			selectionChangedComponents.push(component);
			addSelectionUndoEvent(selectionChangedComponents);
		}
		
		private function onComponentUnselection(e:starling.events.Event):void
		{
			var component:GameNodeBase = e.data as GameNodeBase;
			if(component)
				componentSelectionChanged(component);
			
			selectionChangedComponents = new Vector.<GameComponent>();
			selectionChangedComponents.push(component);
			addSelectionUndoEvent(selectionChangedComponents);
		}
		
		private function onGroupSelection(e:starling.events.Event):void
		{
			var component:GameNodeBase = e.data as GameNodeBase;
			var groupDictionary:Dictionary = new Dictionary;
			component.findGroup(groupDictionary);
			selectionChangedComponents = new Vector.<GameComponent>();
			for each(var comp:GameComponent in groupDictionary)
			{
				if(selectedComponents.indexOf(comp) == -1)
				{
					comp.componentSelected(true);
					if(comp is GameNodeBase)
					{
						componentSelectionChanged(comp as GameNodeBase);
						selectionChangedComponents.push(comp);
					}
				}
			}
			addSelectionUndoEvent(selectionChangedComponents, true);
		}
		
		private function onGroupUnselection(e:starling.events.Event):void
		{
			var component:GameNodeBase = e.data as GameNodeBase;
			var groupDictionary:Dictionary = new Dictionary;
			component.findGroup(groupDictionary);
			selectionChangedComponents = new Vector.<GameComponent>();
			for each(var comp:GameComponent in groupDictionary)
			{
				comp.componentSelected(false);
				if(comp is GameNodeBase)
				{
					componentSelectionChanged(comp as GameNodeBase);
					selectionChangedComponents.push(comp);
				}
			}

			addSelectionUndoEvent(selectionChangedComponents);
		}
		
		private function addSelectionUndoEvent(selection:Vector.<GameComponent>, addToLast:Boolean = false):void
		{
			var undoData:Object = new Object();
			undoData.target = this;
			undoData.selection = selection;
			undoData.addToLast = addToLast;
			var undoEvent:Event = new Event(Level.GROUP_SELECTED,false,undoData);
			dispatchEvent(new Event(World.UNDO_EVENT, true, undoEvent));
		}
		
		public function unselectAll(addEventToLast:Boolean = false):void
		{
			//make a copy of the selected list for the undo event
			var currentSelection:Vector.<GameComponent> = new Vector.<GameComponent>();
			
			for each(var comp:GameComponent in selectedComponents)
			{
				comp.componentSelected(false);
				currentSelection.push(comp);
			}

			if(currentSelection.length)
			{
				addSelectionUndoEvent(currentSelection, addEventToLast);
				selectedComponents = new Vector.<GameComponent>;
			}
		}
		
		private function onMoveEvent(e:starling.events.Event):void
		{
			var touch:Touch = e.data.touches[0] as Touch;
			
			var currentMoveLocation:Point = touch.getLocation(this);
			var previousLocation:Point = touch.getPreviousLocation(this);
			var delta:Point = currentMoveLocation.subtract(previousLocation);
			
			//if component isn't in the currently selected group, unselect everything, and then move component
			if(selectedComponents.indexOf(e.target) == -1)
			{
				unselectAll();
				(e.target as GameComponent).componentMoved(delta);
			}
			else
				for each(var component:GameComponent in selectedComponents)
					component.componentMoved(delta);
		}
		
		public override function handleUndoEvent(undoEvent:Event, isUndo:Boolean = true):void
		{
			var undoData:Object = undoEvent.data;
			var component:GameNodeBase = undoData.component as GameNodeBase;
			if(undoEvent.type == GROUP_SELECTED) //individual selections come through here also
			{
				if(undoData.selection)
				{
					for each(var selectedComp:GameComponent in undoData.selection)
					{
						if(selectedComp is GameNodeBase)
						{
							selectedComp.componentSelected(!selectedComp.m_isSelected);
						
							componentSelectionChanged(selectedComp as GameNodeBase);
						}
					}
				}
			}
			else if(undoEvent.type == MOVE_EVENT)
			{
				var delta:Point;
				if(!isUndo)
					delta = new Point(undoData.endPoint.x-undoData.startPoint.x, undoData.endPoint.y-undoData.startPoint.y);
				else
					delta = new Point(undoData.startPoint.x-undoData.endPoint.x, undoData.startPoint.y-undoData.endPoint.y);
				
				//not added as a temp selection, so move separately
				if(component)
					component.componentMoved(delta);
				for each(var selectedComponent:GameComponent in selectedComponents)
				{
					if(component != selectedComponent)
						selectedComponent.componentMoved(delta);
				}
			}
		}
		
		//to be called once to set everything up 
		//to move/update objects use update events
		public function draw():void
		{
			trace("Bounding Box " + m_boundingBox.width + "  " + m_boundingBox.height);
			
			var maxX:Number = Number.NEGATIVE_INFINITY;
			var maxY:Number = Number.NEGATIVE_INFINITY;
			
			var nodeCount:int = 0;
			for each(var gameNode:GameNode in m_nodeList)
			{
				gameNode.x = gameNode.m_boundingBox.x - m_boundingBox.x;
				gameNode.y = gameNode.m_boundingBox.y - m_boundingBox.y;
				gameNode.m_isDirty = true;
				m_nodesContainer.addChild(gameNode);
				nodeCount++;
			}
			
			var jointCount:int = 0;
			for each(var gameJoint:GameJointNode in m_jointList)
			{
				gameJoint.x = gameJoint.m_boundingBox.x - m_boundingBox.x;
				gameJoint.y = gameJoint.m_boundingBox.y - m_boundingBox.y;
				gameJoint.m_isDirty = true;
				m_jointsContainer.addChild(gameJoint);
				jointCount++;
			}
			
			var edgeCount:int = 0;
			for each(var gameEdge:GameEdgeContainer in m_edgeList)
			{
				gameEdge.x = (gameEdge.m_boundingBox.x - m_boundingBox.x);
				gameEdge.y = (gameEdge.m_boundingBox.y - m_boundingBox.y);
				gameEdge.draw();
				m_edgesContainer.addChild(gameEdge);
				m_errorContainer.addChild(gameEdge.errorContainer);
				edgeCount++;
			}
			trace("Nodes " + nodeCount + " NodeJoints " + jointCount + " Edges " + edgeCount);
			if (m_backgroundImage) {
				m_backgroundImage.width = m_backgroundImage.height = 2 * MIN_BORDER + Math.max(m_boundingBox.width, m_boundingBox.height);
				m_backgroundImage.x = m_backgroundImage.y = - MIN_BORDER - 0.5 * Math.max(m_boundingBox.x, m_boundingBox.y);
				var texturesToRepeat:Number = (50.0 / Constants.GAME_SCALE) * (m_backgroundImage.width / BG_WIDTH);
				m_backgroundImage.setTexCoords(1, new Point(texturesToRepeat, 0.0));
				m_backgroundImage.setTexCoords(2, new Point(0.0, texturesToRepeat));
				m_backgroundImage.setTexCoords(3, new Point(texturesToRepeat, texturesToRepeat));
			}
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
				//scale line size
				var lineSize:Number = 1/(Math.max(parent.scaleX, parent.scaleY));
				marqueeRect.graphics.lineStyle(lineSize, 0xffffff);
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
				
				selectionChangedComponents = new Vector.<GameComponent>();
				for each(var node:GameNode in m_nodeList)
				{
					handleSelection(node);
				}
				for each(var joint:GameJointNode in m_jointList)
				{
					handleSelection(joint);
				}
				removeChild(marqueeRect);
				
				addSelectionUndoEvent(selectionChangedComponents);
			}
		}
		
		protected function handleSelection(node:GameNodeBase):void
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
					selectionChangedComponents.push(node);
					node.componentSelected(!node.m_isSelected);
					componentSelectionChanged(node);
				}
			}
		}
		
		public function toggleUneditableStrings():void
		{
			var visitedNodes:Dictionary = new Dictionary;
			for each(var node:GameNode in m_nodeList)
			{
				if(visitedNodes[node.m_id] == null)
				{
					visitedNodes[node.m_id] = node;
					var groupDictionary:Dictionary = new Dictionary;
					node.findGroup(groupDictionary);
					//check for an editable node
					var uneditable:Boolean = true;
					for each(var comp:GameComponent in groupDictionary)
					{
						if(comp.m_isEditable)
						{
							uneditable = false;
							break;
						}
					}
					if(uneditable)
					{
						for each(var comp1:GameComponent in groupDictionary)
						{
							comp1.hideComponent(comp.visible);
							visitedNodes[comp1.m_id] = comp1;
						}
					}
				}
			}
		}	
		
		public function getNodes():Vector.<GameNode>
		{
			return m_nodeList;
		}
		
		public function getJoints():Vector.<GameJointNode>
		{
			return m_jointList;
		}
		
		public function getLevelText():String
		{
			return m_levelText;
		}
		
		public function getTargetScore():int
		{
			return m_targetScore;
		}
	}
}