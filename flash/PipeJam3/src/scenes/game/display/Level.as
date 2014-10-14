package scenes.game.display
{
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.events.TimerEvent;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.system.System;
	import flash.utils.ByteArray;
	import flash.utils.Dictionary;
	import flash.utils.Timer;
	import starling.textures.TextureAtlas;
	
	import assets.AssetInterface;
	
	import constraints.Constraint;
	import constraints.ConstraintGraph;
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
	
	import graph.PropDictionary;
	
	import networking.GameFileHandler;
	import networking.PlayerValidation;
	
	import org.osmf.events.TimeEvent;
	
	import scenes.BaseComponent;
	import scenes.game.PipeJamGameScene;
	
	import starling.display.BlendMode;
	import starling.display.DisplayObject;
	import starling.display.Image;
	import starling.display.Quad;
	import starling.display.Shape;
	import starling.display.Sprite;
	import starling.events.EnterFrameEvent;
	import starling.events.Event;
	import starling.events.Touch;
	import starling.events.TouchEvent;
	import starling.events.TouchPhase;
	import starling.filters.ColorMatrixFilter;
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
		
		public var selectedNodes:Dictionary;
		/** used by solver to keep track of which nodes map to which constraint values, and visa versa */
		protected var nodeIDToConstraintsTwoWayMap:Dictionary;
		
		protected var marqueeRect:Shape = new Shape();
		protected var m_marqueeChanged:Boolean = false;
		
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
		
		protected var m_groupNodes:Dictionary = new Dictionary();
		
		protected var m_hidingErrorText:Boolean = false;
		
		protected var m_nodesInactiveContainer:Sprite = new Sprite();
		protected var m_errorInactiveContainer:Sprite = new Sprite();
		protected var m_edgesInactiveContainer:Sprite = new Sprite();
		protected var m_plugsInactiveContainer:Sprite = new Sprite();
		public var inactiveLayer:Sprite = new Sprite();
		
		protected var m_nodesContainer:Sprite = new Sprite();
		protected var m_errorContainer:Sprite = new Sprite();
		protected var m_edgesContainer:Sprite = new Sprite();
		protected var m_plugsContainer:Sprite = new Sprite();
		protected var m_groupsContainer:Sprite = new Sprite();
		
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
		static public var NUM_NODES_TO_SELECT:int = 300;
		
		static public var PAINT_RADIUS:int = 60;
		
		static public var CONFLICT_CONSTRAINT_VALUE:Number = 100.0;
		static public var NODE_SIZE_CONSTRAINT_VALUE:Number = 1.0;
		
		public var currentGridDict:Dictionary;
		
		protected var currentSelectionProcessCount:int;
		
		
		/** Tracks total distance components have been dragged since last visibile calculation */
		public var totalMoveDist:Point = new Point();
		
		// The following is used for conflict scrolling purposes: (tracking list of current conflicts)
		protected var m_currentConflictIndex:int = 0;
		
		public var m_inSolver:Boolean = false;
		
		protected var m_paintBrush:Sprite = new Sprite();
		
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
			m_levelQID = _levelLayoutObj["qid"];
			m_levelBestScoreAssignmentsObj = _levelAssignmentsObj;// XObject.clone(_levelAssignmentsObj);
			m_levelOriginalAssignmentsObj = _levelAssignmentsObj;// XObject.clone(_levelAssignmentsObj);
			m_levelAssignmentsObj = _levelAssignmentsObj;// XObject.clone(_levelAssignmentsObj);
			
			m_tutorialTag = m_levelLayoutObj["tutorial"];
			if (m_tutorialTag && (m_tutorialTag.length > 0)) {
				tutorialManager = new TutorialLevelManager(m_tutorialTag);
				m_layoutFixed = tutorialManager.getLayoutFixed();
			}
			
			m_targetScore = int.MAX_VALUE;
			if ((m_levelAssignmentsObj["target_score"] != undefined) && !isNaN(int(m_levelAssignmentsObj["target_score"]))) {
				m_targetScore = int(m_levelAssignmentsObj["target_score"]);
			}
			targetScoreReached = false;
			addEventListener(starling.events.Event.ADDED_TO_STAGE, onAddedToStage); 
			
			// Create paintbrush: TODO make higher res circle
			var atlas:TextureAtlas = AssetInterface.getTextureAtlas("Game", "PipeJamSpriteSheetPNG", "PipeJamSpriteSheetXML");
			var circleTexture:Texture = atlas.getTexture(AssetInterface.PipeJamSubTexture_PaintCircle);
			var circleImage:Image = new Image(circleTexture);
			circleImage.width = circleImage.height = 2 * PAINT_RADIUS;
			circleImage.x = -0.5 * circleImage.width;
			circleImage.y = -0.5 * circleImage.height;
			circleImage.alpha = 0.7;
			m_paintBrush.addChild(circleImage);
			
			gridSystemDict = new Dictionary;
			currentGridDict = new Dictionary;
			NodeSkin.InitializeSkins();
			selectedNodes = new Dictionary;
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
					tutorialManager.onWidgetChange(graphVar.id, PropDictionary.PROP_NARROW, !assignmentIsWide);
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
			if (m_groupsContainer == null) m_groupsContainer = new Sprite();
			
			//m_nodesContainer.filter = BlurFilter.createDropShadow(4.0, 0.78, 0x0, 0.85, 2, 1); //only works up to 2048px
			addChild(m_groupsContainer);
			addChild(m_edgesContainer);
			addChild(m_nodesContainer);
			addChild(m_errorContainer);
			addChild(m_plugsContainer);
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
			if (m_marqueeChanged) {
				m_marqueeChanged = false;
				if(marqueeRect.height > 0 && marqueeRect.width > 0)
				{
					for each(gridSquare in currentGridDict)
					{
						gridSquare.handleMarqueeSelection(marqueeRect.bounds, selectedNodes);
					}
				}
			} else {
				//clean up the old dictionary disposing of what's left
				for each(gridSquare in currentGridDict)
				{
					gridSquare.draw();
				}
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
					if(gridSystemDict[gridName] != null)
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
		
		public function handleScaleChange(newScaleX:Number, newScaleY:Number):void
		{
			var gridSquare:GridSquare;
			if (newScaleX < GROUP_SCALE_THRESHOLD || newScaleY < GROUP_SCALE_THRESHOLD) {
				if (!m_groupsShown) {
					for each (gridSquare in currentGridDict)
					{
						gridSquare.showGroups();
					}
					draw();
				}
			} else {
				if (m_groupsShown) {
					for each (gridSquare in currentGridDict)
					{
						gridSquare.hideGroups();
					}
					draw();
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
			if (isGroup) {
				if (groupLayoutObjs.hasOwnProperty(gridChildId)) {
					var prevNodeGroup:NodeGroup = groupLayoutObjs[gridChildId] as NodeGroup;
					prevNodeGroup.parentGrid.removeGridChild(prevNodeGroup);
				}
				var groupBB:Rectangle = new Rectangle(layoutX, layoutY, layoutWidth, layoutHeight);
				gridChild = new NodeGroup(gridChildLayout, gridChildId, groupBB, grid, m_groupNodes[gridChildId]);
				groupLayoutObjs[gridChildId] = gridChild;
			} else {
				var graphVar:ConstraintVar = levelGraph.variableDict[gridChildId] as ConstraintVar;
				if (graphVar == null) {
					trace("Warning: layout var found with no corresponding contraints var:" + gridChildId);
					return null;
				}
				if (nodeLayoutObjs.hasOwnProperty(gridChildId)) {
					var prevNode:Node = nodeLayoutObjs[gridChildId] as Node;
					prevNode.parentGrid.removeGridChild(prevNode);
				}
				var nodeBB:Rectangle = new Rectangle(layoutX - GridSquare.SKIN_DIAMETER * .5, layoutY - GridSquare.SKIN_DIAMETER * .5, GridSquare.SKIN_DIAMETER, GridSquare.SKIN_DIAMETER);
				gridChild = new Node(gridChildLayout, gridChildId, nodeBB, graphVar, grid);
				nodeLayoutObjs[gridChildId] = gridChild;
				if (graphVar && graphVar.associatedGroupId) {
					if (!m_groupNodes.hasOwnProperty(graphVar.associatedGroupId)) m_groupNodes[graphVar.associatedGroupId] = new Dictionary();
					m_groupNodes[graphVar.associatedGroupId][gridChildId] = gridChild;
				}
			}
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
				var edgeLayoutObj:Object = new Object;
				edgeLayoutObj["id"] = constraintId;
				var result:Object = constraintId.split(" ");
				if (result == null) throw new Error("Invalid constraint layout string found: " + constraintId);
				if (result.length != 3) throw new Error("Invalid constraint layout string found: " + constraintId);
				var graphConstraint:Constraint = levelGraph.constraintsDict[constraintId] as Constraint;
				if (graphConstraint == null) throw new Error("No graph constraint found for constraint layout: " + constraintId);
				edgeLayoutObj["constraint"] = graphConstraint;
				edgeLayoutObj["from_var_id"] = result[0];
				nodeLayoutObjs[result[0]]["connectedEdgeIds"].push(constraintId);
				edgeLayoutObj["to_var_id"] = result[2];
				nodeLayoutObjs[result[2]]["connectedEdgeIds"].push(constraintId);
				
				edgeLayoutObjs[constraintId] = edgeLayoutObj;
				n++;
			}
			//trace("edge count = " + n);
			m_boundingBox = new Rectangle(minX, minY, maxX - minX, maxY - minY);
		}
		
		public function addChildToGroupLevel(child:Sprite):void
		{
			m_groupsContainer.addChild(child);
		}
		
		public function addChildToNodeLevel(child:Sprite):void
		{
			m_nodesContainer.addChild(child);
			//uncomment to add quad as background to each gridSquare for debugging
			//			var color:int = Math.round(0xffffff * Math.random());
			//			var q:Quad = new Quad(gridSize, gridSize, color);
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
				var node:Node = nodeLayoutObjs[nodeId];
				var constraintVar:ConstraintVar = levelGraph.variableDict[nodeId];
				if (constraintVar.constant) continue;
				if (!assignmentsObj["assignments"].hasOwnProperty(constraintVar.formattedId)) assignmentsObj["assignments"][constraintVar.formattedId] = { };
				assignmentsObj["assignments"][constraintVar.formattedId][ConstraintGraph.TYPE_VALUE] = constraintVar.getValue().verboseStrVal;
				var keyfors:Array = new Array();
				for (var i:int = 0; i < constraintVar.keyforVals.length; i++) keyfors.push(constraintVar.keyforVals[i]);
				if (keyfors.length > 0) assignmentsObj["assignments"][constraintVar.formattedId][ConstraintGraph.KEYFOR_VALUES] = keyfors;
				
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
			if (m_groupsContainer) {
				while (m_groupsContainer.numChildren > 0) m_groupsContainer.getChildAt(0).removeFromParent(true);
				m_groupsContainer.removeFromParent(true);
			}
			if (m_plugsContainer) {
				while (m_plugsContainer.numChildren > 0) m_plugsContainer.getChildAt(0).removeFromParent(true);
				m_plugsContainer.removeFromParent(true);
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
		protected function onWidgetChange(evt:VarChangeEvent = null):void
		{
			//trace("Level: onWidgetChange");
			if (evt && evt.graphVar) {
				levelGraph.updateScore(evt.graphVar.id, evt.prop, evt.newValue);
				//evt.graphVar.setProp(evt.prop, evt.newValue);
				//levelGraph.updateScore();
				if (tutorialManager) tutorialManager.onWidgetChange(evt.graphVar.id, evt.prop, evt.newValue);
				dispatchEvent(new WidgetChangeEvent(WidgetChangeEvent.LEVEL_WIDGET_CHANGED, evt.graphVar, evt.prop, evt.newValue, this, evt.pt));
				//save incremental changes so we can update if user quits and restarts
				if(PipeJam3.m_savedCurrentLevel.data.assignmentUpdates) //should only be null when doing assignments from assignments file
				{
					var constraintType:String = evt.newValue ? ConstraintValue.VERBOSE_TYPE_0 : ConstraintValue.VERBOSE_TYPE_1;
					PipeJam3.m_savedCurrentLevel.data.assignmentUpdates[evt.graphVar.id] = constraintType;
				}
				dispatchEvent(new WidgetChangeEvent(WidgetChangeEvent.LEVEL_WIDGET_CHANGED, null, null, false, this, null));
				if (evt.graphVar.associatedGroupId) {
					var nodeGroup:NodeGroup = groupLayoutObjs[evt.graphVar.associatedGroupId];
					if (nodeGroup) nodeGroup.calculateNodeInfo(); // recalc whether group is wide or narrow and hasError
				}
			} else {
				levelGraph.updateScore();
				dispatchEvent(new WidgetChangeEvent(WidgetChangeEvent.LEVEL_WIDGET_CHANGED, null, null, false, this, null));
			}
			onScoreChange(true);
		}
		
		protected var m_propertyMode:String = PropDictionary.PROP_NARROW;
		public function onPropertyModeChange(evt:PropertyModeChangeEvent):void
		{
		/*	var i:int, nodeId:String, gameNode:GameNode, edgeId:String, gameEdge:GameEdgeContainer;
			if (evt.prop == PropDictionary.PROP_NARROW) {
				m_propertyMode = PropDictionary.PROP_NARROW;
				for (edgeId in m_gameEdgeDict) {
					gameEdge = m_gameEdgeDict[edgeId] as GameEdgeContainer;
					gameEdge.setPropertyMode(m_propertyMode);
					activate(gameEdge);
				}
				for (nodeId in m_gameNodeDict) {
					gameNode = m_gameNodeDict[nodeId] as GameNode;
					gameNode.setPropertyMode(m_propertyMode);
					activate(gameNode);
				}
			} else {
				m_propertyMode = evt.prop;
				var edgesToActivate:Vector.<GameEdgeContainer> = new Vector.<GameEdgeContainer>();
				for (nodeId in m_gameNodeDict) {
					gameNode = m_gameNodeDict[nodeId] as GameNode;
					// TODO: broken
					//if (m_nodeList[i] is GameMapGetJoint) {
						//var mapget:GameMapGetJoint = m_nodeList[i] as GameMapGetJoint;
						//if (mapget.getNode.getMapProperty() == evt.prop) {
							//m_nodeList[i].setPropertyMode(m_propertyMode);
							//edgesToActivate = edgesToActivate.concat(mapget.getUpstreamEdgeContainers());
							//continue;
						//}
					//}
					gameNode.setPropertyMode(m_propertyMode);
					deactivate(gameNode);
				}
				var gameNodesToActivate:Vector.<GameNode> = new Vector.<GameNode>();
				for (edgeId in m_gameEdgeDict) {
					gameEdge = m_gameEdgeDict[edgeId] as GameEdgeContainer;
					gameEdge.setPropertyMode(m_propertyMode);
					if (edgesToActivate.indexOf(gameEdge) > -1) {
						gameNodesToActivate.push(gameEdge.m_fromNode);
					} else {
						deactivate(gameEdge);
					}
				}
				for (nodeId in m_gameNodeDict) {
					gameNode = m_gameNodeDict[nodeId] as GameNode;	
					gameNode.setPropertyMode(m_propertyMode);
					if (gameNodesToActivate.indexOf(gameNode) == -1) {
						deactivate(gameNode);
					}
				}
			}
			flatten();*/
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
			if (evt.component is NodeGroup) {
				// Select all nodes in group
				var nodeGroup:NodeGroup = evt.component as NodeGroup;
				
			} else if (evt.component is Node) {
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
			node.select(selectedNodes);
			
			//include locked nodes, but not their children
			if(!node.isLocked)
				for each(var gameEdgeID:String in node.connectedEdgeIds)
				{
					//need to check if the other end is on screen, and if it is, pass this edge off to that node
					var edgeObj:Object = edgeLayoutObjs[gameEdgeID];
					var toNodeID:String = edgeObj["to_var_id"];
					var toNodeObj:Object = nodeLayoutObjs[toNodeID];
					var fromNodeID:String = edgeObj["from_var_id"];
					var fromNodeObj:Object = nodeLayoutObjs[fromNodeID];
					
					var otherNode:Object = toNodeObj;
					if(toNodeObj == node)
						otherNode = fromNodeObj;
					if(selectedNodes[otherNode.id] == null)
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
				//zzz
			}
		}
		
		protected function onErrorAdded(evt:ErrorEvent):void
		{
			
		}
		
		protected function onErrorRemoved(evt:ErrorEvent):void
		{
			
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
				var edgeLayout:Object = edgeLayoutObjs[edgeId];
				if (!edgeLayout) {
					trace("Warning! getNextConflictLocation: Found edgeId with no layout: ", edgeId);
					continue;
				}
				var edgeNode:Node = nodeLayoutObjs[edgeLayout["to_var_id"]];
				if (!edgeNode) {
					trace("Warning! getNextConflictLocation: Found edge with no toNode: ", edgeNode);
					continue;
				}
				if (!edgeNode.isEditable && nodeLayoutObjs[edgeLayout["from_var_id"]]) {
					edgeNode = nodeLayoutObjs[edgeLayout["from_var_id"]];
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
			if (levelGraph.prevScore != levelGraph.currentScore)
				dispatchEvent(new WidgetChangeEvent(WidgetChangeEvent.LEVEL_WIDGET_CHANGED, null, null, false, this, null));
		}
		
		public function handleMarquee(startingPoint:Point, currentPoint:Point):void
		{
			var gridSquare:GridSquare;
			if(startingPoint != null)
			{
				marqueeRect.removeChildren();
				//scale line size
				var lineSize:Number = 1/(Math.max(parent.scaleX, parent.scaleY));
				marqueeRect.graphics.lineStyle(lineSize, 0x000000);
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
				m_marqueeChanged = true;
			}
			else
			{		
				removeChild(marqueeRect);	
				for each(gridSquare in currentGridDict)
				{
					gridSquare.visited = false;
				}
			}
		}
		
		public function beginPaint():void
		{
			//trace("beginPaint()");
			unselectAll();
		}
		
		public function handlePaint(globPt:Point):void
		{
			//trace("handlePaint(", globPt, ")");
			if (!parent) return;
			m_paintBrush.scaleX = 1.0 / parent.scaleX / scaleX;
			m_paintBrush.scaleY = 1.0 / parent.scaleY / scaleY;
			var localPt:Point = this.globalToLocal(globPt);
			m_paintBrush.x = localPt.x;
			m_paintBrush.y = localPt.y;
			addChild(m_paintBrush);
			const dX:Number = PAINT_RADIUS * m_paintBrush.scaleX;
			const dY:Number = PAINT_RADIUS * m_paintBrush.scaleY;
			var leftGridNumber:int = Math.floor((localPt.x - dX) / GRID_SIZE);
			var rightGridNumber:int = Math.floor((localPt.x + dX) / GRID_SIZE);
			var topGridNumber:int = Math.floor((localPt.y - dY) / GRID_SIZE);
			var bottomGridNumber:int = Math.floor((localPt.y + dY) / GRID_SIZE);
			
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
						thisGrid.handlePaintSelection(localPt, dX * dX, selectedNodes);
					}
				}
			}
		}
		
		public function endPaint():void
		{
			//trace("endPaint()");
			m_paintBrush.removeFromParent();
		}
		
		public function unselectAll(addEventToLast:Boolean = false):void
		{
			for each(var node:Node in selectedNodes)
			{
				node.unselect(selectedNodes);
			}
			
			selectedNodes = new Dictionary; 
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
		}
		
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
		
		//this is a test robot. It will find a conflict, select neighboring nodes, and then solve that area, and repeat
		public function solveSelection1(updateCallback:Function, doneCallback:Function):void
		{
			//loop through all nodes, finding ones with conflicts
			for each(var node:Node in nodeLayoutObjs)
			{
				if(node.hasError() && node.unused)
				{
					node.unused = false;
					//trace(node.id);
					onGroupSelection(new SelectionEvent("foo", node));
					solveSelection1(updateCallback, doneCallback);
					unselectAll();
					return;
				}
			}
			
			// if we make it this far start over
			//trace("new loop", loopcount);
			looptimer = new Timer(1000, 1);
			looptimer.addEventListener(TimerEvent.TIMER, solverLoopTimerCallback);
			looptimer.start();
		}
		
		public function getEdgeContainer(edgeId:String):DisplayObject
		{
			var edgeObj:Object = edgeLayoutObjs[edgeId];
			return edgeObj ? edgeObj.edgeSprite : null;
		}
		
		public function getNode(nodeId:String):Node
		{
			var node:Node = nodeLayoutObjs[nodeId];
			return node;
		}

		public var constraintArray:Array;
		public var initvarsArray:Array;
		public var updateCallback:Function;
		public var doneCallback:Function;
		public function solveSelection(_updateCallback:Function, _doneCallback:Function):void
		{
			//figure out which edges have both start and end components selected (all included edges have both ends selected?)
			//assign connected components to component to edge constraint number dict
			//create three constraints for conflicts and weights
			//run the solver, passing in the callback function		
			updateCallback = _updateCallback;
			doneCallback = _doneCallback;
			
			nodeIDToConstraintsTwoWayMap = new Dictionary;
			var storedConstraints:Dictionary = new Dictionary;
			var counter:int = 1;
			constraintArray = new Array;
			initvarsArray = new Array;
			//loop through each object
			for each(var gridChild:GridChild in selectedNodes)
			{
				//loop through each edge, checking far end for existence in dict
				for each(var gameEdgeID:String in gridChild.connectedEdgeIds)
				{
					var constraint1Value:int = -1;
					var constraint2Value:int = -1;
					// TODO: Circular dependency
					var edgeObj:Object = World.m_world.active_level.edgeLayoutObjs[gameEdgeID];
					var toNodeID:String = edgeObj["to_var_id"];
					var toNode:Object = World.m_world.active_level.nodeLayoutObjs[toNodeID];
					var fromNodeID:String = edgeObj["from_var_id"];
					var fromNode:Object = World.m_world.active_level.nodeLayoutObjs[fromNodeID];
					
					//figure out which is the other node
					var nodeToCheck:Object = toNode;
					if(toNode == gridChild)
						nodeToCheck = fromNode;
					
					//if far end of this edge isn't in selected nodes, then add a constraint acting like it's fixed
					//this will help the solver return only better scores.
					if(selectedNodes[nodeToCheck.id] == null)
					{
						//deal with constraints to/from unselected nodes
						if(nodeToCheck == fromNode)
						{
							if(toNode.isEditable)
							{
								if(nodeIDToConstraintsTwoWayMap[toNode.id] == null)
								{
									nodeIDToConstraintsTwoWayMap[toNode.id] = counter;
									nodeIDToConstraintsTwoWayMap[counter] = toNode;
									constraint1Value = counter;
									counter++;
								}
								else
									constraint1Value = nodeIDToConstraintsTwoWayMap[toNode.id];
								
								if(!fromNode.isNarrow)
								{
									if(toNode.isEditable && !toNode.isLocked)
									{
	
										
										constraintArray.push(new Array(CONFLICT_CONSTRAINT_VALUE, constraint1Value));
									}
								}
							}
						}
						else
						{
							if(fromNode.isEditable)
							{
								if(nodeIDToConstraintsTwoWayMap[fromNode.id] == null)
								{
									nodeIDToConstraintsTwoWayMap[fromNode.id] = counter;
									nodeIDToConstraintsTwoWayMap[counter] = fromNode;
									constraint1Value = counter;
									counter++;
								}
								else
									constraint1Value = nodeIDToConstraintsTwoWayMap[fromNode.id];
							
								if(toNode.isNarrow)
								{
	
									
									if(fromNode.isEditable && !fromNode.isLocked)
									{
	
										
										constraintArray.push(new Array(CONFLICT_CONSTRAINT_VALUE, -constraint1Value));
									}
								}
							}
						}
					}
					else
					{
						//found an edge with both end nodes selected
						if(fromNode.isEditable && !fromNode.isLocked)
						{
							if(nodeIDToConstraintsTwoWayMap[fromNode.id] == null)
							{
								nodeIDToConstraintsTwoWayMap[fromNode.id] = counter;
								nodeIDToConstraintsTwoWayMap[counter] = fromNode;
								constraint1Value = counter;
								counter++;
							}
							else
								constraint1Value = nodeIDToConstraintsTwoWayMap[fromNode.id];
						} 
						
						if(toNode.isEditable && !toNode.isLocked)
						{
							if(nodeIDToConstraintsTwoWayMap[toNode.id] == null)
							{
								nodeIDToConstraintsTwoWayMap[toNode.id] = counter;
								nodeIDToConstraintsTwoWayMap[counter] = toNode;
								constraint2Value = counter;
								counter++;
							}
							else
								constraint2Value = nodeIDToConstraintsTwoWayMap[toNode.id];
						}
						
						var constraint:String = constraint1Value+"_"+constraint2Value; 
												
						//check for duplicates						
						if(storedConstraints[constraint] == null)
						{
							storedConstraints[constraint] = constraint;
							if(fromNode.isEditable && toNode.isEditable && !fromNode.isLocked && !toNode.isLocked)
							{
								constraintArray.push(new Array(CONFLICT_CONSTRAINT_VALUE, -constraint1Value, constraint2Value));
							}
							else if(fromNode.isEditable && !fromNode.isLocked && (!toNode.isEditable || toNode.isLocked))
							{
								if(toNode.isNarrow)
									constraintArray.push(new Array(CONFLICT_CONSTRAINT_VALUE, -constraint1Value));
							}
							else if((!fromNode.isEditable || fromNode.isLocked) && toNode.isEditable && !toNode.isLocked)
							{
								if(!fromNode.isNarrow)
									constraintArray.push(new Array(CONFLICT_CONSTRAINT_VALUE, constraint2Value));
							}
						}
					}
					
					//do this once for all selected nodes
					if(toNode.isEditable && !toNode.isLocked && constraint1Value != -1)
					{
						if(storedConstraints[constraint1Value] == null)
						{
							constraintArray.push(new Array(NODE_SIZE_CONSTRAINT_VALUE, constraint1Value));
							storedConstraints[constraint1Value] = toNode;
						}
					}
					if(fromNode.isEditable && !fromNode.isLocked && constraint2Value != -1)
					{
						if(storedConstraints[constraint2Value] == null)
						{
							constraintArray.push(new Array(NODE_SIZE_CONSTRAINT_VALUE, constraint2Value));
							storedConstraints[constraint2Value] = fromNode;
						}
					}
				}
			}
			
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
		}
		
		public function solverStartCallback(evt:TimerEvent):void
		{
			m_inSolver = true;
			MaxSatSolver.run_solver(constraintArray, initvarsArray, updateCallback, doneCallback);
		}
		
		public function solverUpdate(vars:Array, unsat_weight:int):void
		{
			var nodeUpdated:Boolean = false;
			//trace("update", unsat_weight);
			if(	m_inSolver == false) //got marked done early
				return;
			
			//trace(levelGraph.currentScore);
			for (var ii:int = 0; ii < vars.length; ++ ii) 
			{
				var node:Node = nodeIDToConstraintsTwoWayMap[ii+1];
				if(!node.isLocked)
				{
					var constraintVar:ConstraintVar = node["graphVar"];
					var parentGridSquare:GridSquare = node.parentGrid;
					node.setDirty(true);
					node.isNarrow = true;
					if(vars[ii] == 1)
						node.isNarrow = false;
					if(constraintVar) 
						constraintVar.setProp(PropDictionary.PROP_NARROW, node.isNarrow);
					nodeUpdated = true; 
				}
			}
			if(nodeUpdated)
				onWidgetChange();
		}
		
		public var count:int = 3000;
		public var timer:Timer;
		public function solverDone(errMsg:String):void
		{
			//trace(errMsg);
			m_inSolver = false;
			MaxSatSolver.stop_solver();
			levelGraph.updateScore();
			onScoreChange(true);
			System.gc();
			
			//reset to score before solver ran, which might be current score
		//	loadBestScoringConfiguration();
			
			//do it again
			if(count < 3000)
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
		
		public function lockSelection():void
		{
			for each(var node:Node in selectedNodes)
			{
				node.lock();
			}
			
		}
		
		public function unlockSelection():void
		{
			for each(var node:Node in selectedNodes)
			{
				node.unlock();
			}
			
		}
	}
}