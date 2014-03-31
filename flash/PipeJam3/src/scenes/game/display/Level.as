package scenes.game.display
{
	import flash.events.TimerEvent;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.ByteArray;
	import flash.utils.Dictionary;
	import flash.utils.Timer;
	
	import assets.AssetInterface;
	import assets.AssetsAudio;
	
	import audio.AudioManager;
	
	import constraints.Constraint;
	import constraints.ConstraintGraph;
	import constraints.ConstraintValue;
	import constraints.ConstraintVar;
	
	import deng.fzip.FZip;
	
	import display.ToolTipText;
	
	import events.EdgeContainerEvent;
	import events.ErrorEvent;
	import events.GameComponentEvent;
	import events.GroupSelectionEvent;
	import events.MenuEvent;
	import events.MiniMapEvent;
	import events.MoveEvent;
	import events.PropertyModeChangeEvent;
	import events.UndoEvent;
	import events.WidgetChangeEvent;
	
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
	
	import system.MaxSatSolver;
	
	import utils.Base64Encoder;
	import utils.XObject;
	import utils.XString;
	
	/**
	 * Level all game components - widgets and links
	 */
	public class Level extends BaseComponent
	{
		
		/** True to allow user to navigate to any level regardless of whether levels below it are solved for debugging */
		public static var UNLOCK_ALL_LEVELS_FOR_DEBUG:Boolean = false;
		
		/** Name of this level */
		public var level_name:String;
		
		/** Node collection used to create this level, including name obfuscater */
		public var levelGraph:ConstraintGraph;
		
		private var selectedComponents:Vector.<GameComponent>;
		/** used by solver to keep track of which nodes map to which constraint values, and visa versa */
		private var nodeIDToConstraintsTwoWayMap:Dictionary;
		
		private var marqueeRect:Shape = new Shape();
		
		//the level node and decendents
		private var m_levelLayoutObj:Object;
		public var levelObj:Object;
		public var m_levelLayoutName:String;
		public var m_levelQID:String;
		private var m_levelOriginalLayoutObj:Object; //used for restarting the level
		//used when saving, as we need a parent graph element for the above level node
		public var m_levelLayoutObjWrapper:Object;
		public var m_levelAssignmentsObj:Object;
		private var m_levelOriginalAssignmentsObj:Object; //used for restarting the level
		private var m_levelBestScoreAssignmentsObj:Object; //best configuration so far
		public var m_tutorialTag:String;
		public var tutorialManager:TutorialLevelManager;
		private var m_layoutFixed:Boolean = false;
		public var m_targetScore:int;
		
		private var boxDictionary:Dictionary;
		private var edgeContainerDictionary:Dictionary;
		
		private var m_nodeList:Vector.<GameNode>;
		public var m_edgeList:Vector.<GameEdgeContainer>;
		private var m_hidingErrorText:Boolean = false;
		private var m_segmentHovered:GameEdgeSegment;
		public var errorList:Dictionary = new Dictionary();
		
		private var m_nodesInactiveContainer:Sprite = new Sprite();
		private var m_errorInactiveContainer:Sprite = new Sprite();
		private var m_edgesInactiveContainer:Sprite = new Sprite();
		private var m_plugsInactiveContainer:Sprite = new Sprite();
		public var inactiveLayer:Sprite = new Sprite();
		
		private var m_nodesContainer:Sprite = new Sprite();
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
		/** previous - 1 score for player */
		//prevScore gets updated too quickly, so this shadows and lags behind
		private var m_oldScore:int = 0;
		
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
		 * Level contains widgets, links for entire input level constraint graph
		 * @param	_name Name to display
		 * @param	_levelGraph Constraint Graph
		 * @param	_levelObj JSON parsed representation of constraint graph input from PL group
		 * @param	_levelLayoutObj Layout of graph elements
		 * @param	_levelAssignmentsObj Assignment of var values
		 * @param	_targetScore Score needed to complete level
		 * @param	_originalLevelName Level name from PL group
		 */
		public function Level(_name:String, _levelGraph:ConstraintGraph, _levelObj:Object, _levelLayoutObj:Object, _levelAssignmentsObj:Object, _targetScore:int, _originalLevelName:String)
		{
			UNLOCK_ALL_LEVELS_FOR_DEBUG = PipeJamGame.DEBUG_MODE;
			level_name = _name;
			original_level_name = _originalLevelName;
			levelGraph = _levelGraph;
			levelObj = _levelObj;
			m_levelLayoutObj = XObject.clone(_levelLayoutObj);
			m_levelOriginalLayoutObj = _levelLayoutObj;// XObject.clone(_levelLayoutObj);
			m_levelLayoutName = _levelLayoutObj["id"];
			m_levelQID = _levelLayoutObj["qid"];
			m_levelBestScoreAssignmentsObj = _levelAssignmentsObj;// XObject.clone(_levelAssignmentsObj);
			m_levelOriginalAssignmentsObj = _levelAssignmentsObj;// XObject.clone(_levelAssignmentsObj);
			m_levelAssignmentsObj = _levelAssignmentsObj;// XObject.clone(_levelAssignmentsObj);
			
			m_tutorialTag = m_levelLayoutObj["tutorial"];
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
			setNodesFromAssignments(m_levelBestScoreAssignmentsObj, true);
		}
		
		public function loadAssignmentsConfiguration(assignmentsObj:Object):void
		{
			setNodesFromAssignments(assignmentsObj);
		}
		
		private function setNodesFromAssignments(assignmentsObj:Object, updateTutorialManager:Boolean = false):void
		{
			//save object and restore at after initial assignments since I don't want these assignments saved
			var savedAssignmentObj:Object = PipeJam3.m_savedCurrentLevel.data.assignmentUpdates;
			PipeJam3.m_savedCurrentLevel.data.assignmentUpdates = null;
			for (var i:int = 0; i < m_nodeList.length; i++) {
				var gameNode:GameNode = m_nodeList[i];
				// By default, reset gameNode to default value, then if contained in "assignments" obj, use that value instead
				var assignmentIsWide:Boolean = (gameNode.constraintVar.defaultVal.verboseStrVal == ConstraintValue.VERBOSE_TYPE_1);
				if (assignmentsObj["assignments"].hasOwnProperty(gameNode.constraintVar.formattedId)
					&& assignmentsObj["assignments"][gameNode.constraintVar.formattedId].hasOwnProperty(ConstraintGraph.TYPE_VALUE)) {
					assignmentIsWide = (assignmentsObj["assignments"][gameNode.constraintVar.formattedId][ConstraintGraph.TYPE_VALUE] == ConstraintValue.VERBOSE_TYPE_1);
				}
				if (gameNode.isWide() != assignmentIsWide) {
					gameNode.handleWidthChange(assignmentIsWide, true);
					if (updateTutorialManager && tutorialManager) {
						tutorialManager.onWidgetChange(new WidgetChangeEvent(WidgetChangeEvent.WIDGET_CHANGED, gameNode, PropDictionary.PROP_NARROW, !assignmentIsWide, this, true));
					}
				}
				
				//and then set from local storage, if there
				if(!updateTutorialManager && savedAssignmentObj && savedAssignmentObj[gameNode.m_id] != null)
				{
					var newWidth:String = savedAssignmentObj[gameNode.m_id];
					var savedAssignmentIsWide:Boolean = (newWidth == ConstraintValue.VERBOSE_TYPE_1);
					
					if (gameNode.isWide() != savedAssignmentIsWide) 
					{
						gameNode.handleWidthChange(savedAssignmentIsWide, true);
					}
				}

			}
			if(gameNode) dispatchEvent(new WidgetChangeEvent(WidgetChangeEvent.LEVEL_WIDGET_CHANGED, gameNode, PropDictionary.PROP_NARROW, !gameNode.m_isWide, this, false, null));
			refreshTroublePoints();	
			PipeJam3.m_savedCurrentLevel.data.assignmentUpdates = savedAssignmentObj;
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
			trace("Level.initialize()...");
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
			if (m_errorInactiveContainer == null)  m_errorInactiveContainer  = new Sprite();
			if (m_edgesInactiveContainer == null)  m_edgesInactiveContainer  = new Sprite();
			if (m_plugsInactiveContainer == null)  m_plugsInactiveContainer  = new Sprite();
			inactiveLayer.addChild(m_nodesInactiveContainer);
			inactiveLayer.addChild(m_errorInactiveContainer);
			inactiveLayer.addChild(m_edgesInactiveContainer);
			inactiveLayer.addChild(m_plugsInactiveContainer);
			
			if (m_nodesContainer == null)  m_nodesContainer  = new Sprite();
			if (m_errorContainer == null)  m_errorContainer  = new Sprite();
			if (m_edgesContainer == null)  m_edgesContainer  = new Sprite();
			if (m_plugsContainer == null)  m_plugsContainer  = new Sprite();
			//m_nodesContainer.filter = BlurFilter.createDropShadow(4.0, 0.78, 0x0, 0.85, 2, 1); //only works up to 2048px
			addChild(m_nodesContainer);
			addChild(m_errorContainer);
			addChild(m_edgesContainer);
			addChild(m_plugsContainer);
			
			this.alpha = .999;

			m_edgeList = new Vector.<GameEdgeContainer>;
			selectedComponents = new Vector.<GameComponent>;
			totalMoveDist = new Point();
			
			trace(m_levelLayoutObj["id"]);
			
			var minX:Number, minY:Number, maxX:Number, maxY:Number;
			minX = minY = Number.POSITIVE_INFINITY;
			maxX = maxY = Number.NEGATIVE_INFINITY;
			
			//create node for sets
			m_nodeList = new Vector.<GameNode>(); 
			boxDictionary = new Dictionary();
			edgeContainerDictionary = new Dictionary();
			
			// Process <box> 's
			var visibleNodes:int = 0;
			for (var varId:String in m_levelLayoutObj["layout"]["vars"])
			{
				var gameNode:GameNode;
				var boxLayoutObj:Object = m_levelLayoutObj["layout"]["vars"][varId];
				if (!levelGraph.variableDict.hasOwnProperty(varId)) {
					throw new Error("Couldn't find edge set for var id: " + varId);
				} else {
					var constraintVar:ConstraintVar = levelGraph.variableDict[varId];
					gameNode = new GameNode(boxLayoutObj, constraintVar, !m_layoutFixed);
				}
				
				gameNode.addEventListener(WidgetChangeEvent.WIDGET_CHANGED, onWidgetChange);
				
				var boxVisible:Boolean = true;
				if (boxLayoutObj.hasOwnProperty("visible") && (boxLayoutObj["visible"] == "false")) boxVisible = false;
				if (boxVisible) {
					visibleNodes++;
					minX = Math.min(minX, gameNode.boundingBox.left);
					minY = Math.min(minY, gameNode.boundingBox.top);
					maxX = Math.max(maxX, gameNode.boundingBox.right);
					maxY = Math.max(maxY, gameNode.boundingBox.bottom);
				} else {
					gameNode.hideComponent(true);
					boxLayoutObj["visible"] = "false";
				}
				m_nodeList.push(gameNode);
				boxDictionary[varId] = gameNode;
			}
			trace("gamenodeset count = " + m_nodeList.length);
			
			// Process <line> 's
			var visibleLines:int = 0;
			for (var constraintId:String in m_levelLayoutObj["layout"]["constraints"])
			{
				var edgeLayoutObj:Object = m_levelLayoutObj["layout"]["constraints"][constraintId];
				var gameEdge:GameEdgeContainer = createLine(constraintId, edgeLayoutObj);
				if (!gameEdge.hidden) {
					var boundingBox:Rectangle = gameEdge.boundingBox;
					visibleLines++;
					minX = Math.min(minX, boundingBox.x);
					minY = Math.min(minY, boundingBox.y);
					maxX = Math.max(maxX, boundingBox.x + boundingBox.width);
					maxY = Math.max(maxY, boundingBox.y + boundingBox.height);
				}
			}
			
			//set bounds based on largest x, y found in boxes, joints, edges
			m_boundingBox = new Rectangle(minX, minY, maxX - minX, maxY - minY);
			trace("Level " + m_levelLayoutObj["id"] + " m_boundingBox = " + m_boundingBox);
			
			addEventListener(EdgeContainerEvent.CREATE_JOINT, onCreateJoint);
			addEventListener(EdgeContainerEvent.SEGMENT_MOVED, onSegmentMoved);
			addEventListener(EdgeContainerEvent.SEGMENT_DELETED, onSegmentDeleted);
			addEventListener(EdgeContainerEvent.HOVER_EVENT_OVER, onHoverOver);
			addEventListener(EdgeContainerEvent.HOVER_EVENT_OUT, onHoverOut);
			//addEventListener(WidgetChangeEvent.WIDGET_CHANGED, onEdgeSetChange); // do these per-box
			addEventListener(PropertyModeChangeEvent.PROPERTY_MODE_CHANGE, onPropertyModeChange);
			addEventListener(GameComponentEvent.COMPONENT_SELECTED, onComponentSelection);
			addEventListener(GameComponentEvent.COMPONENT_UNSELECTED, onComponentUnselection);
			addEventListener(GroupSelectionEvent.GROUP_SELECTED, onGroupSelection);
			addEventListener(GroupSelectionEvent.GROUP_UNSELECTED, onGroupUnselection);
			addEventListener(MoveEvent.MOVE_EVENT, onMoveEvent);
			addEventListener(MoveEvent.FINISHED_MOVING, onFinishedMoving);
			addEventListener(ErrorEvent.ERROR_ADDED, onErrorAdded);
			addEventListener(ErrorEvent.ERROR_REMOVED, onErrorRemoved);
			
			trace(visibleNodes, visibleLines);
			
			setNodesFromAssignments(m_levelAssignmentsObj);
			initialized = true;
		}
		
		private function createLine(edgeId:String, edgeLayoutObj:Object):GameEdgeContainer
		{
			var pattern:RegExp = /(.*) -> (.*)/i;
			var result:Object = pattern.exec(edgeId);
			if (result == null) throw new Error("Invalid constraint layout string found: " + edgeId);
			if (result.length != 3) throw new Error("Invalid constraint layout string found: " + edgeId);
			var edgeFromVarId:String = result[1];
			var edgeToVarId:String = result[2];
			if (!boxDictionary.hasOwnProperty(edgeFromVarId)) throw new Error("From var not found in boxDictionary:" + edgeFromVarId);
			if (!boxDictionary.hasOwnProperty(edgeToVarId)) throw new Error("To var not found in boxDictionary:" + edgeToVarId);
			var fromNode:GameNode = boxDictionary[edgeFromVarId] as GameNode;
			var toNode:GameNode = boxDictionary[edgeToVarId] as GameNode;
			if (!levelGraph.constraintsDict.hasOwnProperty(edgeId)) throw new Error("Edge not found in levelGraph.constraintsDict:" + edgeId);
			var constraint:Constraint = levelGraph.constraintsDict[edgeId];
			
			//create edge array
			var edgeArray:Array = new Array();
			var ptsArr:Array = edgeLayoutObj["pts"] as Array;
			if (!ptsArr) throw new Error("No layout pts found for edge:" + edgeId);
			if (ptsArr.length < 4) throw new Error("Not enough points found in layout for edge:" + edgeId);
			for (var i:int = 0; i < ptsArr.length; i++) {
				var ptx:Number = Number(ptsArr[i]["x"]);
				var pty:Number = Number(ptsArr[i]["y"]);
				var pt:Point = new Point(ptx * Constants.GAME_SCALE, pty * Constants.GAME_SCALE);
				edgeArray.push(pt);
			}
			
			var newGameEdge:GameEdgeContainer = new GameEdgeContainer(edgeId, edgeArray, fromNode, toNode, constraint, !m_layoutFixed);
			if (!getVisible(edgeLayoutObj)) newGameEdge.hideComponent(true);
			
			m_edgeList.push(newGameEdge);
			
			if (edgeContainerDictionary.hasOwnProperty(edgeId) && (edgeContainerDictionary[edgeId] is GameEdgeContainer)) {
				var oldEdgeContainer:GameEdgeContainer = edgeContainerDictionary[edgeId] as GameEdgeContainer;
				if (m_edgeList.indexOf(oldEdgeContainer) > -1) {
					m_edgeList.splice(m_edgeList.indexOf(oldEdgeContainer), 1);
				}
				oldEdgeContainer.removeFromParent(true);
			}
			
			edgeContainerDictionary[edgeId] = newGameEdge;
			return newGameEdge;
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
			
			m_bestScore = m_currentScore;
			flatten();
			trace("Loaded: " + m_levelLayoutObj["id"] + " for display.");
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
			setNewLayout(null, m_levelOriginalLayoutObj);
			m_levelAssignmentsObj = XObject.clone(m_levelOriginalAssignmentsObj);
			setNodesFromAssignments(m_levelAssignmentsObj);
			targetScoreReached = false;
			trace("Restarted: " + m_levelLayoutObj["id"]);
		}
		
		public function onSaveLayoutFile(event:MenuEvent):void
		{
			updateLevelObj();
			
			var levelObject:Object = PipeJamGame.levelInfo;
			if(levelObject != null)
			{
				m_levelLayoutObjWrapper["id"] = event.data.name;
				levelObject.m_layoutName = event.data.name;
				levelObject.m_layoutDescription = event.data.description;
				var layoutZip:ByteArray = zipJsonFile(m_levelLayoutObjWrapper, "layout");
				var layoutZipEncodedString:String = encodeBytes(layoutZip);
				GameFileHandler.saveLayoutFile(layoutSaved, layoutZipEncodedString);	
			}
		}
		
		protected function layoutSaved(result:int, e:flash.events.Event):void
		{
			dispatchEvent(new MenuEvent(MenuEvent.LAYOUT_SAVED));
		}
		
		public function zipJsonFile(jsonFile:Object, name:String):ByteArray
		{
			var newZip:FZip = new FZip();
			var zipByteArray:ByteArray = new ByteArray();
			zipByteArray.writeUTFBytes(JSON.stringify(jsonFile));
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
		
		public function updateLevelObj():void
		{
			var worldParent:DisplayObject = parent;
			while(worldParent && !(worldParent is World))
				worldParent = worldParent.parent;
			
			updateLayoutObj(worldParent as World, true);
			updateAssignmentsObj();
		}
		
		protected function onRemovedFromStage(event:Event):void
		{
			//disposeChildren();
		}
		
		public function setNewLayout(name:String, newLayoutObj:Object, useExistingLines:Boolean = false):void
		{
			m_levelLayoutObj = XObject.clone(newLayoutObj);
			m_levelLayoutName = name;
			//we might have ended up with a 'world', just grab the first level
			if(m_levelLayoutObj["levels"]) m_levelLayoutObj = m_levelLayoutObj["levels"][0];
			
			var minX:Number, minY:Number, maxX:Number, maxY:Number;
			minX = minY = Number.POSITIVE_INFINITY;
			maxX = maxY = Number.NEGATIVE_INFINITY;
			
			for (var varId:String in m_levelLayoutObj["layout"]["vars"]) {
				if (!boxDictionary.hasOwnProperty(varId)) {
					trace("Warning! Layout varId not found in boxDictionary:" + varId);
					continue;
				}
				var gameNode:GameNode = boxDictionary[varId] as GameNode;
				if (!useExistingLines) {
					gameNode.removeEdges();
				}
				var nodex:Number = Number(m_levelLayoutObj["layout"]["vars"][varId]["x"]);
				var nodey:Number = Number(m_levelLayoutObj["layout"]["vars"][varId]["y"]);
				var nodew:Number = Number(m_levelLayoutObj["layout"]["vars"][varId]["w"]);
				var nodeh:Number = Number(m_levelLayoutObj["layout"]["vars"][varId]["h"]);
				if (isNaN(nodex) || isNaN(nodey) || isNaN(nodew) || isNaN(nodew)) {
					trace("Warning! Bad layout found for varId:" + varId + " x,y,w,h: " + nodex + "," + nodey + "," + nodew + "," + nodeh);
					continue;
				}
				gameNode.width = nodew * Constants.GAME_SCALE;
				gameNode.height = nodeh * Constants.GAME_SCALE;
				gameNode.boundingBox.x = nodex * Constants.GAME_SCALE - gameNode.boundingBox.width/2;
				gameNode.boundingBox.y = nodey * Constants.GAME_SCALE - gameNode.boundingBox.height/2;
				
				gameNode.hideComponent(!getVisible(m_levelLayoutObj["layout"]["vars"][varId]));
				if (!gameNode.hidden) {
					minX = Math.min(minX, gameNode.boundingBox.left);
					minY = Math.min(minY, gameNode.boundingBox.top);
					maxX = Math.max(maxX, gameNode.boundingBox.right);
					maxY = Math.max(maxY, gameNode.boundingBox.bottom);
				}
			}
			
			if(useExistingLines == false)
			{
				//delete all existing edges, and recreate
				for each(var existingEdge:GameEdgeContainer  in m_edgeList) {
					existingEdge.removeFromParent(true);
				}
				edgeContainerDictionary = new Dictionary();
				m_edgeList = new Vector.<GameEdgeContainer>;
			}
			
			for (var constraintId:String in m_levelLayoutObj["layout"]["constraints"]) {
				var prevEdgeContainer:GameEdgeContainer = edgeContainerDictionary[constraintId];
				var boundingBox:Rectangle;
				if(useExistingLines == false && prevEdgeContainer == null)
				{
					var newEdgeContainter:GameEdgeContainer = createLine(constraintId, m_levelLayoutObj["layout"]["constraints"][constraintId]);
					if(newEdgeContainter.boundingBox)
					{
						minX = Math.min(minX, newEdgeContainter.boundingBox.left);
						minY = Math.min(minY, newEdgeContainter.boundingBox.top);
						maxX = Math.max(maxX, newEdgeContainter.boundingBox.right);
						maxY = Math.max(maxY, newEdgeContainter.boundingBox.bottom);
					}
				}
				else if(prevEdgeContainer)
				{
					//create edge array
					var edgeArray:Array = new Array();
					var ptsArr:Array = newLayoutObj["layout"]["constraints"][constraintId]["pts"] as Array;
					if (!ptsArr) throw new Error("No layout pts found for edge:" + constraintId);
					if (ptsArr.length < 4) throw new Error("Not enough points found in layout for edge:" + constraintId);
					for (var i:int = 0; i < ptsArr.length; i++) {
						var ptx:Number = Number(ptsArr[i]["x"]);
						var pty:Number = Number(ptsArr[i]["y"]);
						var pt:Point = new Point(ptx * Constants.GAME_SCALE, pty * Constants.GAME_SCALE);
						edgeArray.push(pt);
					}
					prevEdgeContainer.edgeArray = edgeArray;
					prevEdgeContainer.setupPoints();
					if (!prevEdgeContainer.hideSegments) {
						minX = Math.min(minX, prevEdgeContainer.boundingBox.left);
						minY = Math.min(minY, prevEdgeContainer.boundingBox.top);
						maxX = Math.max(maxX, prevEdgeContainer.boundingBox.right);
						maxY = Math.max(maxY, prevEdgeContainer.boundingBox.bottom);
					}
					prevEdgeContainer.buildLine();
				}
			}
			m_boundingBox = new Rectangle(minX, minY, maxX - minX, maxY - minY);
			trace("Level " + m_levelLayoutObj["id"] + " m_boundingBox = " + m_boundingBox);
			draw();
		}
		
		//update current layout info based on node/edge position
		// TODO: We don't want Level to depend on World, let's avoid circular 
		// class dependency and have World -> Level, not World <-> Level
		public function updateLayoutObj(world:World, includeThumbnail:Boolean = false):void
		{
			for (var varId:String in m_levelLayoutObj["layout"]["vars"]) {
				if (!boxDictionary.hasOwnProperty(varId)) {
					trace("Warning! Layout varid where no gameNode exists in boxDictionary varId:" + varId);
					continue;
				}
				var gameNode:GameNode = boxDictionary[varId] as GameNode;
				var currentLayoutX:Number = (gameNode.x + /*m_boundingBox.x*/ + gameNode.boundingBox.width/2) / Constants.GAME_SCALE;
				m_levelLayoutObj["layout"]["vars"][varId]["x"] = currentLayoutX.toFixed(2);
				var currentLayoutY:Number = (gameNode.y + /*m_boundingBox.y*/ + gameNode.boundingBox.height/2) / Constants.GAME_SCALE;
				m_levelLayoutObj["layout"]["vars"][varId]["y"] = currentLayoutY.toFixed(2);
				if (gameNode.hidden) {
					m_levelLayoutObj["layout"]["vars"][varId]["visible"] = "false";
				} else {
					delete m_levelLayoutObj["layout"]["vars"][varId]["visible"];
				}
			}
			for (var constraintId:String in m_levelLayoutObj["layout"]["constraints"]) {
				if (!edgeContainerDictionary.hasOwnProperty(constraintId)) {
					trace("Warning! Layout constraint found with no corresponding game edgeContainer found: " + constraintId);
					continue;
				}
				var edgeContainer:GameEdgeContainer = edgeContainerDictionary[constraintId] as GameEdgeContainer;
				m_levelLayoutObj["layout"]["constraints"][constraintId]["visible"] = (!edgeContainer.hidden).toString();
				m_levelLayoutObj["layout"]["constraints"][constraintId]["pts"] = new Array();
				
				if(edgeContainer.m_jointPoints.length != GameEdgeContainer.NUM_JOINTS)
					trace("Wrong number of joint points " + constraintId);
				for(var i:int = 0; i<edgeContainer.m_jointPoints.length; i++)
				{
					var pt:Point = edgeContainer.m_jointPoints[i];
					currentLayoutX = (pt.x + edgeContainer.x) / Constants.GAME_SCALE;
					currentLayoutY = (pt.y + edgeContainer.y) / Constants.GAME_SCALE;
					(m_levelLayoutObj["layout"]["constraints"][constraintId]["pts"] as Array).push( { "x": currentLayoutX.toFixed(2), "y": currentLayoutY.toFixed(2) } );
				}
			}
			
			m_levelLayoutObjWrapper = XObject.clone(m_levelLayoutObj);
			if(includeThumbnail)
			{
				var byteArray:ByteArray = world.getThumbnail(300, 300);
				var enc:Base64Encoder = new Base64Encoder();
				enc.encodeBytes(byteArray);
				m_levelLayoutObjWrapper["thumb"] = enc.toString();
			}
		}
		
		//update current constraint info based on node constraints
		public function updateAssignmentsObj():void
		{
			m_levelAssignmentsObj = createAssignmentsObj();
		}
		
		private function createAssignmentsObj():Object
		{
			var hashSize:int = Math.ceil(m_nodeList.length/100);
			PipeJamGame.levelInfo.hash = new Array();
			
			var assignmentsObj:Object = { "id": original_level_name, "hash": [] ,"assignments": { } };
			var count:int = 0;
			var numWide:int = 0;
			for each(var node:GameNode in m_nodeList)
			{
				if (node.constraintVar.constant) continue;
				if (!assignmentsObj["assignments"].hasOwnProperty(node.constraintVar.formattedId)) assignmentsObj["assignments"][node.constraintVar.formattedId] = { };
				assignmentsObj["assignments"][node.constraintVar.formattedId][ConstraintGraph.TYPE_VALUE] = node.constraintVar.getValue().verboseStrVal;
				var keyfors:Array = new Array();
				for (var i:int = 0; i < node.constraintVar.keyforVals.length; i++) keyfors.push(node.constraintVar.keyforVals[i]);
				if (keyfors.length > 0) assignmentsObj["assignments"][node.constraintVar.formattedId][ConstraintGraph.KEYFOR_VALUES] = keyfors;
				
				var isWide:Boolean = (node.constraintVar.getValue().verboseStrVal == ConstraintValue.VERBOSE_TYPE_1);
				if(isWide)
					numWide++;
				
				count++;
				
				if(count == hashSize)
				{
					count = 0;
					//store both in the file and externally
					assignmentsObj["hash"].push(numWide);
					PipeJamGame.levelInfo.hash.push(numWide);
					numWide = 0;
				}
			}
			//for each(var edge:GameEdgeContainer in m_edgeList)
			//{
				// We were outputting editable, hasJam, id, etc but doesn't seem necessary
			//}
			return assignmentsObj;
		}
		
		override public function dispose():void
		{
			initialized = false;
			trace("Disposed of : " + m_levelLayoutObj["id"]);
			if (m_disposed) {
				return;
			}
			
			if (tutorialManager) tutorialManager.endLevel();
			
			for each(var gameNodeSet:GameNode in m_nodeList) {
				gameNodeSet.removeFromParent(true);
				gameNodeSet.removeEventListener(WidgetChangeEvent.WIDGET_CHANGED, onWidgetChange);
			}
			m_nodeList = new Vector.<GameNode>();
			boxDictionary = new Dictionary();
			for each(var gameEdge:GameEdgeContainer in m_edgeList) {
				gameEdge.removeFromParent(true);
			}
			m_edgeList = new Vector.<GameEdgeContainer>();
			edgeContainerDictionary = null;
			
			if (m_nodesContainer) {
				while (m_nodesContainer.numChildren > 0) m_nodesContainer.getChildAt(0).removeFromParent(true);
				m_nodesContainer.removeFromParent(true);
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
			//removeEventListener(WidgetChangeEvent.EDGE_SET_CHANGED, onEdgeSetChange); // do these per-box
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
				newLeft = Math.min(newLeft, event.container.boundingBox.left);
				newRight = Math.max(newRight, event.container.boundingBox.right);
				newTop = Math.min(newTop, event.container.boundingBox.top);
				newBottom = Math.max(newBottom, event.container.boundingBox.bottom);
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
		public function onWidgetChange(evt:WidgetChangeEvent):void
		{
			//trace("Level: onWidgetChange");
			if (!evt.silent) {
				if (tutorialManager) tutorialManager.onWidgetChange(evt);
				if (!evt.propValue) {
					// Wide
					AudioManager.getInstance().audioDriver().playSfx(AssetsAudio.SFX_LOW_BELT);
				} else {
					// Narrow
					AudioManager.getInstance().audioDriver().playSfx(AssetsAudio.SFX_HIGH_BELT);
				}
			}
			var constraintVar:ConstraintVar = evt.widgetChanged.constraintVar;
			constraintVar.setProp(evt.prop, evt.propValue);
			if (!evt.silent) dispatchEvent(new WidgetChangeEvent(WidgetChangeEvent.LEVEL_WIDGET_CHANGED, evt.widgetChanged, evt.prop, evt.propValue, this, evt.silent, evt.point));
			
			//save incremental changes so we can update if user quits and restarts
			if(PipeJam3.m_savedCurrentLevel.data.assignmentUpdates) //should only be null when doing assignments from assignments file
			{
				var constraintType:String = ConstraintValue.VERBOSE_TYPE_1;
				//propValue isn't updated yet, so if it's currently wide, we want to save narrow
				if(evt.propValue)
					constraintType = ConstraintValue.VERBOSE_TYPE_0;
				PipeJam3.m_savedCurrentLevel.data.assignmentUpdates[evt.widgetChanged.m_id] = constraintType;
			}
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
			} else {
				m_propertyMode = evt.prop;
				var edgesToActivate:Vector.<GameEdgeContainer> = new Vector.<GameEdgeContainer>();
				for (i = 0; i < m_nodeList.length; i++) {
					// TODO: broken
					//if (m_nodeList[i] is GameMapGetJoint) {
						//var mapget:GameMapGetJoint = m_nodeList[i] as GameMapGetJoint;
						//if (mapget.getNode.getMapProperty() == evt.prop) {
							//m_nodeList[i].setPropertyMode(m_propertyMode);
							//edgesToActivate = edgesToActivate.concat(mapget.getUpstreamEdgeContainers());
							//continue;
						//}
					//}
					m_nodeList[i].setPropertyMode(m_propertyMode);
					deactivate(m_nodeList[i]);
				}
				var gameNodesToActivate:Vector.<GameNode> = new Vector.<GameNode>();
				for (i = 0; i < m_edgeList.length; i++) {
					m_edgeList[i].setPropertyMode(m_propertyMode);
					if (edgesToActivate.indexOf(m_edgeList[i]) > -1) {
						gameNodesToActivate.push(m_edgeList[i].m_fromNode);
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
			}
		}
		
		private function refreshTroublePoints():void
		{
			for (var i:int = 0; i < m_edgeList.length; i++) {
				m_edgeList[i].refreshConflicts();
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
					for each(var edge:GameEdgeContainer in (component as GameNodeBase).orderedIncomingEdges)
					{
						var fromComponent:GameNodeBase = edge.m_fromNode;
						if(selectedComponents.indexOf(fromComponent) != -1)
						{
							if(selectedComponents.indexOf(edge) == -1)
							{
								selectedComponents.push(edge);
							}
							edge.componentSelected(true);
						}
					}
					for each(var edge1:GameEdgeContainer in (component as GameNodeBase).orderedOutgoingEdges)
					{
						var toComponent:GameNodeBase = edge1.m_toNode;
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
					for each(var edge2:GameEdgeContainer in (component as GameNodeBase).orderedIncomingEdges)
					{
						if(selectedComponents.indexOf(edge2) != -1)
						{
							var edgeIndex:int = selectedComponents.indexOf(edge2);
							selectedComponents.splice(edgeIndex, 1);
							edge2.componentSelected(false);
						}
					}
					for each(var edge3:GameEdgeContainer in (component as GameNodeBase).orderedOutgoingEdges)
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
				// If moved node, check those bounds - otherwise assume they're unchanged
				for (i = 0; i < m_nodeList.length; i++) {
					minX = Math.min(minX, m_nodeList[i].boundingBox.left);
					minY = Math.min(minY, m_nodeList[i].boundingBox.top);
					maxX = Math.max(maxX, m_nodeList[i].boundingBox.right);
					maxY = Math.max(maxY, m_nodeList[i].boundingBox.bottom);
				}
			}
			for (i = 0; i < m_edgeList.length; i++) {
				minX = Math.min(minX, m_edgeList[i].boundingBox.left);
				minY = Math.min(minY, m_edgeList[i].boundingBox.top);
				maxX = Math.max(maxX, m_edgeList[i].boundingBox.right);
				maxY = Math.max(maxY, m_edgeList[i].boundingBox.bottom);
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
				newLeft = Math.min(newLeft, evt.component.boundingBox.left);
				newRight = Math.max(newRight, evt.component.boundingBox.left);
				newTop = Math.min(newTop, evt.component.boundingBox.top);
				newBottom = Math.max(newBottom, evt.component.boundingBox.bottom);
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
					newLeft = Math.min(newLeft, component.boundingBox.left);
					newRight = Math.max(newRight, component.boundingBox.left);
					newTop = Math.min(newTop, component.boundingBox.top);
					newBottom = Math.max(newBottom, component.boundingBox.bottom);

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
				gameNode.x = gameNode.boundingBox.x;
				gameNode.y = gameNode.boundingBox.y;
				gameNode.m_isDirty = true;
				//gameNode.visible = false; // zzz
				m_nodesContainer.addChild(gameNode);
				nodeCount++;
			}
			
			var edgeCount:int = 0;
			for each(var gameEdge:GameEdgeContainer in m_edgeList)
			{
				gameEdge.m_isDirty = true;
				//gameEdge.visible = false; // zzz
				m_edgesContainer.addChild(gameEdge);
				m_errorContainer.addChild(gameEdge.errorContainer);
				if (gameEdge.socket) m_plugsContainer.addChild(gameEdge.socket);
				if (gameEdge.plug)   m_plugsContainer.addChild(gameEdge.plug);
				edgeCount++;
			}
			trace("Nodes " + nodeCount + " Edges " + edgeCount);
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
		
		private static function getVisible(_layoutObj:Object, _defaultValue:Boolean = true):Boolean
		{
			var value:String = _layoutObj["visible"];
			if (!value) return _defaultValue;
			return XString.stringToBool(value);
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
					node.componentSelected(!node.isSelected);
					if (node.isSelected) {
						if ((selectedComponents.indexOf(node) == -1) && (newSelectedComponents.indexOf(node) == -1)) {
							newSelectedComponents.push(node);
						}
					} else {
						if ((selectedComponents.indexOf(node) > -1) && (newUnselectedComponents.indexOf(node) == -1)) {
							newUnselectedComponents.push(node);
						}
					}
					componentSelectionChanged(node, node.isSelected);
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
			//m_errorContainer.flatten();// Can't flatten due to animations
			m_edgesContainer.flatten();
			m_plugsContainer.flatten();
			// Inactive layers
			m_nodesInactiveContainer.flatten();
			//m_errorInactiveContainer.flatten();// Can't flatten due to animations
			m_edgesInactiveContainer.flatten();
			m_plugsInactiveContainer.flatten();
		}
		
		public override function unflatten():void
		{
			super.unflatten();
			// Active layers
			m_nodesContainer.unflatten();
			//m_errorContainer.unflatten();// Can't flatten due to animations
			m_edgesContainer.unflatten();
			m_plugsContainer.unflatten();
			// Inactive layers
			m_nodesInactiveContainer.unflatten();
			//m_errorInactiveContainer.unflatten();// Can't flatten due to animations
			m_edgesInactiveContainer.unflatten();
			m_plugsInactiveContainer.unflatten();
		}
		
		public function getPanZoomAllowed():Boolean
		{ 
			if (tutorialManager) return tutorialManager.getPanZoomAllowed();
			return true;
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
		public function get oldScore():int { return m_oldScore; }
		public function resetBestScore():void
		{
			m_bestScore = m_currentScore;
			m_levelBestScoreAssignmentsObj = XObject.clone(m_levelAssignmentsObj);
		}
		
		public function updateScore(recordBestScore:Boolean = false):void
		{
			m_oldScore = m_prevScore;
			m_prevScore = m_currentScore;
			levelGraph.updateScore();
			m_currentScore = Math.round(levelGraph.score); // TODO: round or force levelGraph score to be int?
			if (recordBestScore && (m_currentScore > m_bestScore)) {
				m_bestScore = m_currentScore;
				trace("New best score: " + m_bestScore);
				m_levelBestScoreAssignmentsObj = createAssignmentsObj();
				//don't update on loading
				if(m_oldScore != 0)
					dispatchEvent(new MenuEvent(MenuEvent.SUBMIT_LEVEL));
			}
			m_conflictEdgesDirty = true;
		}
		
		public function solveSelection():void
		{
			//figure out which edges have both start and end components selected (all included edges have both ends selected?)
			//assign connected components to component to edge constraint number dict
			//create three constraints for conflicts and weights
			//run the solver, passing in the callback function
			nodeIDToConstraintsTwoWayMap = new Dictionary;
			var counter:int = 1;
			var constraintArray:Array = new Array;
			
			for(var i:int = 0; i<selectedComponents.length; i++)
			{
				var constraint1Value:int = -1;
				var constraint2Value:int = -1;
				var component:GameComponent = selectedComponents[i];
				if(component is GameEdgeContainer)
				{
					var edge:GameEdgeContainer = component as GameEdgeContainer;
					var fromNode:GameNodeBase = edge.m_fromNode;
					var toNode:GameNodeBase = edge.m_toNode;
					
					if(fromNode.m_isEditable)
					{
						if(nodeIDToConstraintsTwoWayMap[fromNode.m_id] == null)
						{
							nodeIDToConstraintsTwoWayMap[fromNode.m_id] = counter;
							nodeIDToConstraintsTwoWayMap[counter] = fromNode;
							constraint1Value = counter;
							counter++;
						}
						else
							constraint1Value = nodeIDToConstraintsTwoWayMap[fromNode.m_id];
					} 
					
					if(toNode.m_isEditable)
					{
						if(nodeIDToConstraintsTwoWayMap[toNode.m_id] == null)
						{
							nodeIDToConstraintsTwoWayMap[toNode.m_id] = counter;
							nodeIDToConstraintsTwoWayMap[counter] = toNode;
							constraint2Value = counter;
							counter++;
						}
						else
							constraint2Value = nodeIDToConstraintsTwoWayMap[toNode.m_id];
					}
					
					if(fromNode.m_isEditable && toNode.m_isEditable)
						constraintArray.push(new Array(100, -constraint1Value, constraint2Value));
					else if(fromNode.m_isEditable && !toNode.m_isEditable)
					{
						if(!toNode.m_isWide)
							constraintArray.push(new Array(100, -constraint1Value));
					}
					if(!fromNode.m_isEditable && toNode.m_isEditable)
					{
						if(fromNode.m_isWide)
							constraintArray.push(new Array(100, constraint2Value));
					}
				}
				else if(component is GameNode)
				{
					var node:GameNode = component as GameNode;
					if(node.m_isEditable)
					{
						if(nodeIDToConstraintsTwoWayMap[node.m_id] == null)
						{
							nodeIDToConstraintsTwoWayMap[node.m_id] = counter;
							nodeIDToConstraintsTwoWayMap[counter] = node;
							constraint1Value = counter;
							counter++;
						}
						else
							constraint1Value = nodeIDToConstraintsTwoWayMap[node];
						
						trace(1, constraint1Value);

						constraintArray.push(new Array(1, constraint1Value));
					}
				}
			}
			
			if(constraintArray.length > 0)
			{
				MaxSatSolver.run_solver(constraintArray, solverCallback);
			}
		}
		
		
		protected function solverCallback(vars:Vector.<int>):void
		{
			var gameNode:GameNode;
			var assignmentIsWide:Boolean = false;
			for (var ii:int = 0; ii < vars.length; ++ ii) 
			{
				trace((ii+1) + " " + vars[ii]);
				gameNode = nodeIDToConstraintsTwoWayMap[ii+1];
				assignmentIsWide = false;
				if(vars[ii] == 1)
					assignmentIsWide = true;
				if(gameNode)
					gameNode.handleWidthChange(assignmentIsWide, true);
			}
			
			if(gameNode)
				onWidgetChange(new WidgetChangeEvent(WidgetChangeEvent.WIDGET_CHANGED, gameNode, PropDictionary.PROP_NARROW, !assignmentIsWide, this, false));
		}
	}
}