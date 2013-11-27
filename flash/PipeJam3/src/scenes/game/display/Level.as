package scenes.game.display
{
	import assets.AssetInterface;
	import assets.AssetsAudio;
	import events.ErrorEvent;
	import events.MiniMapEvent;
	
	import audio.AudioManager;
	
	import deng.fzip.FZip;
	
	import display.ToolTipText;
	
	import events.EdgeContainerEvent;
	import events.EdgeSetChangeEvent;
	import events.GameComponentEvent;
	import events.GroupSelectionEvent;
	import events.MenuEvent;
	import events.MoveEvent;
	import events.PropertyModeChangeEvent;
	import events.UndoEvent;
	
	import flash.events.TimerEvent;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.ByteArray;
	import flash.utils.Dictionary;
	import flash.utils.Timer;
	
	import graph.BoardNodes;
	import graph.Edge;
	import graph.EdgeSetRef;
	import graph.LevelNodes;
	import graph.Node;
	import graph.NodeTypes;
	import graph.Port;
	import graph.PropDictionary;
	
	import networking.GameFileHandler;
	
	import scenes.BaseComponent;
	
	import starling.display.BlendMode;
	import starling.display.DisplayObject;
	import starling.display.Image;
	import starling.display.Quad;
	import starling.display.Shape;
	import starling.display.Sprite;
	import starling.events.Event;
	import starling.events.Touch;
	import starling.events.TouchEvent;
	import starling.events.TouchPhase;
	import starling.filters.BlurFilter;
	import starling.textures.Texture;
	
	import utils.Base64Encoder;
	import utils.XString;
	import networking.LevelInformation;
	
	/**
	 * Level all game components - boxes, lines and joints
	 */
	public class Level extends BaseComponent
	{
		
		/** True to allow user to navigate to any level regardless of whether levels below it are solved for debugging */
		public static var UNLOCK_ALL_LEVELS_FOR_DEBUG:Boolean = false;
		
		/** Name of this level */
		public var level_name:String;
		
		/** Node collection used to create this level, including name obfuscater */
		public var levelNodes:LevelNodes;
		
		public var edgeDictionary:Dictionary = new Dictionary;
		private var edgeSetDictionary:Dictionary = new Dictionary;
		
		private var selectedComponents:Vector.<GameComponent>;
		
		private var marqueeRect:Shape = new Shape();
		
		//the level node and decendents
		private var m_levelLayoutXML:XML;
		public var m_levelLayoutName:String;
		public var m_levelQID:String;
		private var m_levelOriginalLayoutXML:XML; //used for restarting the level
		//used when saving, as we need a parent graph element for the above level node
		public var m_levelLayoutXMLWrapper:XML;
		private var m_levelConstraintsXML:XML;
		private var m_levelOriginalConstraintsXML:XML; //used for restarting the level
		private var m_levelBestScoreConstraintsXML:XML; //best configuration so far
		public var m_levelConstraintsXMLWrapper:XML;
		public var m_tutorialTag:String;
		public var tutorialManager:TutorialLevelManager;
		private var m_layoutFixed:Boolean = false;
		public var m_targetScore:int;
		
		private var boxDictionary:Dictionary;
		private var jointDictionary:Dictionary;
		private var edgeContainerDictionary:Dictionary;
		
		private var m_nodeList:Vector.<GameNode>;
		public var m_edgeList:Vector.<GameEdgeContainer>;
		private var m_jointList:Vector.<GameJointNode>;
		private var m_hidingErrorText:Boolean = false;
		private var m_segmentHovered:GameEdgeSegment;
		public var errorList:Dictionary = new Dictionary();
		
		private var m_nodesInactiveContainer:Sprite = new Sprite();
		private var m_jointsInactiveContainer:Sprite = new Sprite();
		private var m_errorInactiveContainer:Sprite = new Sprite();
		private var m_edgesInactiveContainer:Sprite = new Sprite();
		private var m_plugsInactiveContainer:Sprite = new Sprite();
		public var inactiveLayer:Sprite = new Sprite();
		
		private var m_nodesContainer:Sprite = new Sprite();
		private var m_jointsContainer:Sprite = new Sprite();
		private var m_errorContainer:Sprite = new Sprite();
		private var m_edgesContainer:Sprite = new Sprite();
		private var m_plugsContainer:Sprite = new Sprite();
		
		public var m_boundingBox:Rectangle;
		private var m_backgroundImage:Image;
		private var m_levelStartTime:Number;
		
		private var initialized:Boolean = false;
		
		/** Current Score of the player */
		private var m_currentScore:int = 0;
		private var m_bestScore:int = 0;
		
		/** Most recent score of the player */
		private var m_prevScore:int = 0;
		
		/** Base Score = # of lines * possible conflict points */
		private var m_baseScore:int = 0;
		
		/** Set to true when the target score is reached. */
		public var targetScoreReached:Boolean;
		public var original_level_name:String;
		
		/** Tracks total distance components have been dragged since last visibile calculation */
		public var totalMoveDist:Point = new Point();
		
		// The following are used for conflict scrolling purposes: (tracking list of current conflicts)
		private var m_currentConflictIndex:int = -1;
		private var m_levelConflictEdges:Vector.<GameEdgeContainer> = new Vector.<GameEdgeContainer>();
		private var m_levelConflictEdgeDict:Dictionary = new Dictionary();
		private var m_conflictEdgesDirty:Boolean = true;
		
		private static const BG_WIDTH:Number = 256;
		private static const MIN_BORDER:Number = 1000;
		private static const USE_TILED_BACKGROUND:Boolean = false; // true to include a background that scrolls with the view
		
		/**
		 * Level contains multiple boards that each contain multiple pipes
		 * @param	_name Name of the level
		 * @param  _levelNodes The node objects used to create this level (including name obfuscater)
		 * @param  _levelLayoutXML the layout xml
		 * @param  _levelConstraintsXML the constraints xml
		 */
		public function Level( _name:String, _levelNodes:LevelNodes, _levelLayoutXML:XML, _levelConstraintsXML:XML, _targetScore:int, _originalLevelName:String)
		{
			UNLOCK_ALL_LEVELS_FOR_DEBUG = PipeJamGame.DEBUG_MODE;
			level_name = _name;
			original_level_name = _originalLevelName;
			levelNodes = _levelNodes;
			m_levelLayoutXML = _levelLayoutXML;//.copy();
			m_levelOriginalLayoutXML = _levelLayoutXML;//.copy();
			m_levelLayoutName = _levelLayoutXML.@id;
			m_levelQID = _levelLayoutXML.@qid;
			m_levelBestScoreConstraintsXML = _levelConstraintsXML.copy();
			m_levelOriginalConstraintsXML = _levelConstraintsXML.copy();
			m_levelConstraintsXML = _levelConstraintsXML.copy();
			
			m_tutorialTag = m_levelLayoutXML.attribute("tutorial").toString();
			if (m_tutorialTag && (m_tutorialTag.length > 0)) {
				tutorialManager = new TutorialLevelManager(m_tutorialTag);
				m_layoutFixed = tutorialManager.getLayoutFixed();
			}
			
			m_targetScore = _targetScore;
			targetScoreReached = false;
			addEventListener(Event.ADDED_TO_STAGE, onAddedToStage);	
			addEventListener(Event.REMOVED_FROM_STAGE, onRemovedFromStage);	
		}
		
		public function loadBestScoringConfiguration():void
		{
			setConstraints(m_levelBestScoreConstraintsXML, true);
		}
		
		private function setConstraints(constraintsXML:XML, updateTutorialManager:Boolean = false):void
		{
			var gameNode:GameNode;
			
			for each(var boxConstraint:XML in constraintsXML.box)
			{
				gameNode = boxDictionary[String(boxConstraint.@id)];
				if (!gameNode) {
					//throw new Error("Box node not found for id found in constraints file:" + boxConstraint.@id);
					continue;
				}
				var constraintIsEditable:Boolean = XString.stringToBool(String(boxConstraint.@editable));
				var constraintIsWide:Boolean = (boxConstraint.@width == "wide");
				var widthMismatch:Boolean = (gameNode.isWide() != constraintIsWide);
				gameNode.handleWidthChange(constraintIsWide, true);
				if (updateTutorialManager && tutorialManager && widthMismatch) {
					tutorialManager.onEdgeSetChange(new EdgeSetChangeEvent(EdgeSetChangeEvent.EDGE_SET_CHANGED, gameNode, PropDictionary.PROP_NARROW, !constraintIsWide, this, true));
				}
				if (!constraintIsEditable && widthMismatch && !(gameNode is GameNodeFixed)) {
					trace(gameNode.m_id, "Mismatch in uneditable gameNode where constraints file isWide=" + constraintIsWide + " and edges in XML have isWide=" + gameNode.isWide());
				}
				if (constraintIsEditable != gameNode.isEditable()) {
					gameNode.m_isEditable = constraintIsEditable;
					gameNode.m_isDirty = true;
					if (!(gameNode is GameNodeFixed)) trace(gameNode.m_id, "Mismatch between constraints file editable=" + constraintIsEditable + " and edges in XML have editable=" + gameNode.isEditable());
				}
			}
			if(gameNode)
			{
				dispatchEvent(new EdgeSetChangeEvent(EdgeSetChangeEvent.LEVEL_EDGE_SET_CHANGED, gameNode, PropDictionary.PROP_NARROW, !gameNode.m_isWide, this, false, null));
			}
			refreshTroublePoints();	
		}
		
		protected function createLine(edgeXML:XML, copyLines:Vector.<GameEdgeContainer> = null):Rectangle
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
			// Check for INCOMING/OUTGOING/END/START_PIPE_DEPENDENT_BALL nodes, hide these
			var hideLine:Boolean = false;
			if (dir == GameEdgeContainer.DIR_JOINT_TO_BOX) {
				switch (newEdge.from_node.kind) {
					case NodeTypes.INCOMING:
					case NodeTypes.START_PIPE_DEPENDENT_BALL:
						//trace("Hide line id:" + edgeContainerID + " from:" + newEdge.from_node.kind + " to:" + newEdge.to_node.kind);
						hideLine = true;
						break;
				}
			} else {
				switch (newEdge.to_node.kind) {
					case NodeTypes.OUTGOING:
						// Only need to create outgoing joint if others come out of it,
						// if joint was not created, don't create the line
						if (myJoint && !myJoint.hidden) {
							hideLine = false;
						} else {
							hideLine = true;
						}
						break;
					case NodeTypes.END:
						//trace("Hide line id:" + edgeContainerID + " from:" + newEdge.from_node.kind + " to:" + newEdge.to_node.kind);
						hideLine = true;
						break;
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
			
			var lineID:String = edgeXML.@id;
			var newGameEdge:GameEdgeContainer;
			// get editable property from related edge or end segment/joint
			var edgeIsCopy:Boolean = (edgeContainerID.indexOf(Constants.XML_ANNOT_COPY) > -1);
			if (dir == GameEdgeContainer.DIR_BOX_TO_JOINT) {
				newGameEdge = new GameEdgeContainer(edgeXML.@id, edgeArray, myNode, myJoint, fromPortID, toPortID, dir, newEdge, !m_layoutFixed, edgeIsCopy, hideLine);
			} else {
				newGameEdge = new GameEdgeContainer(edgeXML.@id, edgeArray, myJoint, myNode, fromPortID, toPortID, dir, newEdge, !m_layoutFixed, edgeIsCopy, hideLine);
			}
			if (!getVisible(edgeXML)) newGameEdge.hideComponent(true);
			
			m_edgeList.push(newGameEdge);
			if (edgeIsCopy) {
				copyLines.push(newGameEdge);
			}
			
			if (edgeContainerDictionary.hasOwnProperty(edgeContainerID) && (edgeContainerDictionary[edgeContainerID] is GameEdgeContainer)) {
				var oldEdgeContainer:GameEdgeContainer = edgeContainerDictionary[edgeContainerID] as GameEdgeContainer;
				if (m_edgeList.indexOf(oldEdgeContainer) > -1) {
					m_edgeList.splice(m_edgeList.indexOf(oldEdgeContainer), 1);
				}
				oldEdgeContainer.removeFromParent(true);
			}
			
			edgeContainerDictionary[edgeContainerID] = newGameEdge;
			return hideLine ? null : newGameEdge.m_boundingBox;
		}
		
		protected function onAddedToStage(event:Event):void
		{
			removeEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
			if (m_disposed) {
				restart(); // undo progress if left the level and coming back
			} else {
				start();
			}
			
			refreshTroublePoints();
			flatten();
			
			dispatchEvent(new starling.events.Event(Game.STOP_BUSY_ANIMATION,true));
		}
		
		public function initialize():void
		{
			if (initialized) return;
			if (USE_TILED_BACKGROUND && !m_backgroundImage) {
				// TODO: may need to refine GridViewPanel .onTouch method as well to get this to work: if(this.m_currentLevel && event.target == m_backgroundImage)
				var background:Texture = AssetInterface.getTexture("Game", "BoxesGamePanelBackgroundImageClass");
				background.repeat = true;
				m_backgroundImage = new Image(background);
				m_backgroundImage.width = m_backgroundImage.height = 2 * MIN_BORDER;
				m_backgroundImage.x = m_backgroundImage.y = -MIN_BORDER;
				m_backgroundImage.blendMode = BlendMode.NONE;
				addChild(m_backgroundImage);
			}
			
			if (inactiveLayer == null)  inactiveLayer  = new Sprite();
			if (m_nodesInactiveContainer == null)  m_nodesInactiveContainer  = new Sprite();
			if (m_jointsInactiveContainer == null) m_jointsInactiveContainer = new Sprite();
			if (m_errorInactiveContainer == null)  m_errorInactiveContainer  = new Sprite();
			if (m_edgesInactiveContainer == null)  m_edgesInactiveContainer  = new Sprite();
			if (m_plugsInactiveContainer == null)  m_plugsInactiveContainer  = new Sprite();
			inactiveLayer.addChild(m_nodesInactiveContainer);
			inactiveLayer.addChild(m_jointsInactiveContainer);
			inactiveLayer.addChild(m_errorInactiveContainer);
			inactiveLayer.addChild(m_edgesInactiveContainer);
			inactiveLayer.addChild(m_plugsInactiveContainer);
			
			if (m_nodesContainer == null)  m_nodesContainer  = new Sprite();
			if (m_jointsContainer == null) m_jointsContainer = new Sprite();
			if (m_errorContainer == null)  m_errorContainer  = new Sprite();
			if (m_edgesContainer == null)  m_edgesContainer  = new Sprite();
			if (m_plugsContainer == null)  m_plugsContainer  = new Sprite();
			//m_nodesContainer.filter = BlurFilter.createDropShadow(4.0, 0.78, 0x0, 0.85, 2, 1); //only works up to 2048px
			addChild(m_nodesContainer);
			addChild(m_jointsContainer);
			addChild(m_errorContainer);
			addChild(m_edgesContainer);
			addChild(m_plugsContainer);
			
			this.alpha = .999;

			m_edgeList = new Vector.<GameEdgeContainer>;
			selectedComponents = new Vector.<GameComponent>;
			totalMoveDist = new Point();
			
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
			var visibleNodes:int = 0;
			for each(var boxLayoutXML:XML in m_levelLayoutXML.box)
			{
				var boxEdgeSetId:String = boxLayoutXML.@id;
				var gameNode:GameNode;
				if (!edgeSetDictionary.hasOwnProperty(boxEdgeSetId)) {
					// TODO: If we have another level with this subboard, produce a link here:
					if (boxEdgeSetId.indexOf(Constants.XML_ANNOT_EXT) == 0) {
						// Found a reference to an external SUBBOARD, create fixed node
						var isWide:Boolean = true; // TODO: get this from the defaultWidth property of the subboard port
						if (boxEdgeSetId.indexOf(Constants.XML_ANNOT_EXT_OUT) > -1) {
							isWide = false;
						}
						gameNode = new GameNodeFixed(boxLayoutXML, !m_layoutFixed, isWide);
					} else {
						throw new Error("Couldn't find edge set for box id: " + boxLayoutXML.@id);
					}
				} else {
					var edgeSet:EdgeSetRef = edgeSetDictionary[boxEdgeSetId];
					//grab an example edge for it's attributes FIX - use constraints xml file
					var levelEdges:Vector.<Edge> = edgeSet.getLevelEdges(original_level_name);
					gameNode = new GameNode(boxLayoutXML, !m_layoutFixed, edgeSet, levelEdges);
				}
				
				gameNode.addEventListener(EdgeSetChangeEvent.EDGE_SET_CHANGED, onEdgeSetChange);
				
				if (getVisible(boxLayoutXML)) {
					visibleNodes++;
					minX = Math.min(minX, gameNode.m_boundingBox.left);
					minY = Math.min(minY, gameNode.m_boundingBox.top);
					maxX = Math.max(maxX, gameNode.m_boundingBox.right);
					maxY = Math.max(maxY, gameNode.m_boundingBox.bottom);
				} else {
					gameNode.hideComponent(true);
					boxLayoutXML.@visible="false";
				}
				m_nodeList.push(gameNode);
				boxDictionary[boxEdgeSetId] = gameNode;
			}
			trace("gamenodeset count = " + m_nodeList.length);
			
			m_jointList = new Vector.<GameJointNode>();
			jointDictionary = new Dictionary();
			// Process <joint> 's
			var visibleJoints:int = 0;
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
							jointLayoutXML.@visible="false";
							break;
						case NodeTypes.OUTGOING:
							// Only create the joint for an outgoing node if other lines connect
							// to it (these lines are the SUBBOARD outgoing ports that correspond
							// to this OUTGOING edge)
							var numOutputs:Number = Number(jointLayoutXML.@outputs);
							if (isNaN(numOutputs) || (numOutputs == 0)) {
								jointLayoutXML.@visible="false";
							}
							break;
					}
				}
				
				var joint:GameJointNode;
				if (foundNode) {
					switch (foundNode.kind) {
						case NodeTypes.GET:
							joint = new GameMapGetJoint(jointLayoutXML, !m_layoutFixed, foundNode, foundPort);
							break;
						case NodeTypes.BALL_SIZE_TEST:
							joint = new GameIfTestJoint(jointLayoutXML, !m_layoutFixed, foundNode, foundPort);
							break;
						default:
							joint = new GameJointNode(jointLayoutXML, !m_layoutFixed, foundNode, foundPort);
							break;
					}
				} else {
					joint = new GameJointNode(jointLayoutXML, !m_layoutFixed, null, foundPort);
				}
				
				if (getVisible(jointLayoutXML)) {
					visibleJoints++;
					minX = Math.min(minX, joint.m_boundingBox.left);
					minY = Math.min(minY, joint.m_boundingBox.top);
					maxX = Math.max(maxX, joint.m_boundingBox.right);
					maxY = Math.max(maxY, joint.m_boundingBox.bottom);
				} else {
					joint.hideComponent(true);
					jointLayoutXML.@visible = "false";
				}
				//trace("joint:" + joint.m_id + " hidden:" + joint.hidden + " kind:" + foundNode.kind);
				m_jointList.push(joint);
				jointDictionary[joint.m_id] = joint;
			}
			
			// Process <line> 's
			var visibleLines:int = 0;
			var copyLines:Vector.<GameEdgeContainer> = new Vector.<GameEdgeContainer>();
			for each(var edgeXML:XML in m_levelLayoutXML.line)
			{
				var boundingBox:Rectangle = createLine(edgeXML, copyLines);
				var edgeVisible:Boolean = (boundingBox != null);
				if(edgeVisible) {
					visibleLines++;
				} else {
					edgeXML.@visible="false";
				}
				if (boundingBox && edgeVisible) {
					minX = Math.min(minX, boundingBox.x);
					minY = Math.min(minY, boundingBox.y);
					maxX = Math.max(maxX, boundingBox.x + boundingBox.width);
					maxY = Math.max(maxY, boundingBox.y + boundingBox.height);
				}
			}
		//	this.m_edgesContainer.flatten();
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
			
			addEventListener(EdgeContainerEvent.CREATE_JOINT, onCreateJoint);
			addEventListener(EdgeContainerEvent.SEGMENT_MOVED, onSegmentMoved);
			addEventListener(EdgeContainerEvent.SEGMENT_DELETED, onSegmentDeleted);
			addEventListener(EdgeContainerEvent.HOVER_EVENT_OVER, onHoverOver);
			addEventListener(EdgeContainerEvent.HOVER_EVENT_OUT, onHoverOut);
			//addEventListener(EdgeSetChangeEvent.EDGE_SET_CHANGED, onEdgeSetChange); // do these per-box
			addEventListener(PropertyModeChangeEvent.PROPERTY_MODE_CHANGE, onPropertyModeChange);
			addEventListener(GameComponentEvent.COMPONENT_SELECTED, onComponentSelection);
			addEventListener(GameComponentEvent.COMPONENT_UNSELECTED, onComponentUnselection);
			addEventListener(GroupSelectionEvent.GROUP_SELECTED, onGroupSelection);
			addEventListener(GroupSelectionEvent.GROUP_UNSELECTED, onGroupUnselection);
			addEventListener(MoveEvent.MOVE_EVENT, onMoveEvent);
			addEventListener(MoveEvent.FINISHED_MOVING, onFinishedMoving);
			addEventListener(ErrorEvent.ERROR_ADDED, onErrorAdded);
			addEventListener(ErrorEvent.ERROR_REMOVED, onErrorRemoved);
			
			trace(visibleNodes, visibleJoints, visibleLines);
			
			setConstraints(m_levelConstraintsXML);
			initialized = true;
		}
		
		public function start():void
		{
			m_segmentHovered = null;
			initialize();
			
			m_disposed = false;
			m_levelStartTime = new Date().time;
			if (tutorialManager) tutorialManager.startLevel();
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
			
			m_bestScore = m_currentScore;
			flatten();
			trace("Loaded: " + m_levelLayoutXML.@id + " for display.");
		}
		
		public function restart():void
		{
			m_segmentHovered = null;
			if (!initialized) {
				start();
			} else {
				if (tutorialManager) tutorialManager.startLevel();
				m_levelStartTime = new Date().time;
			}
			var propChangeEvt:PropertyModeChangeEvent = new PropertyModeChangeEvent(PropertyModeChangeEvent.PROPERTY_MODE_CHANGE, PropDictionary.PROP_NARROW);
			onPropertyModeChange(propChangeEvt);
			dispatchEvent(propChangeEvt);
			setNewLayout(null, m_levelOriginalLayoutXML);
			m_levelConstraintsXML = m_levelOriginalConstraintsXML.copy();
			setConstraints(m_levelConstraintsXML);
			targetScoreReached = false;
			trace("Restarted: " + m_levelLayoutXML.@id);
		}
		
		public function onSaveLayoutFile(event:MenuEvent):void
		{
			updateLevelXML();
			
			var levelObject:LevelInformation = PipeJamGame.levelInfo;
			if(levelObject != null)
			{
				m_levelLayoutXMLWrapper.@id = event.data.name;
				levelObject.m_layoutName = event.data.name;
				levelObject.m_layoutDescription = event.data.description;
				var layoutZip:ByteArray = zipXMLFile(this.m_levelLayoutXMLWrapper, "layout");
				var layoutZipEncodedString:String = encodeBytes(layoutZip);
				GameFileHandler.saveLayoutFile(layoutSaved, layoutZipEncodedString);	
			}
		}
		
		protected function layoutSaved(result:int, e:flash.events.Event):void
		{
			dispatchEvent(new MenuEvent(MenuEvent.LAYOUT_SAVED));
		}
		
		public function zipXMLFile(xmlFile:XML, name:String):ByteArray
		{
			var newZip:FZip = new FZip();
			var zipByteArray:ByteArray = new ByteArray();
			zipByteArray.writeUTFBytes(xmlFile.toString());
			newZip.addFile(name,  zipByteArray);
			var byteArray:ByteArray = new ByteArray;
			newZip.serialize(byteArray);
			return byteArray;
		}
		
		public function encodeBytes(bytes:ByteArray):String
		{
			var encoder:Base64Encoder = new Base64Encoder();
			encoder.encodeBytes(bytes);
			var encodedString:String = encoder.toString();

			return encodedString;
		}
		
		public function updateLevelXML():void
		{
			var worldParent:DisplayObject = parent;
			while(worldParent && !(worldParent is World))
				worldParent = worldParent.parent;
			
			updateLayoutXML(worldParent as World, true);
			updateConstraintXML();
		}
		
		protected function onRemovedFromStage(event:Event):void
		{
			//disposeChildren();
		}
		
		public function setNewLayout(name:String, newLayoutXML:XML, useExistingLines:Boolean = false):void
		{
			m_levelLayoutXML = newLayoutXML.copy();
			m_levelLayoutName = name;
			//we might have ended up with a 'world', just grab the first level
			if(m_levelLayoutXML.level != undefined)
				m_levelLayoutXML = m_levelLayoutXML.level[0];
			
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
					if (!useExistingLines) {
						gameNode.removeEdges();
					}
					gameNode.m_boundingBox.x = child.@x * Constants.GAME_SCALE - gameNode.m_boundingBox.width/2;
					gameNode.m_boundingBox.y = child.@y * Constants.GAME_SCALE - gameNode.m_boundingBox.height/2;
					
					gameNode.hideComponent(!getVisible(child));
					if (!gameNode.hidden) {
						minX = Math.min(minX, gameNode.m_boundingBox.left);
						minY = Math.min(minY, gameNode.m_boundingBox.top);
						maxX = Math.max(maxX, gameNode.m_boundingBox.right);
						maxY = Math.max(maxY, gameNode.m_boundingBox.bottom);
					}
				}
			}
			//update lines
			
			if(useExistingLines == false)
			{
				//delete all existing edges, and recreate
				for each(var existingEdge:GameEdgeContainer  in m_edgeList) {
					existingEdge.removeFromParent(true);
				}
				edgeContainerDictionary = new Dictionary();
				m_edgeList = new Vector.<GameEdgeContainer>;
			}
			
			for each(var edge:XML in m_levelLayoutXML.line)
			{
				var edgeID:String = edge.@id;
				var edgeContainer:GameEdgeContainer = edgeContainerDictionary[edgeID];
				var boundingBox:Rectangle;
				if(useExistingLines == false && edgeContainer == null)
				{
					boundingBox = createLine(edge);
					
					if(boundingBox)
					{
						minX = Math.min(minX, boundingBox.left);
						minY = Math.min(minY, boundingBox.top);
						maxX = Math.max(maxX, boundingBox.right);
						maxY = Math.max(maxY, boundingBox.bottom);
					}
				}
				else if(edgeContainer)
				{
					//create edge array
					var edgeArray:Array = new Array;
					
					var edgePoints:XMLList = edge.point;
					for each(var pointXML:XML in edgePoints)
					{
						var pt:Point = new Point(pointXML.@x * Constants.GAME_SCALE, pointXML.@y * Constants.GAME_SCALE);
						edgeArray.push(pt);
					}
					edgeContainer.m_edgeArray = edgeArray;
					edgeContainer.setupPoints();
					if (!edgeContainer.hideSegments) {
						minX = Math.min(minX, edgeContainer.m_boundingBox.left);
						minY = Math.min(minY, edgeContainer.m_boundingBox.top);
						maxX = Math.max(maxX, edgeContainer.m_boundingBox.right);
						maxY = Math.max(maxY, edgeContainer.m_boundingBox.bottom);
					}
					edgeContainer.createLine();
				}
				

			}
			trace("Level " + m_levelLayoutXML.attribute("id") + " m_boundingBox = " + m_boundingBox);
			m_boundingBox = new Rectangle(minX, minY, maxX - minX, maxY - minY);
			
			draw();
		}
		
		//update current layout info based on node/edge position
		// TODO: We don't want Level to depend on World, let's avoid circular 
		// class dependency and have World -> Level, not World <-> Level
		public function updateLayoutXML(world:World, includeThumbnail:Boolean = false):void
		{
			var children:XMLList = m_levelLayoutXML.children();
			for each(var child:XML in children)
			{
				var childName:String = child.localName();
				var currentLayoutX:Number, currentLayoutY:Number;
				if(childName.indexOf("box") != -1)
				{
					var boxID:String = child.@id;
					var edgeSet:GameNode = boxDictionary[boxID];
					currentLayoutX = (edgeSet.x + /*m_boundingBox.x*/ + edgeSet.m_boundingBox.width/2) / Constants.GAME_SCALE;
					child.@x = currentLayoutX.toFixed(2);
					currentLayoutY = (edgeSet.y + /*m_boundingBox.y*/ + edgeSet.m_boundingBox.height/2) / Constants.GAME_SCALE;
					child.@y = currentLayoutY.toFixed(2);
					child.@visible = (!edgeSet.hidden).toString();
				}
				else if(childName.indexOf("joint") != -1)
				{
					var jointID:String = child.@id;
					var joint:GameJointNode = jointDictionary[jointID];
					if(joint != null)
					{
						currentLayoutX = (joint.x + /*m_boundingBox.x*/ + joint.m_boundingBox.width/2) / Constants.GAME_SCALE;
						child.@x = currentLayoutX.toFixed(2);
						currentLayoutY = (joint.y + /*m_boundingBox.y*/ + joint.m_boundingBox.height/2) / Constants.GAME_SCALE;
						child.@y = currentLayoutY.toFixed(2);
						child.@visible = (!joint.hidden).toString();
					}
				}
				else if(childName.indexOf("line") != -1)
				{
					var lineID:String = child.@id;
					var edgeContainer:GameEdgeContainer = edgeContainerDictionary[lineID];
					if(edgeContainer != null)
					{
						child.@visible = (!edgeContainer.hidden).toString();
						
						//remove all current points, and then add new ones
						delete child.point;
						
						if(edgeContainer.m_jointPoints.length != GameEdgeContainer.NUM_JOINTS)
							trace("Wrong number of joint points " + lineID);
						for(var i:int = 0; i<edgeContainer.m_jointPoints.length; i++)
						{
							var pt:Point = edgeContainer.m_jointPoints[i];
							var ptXML:XML = <point></point>;
							currentLayoutX = (pt.x + edgeContainer.x) / Constants.GAME_SCALE;
							ptXML.@x = currentLayoutX.toFixed(2);
							currentLayoutY = (pt.y + edgeContainer.y) / Constants.GAME_SCALE;
							ptXML.@y = currentLayoutY.toFixed(2);
							
							child.appendChild(ptXML);
						}
					}
				}
			}
			
			m_levelLayoutXMLWrapper = <layout/>;
			m_levelLayoutXMLWrapper.appendChild(m_levelLayoutXML);
			if(includeThumbnail)
			{
				var byteArray:ByteArray = world.getThumbnail(300, 300);
				var thumbXML:XML = <thumb/>;
				var enc:Base64Encoder = new Base64Encoder();
				enc.encodeBytes(byteArray);
				thumbXML.appendChild(enc.toString());
				m_levelLayoutXMLWrapper.appendChild(thumbXML);

			}
		}
		
		//update current constraint info based on node constraints
		public function updateConstraintXML():void
		{
			fillConstraintsXML(m_levelConstraintsXML);
			// TODO: Hardcoding "world" id correct?
			m_levelConstraintsXMLWrapper = <constraints id="world"/>;
			m_levelConstraintsXMLWrapper.appendChild(m_levelConstraintsXML);
		}
		
		private function fillConstraintsXML(constraintsXML:XML):void
		{
			delete constraintsXML.box;
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
				
				constraintsXML.appendChild(child);
			}
			for each(var edge:GameEdgeContainer in m_edgeList)
			{
				var hasJam:Boolean = edge.m_errorProps.hasProp(PropDictionary.PROP_NARROW);
				
				var lineXML:XML = <line/>;
				lineXML.@id = edge.m_id
				lineXML.@width = edge.isWide().toString();
				lineXML.@editable = edge.isEditable().toString();
				lineXML.@jam = hasJam.toString(); // used for annotating code (buzzsaw)
				
				constraintsXML.appendChild(lineXML);
			}
		}
		
		override public function dispose():void
		{
			initialized = false;
			trace("Disposed of : " + m_levelLayoutXML.@id);
			if (m_disposed) {
				return;
			}
			
			if (tutorialManager) tutorialManager.endLevel();
			
			for each(var gameNodeSet:GameNode in m_nodeList) {
				gameNodeSet.removeFromParent(true);
				gameNodeSet.removeEventListener(EdgeSetChangeEvent.EDGE_SET_CHANGED, onEdgeSetChange);
			}
			m_nodeList = new Vector.<GameNode>();
			boxDictionary = new Dictionary();
			for each(var jointElem:GameNodeBase in m_jointList) {
				jointElem.removeFromParent(true);
			}
			m_jointList = new Vector.<GameJointNode>();
			jointDictionary = new Dictionary();
			for each(var gameEdge:GameEdgeContainer in m_edgeList) {
				gameEdge.removeFromParent(true);
			}
			m_edgeList = new Vector.<GameEdgeContainer>();
			edgeContainerDictionary = null;
			
			if (m_nodesContainer) {
				while (m_nodesContainer.numChildren > 0) m_nodesContainer.getChildAt(0).removeFromParent(true);
				m_nodesContainer.removeFromParent(true);
			}
			if (m_jointsContainer) {
				while (m_jointsContainer.numChildren > 0) m_jointsContainer.getChildAt(0).removeFromParent(true);
				m_jointsContainer.removeFromParent(true);
			}
			if (m_errorContainer) {
				while (m_errorContainer.numChildren > 0) m_errorContainer.getChildAt(0).removeFromParent(true);
				m_errorContainer.removeFromParent(true);
			}
			if (m_edgesContainer) {
				while (m_edgesContainer.numChildren > 0) m_edgesContainer.getChildAt(0).removeFromParent(true);
				m_edgesContainer.removeFromParent(true);
			}
			if (m_plugsContainer) {
				while (m_plugsContainer.numChildren > 0) m_plugsContainer.getChildAt(0).removeFromParent(true);
				m_plugsContainer.removeFromParent(true);
			}
			
			disposeChildren();
			
			removeEventListener(EdgeContainerEvent.CREATE_JOINT, onCreateJoint);
			removeEventListener(EdgeContainerEvent.SEGMENT_MOVED, onSegmentMoved);
			removeEventListener(EdgeContainerEvent.SEGMENT_DELETED, onSegmentDeleted);
			removeEventListener(EdgeContainerEvent.HOVER_EVENT_OVER, onHoverOver);
			removeEventListener(EdgeContainerEvent.HOVER_EVENT_OUT, onHoverOut);
			//removeEventListener(EdgeSetChangeEvent.EDGE_SET_CHANGED, onEdgeSetChange); // do these per-box
			removeEventListener(PropertyModeChangeEvent.PROPERTY_MODE_CHANGE, onPropertyModeChange);
			removeEventListener(GameComponentEvent.COMPONENT_SELECTED, onComponentSelection);
			removeEventListener(GameComponentEvent.COMPONENT_UNSELECTED, onComponentSelection);
			removeEventListener(GroupSelectionEvent.GROUP_SELECTED, onGroupSelection);
			removeEventListener(GroupSelectionEvent.GROUP_UNSELECTED, onGroupUnselection);
			removeEventListener(MoveEvent.MOVE_EVENT, onMoveEvent);
			removeEventListener(MoveEvent.FINISHED_MOVING, onFinishedMoving);
			removeEventListener(ErrorEvent.ERROR_ADDED, onErrorAdded);
			removeEventListener(ErrorEvent.ERROR_REMOVED, onErrorRemoved);
			super.dispose();
			
			addEventListener(Event.ADDED_TO_STAGE, onAddedToStage); //if re-added to stage, start up again
		}
		
		override protected function onTouch(event:TouchEvent):void
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
		
		private function onSegmentMoved(event:EdgeContainerEvent):void
		{
			var newLeft:Number = m_boundingBox.left;
			var newRight:Number = m_boundingBox.right;
			var newTop:Number = m_boundingBox.top;
			var newBottom:Number = m_boundingBox.bottom;
			if (event.container != null) {
				newLeft = Math.min(newLeft, event.container.m_boundingBox.left);
				newRight = Math.max(newRight, event.container.m_boundingBox.right);
				newTop = Math.min(newTop, event.container.m_boundingBox.top);
				newBottom = Math.max(newBottom, event.container.m_boundingBox.bottom);
				m_boundingBox = new Rectangle(newLeft, newTop, newRight - newLeft, newBottom - newTop);
			}
			if (tutorialManager != null) {
				var pointingAt:Boolean = false;
				if ((tutorialManager.getTextInfo() != null) && (tutorialManager.getTextInfo().pointAtFn != null)) {
					var pointAtObject:DisplayObject = tutorialManager.getTextInfo().pointAtFn(this);
					if (pointAtObject == event.segment) pointingAt = true;
				}
				tutorialManager.onSegmentMoved(event, pointingAt);
			}
		}
		
		private function onSegmentDeleted(event:EdgeContainerEvent):void
		{
			// TODO: notify tutorial manager
		}
		
		private function onHoverOver(event:EdgeContainerEvent):void
		{
			m_segmentHovered = event.segment;
		}
		
		private function onHoverOut(event:EdgeContainerEvent):void
		{
			m_segmentHovered = null;
		}
		
		//called when a segment is double-clicked on
		private function onCreateJoint(event:EdgeContainerEvent):void
		{
			if (tutorialManager && (event.container != null)) tutorialManager.onJointCreated(event);
		}
		
		//assume this only generates on toggle width events
		public function onEdgeSetChange(evt:EdgeSetChangeEvent):void
		{
			//trace("Level: onEdgeSetChange");
			if (!evt.silent) {
				if (tutorialManager) tutorialManager.onEdgeSetChange(evt);
				if (!evt.propValue) {
					// Wide
					AudioManager.getInstance().audioDriver().playSfx(AssetsAudio.SFX_LOW_BELT);
				} else {
					// Narrow
					AudioManager.getInstance().audioDriver().playSfx(AssetsAudio.SFX_HIGH_BELT);
				}
			}
			var edgeSet:EdgeSetRef = evt.edgeSetChanged.m_edgeSet;
			if(edgeSet != null) {
				edgeSet.setProp(evt.prop, evt.propValue);
			}
			if (!evt.silent) dispatchEvent(new EdgeSetChangeEvent(EdgeSetChangeEvent.LEVEL_EDGE_SET_CHANGED, evt.edgeSetChanged, evt.prop, evt.propValue, this, evt.silent, evt.point));
		}
		
		private var m_propertyMode:String = PropDictionary.PROP_NARROW;
		public function onPropertyModeChange(evt:PropertyModeChangeEvent):void
		{
			var i:int;
			if (evt.prop == PropDictionary.PROP_NARROW) {
				m_propertyMode = PropDictionary.PROP_NARROW;
				for (i = 0; i < m_edgeList.length; i++) {
					m_edgeList[i].setPropertyMode(m_propertyMode);
					activate(m_edgeList[i]);
				}
				for (i = 0; i < m_nodeList.length; i++) {
					m_nodeList[i].setPropertyMode(m_propertyMode);
					activate(m_nodeList[i]);
				}
				for (i = 0; i < m_jointList.length; i++) {
					m_jointList[i].setPropertyMode(m_propertyMode);
					activate(m_jointList[i]);
				}
			} else {
				m_propertyMode = evt.prop;
				var edgesToActivate:Vector.<GameEdgeContainer> = new Vector.<GameEdgeContainer>();
				for (i = 0; i < m_jointList.length; i++) {
					if (m_jointList[i] is GameMapGetJoint) {
						var mapget:GameMapGetJoint = m_jointList[i] as GameMapGetJoint;
						if (mapget.getNode.getMapProperty() == evt.prop) {
							m_jointList[i].setPropertyMode(m_propertyMode);
							edgesToActivate = edgesToActivate.concat(mapget.getUpstreamEdgeContainers());
							continue;
						}
					}
					m_jointList[i].setPropertyMode(m_propertyMode);
					deactivate(m_jointList[i]);
				}
				var gameNodesToActivate:Vector.<GameNode> = new Vector.<GameNode>();
				var gameJointsToActivate:Vector.<GameJointNode> = new Vector.<GameJointNode>();
				for (i = 0; i < m_edgeList.length; i++) {
					m_edgeList[i].setPropertyMode(m_propertyMode);
					if (edgesToActivate.indexOf(m_edgeList[i]) > -1) {
						if (m_edgeList[i].m_fromComponent is GameNode) {
							gameNodesToActivate.push(m_edgeList[i].m_fromComponent as GameNode);
						} else if (m_edgeList[i].m_fromComponent is GameJointNode) {
							gameJointsToActivate.push(m_edgeList[i].m_fromComponent as GameJointNode);
						}
					} else {
						deactivate(m_edgeList[i]);
					}
				}
				for (i = 0; i < m_nodeList.length; i++) {
					m_nodeList[i].setPropertyMode(m_propertyMode);
					if (gameNodesToActivate.indexOf(m_nodeList[i]) == -1) {
						deactivate(m_nodeList[i]);
					}
				}
				for (i = 0; i < gameJointsToActivate.length; i++) {
					gameJointsToActivate[i].setPropertyMode(m_propertyMode);
					activate(gameJointsToActivate[i]);
				}
			}
			flatten();
		}
		
		private function activate(comp:GameComponent):void
		{
			if (comp is GameEdgeContainer) {
				var edge:GameEdgeContainer = comp as GameEdgeContainer;
				m_edgesContainer.addChild(edge);
				if (edge.socket) m_plugsContainer.addChild(edge.socket);
				if (edge.plug)   m_plugsContainer.addChild(edge.plug);
			} else if (comp is GameNode) {
				m_nodesContainer.addChild(comp);
			} else if (comp is GameJointNode) {
				m_jointsContainer.addChild(comp);
			}
		}
		
		private function deactivate(comp:GameComponent):void
		{
			if (comp is GameEdgeContainer) {
				var edge:GameEdgeContainer = comp as GameEdgeContainer;
				m_edgesInactiveContainer.addChild(edge);
				if (edge.socket) m_plugsInactiveContainer.addChild(edge.socket);
				if (edge.plug)   m_plugsInactiveContainer.addChild(edge.plug);
			} else if (comp is GameNode) {
				m_nodesInactiveContainer.addChild(comp);
			} else if (comp is GameJointNode) {
				m_jointsInactiveContainer.addChild(comp);
			}
		}
		
		private function refreshTroublePoints():void
		{
			for (var i:int = 0; i < m_edgeList.length; i++) {
				m_edgeList[i].onConflictChange();
			}
		}
		
		//data object should be in final selected/unselected state
		private function componentSelectionChanged(component:GameComponent, selected:Boolean):void
		{
			if(selected)
			{
				if(selectedComponents.indexOf(component) == -1)
					selectedComponents.push(component);
				//push any connecting edges that have both connected nodes selected
				if (component is GameNodeBase) {
					for each(var edge:GameEdgeContainer in (component as GameNodeBase).m_incomingEdges)
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
					for each(var edge1:GameEdgeContainer in (component as GameNodeBase).m_outgoingEdges)
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
			}
			else
			{
				var index:int = selectedComponents.indexOf(component);
				if(index != -1)
					selectedComponents.splice(index, 1);
				if (component is GameNodeBase) {
					for each(var edge2:GameEdgeContainer in (component as GameNodeBase).m_incomingEdges)
					{
						if(selectedComponents.indexOf(edge2) != -1)
						{
							var edgeIndex:int = selectedComponents.indexOf(edge2);
							selectedComponents.splice(edgeIndex, 1);
							edge2.componentSelected(false);
						}
					}
					for each(var edge3:GameEdgeContainer in (component as GameNodeBase).m_outgoingEdges)
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
		}
		
		private function onComponentSelection(evt:GameComponentEvent):void
		{
			var component:GameComponent = evt.component;
			if(component)
				componentSelectionChanged(component, true);
			
			var selectionChangedComponents:Vector.<GameComponent> = new Vector.<GameComponent>();
			selectionChangedComponents.push(component);
			addSelectionUndoEvent(selectionChangedComponents, true);
		}
		
		private function onComponentUnselection(evt:GameComponentEvent):void
		{
			var component:GameComponent = evt.component;
			if(component)
				componentSelectionChanged(component, false);
			
			var selectionChangedComponents:Vector.<GameComponent> = new Vector.<GameComponent>();
			selectionChangedComponents.push(component);
			addSelectionUndoEvent(selectionChangedComponents, false);
		}
		
		private function onGroupSelection(evt:GroupSelectionEvent):void
		{
			var selectionChangedComponents:Vector.<GameComponent> = evt.selection.concat();
			for each (var comp:GameComponent in selectionChangedComponents) {
				comp.componentSelected(true);
				componentSelectionChanged(comp, true);
			}
			addSelectionUndoEvent(evt.selection.concat(), true, true);
		}
		
		private function onGroupUnselection(evt:GroupSelectionEvent):void
		{
			var selectionChangedComponents:Vector.<GameComponent> = evt.selection.concat();
			for each (var comp:GameComponent in selectionChangedComponents) {
				comp.componentSelected(false);
				componentSelectionChanged(comp, false);
			}
			addSelectionUndoEvent(evt.selection.concat(), false);
		}
		
		private function onFinishedMoving(evt:MoveEvent):void
		{
			// Recalc bounds
			var minX:Number, minY:Number, maxX:Number, maxY:Number;
			minX = minY = Number.POSITIVE_INFINITY;
			maxX = maxY = Number.NEGATIVE_INFINITY;
			var i:int;
			if (evt.component is GameNodeBase) {
				// If moved node or joint, check those bounds - otherwise assume they're unchanged
				for (i = 0; i < m_nodeList.length; i++) {
					minX = Math.min(minX, m_nodeList[i].m_boundingBox.left);
					minY = Math.min(minY, m_nodeList[i].m_boundingBox.top);
					maxX = Math.max(maxX, m_nodeList[i].m_boundingBox.right);
					maxY = Math.max(maxY, m_nodeList[i].m_boundingBox.bottom);
				}
				for (i = 0; i < m_jointList.length; i++) {
					minX = Math.min(minX, m_jointList[i].m_boundingBox.left);
					minY = Math.min(minY, m_jointList[i].m_boundingBox.top);
					maxX = Math.max(maxX, m_jointList[i].m_boundingBox.right);
					maxY = Math.max(maxY, m_jointList[i].m_boundingBox.bottom);
				}
			}
			for (i = 0; i < m_edgeList.length; i++) {
				minX = Math.min(minX, m_edgeList[i].m_boundingBox.left);
				minY = Math.min(minY, m_edgeList[i].m_boundingBox.top);
				maxX = Math.max(maxX, m_edgeList[i].m_boundingBox.right);
				maxY = Math.max(maxY, m_edgeList[i].m_boundingBox.bottom);
			}
			var oldBB:Rectangle = m_boundingBox.clone();
			m_boundingBox = new Rectangle(minX, minY, maxX - minX, maxY - minY);
			if (oldBB.x != m_boundingBox.x ||
			    oldBB.y != m_boundingBox.y ||
				oldBB.width != m_boundingBox.width ||
				oldBB.height != m_boundingBox.height) {
					dispatchEvent(new MiniMapEvent(MiniMapEvent.LEVEL_RESIZED));
			}
		}
		
		private function onErrorAdded(evt:ErrorEvent):void
		{
			errorList[evt.errorParticleSystem.id] = evt.errorParticleSystem;
		}
		
		private function onErrorRemoved(evt:ErrorEvent):void
		{
			delete errorList[evt.errorParticleSystem.id];
		}
		
		private function addSelectionUndoEvent(selection:Vector.<GameComponent>, selected:Boolean, addToLast:Boolean = false):void
		{
			if (selection.length == 0) {
				return;
			}
			var component:GameComponent = selection[0];
			var eventToUndo:Event;
			if (selected) {
				eventToUndo = new GroupSelectionEvent(GroupSelectionEvent.GROUP_SELECTED, component, selection);
			} else {
				eventToUndo = new GroupSelectionEvent(GroupSelectionEvent.GROUP_UNSELECTED, component, selection);
			}
			var eventToDispatch:UndoEvent = new UndoEvent(eventToUndo, this);
			eventToDispatch.addToLast = addToLast;
			dispatchEvent(eventToDispatch);
		}
		
		public function unselectAll(addEventToLast:Boolean = false):void
		{
			//make a copy of the selected list for the undo event
			var currentSelection:Vector.<GameComponent> = selectedComponents.concat();
			totalMoveDist = new Point();
			selectedComponents = new Vector.<GameComponent>();
			
			for each(var comp:GameComponent in currentSelection)
			{
				comp.componentSelected(false);
				componentSelectionChanged(comp, false);
			}
			
			if(currentSelection.length)
			{
				addSelectionUndoEvent(currentSelection, false, addEventToLast);
			}
		}
		
		private function onMoveEvent(evt:MoveEvent):void
		{
			var delta:Point = evt.delta;
			var newLeft:Number = m_boundingBox.left;
			var newRight:Number = m_boundingBox.right;
			var newTop:Number = m_boundingBox.top;
			var newBottom:Number = m_boundingBox.bottom;
			var movedNodes:Vector.<GameNode> = new Vector.<GameNode>();
			//if component isn't in the currently selected group, unselect everything, and then move component
			if(selectedComponents.indexOf(evt.component) == -1)
			{
				unselectAll();
				evt.component.componentMoved(delta);
				newLeft = Math.min(newLeft, evt.component.m_boundingBox.left);
				newRight = Math.max(newRight, evt.component.m_boundingBox.left);
				newTop = Math.min(newTop, evt.component.m_boundingBox.top);
				newBottom = Math.max(newBottom, evt.component.m_boundingBox.bottom);
				if (tutorialManager && (evt.component is GameNode)) {
					movedNodes.push(evt.component as GameNode);
					tutorialManager.onGameNodeMoved(movedNodes);
				}
			}
			else
			{
				//if (selectedComponents.length == 0) {
				//	totalMoveDist = new Point();
				//	return;
				//}
				var movedGameNode:Boolean = false;
				for each(var component:GameComponent in selectedComponents)
				{
					component.componentMoved(delta);
					newLeft = Math.min(newLeft, component.m_boundingBox.left);
					newRight = Math.max(newRight, component.m_boundingBox.left);
					newTop = Math.min(newTop, component.m_boundingBox.top);
					newBottom = Math.max(newBottom, component.m_boundingBox.bottom);

					if (component is GameNode) {
						movedNodes.push(component as GameNode);
						movedGameNode = true;
					}
				}
				if (tutorialManager && movedGameNode) tutorialManager.onGameNodeMoved(movedNodes);
			}
			totalMoveDist.x += delta.x;
			totalMoveDist.y += delta.y;
			trace(totalMoveDist);
			dispatchEvent(new MiniMapEvent(MiniMapEvent.ERRORS_MOVED));
			m_boundingBox = new Rectangle(newLeft, newTop, newRight - newLeft, newBottom - newTop);
		}
		
		public override function handleUndoEvent(undoEvent:Event, isUndo:Boolean = true):void
		{
			if (undoEvent is GroupSelectionEvent) //individual selections come through here also
			{
				var groupEvt:GroupSelectionEvent = undoEvent as GroupSelectionEvent;
				if (groupEvt.selection)
				{
					for each(var selectedComp:GameComponent in groupEvt.selection)
					{
						if(selectedComp is GameNodeBase)
						{
							var performSelection:Boolean;
							if (undoEvent.type == GroupSelectionEvent.GROUP_SELECTED) {
								performSelection = !isUndo; // select if redo, unselect if undo
							} else {
								performSelection = isUndo; // unselect if redo, select if undo
							}
							selectedComp.componentSelected(performSelection);
							componentSelectionChanged(selectedComp as GameNodeBase, performSelection);
						}
					}
				}
			}
			else if (undoEvent is MoveEvent)
			{
				var moveEvt:MoveEvent = undoEvent as MoveEvent;
				var delta:Point;
				if (!isUndo) {
					delta = moveEvt.delta.clone();
				} else {
					delta = new Point(-moveEvt.delta.x, -moveEvt.delta.y);
				}
				trace("isUndo:" + isUndo + " delta:" + delta);
				//not added as a temp selection, so move separately
				if (moveEvt.component)
					moveEvt.component.componentMoved(delta);
				for each(var selectedComponent:GameComponent in selectedComponents)
				{
					if (moveEvt.component != selectedComponent)
						selectedComponent.componentMoved(delta);
				}
			}
		}
		
		//to be called once to set everything up 
		//to move/update objects use update events
		public function draw():void
		{
			trace("Bounding Box " + m_boundingBox);
			var maxX:Number = Number.NEGATIVE_INFINITY;
			var maxY:Number = Number.NEGATIVE_INFINITY;
			
			var nodeCount:int = 0;
			for each(var gameNode:GameNode in m_nodeList)
			{
				gameNode.x = gameNode.m_boundingBox.x;
				gameNode.y = gameNode.m_boundingBox.y;
				gameNode.m_isDirty = true;
				m_nodesContainer.addChild(gameNode);
				nodeCount++;
			}
			
			var jointCount:int = 0;
			for each(var gameJoint:GameJointNode in m_jointList)
			{
				gameJoint.x = gameJoint.m_boundingBox.x;
				gameJoint.y = gameJoint.m_boundingBox.y;
				gameJoint.m_isDirty = true;
				m_jointsContainer.addChild(gameJoint);
				jointCount++;
			}
			
			var edgeCount:int = 0;
			for each(var gameEdge:GameEdgeContainer in m_edgeList)
			{
				gameEdge.m_isDirty = true;
				m_edgesContainer.addChild(gameEdge);
				m_errorContainer.addChild(gameEdge.errorContainer);
				if (gameEdge.socket) m_plugsContainer.addChild(gameEdge.socket);
				if (gameEdge.plug)   m_plugsContainer.addChild(gameEdge.plug);
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
			flatten();
		}
		
		private static function getVisible(_xml:XML, _defaultValue:Boolean = true):Boolean
		{
			var value:String = _xml.attribute("visible").toString();
			if (value.length == 0) return _defaultValue;
			return XString.stringToBool(value);
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
			if (m_layoutFixed) return;
			
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
				flatten();
			}
			else
			{
				var newSelectedComponents:Vector.<GameComponent> = new Vector.<GameComponent>();
				var newUnselectedComponents:Vector.<GameComponent> = new Vector.<GameComponent>();
				
				for each(var node:GameNode in m_nodeList)
				{
					handleSelection(node, newSelectedComponents, newUnselectedComponents);
				}
				for each(var joint:GameJointNode in m_jointList)
				{
					handleSelection(joint, newSelectedComponents, newUnselectedComponents);
				}
				removeChild(marqueeRect);
				
				addSelectionUndoEvent(newSelectedComponents, true);
				addSelectionUndoEvent(newUnselectedComponents, false, true);
			}
		}
		
		protected function handleSelection(node:GameNodeBase, newSelectedComponents:Vector.<GameComponent>, newUnselectedComponents:Vector.<GameComponent>):void
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
					if (node.m_isSelected) {
						if ((selectedComponents.indexOf(node) == -1) && (newSelectedComponents.indexOf(node) == -1)) {
							newSelectedComponents.push(node);
						}
					} else {
						if ((selectedComponents.indexOf(node) > -1) && (newUnselectedComponents.indexOf(node) == -1)) {
							newUnselectedComponents.push(node);
						}
					}
					componentSelectionChanged(node, node.m_isSelected);
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
		
		public function getNode(_id:String):GameNode
		{
			if (boxDictionary.hasOwnProperty(_id) && (boxDictionary[_id] is GameNode)) {
				return (boxDictionary[_id] as GameNode);
			}
			return null;
		}
		
		public function getJoint(_id:String):GameJointNode
		{
			if (jointDictionary.hasOwnProperty(_id) && (jointDictionary[_id] is GameJointNode)) {
				return (jointDictionary[_id] as GameJointNode);
			}
			return null;
		}
		
		public function getEdgeContainer(_id:String):GameEdgeContainer
		{
			if (edgeContainerDictionary.hasOwnProperty(_id) && (edgeContainerDictionary[_id] is GameEdgeContainer)) {
				return (edgeContainerDictionary[_id] as GameEdgeContainer);
			}
			return null;
		}
		
		public function getNodes():Vector.<GameNode>
		{
			return m_nodeList;
		}
		
		public function getJoints():Vector.<GameJointNode>
		{
			return m_jointList;
		}
		
		public function getLevelTextInfo():TutorialManagerTextInfo
		{
			return tutorialManager ? tutorialManager.getTextInfo() : null;
		}
		
		public function getLevelToolTipsInfo():Vector.<TutorialManagerTextInfo>
		{
			return tutorialManager ? tutorialManager.getPersistentToolTipsInfo() : (new Vector.<TutorialManagerTextInfo>());
		}
		
		public function getTargetScore():int
		{
			return m_targetScore;
		}
		
		public function setTargetScore(score:int):void
		{
			m_targetScore = score;
		}
		
		public function getTimeMs():Number
		{
			return new Date().time - m_levelStartTime;
		}	
		
		public function getNodesContainer():Sprite
		{
			return m_nodesContainer;
		}
		
		public function addGameComponentToStage(component:GameComponent):void
		{
			if(component is GameNodeBase)
				this.m_nodesContainer.addChild(component);
			else if(component is GameJointNode)
				this.m_jointsContainer.addChild(component);
			else if(component is GameEdgeContainer)
			{
				var gameEdge:GameEdgeContainer = component as GameEdgeContainer;
				this.m_edgesContainer.addChild(gameEdge);
				this.m_errorContainer.addChild(gameEdge.errorContainer);
				if (gameEdge.socket) m_plugsContainer.addChild(gameEdge.socket);
				if (gameEdge.plug)   m_plugsContainer.addChild(gameEdge.plug);
			}
		}
		
		public function removeGameComponentFromStage(component:GameComponent):void
		{
			if(component is GameNodeBase)
				this.m_nodesContainer.removeChild(component);
			else if(component is GameJointNode)
				this.m_jointsContainer.removeChild(component);
			else if(component is GameEdgeContainer)
			{
				var gameEdge:GameEdgeContainer = component as GameEdgeContainer;
				this.m_edgesContainer.removeChild(gameEdge);
				this.m_errorContainer.removeChild(gameEdge.errorContainer);
				if (gameEdge.socket) m_plugsContainer.addChild(gameEdge.socket);
				if (gameEdge.plug)   m_plugsContainer.addChild(gameEdge.plug);
			}
		}
		
		public function hideErrorText():void
		{
			if (!m_hidingErrorText) {
				for (var i:int = 0; i < m_edgeList.length; i++) {
					m_edgeList[i].hideErrorText();
				}
				m_hidingErrorText = true;
			}
		}
		
		public function showErrorText():void
		{
			if (m_hidingErrorText) {
				for (var i:int = 0; i < m_edgeList.length; i++) {
					m_edgeList[i].showErrorText();
				}
				m_hidingErrorText = false;
			}
		}
		
		/**
		 * Get next conflict: used for conflict scrolling
		 * @param	forward True to scroll forward, false to scroll backwards
		 * @return Conflict DisplayObject (if any exist)
		 */
		public function getNextConflict(forward:Boolean):DisplayObject
		{
			if (m_conflictEdgesDirty) {
				for (var i:int = 0; i < m_edgeList.length; i++) {
					if (m_edgeList[i].hasError()) {
						if (!m_levelConflictEdgeDict.hasOwnProperty(m_edgeList[i].m_id)) {
							// Add to list/dict if not on there already
							if (m_levelConflictEdges.indexOf(m_edgeList[i]) == -1) m_levelConflictEdges.push(m_edgeList[i]);
							m_levelConflictEdgeDict[m_edgeList[i].m_id] = true;
						}
					} else {
						if (m_levelConflictEdgeDict.hasOwnProperty(m_edgeList[i].m_id)) {
							// Remove from edge conflict list/dict if on it
							var delindx:int = m_levelConflictEdges.indexOf(m_edgeList[i]);
							if (delindx > -1) m_levelConflictEdges.splice(delindx, 1);
							delete m_levelConflictEdgeDict[m_edgeList[i].m_id];
						}
					}
				}
				m_conflictEdgesDirty = false;
			}
			if (m_levelConflictEdges.length == 0) return null;
			if (forward) {
				m_currentConflictIndex++;
			} else {
				m_currentConflictIndex--;
			}
			if (m_currentConflictIndex >= m_levelConflictEdges.length) {
				m_currentConflictIndex = 0;
			} else if (m_currentConflictIndex < 0) {
				m_currentConflictIndex = m_levelConflictEdges.length - 1;
			}
			return m_levelConflictEdges[m_currentConflictIndex].errorContainer;
		}
		
		//can't flatten errorContainer as particle system is unsupported display object
		public override function flatten():void
		{
			return; // uncomment when more testing performed
			// Active layers
			m_nodesContainer.flatten();
			m_jointsContainer.flatten();
			//m_errorContainer.flatten();// Can't flatten due to animations
			m_edgesContainer.flatten();
			m_plugsContainer.flatten();
			// Inactive layers
			m_nodesInactiveContainer.flatten();
			m_jointsInactiveContainer.flatten();
			//m_errorInactiveContainer.flatten();// Can't flatten due to animations
			m_edgesInactiveContainer.flatten();
			m_plugsInactiveContainer.flatten();
		}
		
		public override function unflatten():void
		{
			super.unflatten();
			// Active layers
			m_nodesContainer.unflatten();
			m_jointsContainer.unflatten();
			//m_errorContainer.unflatten();// Can't flatten due to animations
			m_edgesContainer.unflatten();
			m_plugsContainer.unflatten();
			// Inactive layers
			m_nodesInactiveContainer.unflatten();
			m_jointsInactiveContainer.unflatten();
			//m_errorInactiveContainer.unflatten();// Can't flatten due to animations
			m_edgesInactiveContainer.unflatten();
			m_plugsInactiveContainer.unflatten();
		}
		
		public function getPanZoomAllowed():Boolean
		{ 
			if (tutorialManager) return tutorialManager.getPanZoomAllowed();
			return true;
		}
		
		public function boardInLevel(boardName:String):Boolean
		{
			if (levelNodes && levelNodes.boardNodesDictionary) {
				return levelNodes.boardNodesDictionary.hasOwnProperty(boardName);
			}
			return false;
		}
		
		public static const SEGMENT_DELETION_ENABLED:Boolean = false;
		public function onDeletePressed():void
		{
			// Only delete if layout moves are allowed
			if (tutorialManager && tutorialManager.getLayoutFixed()) return;
			if (!SEGMENT_DELETION_ENABLED) return;
			if (m_segmentHovered) m_segmentHovered.onDeleted();
		}
		
		public function get currentScore():int { return m_currentScore; }
		public function get bestScore():int { return m_bestScore; }
		public function get prevScore():int { return m_prevScore; }
		public function get baseScore():int { return m_baseScore; }
		
		public function resetBestScore():void
		{
			m_bestScore = m_currentScore;
			m_levelBestScoreConstraintsXML = m_levelConstraintsXML.copy();
		}
		
		public function updateScore(recordBestScore:Boolean = false):void
		{
			/* Old scoring:
			* 
			For pipes:
			No points for any red pipe.
			For green pipes:
			10 points for every wide input pipe
			5 points for every narrow input pipe
			10 points for every narrow output pipe
			5 points for every wide output pipe
			1 point for every internal pipe, no matter what its width
			
			For solving the game:
			30 points per board solved
			- Changed this to 30 from 10 = original
			
			100 points per level solved
			1000 points per world solved
			
			For each exception to the laws of physics:
			-50 points
			*/
			
			/*
			 * New Scoring:
			 * +75 for each edge
			 * +25 for wide inputs
			 * +25 for narrow outputs
			 * -75 for errors
			*/
			
			m_prevScore = m_currentScore;
			var wideInputs:int = 0;
			var narrowOutputs:int = 0;
			var errors:int = 0;
			var totalLines:int = 0;
			var scoringNodes:Vector.<GameNode> = new Vector.<GameNode>();
			var potentialScoringNodes:Vector.<GameNode> = new Vector.<GameNode>();
			var errorEdges:Vector.<Edge> = new Vector.<Edge>();
			var errorPorts:Vector.<Port> = new Vector.<Port>();
			for (var edge:Object in edgeDictionary) {
				++ totalLines;
			}
			// Pass over all nodes, find nodes involved in scoring
			var allNodes:Vector.<GameNode> = getNodes();
			for (var nodeI:int = 0; nodeI < allNodes.length; nodeI++)
			{
				var nodeSet:GameNode = allNodes[nodeI];
				if (nodeSet.isEditable()) { // don't count star points for uneditable boxes
					var properIsWide:Boolean = nodeSet.m_edgeSet ? !nodeSet.m_edgeSet.getProps().hasProp(PropDictionary.PROP_NARROW) : nodeSet.isWide();
					if (properIsWide) {
						if (nodeSet.m_numIncomingNodeEdges - nodeSet.m_numOutgoingNodeEdges > 0) {
							wideInputs += nodeSet.m_numIncomingNodeEdges - nodeSet.m_numOutgoingNodeEdges;
							scoringNodes.push(nodeSet);
						} else if (nodeSet.m_numOutgoingNodeEdges - nodeSet.m_numIncomingNodeEdges > 0) {
							potentialScoringNodes.push(nodeSet);
						}
					} else {
						if (nodeSet.m_numOutgoingNodeEdges - nodeSet.m_numIncomingNodeEdges > 0) {
							narrowOutputs += nodeSet.m_numOutgoingNodeEdges - nodeSet.m_numIncomingNodeEdges;
							scoringNodes.push(nodeSet);
						} else if (nodeSet.m_numIncomingNodeEdges - nodeSet.m_numOutgoingNodeEdges > 0) {
							potentialScoringNodes.push(nodeSet);
						}
					}
				}
				for (var ie:int = 0; ie < nodeSet.m_incomingEdges.length; ie++) {
					var incomingEdge:GameEdgeContainer = nodeSet.m_incomingEdges[ie];
					if (!incomingEdge.graphEdge) continue;
					if (incomingEdge.graphEdge.hasAnyConflict() && (errorEdges.indexOf(incomingEdge.graphEdge) == -1)) {
						errors++;
						errorEdges.push(incomingEdge.graphEdge);
					}
					if (incomingEdge.graphEdge.from_port && incomingEdge.graphEdge.from_port.hasAnyConflict() && (errorPorts.indexOf(incomingEdge.graphEdge.from_port) == -1)) {
						errors++;
						errorPorts.push(incomingEdge.graphEdge.from_port);
					}
					if (incomingEdge.graphEdge.to_port && incomingEdge.graphEdge.to_port.hasAnyConflict() && (errorPorts.indexOf(incomingEdge.graphEdge.to_port) == -1)) {
						errors++;
						errorPorts.push(incomingEdge.graphEdge.to_port);
					}
				}
			}
			
			var allJoints:Vector.<GameJointNode> = getJoints();
			for (var j:int = 0; j < allJoints.length; j++) {
				var myJoint:GameJointNode = allJoints[j];
				for (var jie:int = 0; jie < myJoint.m_incomingEdges.length; jie++) {
					var injEdge:GameEdgeContainer = myJoint.m_incomingEdges[jie];
					if (!injEdge.graphEdge) continue;
					if (injEdge.graphEdge.hasAnyConflict() && (errorEdges.indexOf(injEdge.graphEdge) == -1)) {
						errors++;
						errorEdges.push(injEdge.graphEdge);
					}
					if (injEdge.graphEdge.from_port && injEdge.graphEdge.from_port.hasAnyConflict() && (errorPorts.indexOf(injEdge.graphEdge.from_port) == -1)) {
						errors++;
						errorPorts.push(injEdge.graphEdge.from_port);
					}
					if (injEdge.graphEdge.to_port && injEdge.graphEdge.to_port.hasAnyConflict() && (errorPorts.indexOf(injEdge.graphEdge.to_port) == -1)) {
						errors++;
						errorPorts.push(injEdge.graphEdge.to_port);
					}
				}
			}
			
			//trace("totalLines:" + totalLines + " wideInputs:" + wideInputs + " narrowOutputs:" + narrowOutputs + " errors:" + errors);
			m_currentScore = Constants.POINTS_PER_LINE * totalLines + Constants.WIDE_INPUT_POINTS * wideInputs + Constants.NARROW_OUTPUT_POINTS * narrowOutputs + Constants.ERROR_POINTS * errors;
			if (recordBestScore && (m_currentScore > m_bestScore)) {
				m_bestScore = m_currentScore;
				trace("New best score: " + m_bestScore);
				fillConstraintsXML(m_levelBestScoreConstraintsXML);
			}
			m_baseScore = Constants.POINTS_PER_LINE * totalLines;
			m_conflictEdgesDirty = true;
		}
		
	}
}