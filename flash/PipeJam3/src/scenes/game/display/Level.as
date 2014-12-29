package scenes.game.display
{
	import flash.events.Event;
	import flash.events.TimerEvent;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.system.System;
	import flash.ui.Keyboard;
	import flash.utils.ByteArray;
	import flash.utils.Dictionary;
	import flash.utils.Timer;
	import starling.display.BlendMode;
	import starling.display.DisplayObject;
	import starling.display.Image;
	import starling.display.Sprite;
	import starling.events.EnterFrameEvent;
	import starling.events.Event;
	import starling.events.Touch;
	import starling.events.TouchEvent;
	import starling.events.TouchPhase;
	import starling.textures.Texture;
	
	import assets.AssetInterface;
	import constraints.Constraint;
	import constraints.ConstraintClause;
	import constraints.ConstraintEdge;
	import constraints.ConstraintGraph;
	import constraints.ConstraintScoringConfig;
	import constraints.ConstraintValue;
	import constraints.ConstraintVar;
	import constraints.events.ErrorEvent;
	import constraints.events.VarChangeEvent;
	import deng.fzip.FZip;
	import events.MenuEvent;
	import events.MiniMapEvent;
	import events.PropertyModeChangeEvent;
	import events.SelectionEvent;
	import events.WidgetChangeEvent;
	import networking.GameFileHandler;
	import networking.PlayerValidation;
	import scenes.BaseComponent;
	import scenes.game.display.Node;
	import scenes.game.PipeJamGameScene;
	import system.MaxSatSolver;
	import utils.Base64Encoder;
	import utils.PropDictionary;
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
		
		public var selectedNodes:Vector.<GridChild> = new Vector.<GridChild>();
		/** used by solver to keep track of which nodes map to which constraint values, and visa versa */
		protected var nodeIDToConstraintsTwoWayMap:Dictionary;
		
		//the level node and decendents
		protected var m_levelLayoutObj:Object;
		public var levelObj:Object;
		public var m_levelLayoutName:String;
		public var m_levelQID:String;
		//used when saving, as we need a parent graph element for the above level node
		public var m_levelLayoutObjWrapper:Object;
		public var m_levelAssignmentsObj:Object;
		protected var m_levelOriginalAssignmentsObj:Object; //used for restarting the level
		protected var m_levelBestScoreAssignmentsObj:Object; //best configuration so far
		public var m_tutorialTag:String;
		public var tutorialManager:TutorialLevelManager;
		protected var m_layoutFixed:Boolean = false;
		public var m_targetScore:int;
		
		public var nodeLayoutObjs:Dictionary = new Dictionary();
		public var groupLayoutObjs:Dictionary = new Dictionary();
		public var edgeLayoutObjs:Dictionary = new Dictionary();
		
		protected var m_hidingErrorText:Boolean = false;
		
		protected var m_nodesInactiveContainer:Sprite = new Sprite();
		protected var m_errorInactiveContainer:Sprite = new Sprite();
		protected var m_edgesInactiveContainer:Sprite = new Sprite();
		public var inactiveLayer:Sprite = new Sprite();
		
		protected var m_nodesContainer:Sprite = new Sprite();
		protected var m_errorContainer:Sprite = new Sprite();
		protected var m_edgesContainer:Sprite = new Sprite();
		
		public var m_boundingBox:Rectangle = new Rectangle(0, 0, 1, 1);
		protected var m_backgroundImage:Image;
		protected var m_levelStartTime:Number;
		
		protected var initialized:Boolean = false;
		
		/** Current Score of the player */
		protected var m_bestScore:int = 0;
		
		/** Set to true when the target score is reached. */
		public var targetScoreReached:Boolean;
		public var original_level_name:String;
		
		protected var gridSystemDict:Dictionary;
		
		static public var GRID_SIZE:int = 500;
		static public var NUM_NODES_TO_SELECT:int = 75;
				
		static public var CONFLICT_CONSTRAINT_VALUE:Number = 100.0;
		static public var FIXED_CONSTRAINT_VALUE:Number = 1000.0;
		static public var WIDE_NODE_SIZE_CONSTRAINT_VALUE:Number = 1.0;
		static public var NARROW_NODE_SIZE_CONSTRAINT_VALUE:Number = 0.0;
		public var currentGridDict:Dictionary;
		
		protected var currentSelectionProcessCount:int;
		
		
		/** Tracks total distance components have been dragged since last visibile calculation */
		public var totalMoveDist:Point = new Point();
		
		// The following is used for conflict scrolling purposes: (tracking list of current conflicts)
		protected var m_currentConflictIndex:int = 0;
		
		public var m_inSolver:Boolean = false;
		
		protected static const BG_WIDTH:Number = 256;
		protected static const MIN_BORDER:Number = 1000;
		protected static const USE_TILED_BACKGROUND:Boolean = false; // true to include a background that scrolls with the view
		
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
		public function Level(_name:String, _levelGraph:ConstraintGraph, _levelObj:Object, _levelLayoutObj:Object, _levelAssignmentsObj:Object, _originalLevelName:String)
		{
			UNLOCK_ALL_LEVELS_FOR_DEBUG = PipeJamGame.DEBUG_MODE;
			level_name = _name;
			original_level_name = _originalLevelName;
			levelGraph = _levelGraph;
			levelObj = _levelObj;
			m_levelLayoutObj = _levelLayoutObj;
			m_levelLayoutName = _levelLayoutObj["id"];
			m_levelQID = _levelObj["qid"];
			m_levelBestScoreAssignmentsObj = _levelAssignmentsObj;// XObject.clone(_levelAssignmentsObj);
			m_levelOriginalAssignmentsObj = _levelAssignmentsObj;// XObject.clone(_levelAssignmentsObj);
			m_levelAssignmentsObj = _levelAssignmentsObj;// XObject.clone(_levelAssignmentsObj);
			
			m_tutorialTag = m_levelLayoutObj["tutorial"];
			if (m_tutorialTag && (m_tutorialTag.length > 0)) {
				tutorialManager = new TutorialLevelManager(m_tutorialTag);
				m_layoutFixed = tutorialManager.getLayoutFixed();
			}
			
			if(levelGraph.graphScoringConfig && levelGraph.graphScoringConfig.getScoringValue(ConstraintScoringConfig.CONSTRAINT_VALUE_KEY))
				CONFLICT_CONSTRAINT_VALUE = levelGraph.graphScoringConfig.getScoringValue(ConstraintScoringConfig.CONSTRAINT_VALUE_KEY);
			
			if(levelGraph.graphScoringConfig && levelGraph.graphScoringConfig.getScoringValue(ConstraintScoringConfig.TYPE_1_VALUE_KEY))
				WIDE_NODE_SIZE_CONSTRAINT_VALUE = levelGraph.graphScoringConfig.getScoringValue(ConstraintScoringConfig.TYPE_1_VALUE_KEY);
			
			if(levelGraph.graphScoringConfig && levelGraph.graphScoringConfig.getScoringValue(ConstraintScoringConfig.TYPE_0_VALUE_KEY))
				NARROW_NODE_SIZE_CONSTRAINT_VALUE = levelGraph.graphScoringConfig.getScoringValue(ConstraintScoringConfig.TYPE_0_VALUE_KEY);
			
			m_targetScore = int.MAX_VALUE;
			if ((m_levelAssignmentsObj["target_score"] != undefined) && !isNaN(int(m_levelAssignmentsObj["target_score"]))) {
				m_targetScore = int(m_levelAssignmentsObj["target_score"]);
			}
			else
				m_targetScore = 1000;
			
			targetScoreReached = false;
			addEventListener(starling.events.Event.ADDED_TO_STAGE, onAddedToStage); 
			
			gridSystemDict = new Dictionary;
			currentGridDict = new Dictionary;
			NodeSkin.InitializeSkins();
		}
		
		public function loadBestScoringConfiguration():void
		{
			loadAssignments(m_levelBestScoreAssignmentsObj, true);
		}
		
		public function loadInitialConfiguration():void
		{
			loadAssignments(m_levelOriginalAssignmentsObj, true);
		}
		
		public function loadAssignmentsConfiguration(assignmentsObj:Object):void
		{
			loadAssignments(assignmentsObj);
		}
		
		protected function loadAssignments(assignmentsObj:Object, updateTutorialManager:Boolean = false):void
		{
			PipeJam3.m_savedCurrentLevel.data.assignmentUpdates = null;
			var graphVar:ConstraintVar;
			for (var varId:String in levelGraph.variableDict) {
				graphVar = levelGraph.variableDict[varId] as ConstraintVar;
				setGraphVarFromAssignments(graphVar, assignmentsObj, updateTutorialManager);
			}
			if(graphVar) dispatchEvent(new WidgetChangeEvent(WidgetChangeEvent.LEVEL_WIDGET_CHANGED, graphVar, PropDictionary.PROP_NARROW, graphVar.getProps().hasProp(PropDictionary.PROP_NARROW), this, null));
			refreshTroublePoints();
			onScoreChange();
		}
		
		protected function setGraphVarFromAssignments(graphVar:ConstraintVar, assignmentsObj:Object, updateTutorialManager:Boolean = false):void
		{
			//save object and restore at after initial assignments since I don't want these assignments saved
			var savedAssignmentObj:Object = PipeJam3.m_savedCurrentLevel.data.assignmentUpdates;
			// By default, reset gameNode to default value, then if contained in "assignments" obj, use that value instead
			var assignmentIsWide:Boolean = (graphVar.defaultVal.verboseStrVal == ConstraintValue.VERBOSE_TYPE_1);
			if (assignmentsObj["assignments"].hasOwnProperty(graphVar.formattedId)
				&& assignmentsObj["assignments"][graphVar.formattedId].hasOwnProperty(ConstraintGraph.TYPE_VALUE)) {
				assignmentIsWide = (assignmentsObj["assignments"][graphVar.formattedId][ConstraintGraph.TYPE_VALUE] == ConstraintValue.VERBOSE_TYPE_1);
			}
			if (graphVar.getProps().hasProp(PropDictionary.PROP_NARROW) == assignmentIsWide) {
				levelGraph.updateScore(graphVar.id, PropDictionary.PROP_NARROW, !assignmentIsWide);
				//graphVar.setProp(PropDictionary.PROP_NARROW, !assignmentIsWide);
				//levelGraph.updateScore();
				if (updateTutorialManager && tutorialManager) {
					tutorialManager.onWidgetChange(graphVar.id, PropDictionary.PROP_NARROW, !assignmentIsWide, levelGraph);
				}
			}
			var gameNode:Node = nodeLayoutObjs[graphVar.id] as Node;
			if (gameNode && gameNode.isNarrow == assignmentIsWide) {
				gameNode.isNarrow = !assignmentIsWide;
				gameNode.setDirty(true);
			}
			
			//and then set from local storage, if there (but only if we really want it)
			if(PipeJamGameScene.levelContinued && !updateTutorialManager && savedAssignmentObj && savedAssignmentObj[graphVar.id] != null)
			{
				var newWidth:String = savedAssignmentObj[graphVar.id];
				var savedAssignmentIsWide:Boolean = (newWidth == ConstraintValue.VERBOSE_TYPE_1);
				if (graphVar.getProps().hasProp(PropDictionary.PROP_NARROW) == savedAssignmentIsWide) 
				{
					graphVar.setProp(PropDictionary.PROP_NARROW, !savedAssignmentIsWide);
				}
			}
		}
		
		protected function onAddedToStage(event:starling.events.Event):void
		{
			addEventListener(starling.events.Event.REMOVED_FROM_STAGE, onRemovedFromStage); 
			removeEventListener(starling.events.Event.ADDED_TO_STAGE, onAddedToStage);
			addEventListener(EnterFrameEvent.ENTER_FRAME, onEnterFrame);
			if (m_disposed) {
				restart(); // undo progress if left the level and coming back
			} else {
				start();
			}
			
			//for (var varId:String in levelGraph.variableDict) {
				//var graphVar:ConstraintVar = levelGraph.variableDict[varId] as ConstraintVar;
				//graphVar.addEventListener(VarChangeEvent.VAR_CHANGED_IN_GRAPH, onWidgetChange);
			//}
			addEventListener(VarChangeEvent.VAR_CHANGE_USER, onWidgetChange);
//			
//			refreshTroublePoints();
//			flatten();
			
			dispatchEvent(new starling.events.Event(Constants.STOP_BUSY_ANIMATION,true));
		}
		
		public function initialize():void
		{
			if (initialized) return;
			//trace("Level.initialize()...");
			var time1:Number = new Date().getTime();
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
			if (m_errorInactiveContainer == null)  m_errorInactiveContainer  = new Sprite();
			if (m_nodesInactiveContainer == null)  m_nodesInactiveContainer  = new Sprite();
			if (m_edgesInactiveContainer == null)  m_edgesInactiveContainer  = new Sprite();
			inactiveLayer.addChild(m_nodesInactiveContainer);
			inactiveLayer.addChild(m_errorInactiveContainer);
			inactiveLayer.addChild(m_edgesInactiveContainer);
			
			if (m_errorContainer == null)  m_errorContainer  = new Sprite();
			if (m_nodesContainer == null)  m_nodesContainer  = new Sprite();
			if (m_edgesContainer == null)  m_edgesContainer  = new Sprite();
			
			//m_nodesContainer.filter = BlurFilter.createDropShadow(4.0, 0.78, 0x0, 0.85, 2, 1); //only works up to 2048px
			addChild(m_errorContainer);
			addChild(m_edgesContainer);
			addChild(m_nodesContainer);
			//trace("load level time1", new Date().getTime()-time1);
			this.alpha = .999;

			totalMoveDist = new Point();
			loadLayout();
			
			//trace("Level " + m_levelLayoutObj["id"] + " m_boundingBox = " + m_boundingBox, "load layout time", new Date().getTime()-time1);
			
			//addEventListener(WidgetChangeEvent.WIDGET_CHANGED, onEdgeSetChange); // do these per-box
			addEventListener(PropertyModeChangeEvent.PROPERTY_MODE_CHANGE, onPropertyModeChange);
			addEventListener(SelectionEvent.COMPONENT_SELECTED, onComponentSelection);
			addEventListener(SelectionEvent.COMPONENT_UNSELECTED, onComponentUnselection);
			addEventListener(SelectionEvent.GROUP_SELECTED, onGroupSelection);
			addEventListener(SelectionEvent.GROUP_UNSELECTED, onGroupUnselection);
			levelGraph.addEventListener(ErrorEvent.ERROR_ADDED, onErrorAdded);
			levelGraph.addEventListener(ErrorEvent.ERROR_REMOVED, onErrorRemoved);
			
			loadInitialConfiguration();
			initialized = true;
			//trace("Level edges and nodes all created.");
			// When level loaded, don't need this event listener anymore
			dispatchEvent(new MenuEvent(MenuEvent.LEVEL_LOADED));
			//trace("load level time2", new Date().getTime() - time1);
			m_disposed = false;
		}
		
		protected function onEnterFrame(evt:EnterFrameEvent):void
		{
			var gridSquare:GridSquare;
			for each(gridSquare in currentGridDict)
			{
				gridSquare.draw();
			}
		}
		
		//called on when GridViewPanel content is moving
		public function updateLevelDisplay(viewRect:Rectangle = null):void
		{
			var leftGridNumber:int = Math.floor(viewRect ? viewRect.left/GRID_SIZE : -1);
			var rightGridNumber:int = Math.floor(viewRect ? viewRect.right/GRID_SIZE : GRID_SIZE);
			var topGridNumber:int = Math.floor(viewRect ? viewRect.top/GRID_SIZE : -1);
			var bottomGridNumber:int = Math.floor(viewRect ? viewRect.bottom/GRID_SIZE : GRID_SIZE);
			var newCurrentGridDict:Dictionary = new Dictionary;
			
			//create a new dictionary of current grid squares, removing those from the old dict
			for(var i:int = leftGridNumber; i<rightGridNumber+1; i++)
				for(var j:int = topGridNumber; j<bottomGridNumber+1; j++)
				{
					var gridName:String = i+"_"+j;
					if(gridSystemDict[gridName] != null) //it's created if there's something in it
					{
						gridSystemDict[gridName].activate();
						newCurrentGridDict[gridName] = gridSystemDict[gridName];
						delete currentGridDict[gridName];
					}
				}
			
			//clean up the old dictionary disposing of what's left
			for each(var gridSquare:GridSquare in currentGridDict)
			{
				//these we need to check the bounding box to see if it overlaps with the view rect,
				//if it does, keep it around, else destroy it
				if(viewRect == null || gridSquare.intersects(viewRect))
				{
					gridSquare.activate();
					newCurrentGridDict[gridSquare.id] = gridSystemDict[gridSquare.id];
					delete currentGridDict[gridSquare.id];
				}
				else
				{
					gridSquare.removeFromParent(true);
				}
			}
			
			currentGridDict = newCurrentGridDict;
		}
		
		public function draw():void
		{
			for each(var gridSquare:GridSquare in currentGridDict)
			{
				gridSquare.draw();
			}
		}
		
		private static const GROUP_SCALE_THRESHOLD:Number = 5.0 / Constants.GAME_SCALE;
		private var m_groupsShown:Boolean = false;
		
		private static const MIN_NODE_SCALE:Number = 4.0 / Constants.GAME_SCALE;
		
		public function handleScaleChange(newScaleX:Number, newScaleY:Number):void
		{
			var gridSquare:GridSquare,
				newNodeScaleX:Number,
				newNodeScaleY:Number;
			if (newScaleX < MIN_NODE_SCALE || newScaleY < MIN_NODE_SCALE) {
				newNodeScaleX = MIN_NODE_SCALE / newScaleX;
				newNodeScaleY = MIN_NODE_SCALE / newScaleY;
			} else {
				newNodeScaleX = newNodeScaleY = 1;
			}
			for each (gridSquare in currentGridDict)
			{
				gridSquare.scaleNodes(newNodeScaleX, newNodeScaleY);
			}
				
			if (newScaleX < GROUP_SCALE_THRESHOLD || newScaleY < GROUP_SCALE_THRESHOLD) {
				if (!m_groupsShown) {
					// TODO GROUPS
				}
			} else {
				if (m_groupsShown) {
					// TODO GROUPS
					m_groupsShown = false;
				}
			}
		}
		
		protected function createGridChildFromLayoutObj(gridChildId:String, gridChildLayout:Object, isGroup:Boolean):GridChild
		{
			var layoutX:Number = Number(gridChildLayout["x"]) * Constants.GAME_SCALE;
			var layoutY:Number = Number(gridChildLayout["y"]) * Constants.GAME_SCALE;
			
			var layoutWidth:Number = Number(gridChildLayout["w"]) * Constants.GAME_SCALE;
			var layoutHeight:Number = Number(gridChildLayout["h"]) * Constants.GAME_SCALE;
			
			var xArrayPos:int = Math.floor(layoutX / GRID_SIZE);
			var yArrayPos:int = Math.floor(layoutY / GRID_SIZE);
			
			var nodeGridName:String = xArrayPos + "_" + yArrayPos;
			var grid:GridSquare = gridSystemDict[nodeGridName];
			if(grid == null)
			{
				grid = new GridSquare(xArrayPos, yArrayPos, GRID_SIZE, GRID_SIZE);
				gridSystemDict[nodeGridName] = grid;
			}
			var gridChild:GridChild;
			//if (graphVar == null) {
				//trace("Warning: layout var found with no corresponding contraints var:" + gridChildId);
				//return null;
			//}
			if (nodeLayoutObjs.hasOwnProperty(gridChildId)) {
				var prevNode:Node = nodeLayoutObjs[gridChildId] as Node;
				prevNode.parentGrid.removeGridChild(prevNode);
			}
			var nodeBB:Rectangle = new Rectangle(layoutX - GridSquare.SKIN_DIAMETER * .5, layoutY - GridSquare.SKIN_DIAMETER * .5, GridSquare.SKIN_DIAMETER, GridSquare.SKIN_DIAMETER);
			if (gridChildId.substr(0, 3) == "var") {
				var graphVar:ConstraintVar = levelGraph.variableDict[gridChildId] as ConstraintVar;
				gridChild = new VariableNode(gridChildLayout, gridChildId, nodeBB, graphVar, grid);
			} else {
				var graphClause:ConstraintClause = levelGraph.clauseDict[gridChildId] as ConstraintClause;
				gridChild = new ClauseNode(gridChildLayout, gridChildId, nodeBB, graphClause, grid);
			}
			
			nodeLayoutObjs[gridChildId] = gridChild;
			grid.addGridChild(gridChild);
			return gridChild;
		}
		
		protected function loadLayout():void
		{
			nodeLayoutObjs = new Dictionary();
			groupLayoutObjs = new Dictionary();
			edgeLayoutObjs = new Dictionary();
			
			var minX:Number, minY:Number, maxX:Number, maxY:Number;
			minX = minY = Number.POSITIVE_INFINITY;
			maxX = maxY = Number.NEGATIVE_INFINITY;
			
			// Process layout nodes (vars)
			var visibleNodes:int = 0;
			var n:uint = 0;
			var gridChild:GridChild;
			for (var varId:String in m_levelLayoutObj["layout"]["vars"])
			{
				var thisNodeLayout:Object = m_levelLayoutObj["layout"]["vars"][varId];
				gridChild = createGridChildFromLayoutObj(varId, thisNodeLayout, false);
				if (gridChild == null) continue;
				minX = Math.min(minX, gridChild.bb.left);
				minY = Math.min(minY, gridChild.bb.top);
				maxX = Math.max(maxX, gridChild.bb.right);
				maxY = Math.max(maxY, gridChild.bb.bottom);
				n++;

			}
			for (var groupId:String in m_levelLayoutObj["layout"]["groups"])
			{
				var thisGroupLayout:Object = m_levelLayoutObj["layout"]["groups"][groupId];
				gridChild = createGridChildFromLayoutObj(groupId, thisGroupLayout, true);
				if (gridChild == null) continue;
				minX = Math.min(minX, gridChild.bb.left);
				minY = Math.min(minY, gridChild.bb.top);
				maxX = Math.max(maxX, gridChild.bb.right);
				maxY = Math.max(maxY, gridChild.bb.bottom);
			}
			for each(var gridSquare:GridSquare in currentGridDict)
			{
				gridSquare.calculateBounds();
			}
			//trace("node count = " + n);
			
			// Process layout edges (constraints)
			var visibleLines:int = 0;
			n = 0;
			
			for (var constraintId:String in levelGraph.constraintsDict)
			{
			//	edgeLayoutObj."id" = constraintId;
				var result:Object = constraintId.split(" ");
				if (result == null) throw new Error("Invalid constraint layout string found: " + constraintId);
				if (result.length != 3) throw new Error("Invalid constraint layout string found: " + constraintId);
				var graphConstraint:Constraint = levelGraph.constraintsDict[constraintId] as Constraint;
				if (graphConstraint == null) throw new Error("No graph constraint found for constraint layout: " + constraintId);
		//		edgeLayoutObj. = graphConstraint;
				var startNode:Node = nodeLayoutObjs[result[0]];
				var endNode:Node = nodeLayoutObjs[result[2]];
				//switch end points if needed (support both clause oriented files, and original, for the time being)
				if(result[2].indexOf('c') == -1 && result[0].indexOf('c') != -1)
				{
					startNode = nodeLayoutObjs[result[2]];
					endNode = nodeLayoutObjs[result[0]];
				}
				var edge:Edge = new Edge(constraintId, graphConstraint,startNode, endNode);
				startNode["connectedEdgeIds"].push(constraintId);
				endNode["connectedEdgeIds"].push(constraintId);
				
				edgeLayoutObjs[constraintId] = edge;
				
				addEdgeToGrids(edge);
				n++;
			}
			//trace("edge count = " + n);
			m_boundingBox = new Rectangle(minX, minY, maxX - minX, maxY - minY);
		}
		
		//in real life this probably should figure out what squares it travels through also.
		public function addEdgeToGrids(edge:Edge):void
		{
			edge.toNode.parentGrid.addEdge(edge);
			edge.fromNode.parentGrid.addEdge(edge);
		}
		
		public function addChildToConflictBackgroundLevel(child:Sprite):void
		{
			m_errorContainer.addChild(child);
		}
		
		public function addChildToNodeLevel(child:Sprite):void
		{
			m_nodesContainer.addChild(child);
			//uncomment to add quad as background to each gridSquare for debugging
//			var color:int = Math.random()*0xffffff;
//			var q:Quad = new Quad(GRID_SIZE, GRID_SIZE, color);
//			q.x = child.x;
//			q.y = child.y;
//			addChildAt(q,0);
		}
		
		public function addChildToEdgeLevel(child:Sprite):void
		{
			m_edgesContainer.addChild(child);
		}
		
		
		public function start():void
		{
			// create all nodes, edges for tutorials so that the tutorial indicators/arrows have something to point at
			if (tutorialManager) updateLevelDisplay();
			initialize();
			m_currentConflictIndex = 0;
			m_levelStartTime = new Date().time;
			if (tutorialManager) tutorialManager.startLevel();
			
			levelGraph.resetScoring();
			m_bestScore = levelGraph.currentScore;
			levelGraph.startingScore = levelGraph.currentScore;
			flatten();
			//trace("Loaded: " + m_levelLayoutObj["id"] + " for display.");
		}
		
		public function restart():void
		{
			unselectAll();
			if (!initialized) {
				start();
			} else {
				if (tutorialManager) {
					updateLevelDisplay(); // create any uncreated/disposed nodes
					tutorialManager.startLevel();
				}
				m_levelStartTime = new Date().time;
				m_currentConflictIndex = 0;
			}
			var propChangeEvt:PropertyModeChangeEvent = new PropertyModeChangeEvent(PropertyModeChangeEvent.PROPERTY_MODE_CHANGE, PropDictionary.PROP_NARROW);
			onPropertyModeChange(propChangeEvt);
			dispatchEvent(propChangeEvt);
			m_levelAssignmentsObj = XObject.clone(m_levelOriginalAssignmentsObj);
			loadAssignments(m_levelAssignmentsObj);
			
			targetScoreReached = false;
			//trace("Restarted: " + m_levelLayoutObj["id"]);
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
			// TODO: Circular dependency
			while(worldParent && !(worldParent is World))
				worldParent = worldParent.parent;
			
			updateAssignmentsObj();
		}
		
		protected function onRemovedFromStage(event:starling.events.Event):void
		{
			removeEventListener(EnterFrameEvent.ENTER_FRAME, onEnterFrame);
			addEventListener(starling.events.Event.ADDED_TO_STAGE, onAddedToStage); 
			removeEventListener(starling.events.Event.REMOVED_FROM_STAGE, onRemovedFromStage);
			//disposeChildren();
		}
		
		//update current constraint info based on node constraints
		public function updateAssignmentsObj():void
		{
			m_levelAssignmentsObj = createAssignmentsObj();
		}
		
		protected function createAssignmentsObj():Object
		{
			var hashSize:int = 0;
			var nodeId:String;
			for (nodeId in nodeLayoutObjs) hashSize++;
			
			PipeJamGame.levelInfo.hash = new Array();
			
			var assignmentsObj:Object = { "id": original_level_name, 
									"hash": [], 
									"target_score": this.m_targetScore,
									"starting_score": this.levelGraph.currentScore,
		//							"starting_jams": this.m_levelConflictEdges.length,
									"assignments": { } };
			var count:int = 0;
			var numWide:int = 0;
			for (nodeId in nodeLayoutObjs) {
				if (nodeId.substr(0, 1) == "c") continue;
				var constraintVar:ConstraintVar = levelGraph.variableDict[nodeId];
				if (constraintVar.constant) continue;
				if (!assignmentsObj["assignments"].hasOwnProperty(constraintVar.formattedId)) assignmentsObj["assignments"][constraintVar.formattedId] = { };
				assignmentsObj["assignments"][constraintVar.formattedId][ConstraintGraph.TYPE_VALUE] = constraintVar.getValue().verboseStrVal;
				
				var isWide:Boolean = (constraintVar.getValue().verboseStrVal == ConstraintValue.VERBOSE_TYPE_1);
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
			return assignmentsObj;
		}
		
		override public function dispose():void
		{
			initialized = false;
			//trace("Disposed of : " + m_levelLayoutObj["id"]);
			if (m_disposed) {
				return;
			}
			
			if (tutorialManager) tutorialManager.endLevel();
			
			nodeLayoutObjs = new Dictionary();
			
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
			
			for each(var gridSquare:GridSquare in currentGridDict)
			{
				gridSquare.removeFromParent(true);
			}
			
			disposeChildren();
			
			removeEventListener(VarChangeEvent.VAR_CHANGE_USER, onWidgetChange);
			removeEventListener(PropertyModeChangeEvent.PROPERTY_MODE_CHANGE, onPropertyModeChange);
			removeEventListener(SelectionEvent.COMPONENT_SELECTED, onComponentSelection);
			removeEventListener(SelectionEvent.COMPONENT_UNSELECTED, onComponentSelection);
			removeEventListener(SelectionEvent.GROUP_SELECTED, onGroupSelection);
			removeEventListener(SelectionEvent.GROUP_UNSELECTED, onGroupUnselection);
			if (levelGraph) levelGraph.removeEventListener(ErrorEvent.ERROR_ADDED, onErrorAdded);
			if (levelGraph) levelGraph.removeEventListener(ErrorEvent.ERROR_REMOVED, onErrorRemoved);
			super.dispose();		
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
		
		//assume this only generates on toggle width events
		public function onWidgetChange(evt:VarChangeEvent = null):void
		{
			//trace("Level: onWidgetChange");
			if (evt && evt.graphVar) {
				levelGraph.updateScore(evt.graphVar.id, evt.prop, evt.newValue);
				//evt.graphVar.setProp(evt.prop, evt.newValue);
				//levelGraph.updateScore();
				if (tutorialManager) tutorialManager.onWidgetChange(evt.graphVar.id, evt.prop, evt.newValue, levelGraph);
				dispatchEvent(new WidgetChangeEvent(WidgetChangeEvent.LEVEL_WIDGET_CHANGED, evt.graphVar, evt.prop, evt.newValue, this, evt.pt));
				//save incremental changes so we can update if user quits and restarts
				if(PipeJam3.m_savedCurrentLevel.data.assignmentUpdates) //should only be null when doing assignments from assignments file
				{
					var constraintType:String = evt.newValue ? ConstraintValue.VERBOSE_TYPE_0 : ConstraintValue.VERBOSE_TYPE_1;
					PipeJam3.m_savedCurrentLevel.data.assignmentUpdates[evt.graphVar.id] = constraintType;
				}
				dispatchEvent(new WidgetChangeEvent(WidgetChangeEvent.LEVEL_WIDGET_CHANGED, null, null, false, this, null));
			} else {
				levelGraph.updateScore();
				if (tutorialManager) tutorialManager.afterScoreUpdate(levelGraph);
				dispatchEvent(new WidgetChangeEvent(WidgetChangeEvent.LEVEL_WIDGET_CHANGED, null, null, false, this, null));
			}
			onScoreChange(true);
		}
		
		protected var m_propertyMode:String = PropDictionary.PROP_NARROW;
		public function onPropertyModeChange(evt:PropertyModeChangeEvent):void
		{
			if (evt.prop != PropDictionary.PROP_NARROW)
			{
				throw new Error("Unsupported property: " + evt.prop);
			}
		}
		
		protected function refreshTroublePoints():void
		{
	//		for (var edgeId:String in m_gameEdgeDict) {
	//			var gameEdge:GameEdgeContainer = m_gameEdgeDict[edgeId] as GameEdgeContainer;
	//			gameEdge.refreshConflicts();
	//		}
		}
		
		//data object should be in final selected/unselected state
		protected function componentSelectionChanged(component:Object, selected:Boolean):void
		{
			
		}
		
		protected function onComponentSelection(evt:SelectionEvent):void
		{
			var component:Object = evt.component;
			if(component)
				componentSelectionChanged(component, true);
			
			var selectionChangedComponents:Vector.<Object> = new Vector.<Object>();
			selectionChangedComponents.push(component);
		}
		
		protected function onComponentUnselection(evt:SelectionEvent):void
		{
			var component:Object = evt.component;
			if(component)
				componentSelectionChanged(component, false);
			
			var selectionChangedComponents:Vector.<Object> = new Vector.<Object>();
			selectionChangedComponents.push(component);
		}
		
		//used when ctrl-shift clicking a node, selects x whole group or nearest neighbors if no group
		protected function onGroupSelection(evt:SelectionEvent):void
		{
			if (evt.component is Node) {
				var node:Node = evt.component as Node;
				currentSelectionProcessCount = 1;
				var nextToVisitArray:Array = new Array;
				var previouslyCheckedNodes:Dictionary = new Dictionary;
				selectSurroundingNodes(node, nextToVisitArray, previouslyCheckedNodes);
				for each(var nextNode:Node in nextToVisitArray)
				{
					selectSurroundingNodes(nextNode, nextToVisitArray, previouslyCheckedNodes);
					if(currentSelectionProcessCount > NUM_NODES_TO_SELECT)
						break;
					currentSelectionProcessCount++;
				}
			}
		}
		
		public function selectSurroundingNodes(node:Node, nextToVisitArray:Array, previouslyCheckedNodes:Dictionary):void
		{
			node.select();
			
			for each(var gameEdgeID:String in node.connectedEdgeIds)
			{
				var edge:Edge = edgeLayoutObjs[gameEdgeID];
				var toNode:Node = edge.toNode;
				var fromNode:Node = edge.fromNode;
				
				var otherNode:Node = toNode;
				if(toNode == node)
					otherNode = fromNode;
				if(!otherNode.isSelected)
				{
					if(previouslyCheckedNodes[otherNode.id] == null)
					{
						nextToVisitArray.push(otherNode);
						previouslyCheckedNodes[otherNode.id] = otherNode;
					}
				}
			}
		}
		
		protected function onGroupUnselection(evt:SelectionEvent):void
		{
			for each (var comp:Object in evt.selection) {
				// TODO
			}
		}
		
		protected function onErrorAdded(evt:ErrorEvent):void
		{
			var clauseNode:ClauseNode;
			var clauseConstraint:ConstraintEdge = evt.constraintError as ConstraintEdge;
			if(clauseConstraint)
			{
				if(clauseConstraint.lhs.id.indexOf('c') != -1)
				{
					clauseNode = nodeLayoutObjs[clauseConstraint.lhs.id];
				}
				else if(clauseConstraint.rhs.id.indexOf('c') != -1)
				{
					clauseNode = nodeLayoutObjs[clauseConstraint.rhs.id];
				}
				if(clauseNode)
					clauseNode.addError(true);
			}
		}
		
		protected function onErrorRemoved(evt:ErrorEvent):void
		{
			var clauseNode:ClauseNode;
			var clauseConstraint:ConstraintEdge = evt.constraintError as ConstraintEdge;
			if(clauseConstraint)
			{
				if(clauseConstraint.lhs.id.indexOf('c') != -1)
				{
					clauseNode = nodeLayoutObjs[clauseConstraint.lhs.id];
				}
				else if(clauseConstraint.rhs.id.indexOf('c') != -1)
				{
					clauseNode = nodeLayoutObjs[clauseConstraint.rhs.id];
				}
				if(clauseNode)
					clauseNode.addError(false);
			}
		}
		
		protected static function getVisible(_layoutObj:Object, _defaultValue:Boolean = true):Boolean
		{
			var value:String = _layoutObj["visible"];
			if (!value) return _defaultValue;
			return XString.stringToBool(value);
		}

		public function getNodes():Dictionary
		{
			return nodeLayoutObjs;
		}
		
		public function getLevelTextInfo():TutorialManagerTextInfo
		{
			return tutorialManager ? tutorialManager.getTextInfo() : null;
		}
		
		public function getLevelToolTipsInfo():Vector.<TutorialManagerTextInfo>
		{
			return tutorialManager ? tutorialManager.getPersistentToolTipsInfo() : (new Vector.<TutorialManagerTextInfo>());
		}
		
		public function getMaxSelectableWidgets():int
		{
			var num:int = -1;
			if (tutorialManager) num = tutorialManager.getMaxSelectableWidgets();
			if (num > 0) return num;
			return 1000;
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
//			if (!m_hidingErrorText) {
//				for (var edgeId:String in m_gameEdgeDict) {
//					var gameEdge:GameEdgeContainer = m_gameEdgeDict[edgeId] as GameEdgeContainer;
//					gameEdge.hideErrorText();
//				}
//				m_hidingErrorText = true;
//			}
		}
		
		public function showErrorText():void
		{
//			if (m_hidingErrorText) {
//				for (var edgeId:String in m_gameEdgeDict) {
//					var gameEdge:GameEdgeContainer = m_gameEdgeDict[edgeId] as GameEdgeContainer;
//					gameEdge.showErrorText();
//				}
//				m_hidingErrorText = false;
//			}
		}
		
		/**
		 * Get next conflict: used for conflict scrolling
		 * @param	forward True to scroll forward, false to scroll backwards
		 * @return Conflict DisplayObject (if any exist)
		 */
		public function getNextConflictLocation(forward:Boolean):Point
		{
			var i:int = 0;
			var conflictIndex:int = m_currentConflictIndex + (forward ? 1 : -1);
			//trace("m_currentConflictIndex:", m_currentConflictIndex, " conflictIndex:", conflictIndex);
			var firstConflictLoc:Point;
			var lastConflictLoc:Point;
			for (var edgeId:String in levelGraph.unsatisfiedConstraintDict) {
				var edgeLayout:Edge = edgeLayoutObjs[edgeId];
				if (!edgeLayout) {
					//trace("Warning! getNextConflictLocation: Found edgeId with no layout: ", edgeId);
					continue;
				}
				var edgeNode:Node = edgeLayout.toNode;
				if (!edgeNode) {
					//trace("Warning! getNextConflictLocation: Found edge with no toNode: ", edgeNode);
					continue;
				}
				if (!edgeNode.isEditable && edgeLayout.fromNode) {
					edgeNode = edgeLayout.fromNode;
				}
				var conflictLoc:Point = edgeNode.centerPoint.clone();
				if (i == conflictIndex) {
					m_currentConflictIndex = i;
					return conflictLoc;
				} else if (i == 0) {
					firstConflictLoc = conflictLoc;
				} else if (!firstConflictLoc) {
					firstConflictLoc = conflictLoc;
				}
				i++;
				lastConflictLoc = conflictLoc;
			}
			if (lastConflictLoc && conflictIndex < 0) {
				m_currentConflictIndex = i - 1;
				return lastConflictLoc;
			}
			if (firstConflictLoc) {
				m_currentConflictIndex = 0;
				return firstConflictLoc;
			}
			return null;
		}
		
		//can't flatten errorContainer as particle system is unsupported display object
		public override function flatten():void
		{
			return; // uncomment when more testing performed
			// Active layers
			m_errorContainer.flatten();
			m_nodesContainer.flatten();
			m_edgesContainer.flatten();
			// Inactive layers
			m_errorInactiveContainer.flatten();
			m_nodesInactiveContainer.flatten();
			m_edgesInactiveContainer.flatten();
		}
		
		public override function unflatten():void
		{
			super.unflatten();
			// Active layers
			m_errorContainer.unflatten();
			m_nodesContainer.unflatten();
			m_edgesContainer.unflatten();
			// Inactive layers
			m_errorInactiveContainer.unflatten();
			m_nodesInactiveContainer.unflatten();
			m_edgesInactiveContainer.unflatten();
		}
		
		public function getPanZoomAllowed():Boolean
		{ 
			if (tutorialManager) return tutorialManager.getPanZoomAllowed();
			return true;
		}
		
		public function getVisibleBrushes():int
		{ 
			if (tutorialManager) 
				return tutorialManager.getVisibleBrushes();
			//all visible
			return 0xFFFFFF;
		}
		
		public function getAutoSolveAllowed():Boolean
		{ 
			if (tutorialManager) return tutorialManager.getAutoSolveAllowed();
			return true;
		}
		
		public static const SEGMENT_DELETION_ENABLED:Boolean = false;
		public function onDeletePressed():void
		{

		}
		
		
		public function get currentScore():int { return levelGraph.currentScore; }
		public function get bestScore():int { return m_bestScore; }
		public function get startingScore():int { return levelGraph.startingScore; }
		public function get prevScore():int { return levelGraph.prevScore; }
		public function get oldScore():int { return levelGraph.oldScore; }
		
		public function resetBestScore():void
		{
			m_bestScore = levelGraph.currentScore;
			m_levelBestScoreAssignmentsObj = XObject.clone(m_levelAssignmentsObj);
		}
		
		public function onScoreChange(recordBestScore:Boolean = false):void
		{
			if (recordBestScore && (levelGraph.currentScore > m_bestScore)) {
				m_bestScore = levelGraph.currentScore;
				//trace("New best score: " + m_bestScore);
				m_levelBestScoreAssignmentsObj = createAssignmentsObj();
				//don't update on loading
				if(levelGraph.oldScore != 0 && PlayerValidation.playerLoggedIn)
					dispatchEvent(new MenuEvent(MenuEvent.SUBMIT_LEVEL));
			}
			//if (levelGraph.prevScore != levelGraph.currentScore)
			dispatchEvent(new WidgetChangeEvent(WidgetChangeEvent.LEVEL_WIDGET_CHANGED, null, null, false, this, null));
		}
		
		public function unselectAll():void
		{
			for each(var node:Node in selectedNodes)
			{
				node.unselect();
			}
			selectedNodes = new Vector.<GridChild>();
			dispatchEvent(new SelectionEvent(SelectionEvent.NUM_SELECTED_NODES_CHANGED, null, null));
		}
		
		public function onUseSelectionPressed(choice:String):void
		{
			var assignmentIsWide:Boolean = false;
			if(choice == MenuEvent.MAKE_SELECTION_WIDE)
				assignmentIsWide = true;
			else if(choice == MenuEvent.MAKE_SELECTION_NARROW)
				assignmentIsWide = false;
			
			//need to update nodes first...
			var gridSquare:GridSquare;
			for each(gridSquare in gridSystemDict)
			{
				gridSquare.updateSelectedNodesAssignment(assignmentIsWide);
			}
			//...and then redraw edges based on those changes
			for each(gridSquare in gridSystemDict)
			{
				gridSquare.updateSelectedEdges();
			}
			//update score
			onWidgetChange();
			unselectAll();
		}
		
		protected var solverRunningTime:Number;
		public function solverTimerCallback(evt:TimerEvent):void
		{
			solveSelection(solverUpdate, solverDone);
		}
		
		public function solverLoopTimerCallback(evt:TimerEvent):void
		{
			for each(var node:Node in nodeLayoutObjs)
			{
				node.unused = true;
			}
			solveSelection(solverUpdate, solverDone);
		}
		
		public var loopcount:int = 0;
		public var looptimer:Timer;
		//this is a test robot. It will find a conflict, select neighboring nodes, solve that area, and repeat
		public function solveSelection(updateCallback:Function, doneCallback:Function, firstRun:Boolean = false):void
		{
			if(firstRun)
			{
				solverRunningTime = new Date().getTime();
			}
			//if caps lock is down, start repeated solving using 'random' selection
//			if(Keyboard.capsLock)
//			{
//				//loop through all nodes, finding ones with conflicts
//				for each(var node:Node in nodeLayoutObjs)
//				{
//					if(node.hasError() && node.unused)
//					{
//						node.unused = false;
//					//trace(node.id);
//						onGroupSelection(new SelectionEvent("foo", node));
//						solveSelection1(updateCallback, doneCallback);
//						unselectAll();
//						return;
//					}
//				}
//				
//				// if we make it this far start over
//				//trace("new loop", loopcount);
//				looptimer = new Timer(1000, 1);
//				looptimer.addEventListener(TimerEvent.TIMER, solverLoopTimerCallback);
//				looptimer.start();
//			}
//			else
				solveSelection1(updateCallback, doneCallback);
		}
		
		public function getEdgeContainer(edgeId:String):DisplayObject
		{
			var edge:Edge = edgeLayoutObjs[edgeId];
			return edge ? edge.skin : null;
		}
		
		public function getNode(nodeId:String):Node
		{
			var node:Node = nodeLayoutObjs[nodeId];
			return node;
		}
	
		public var updateCallback:Function;
		public var doneCallback:Function;
		private var constraintArray:Array;
		private var initvarsArray:Array;
		private var newSelectedVars:Vector.<Node>;
		private var newSelectedClauses:Dictionary;
		private var storedDirectEdgesDict:Dictionary;
		private var directNodeArray:Array;
		private var counter:int;
		public function solveSelection1(_updateCallback:Function, _doneCallback:Function):void
		{
			//figure out which edges have both start and end components selected (all included edges have both ends selected?)
			//assign connected components to component to edge constraint number dict
			//create three constraints for conflicts and weights
			//run the solver, passing in the callback function		
			updateCallback = _updateCallback;
			doneCallback = _doneCallback;
			
			nodeIDToConstraintsTwoWayMap = new Dictionary;
			var storedConstraints:Dictionary = new Dictionary;
			counter = 1;
			constraintArray = new Array;
			initvarsArray = new Array;
			directNodeArray = new Array;
			storedDirectEdgesDict = new Dictionary;
			//loop through each object, store selected variables for later use
			newSelectedVars = new Vector.<Node>;
			newSelectedClauses = new Dictionary;
			
			createConstraintsForClauses(); 

			findIsolatedSelectedVars(); //handle one-offs so something gets done in minimal cases
			
			fixEdgeVarValues(); //find nodes just off selection map, and fix their values so they don't change
	
			if(constraintArray.length > 0)
			{
				//generate initvars array
				for(var ii:int = 1;ii<counter;ii++)
				{
					var gameNode:Object = nodeIDToConstraintsTwoWayMap[ii];
					if(gameNode.isNarrow)
						initvarsArray.push(0);
					else
						initvarsArray.push(1);
				}

				//build in a delay to allow UI to change
				World.m_world.showSolverState(true);
				timer = new Timer(500,1);
				timer.addEventListener(TimerEvent.TIMER, solverStartCallback);
				timer.start();
			}
			else //just end
				doneCallback("");
		}
		
		private function createConstraintsForClauses():void
		{
			for each(var gridChild:GridChild in selectedNodes)
			{
				if((gridChild is Node) && (gridChild as Node).isClause)
				{
					newSelectedClauses[(gridChild as Node).id] = gridChild;
					var clauseArray:Array = new Array();
					clauseArray.push(CONFLICT_CONSTRAINT_VALUE);
					
					//find all variables connected to the constraint, and add them to the array
					for each(var gameEdgeID:String in gridChild.connectedEdgeIds)
					{
						var edge:Edge = World.m_world.active_level.edgeLayoutObjs[gameEdgeID];
						var fromNode:Node = edge.fromNode;
						
						storedDirectEdgesDict[gameEdgeID] = edge;
						
						var constraintID:int;
						if(nodeIDToConstraintsTwoWayMap[fromNode.id] == null)
						{
							nodeIDToConstraintsTwoWayMap[fromNode.id] = counter;
							nodeIDToConstraintsTwoWayMap[counter] = fromNode;
							constraintID = counter;
							counter++;
						}
						else
							constraintID = nodeIDToConstraintsTwoWayMap[fromNode.id];
						
						//if the constraint starts from the clause, it's a positive var, else it's negative.
						if(gameEdgeID.indexOf('c') == 0)
							clauseArray.push(constraintID);
						else
							clauseArray.push(-constraintID);
						
						directNodeArray.push(fromNode);
						
					}
					constraintArray.push(clauseArray);
				}
				else if((gridChild is Node) && (gridChild as Node).isClause == false)
				{
					newSelectedVars.push(gridChild as Node);
				}
			}
		}
		
		private function findIsolatedSelectedVars():void
		{
			//check for variables that have no selected attached clauses. If found, create a clause for each attached constraint
			//and clauses for the far ends to suggest they don't change
			for each(var selectedVar:Node in newSelectedVars)
			{
				var attachedSelected:Boolean = false;
				
				for each(var edgeID:String in selectedVar.connectedEdgeIds)
				{
					var edgeToCheck:Edge = World.m_world.active_level.edgeLayoutObjs[edgeID];
					var toNodeToCheck:Node = edgeToCheck.toNode;
					if(newSelectedClauses[toNodeToCheck.id])
					{
						attachedSelected = true;
						continue;
					}
				}
				
				if(attachedSelected == false)
				{
					for each(var unattachedEdgeID:String in selectedVar.connectedEdgeIds)
					{
						var unattachedEdge:Edge = World.m_world.active_level.edgeLayoutObjs[unattachedEdgeID];
						var toNode:Node = unattachedEdge.toNode;
						var clauseArray:Array = new Array();
						clauseArray.push(CONFLICT_CONSTRAINT_VALUE);
						for each(var gameEdgeID:String in toNode.connectedEdgeIds)
						{
							var constraintEdge:Edge = World.m_world.active_level.edgeLayoutObjs[gameEdgeID];
							var fromNode:Node = constraintEdge.fromNode;
							//directNodeArray.push(fromNode1);
							//directEdgeDict[gameEdgeID1] = edge3;
							
							var constraintID:int;
							if(nodeIDToConstraintsTwoWayMap[fromNode.id] == null)
							{
								nodeIDToConstraintsTwoWayMap[fromNode.id] = counter;
								nodeIDToConstraintsTwoWayMap[counter] = fromNode;
								constraintID = counter;
								counter++;
							}
							else
								constraintID = nodeIDToConstraintsTwoWayMap[fromNode.id];
							
							//if the constraint starts from the clause, it's a positive var, else it's negative.
							if(gameEdgeID.indexOf('c') == 0)
								clauseArray.push(constraintID);
							else
								clauseArray.push(-constraintID);
							
							if(fromNode != selectedVar)
							{
								//create a separate clause here for this one node, based on it's current size
								var nodeClauseArray:Array = new Array();
								nodeClauseArray.push(CONFLICT_CONSTRAINT_VALUE);
								
								if(fromNode.isNarrow)
									nodeClauseArray.push(-constraintID);
								else
									nodeClauseArray.push(constraintID);
								constraintArray.push(nodeClauseArray);
							}	
						}
						constraintArray.push(clauseArray);
					}
				}
			}
		}
		
		private function fixEdgeVarValues():void
		{
			//now, find all the other constraints associated with the directly connected variables,
			//add the nodes connected to those constraints as fixed values,
			//so the score doesn't go down.
			for each(var directNode:Node in directNodeArray)
			{
				for each(var conEdgeID:String in directNode.connectedEdgeIds)
				{
					//have we already dealt with this edge?
					if(storedDirectEdgesDict[conEdgeID])
						continue;
					
					var conEdge:Edge = World.m_world.active_level.edgeLayoutObjs[conEdgeID];
					storedDirectEdgesDict[conEdgeID] = conEdge;
					
					var nextLayerClause:Node = conEdge.toNode;
					
					//check to see if this clause is satisfied by the remaining connections, and if it is, ignore it
					var satisfied:Boolean = false;
					var usedEdgeArray:Array = new Array;
					for each(var nextLayerEdgeID:String in nextLayerClause.connectedEdgeIds)
					{				
						if(storedDirectEdgesDict[nextLayerEdgeID])
						{
							usedEdgeArray.push(nextLayerEdgeID);
							continue;
						}
						var nextLayerEdge:Edge = World.m_world.active_level.edgeLayoutObjs[nextLayerEdgeID];
						var nextLayerVar:Node = nextLayerEdge.fromNode;
						
						if(nextLayerEdgeID.indexOf('c') == 0 && !nextLayerVar.isNarrow)
						{
							satisfied = true;
							break;
						}
						else if(nextLayerVar.isNarrow)
						{
							satisfied = true;
							break;
						}
					}
					
					//follow these out one more layer
					if(!satisfied)
					{
						var clauseArray:Array = new Array();
						clauseArray.push(FIXED_CONSTRAINT_VALUE);
						
						for each(var edgeID:String in usedEdgeArray)
						{
							var nextLayerEdge1:Edge = World.m_world.active_level.edgeLayoutObjs[edgeID];
							var nextLayerVar1:Node = nextLayerEdge1.fromNode;
							var varArray:Array = new Array();
							varArray.push(FIXED_CONSTRAINT_VALUE);
							
							var nextLevelConstraintID:int;
							if(nodeIDToConstraintsTwoWayMap[nextLayerVar1.id] == null)
							{
								nodeIDToConstraintsTwoWayMap[nextLayerVar1.id] = counter;
								nodeIDToConstraintsTwoWayMap[counter] = nextLayerVar1;
								nextLevelConstraintID = counter;
								counter++;
							}
							else
								nextLevelConstraintID = nodeIDToConstraintsTwoWayMap[nextLayerVar1.id];
							
							if(edgeID.indexOf('c') == 0)
								clauseArray.push(nextLevelConstraintID);
							else
								clauseArray.push(-nextLevelConstraintID);
						}
						constraintArray.push(clauseArray);
					}
				}
			}
		}
		
		public function solverStartCallback(evt:TimerEvent):void
		{
			m_inSolver = true;
			MaxSatSolver.run_solver(constraintArray, initvarsArray, updateCallback, doneCallback);
			dispatchEvent(new starling.events.Event(MaxSatSolver.SOLVER_STARTED, true));
		}
		
		public function solverUpdate(vars:Array, unsat_weight:int):void
		{
			var someNodeUpdated:Boolean = false;
			//trace("update", unsat_weight);
			if(	m_inSolver == false) //got marked done early
				return;
			
			//trace(levelGraph.currentScore);
			for (var ii:int = 0; ii < vars.length; ++ ii) 
			{
				var node:Node = nodeIDToConstraintsTwoWayMap[ii+1];
				var nodeUpdated:Boolean = false;
				var constraintVar:ConstraintVar = node["graphVar"];
				var currentVal:Boolean = node.isNarrow;
				node.isNarrow = true;
				if(vars[ii] == 1)
					node.isNarrow = false;
				someNodeUpdated = someNodeUpdated || (currentVal != node.isNarrow);
				nodeUpdated = currentVal != node.isNarrow; 
				if(currentVal != node.isNarrow)
				{
					node.setDirty(true, true);
					if(constraintVar) 
						constraintVar.setProp(PropDictionary.PROP_NARROW, node.isNarrow);
					if (tutorialManager) tutorialManager.onWidgetChange(constraintVar.id, PropDictionary.PROP_NARROW, node.isNarrow, levelGraph);
				}
			}
			if(someNodeUpdated)
				onWidgetChange();
		}
		
		public var count:int = 0;
		public var timer:Timer;
		public function solverDone(errMsg:String):void
		{
			//trace(errMsg);
			m_inSolver = false;
			MaxSatSolver.stop_solver();
			levelGraph.updateScore();
			onScoreChange(true);
			System.gc();
			dispatchEvent(new starling.events.Event(MaxSatSolver.SOLVER_STOPPED, true));
			//trace("time elapsed", new Date().getTime()-solverRunningTime);
			//trace("num conflicts", MiniMap.numConflicts);
			//do it again?
			if(Keyboard.capsLock && count < 3000)
			{
				count++;
				//trace("count", count);
				timer = new Timer(1000, 1);
				timer.addEventListener(TimerEvent.TIMER, solverTimerCallback);
				timer.start();
			}
		}
		
		public function onViewSpaceChanged(event:MiniMapEvent):void
		{
			
		}
		
		public function adjustSize(newWidth:Number, newHeight:Number):void
		{
			
		}
		
		public function selectNodes(localPt:Point, dX:Number, dY:Number):void
		{
			var leftGridNumber:int = Math.floor((localPt.x - dX) / GRID_SIZE);
			var rightGridNumber:int = Math.floor((localPt.x + dX) / GRID_SIZE);
			var topGridNumber:int = Math.floor((localPt.y - dY) / GRID_SIZE);
			var bottomGridNumber:int = Math.floor((localPt.y + dY) / GRID_SIZE);
			var selectionChanged:Boolean = false;
			for (var i:int = leftGridNumber; i <= rightGridNumber; i++)
			{
				for(var j:int = topGridNumber; j <= bottomGridNumber; j++)
				{
					var gridName:String = i + "_" + j;
					//trace("gridName: ", gridName);
					if(gridSystemDict[gridName] is GridSquare)
					{
						var thisGrid:GridSquare = gridSystemDict[gridName] as GridSquare;
						//thisGrid.showDebugQuad();
						var thisGridSelectionChanged:Boolean = thisGrid.handlePaintSelection(localPt, dX * dX, selectedNodes, getMaxSelectableWidgets());
						selectionChanged = (selectionChanged || thisGridSelectionChanged);
						if (selectedNodes.length >= getMaxSelectableWidgets()) break;
					}
				}
			}
			//trace("Paint select changed:" + selectionChanged);
			if (selectionChanged) dispatchEvent(new SelectionEvent(SelectionEvent.NUM_SELECTED_NODES_CHANGED, null, null));
		}
	}
}