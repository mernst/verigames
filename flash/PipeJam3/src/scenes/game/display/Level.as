package scenes.game.display
{
	import flash.events.Event;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.ByteArray;
	import flash.utils.Dictionary;
	
	import assets.AssetInterface;
	
	import constraints.Constraint;
	import constraints.ConstraintGraph;
	import constraints.ConstraintValue;
	import constraints.ConstraintVar;
	import constraints.events.ErrorEvent;
	import constraints.events.VarChangeEvent;
	
	import deng.fzip.FZip;
	
	import events.GameComponentEvent;
	import events.GroupSelectionEvent;
	import events.MenuEvent;
	import events.MiniMapEvent;
	import events.PropertyModeChangeEvent;
	import events.UndoEvent;
	import events.WidgetChangeEvent;
	
	import graph.PropDictionary;
	
	import networking.GameFileHandler;
	
	import scenes.BaseComponent;
	import scenes.game.PipeJamGameScene;
	
	import starling.display.BlendMode;
	import starling.display.DisplayObject;
	import starling.display.Image;
	import starling.display.Shape;
	import starling.display.Sprite;
	import starling.events.EnterFrameEvent;
	import starling.events.Event;
	import starling.events.Touch;
	import starling.events.TouchEvent;
	import starling.events.TouchPhase;
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
		
		protected var selectedComponents:Vector.<GameComponent>;
		/** used by solver to keep track of which nodes map to which constraint values, and visa versa */
		protected var nodeIDToConstraintsTwoWayMap:Dictionary;
		
		protected var marqueeRect:Shape = new Shape();
		
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
		protected var boxDictionary:Dictionary;
		protected var edgeContainerDictionary:Dictionary;
		
		public var nodeLayoutObjs:Dictionary = new Dictionary();
		public var edgeLayoutObjs:Dictionary = new Dictionary();
		
		protected var m_gameNodeDict:Dictionary = new Dictionary();
		protected var m_gameEdgeDict:Dictionary = new Dictionary();
		
//		protected var m_nodeList:Vector.<GameNode2>;
//		public var m_edgeList:Vector.<GameEdge>;
		
		protected var m_hidingErrorText:Boolean = false;
//		protected var m_segmentHovered:GameEdgeSegment;
		public var errorConstraintDict:Dictionary = new Dictionary();
		
		protected var m_nodesInactiveContainer:Sprite = new Sprite();
		protected var m_errorInactiveContainer:Sprite = new Sprite();
		protected var m_edgesInactiveContainer:Sprite = new Sprite();
		protected var m_plugsInactiveContainer:Sprite = new Sprite();
		public var inactiveLayer:Sprite = new Sprite();
		
		protected var m_nodesContainer:Sprite = new Sprite();
		protected var m_errorContainer:Sprite = new Sprite();
		protected var m_edgesContainer:Sprite = new Sprite();
		protected var m_plugsContainer:Sprite = new Sprite();
		
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
		
		static public var gridSize:int = 500;
		
		public var currentGridDict:Dictionary;
		public var selectedNodeConstraintDict:Dictionary;

		
		/** Tracks total distance components have been dragged since last visibile calculation */
		public var totalMoveDist:Point = new Point();
		
		// The following are used for conflict scrolling purposes: (tracking list of current conflicts)
		protected var m_currentConflictIndex:int = -1;
//		protected var m_levelConflictEdges:Vector.<GameEdgeContainer> = new Vector.<GameEdgeContainer>();
		protected var m_levelConflictEdgeDict:Dictionary = new Dictionary();
		protected var m_conflictEdgesDirty:Boolean = true;
		
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
			addEventListener(starling.events.Event.REMOVED_FROM_STAGE, onRemovedFromStage); 
			
			gridSystemDict = new Dictionary;
			currentGridDict = new Dictionary;
			NodeSkin.InitializeSkins();
			
			selectedNodeConstraintDict = new Dictionary;
			
			addEventListener(EnterFrameEvent.ENTER_FRAME, onEnterFrame);
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
			removeEventListener(starling.events.Event.ADDED_TO_STAGE, onAddedToStage);
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
			
			dispatchEvent(new starling.events.Event(Game.STOP_BUSY_ANIMATION,true));
		}
		
		public function initialize():void
		{
			if (initialized) return;
			trace("Level.initialize()...");
			var time1:Number = new Date().getTime();
			refreshLevelErrors();
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
			addChild(m_edgesContainer);
			addChild(m_nodesContainer);
			addChild(m_errorContainer);
			addChild(m_plugsContainer);
			trace("load level time1", new Date().getTime()-time1);
			this.alpha = .999;

			selectedComponents = new Vector.<GameComponent>;
			totalMoveDist = new Point();
			loadLayout();
			
			trace("Level " + m_levelLayoutObj["id"] + " m_boundingBox = " + m_boundingBox, "load layout time", new Date().getTime()-time1);
			
			//addEventListener(WidgetChangeEvent.WIDGET_CHANGED, onEdgeSetChange); // do these per-box
			addEventListener(PropertyModeChangeEvent.PROPERTY_MODE_CHANGE, onPropertyModeChange);
			addEventListener(GameComponentEvent.COMPONENT_SELECTED, onComponentSelection);
			addEventListener(GameComponentEvent.COMPONENT_UNSELECTED, onComponentUnselection);
			addEventListener(GroupSelectionEvent.GROUP_SELECTED, onGroupSelection);
			addEventListener(GroupSelectionEvent.GROUP_UNSELECTED, onGroupUnselection);
			levelGraph.addEventListener(ErrorEvent.ERROR_ADDED, onErrorAdded);
			levelGraph.addEventListener(ErrorEvent.ERROR_REMOVED, onErrorRemoved);
			
			//setNodesFromAssignments(m_levelAssignmentsObj);
			//force update of conflict count dictionary, ignore return value
			getNextConflict(true);
			initialized = true;
			trace("Level edges and nodes all created.");
			// When level loaded, don't need this event listener anymore
			dispatchEvent(new MenuEvent(MenuEvent.LEVEL_LOADED));
			trace("load level time2", new Date().getTime()-time1);
		}
		
		public function refreshLevelErrors():void
		{
			errorConstraintDict = new Dictionary();
			for (var constriantId:String in levelGraph.constraintsDict) {
				var constraint:Constraint = levelGraph.constraintsDict[constriantId] as Constraint;
				if (!constraint.isSatisfied()) errorConstraintDict[constriantId] = constraint;
			}
		}
		
		protected function onEnterFrame(evt:EnterFrameEvent):void
		{
			//clean up the old dictionary disposing of what's left
			for each(var gridSquare:GridSquare in currentGridDict)
			{
				gridSquare.draw();
			}
		}
		
		//called on when GridViewPanel content is moving
		public function updateLevelDisplay(viewRect:Rectangle):void
		{
			var leftGridNumber:int = Math.floor(viewRect.left/gridSize);
			var rightGridNumber:int = Math.floor(viewRect.right/gridSize);
			var topGridNumber:int = Math.floor(viewRect.top/gridSize);
			var bottomGridNumber:int = Math.floor(viewRect.bottom/gridSize);
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
				if(gridSquare.intersects(viewRect))
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
			onScoreChange();
		}
		
		public function draw():void
		{
			for each(var gridSquare:GridSquare in currentGridDict)
			{
				gridSquare.draw();
			}
		}
		
		protected function loadLayout():void
		{
			nodeLayoutObjs = new Dictionary();
			edgeLayoutObjs = new Dictionary();
			
			var minX:Number, minY:Number, maxX:Number, maxY:Number;
			minX = minY = Number.POSITIVE_INFINITY;
			maxX = maxY = Number.NEGATIVE_INFINITY;
			
			// Process layout nodes (vars)
			var visibleNodes:int = 0;
			var n:uint = 0;
			for (var varId:String in m_levelLayoutObj["layout"]["vars"])
			{
				var boxLayoutObj:Object = m_levelLayoutObj["layout"]["vars"][varId];
				var graphVar:ConstraintVar = levelGraph.variableDict[varId] as ConstraintVar;
				if (graphVar == null) {
					trace("Warning: layout var found with no corresponding contraints var:" + varId);
					continue;
				}
				boxLayoutObj["id"] = varId;
				boxLayoutObj["var"] = graphVar;
				var nodeX:Number = Number(boxLayoutObj["x"]) * Constants.GAME_SCALE;
				var nodeY:Number = Number(boxLayoutObj["y"]) * Constants.GAME_SCALE;
				
				
				var nodeWidth:Number = 1;//Number(boxLayoutObj["w"]) * Constants.GAME_SCALE;
				var nodeHeight:Number = 1;//Number(boxLayoutObj["h"]) * Constants.GAME_SCALE;
				//Center node at nodeX, nodeY, which means our bounding rectangle needs to be adjusted by .5*width and height
				var nodeBoundingBox:Rectangle = new Rectangle(nodeX - GridSquare.SKIN_DIAMETER*.5, nodeY - GridSquare.SKIN_DIAMETER*.5, GridSquare.SKIN_DIAMETER, GridSquare.SKIN_DIAMETER);
				minX = Math.min(minX, nodeBoundingBox.left);
				minY = Math.min(minY, nodeBoundingBox.top);
				maxX = Math.max(maxX, nodeBoundingBox.right);
				maxY = Math.max(maxY, nodeBoundingBox.bottom);
				boxLayoutObj["bb"] = nodeBoundingBox;
				boxLayoutObj["connectedEdges"] = new Array;
				nodeLayoutObjs[varId] = boxLayoutObj;
				
				var xArrayPos:int = Math.floor(nodeBoundingBox.x/gridSize);
				var yArrayPos:int = Math.floor(nodeBoundingBox.y/gridSize);
				
				var nodeGridName:String = xArrayPos + "_" + yArrayPos;
				var grid:GridSquare = gridSystemDict[nodeGridName];
				if(grid == null)
				{
					grid = new GridSquare(xArrayPos, yArrayPos, gridSize, gridSize);
					gridSystemDict[nodeGridName] = grid;
				}
				
				grid.addNode(boxLayoutObj);
				
				n++;
			}
			trace("node count = " + n);
			
			// Process layout edges (constraints)
			var visibleLines:int = 0;
			n = 0;
			var constraintLength:int = m_levelLayoutObj["layout"]["constraints"].length;
			for(var constraintNum:int = 0; constraintNum<constraintLength; constraintNum++)
			{
				var constraintId:String = m_levelLayoutObj["layout"]["constraints"][constraintNum];
				var edgeLayoutObj:Object = new Object;
				edgeLayoutObj["id"] = constraintId;
				var result:Object = constraintId.split(" ");
				if (result == null) throw new Error("Invalid constraint layout string found: " + constraintId);
				if (result.length != 3) throw new Error("Invalid constraint layout string found: " + constraintId);
				var graphConstraint:Constraint = levelGraph.constraintsDict[constraintId] as Constraint;
				if (graphConstraint == null) throw new Error("No graph constraint found for constraint layout: " + constraintId);
				edgeLayoutObj["constraint"] = graphConstraint;
				edgeLayoutObj["from_var_id"] = result[0];
				nodeLayoutObjs[result[0]]["connectedEdges"].push(constraintId);
				edgeLayoutObj["to_var_id"] = result[2];
				nodeLayoutObjs[result[2]]["connectedEdges"].push(constraintId);
				
				edgeLayoutObjs[constraintId] = edgeLayoutObj;
				n++;
			}
			trace("edge count = " + n);
			m_boundingBox = new Rectangle(minX, minY, maxX - minX, maxY - minY);
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
			initialize();
			
			m_disposed = false;
			m_levelStartTime = new Date().time;
			if (tutorialManager) tutorialManager.startLevel();
			
			levelGraph.resetScoring();
			m_bestScore = levelGraph.currentScore;
			levelGraph.startingScore = levelGraph.currentScore;
			flatten();
			trace("Loaded: " + m_levelLayoutObj["id"] + " for display.");
		}
		
		public function restart():void
		{
			if (!initialized) {
				start();
			} else {
				if (tutorialManager) tutorialManager.startLevel();
				m_levelStartTime = new Date().time;
			}
			var propChangeEvt:PropertyModeChangeEvent = new PropertyModeChangeEvent(PropertyModeChangeEvent.PROPERTY_MODE_CHANGE, PropDictionary.PROP_NARROW);
			onPropertyModeChange(propChangeEvt);
			dispatchEvent(propChangeEvt);
			m_levelAssignmentsObj = XObject.clone(m_levelOriginalAssignmentsObj);
			loadAssignments(m_levelAssignmentsObj);
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
			
			updateAssignmentsObj();
		}
		
		protected function onRemovedFromStage(event:starling.events.Event):void
		{
			trace("REMOVED!")
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
			for (nodeId in m_gameNodeDict) hashSize++;
			
			PipeJamGame.levelInfo.hash = new Array();
			
			var assignmentsObj:Object = { "id": original_level_name, 
									"hash": [], 
									"target_score": this.m_targetScore,
									"starting_score": this.levelGraph.currentScore,
		//							"starting_jams": this.m_levelConflictEdges.length,
									"assignments": { } };
			var count:int = 0;
			var numWide:int = 0;
	/*		for (nodeId in m_gameNodeDict) {
				var node:GameNode = m_gameNodeDict[nodeId] as GameNode;
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
			}*/
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
			
			m_gameEdgeDict = new Dictionary();
			
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
			
			removeEventListener(VarChangeEvent.VAR_CHANGE_USER, onWidgetChange);
			removeEventListener(PropertyModeChangeEvent.PROPERTY_MODE_CHANGE, onPropertyModeChange);
			removeEventListener(GameComponentEvent.COMPONENT_SELECTED, onComponentSelection);
			removeEventListener(GameComponentEvent.COMPONENT_UNSELECTED, onComponentSelection);
			removeEventListener(GroupSelectionEvent.GROUP_SELECTED, onGroupSelection);
			removeEventListener(GroupSelectionEvent.GROUP_UNSELECTED, onGroupUnselection);
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
			if (evt) {
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
		protected function componentSelectionChanged(component:GameComponent, selected:Boolean):void
		{
		
		}
		
		protected function onComponentSelection(evt:GameComponentEvent):void
		{
			var component:GameComponent = evt.component;
			if(component)
				componentSelectionChanged(component, true);
			
			var selectionChangedComponents:Vector.<GameComponent> = new Vector.<GameComponent>();
			selectionChangedComponents.push(component);
		}
		
		protected function onComponentUnselection(evt:GameComponentEvent):void
		{
			var component:GameComponent = evt.component;
			if(component)
				componentSelectionChanged(component, false);
			
			var selectionChangedComponents:Vector.<GameComponent> = new Vector.<GameComponent>();
			selectionChangedComponents.push(component);
		}
		
		protected function onGroupSelection(evt:GroupSelectionEvent):void
		{
			var selectionChangedComponents:Vector.<GameComponent> = evt.selection.concat();
			for each (var comp:GameComponent in selectionChangedComponents) {
				comp.componentSelected(true);
				componentSelectionChanged(comp, true);
			}
		}
		
		protected function onGroupUnselection(evt:GroupSelectionEvent):void
		{
			var selectionChangedComponents:Vector.<GameComponent> = evt.selection.concat();
			for each (var comp:GameComponent in selectionChangedComponents) {
				comp.componentSelected(false);
				componentSelectionChanged(comp, false);
			}
		}
		
		protected function onErrorAdded(evt:ErrorEvent):void
		{
			errorConstraintDict[evt.constraintError.id] = evt.constraintError;
		}
		
		protected function onErrorRemoved(evt:ErrorEvent):void
		{
			delete errorConstraintDict[evt.constraintError.id];
		}
		
		
		protected static function getVisible(_layoutObj:Object, _defaultValue:Boolean = true):Boolean
		{
			var value:String = _layoutObj["visible"];
			if (!value) return _defaultValue;
			return XString.stringToBool(value);
		}

		public function getNodes():Dictionary
		{
			return m_gameNodeDict;
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
		public function getNextConflict(forward:Boolean):DisplayObject
		{
//			if (m_conflictEdgesDirty) {
//				for (var edgeId:String in m_gameEdgeDict) {
//					var gameEdge:GameEdgeContainer = m_gameEdgeDict[edgeId] as GameEdgeContainer;
//					if (gameEdge.hasError()) {
//						if (!m_levelConflictEdgeDict.hasOwnProperty(gameEdge.m_id)) {
//							// Add to list/dict if not on there already
//							if (m_levelConflictEdges.indexOf(gameEdge) == -1) m_levelConflictEdges.push(gameEdge);
//							m_levelConflictEdgeDict[gameEdge.m_id] = true;
//						}
//					} else {
//						if (m_levelConflictEdgeDict.hasOwnProperty(gameEdge.m_id)) {
//							// Remove from edge conflict list/dict if on it
//							var delindx:int = m_levelConflictEdges.indexOf(gameEdge);
//							if (delindx > -1) m_levelConflictEdges.splice(delindx, 1);
//							delete m_levelConflictEdgeDict[gameEdge.m_id];
//						}
//					}
//				}
//				m_conflictEdgesDirty = false;
//			}
//			//keep track of number of conflicts
//			PipeJamGame.levelInfo.conflicts = m_levelConflictEdges.length;
//			
//			if (m_levelConflictEdges.length == 0) return null;
//			if (forward) {
//				m_currentConflictIndex++;
//			} else {
//				m_currentConflictIndex--;
//			}
//			if (m_currentConflictIndex >= m_levelConflictEdges.length) {
//				m_currentConflictIndex = 0;
//			} else if (m_currentConflictIndex < 0) {
//				m_currentConflictIndex = m_levelConflictEdges.length - 1;
//			}
//			return m_levelConflictEdges[m_currentConflictIndex].errorContainer;
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
		
		public function getSolveButtonsAllowed():Boolean
		{ 
			if (tutorialManager) return tutorialManager.getSolveButtonsAllowed();
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
				trace("New best score: " + m_bestScore);
				m_levelBestScoreAssignmentsObj = createAssignmentsObj();
				//don't update on loading
				if(levelGraph.oldScore != 0)
					dispatchEvent(new MenuEvent(MenuEvent.SUBMIT_LEVEL));
			}
			if (levelGraph.prevScore != levelGraph.currentScore)
				dispatchEvent(new WidgetChangeEvent(WidgetChangeEvent.LEVEL_WIDGET_CHANGED, null, null, false, this, null));
			m_conflictEdgesDirty = true;
		}
		
		public function handleMarquee(startingPoint:Point, currentPoint:Point):void
		{
			var gridSquare:GridSquare;
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
				if(marqueeRect.height > 0 && marqueeRect.width > 0)
				{
					for each(gridSquare in currentGridDict)
					{
						gridSquare.handleSelection(marqueeRect.bounds, selectedNodeConstraintDict);
					}
				}
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
		
		public function unselectAll(addEventToLast:Boolean = false):void
		{
			for each(var gridSquare:GridSquare in currentGridDict)
			{
				gridSquare.unselectAll();
			}
			
			selectedNodeConstraintDict = new Dictionary; 
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
		
		public function solveSelection(updateCallback:Function, doneCallback:Function):void
		{
			//figure out which edges have both start and end components selected (all included edges have both ends selected?)
			//assign connected components to component to edge constraint number dict
			//create three constraints for conflicts and weights
			//run the solver, passing in the callback function
			nodeIDToConstraintsTwoWayMap = new Dictionary;
			var storedConstraints:Dictionary = new Dictionary;
			var counter:int = 1;
			var constraintArray:Array = new Array;
			var initvarsArray:Array = new Array;
			//loop through each object
			for each(var node:Object in selectedNodeConstraintDict)
			{
				//loop through each edge, checking far end for existence in dict
				for each(var gameEdgeID:String in node.connectedEdges)
				{
					var constraint1Value:int = -1;
					var constraint2Value:int = -1;
					var edgeObj:Object = World.m_world.active_level.edgeLayoutObjs[gameEdgeID];
					var toNodeID:String = edgeObj["to_var_id"];
					var toNode:Object = World.m_world.active_level.nodeLayoutObjs[toNodeID];
					var fromNodeID:String = edgeObj["from_var_id"];
					var fromNode:Object = World.m_world.active_level.nodeLayoutObjs[fromNodeID];
					
					//figure out which is the other node
					var nodeToCheck:Object = toNode;
					if(toNode == node)
						nodeToCheck = fromNode;
					
					if(selectedNodeConstraintDict[nodeToCheck.id] != null)
					{
						//found an edge with both end nodes selected
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
						} 
						
						if(toNode.isEditable)
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
							
							if(fromNode.isEditable && toNode.isEditable)
								constraintArray.push(new Array(100, -constraint1Value, constraint2Value));
							else if(fromNode.isEditable && !toNode.isEditable)
							{
								if(toNode.isNarrow)
									constraintArray.push(new Array(100, -constraint1Value));
							}
							if(!fromNode.isEditable && toNode.isEditable)
							{
								if(!fromNode.isNarrow)
									constraintArray.push(new Array(100, constraint2Value));
							}
							
							if(toNode.isEditable && storedConstraints[constraint1Value] != toNode)
							{
								constraintArray.push(new Array(1, constraint1Value));
								storedConstraints[constraint1Value] = toNode;
							}
							if(fromNode.isEditable && storedConstraints[constraint2Value] != fromNode)
							{
								constraintArray.push(new Array(1, constraint2Value));
								storedConstraints[constraint2Value] = fromNode;
							}
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
				m_inSolver = true;
				MaxSatSolver.run_solver(constraintArray, initvarsArray, updateCallback, doneCallback);
			}
		}
		
		public function solverUpdate(vars:Array, unsat_weight:int):void
		{
			var assignmentIsWide:Boolean = false;
			
			if(	m_inSolver == false) //got marked done early
				return;
			
			for (var ii:int = 0; ii < vars.length; ++ ii) 
			{
				var node:Object = nodeIDToConstraintsTwoWayMap[ii+1];
				var constraintVar:ConstraintVar = node["var"];
				var parentGridSquare:GridSquare = node.parentGrid;
				parentGridSquare.setNodeDirty(node, true);
				node.isNarrow = true;
				if(vars[ii] == 1)
					node.isNarrow = false;
				if(constraintVar) 
					constraintVar.setProp(PropDictionary.PROP_NARROW, node.isNarrow);
			}
			onWidgetChange();
		}
		
		public function solverDone(errMsg:String):void
		{
			m_inSolver = false;
			MaxSatSolver.stop_solver();
			levelGraph.updateScore();
			onScoreChange(true);
		}
		
		public function onViewSpaceChanged(event:MiniMapEvent):void
		{
			
		}
		
		public function adjustSize(newWidth:Number, newHeight:Number):void
		{
			
		}
	}
}