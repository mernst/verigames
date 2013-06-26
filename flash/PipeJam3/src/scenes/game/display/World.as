package scenes.game.display
{
	import events.EdgeSetChangeEvent;
	import flash.geom.Point;
	import graph.LevelNodes;
	import graph.Network;
	import graph.Node;
	import scenes.BaseComponent;
	import scenes.game.components.dialogs.InGameMenuDialog;
	import scenes.game.components.GameControlPanel;
	import scenes.game.components.GridViewPanel;
	import system.PipeSimulator;
	import scenes.game.PipeJamGameScene;
	import events.NavigationEvent;
	
	import flash.utils.Dictionary;
	import starling.display.Button;
	import starling.display.Image;
	import starling.events.Event;
	import starling.events.KeyboardEvent;
	
	/**
	 * World that contains levels that each contain boards that each contain pipes
	 */
	public class World extends BaseComponent
	{
		protected var edgeSetGraphViewPanel:GridViewPanel;
		public var gameControlPanel:GameControlPanel;
		protected var inGameMenuBox:InGameMenuDialog;
		
		/** All the levels in this world */
		public var levels:Vector.<Level> = new Vector.<Level>();
		protected var currentLevelNumber:Number = 0;
		
		/** Images used for boards of a given level (different colors, same texture) */
		public var level_background_images:Vector.<Image>;
		
		/** Map from edge set index to Vector of Pipe instances */
		public var pipeEdgeSetDictionary:Dictionary = new Dictionary();
		
		/** Map from edge_id to Pipe instance */
		public var pipeIdDictionary:Dictionary = new Dictionary();
		
		/** Current level being played by the user */
		public var active_level:Level = null;
		
		//shim to make it start with a level until we get servers up
		protected var firstLevel:Level = null;
		
		/** Network for this world */
		public var m_network:Network;
		
		/** simulator for the network */
		public var m_simulator:PipeSimulator;
		
		/** Original XML used for this world */
		public var world_xml:XML;
		
		/** True if at least one level on this board has not succeeded */
		public var failed:Boolean = false;
		
		/** True if all levels on this board have succeeded */
		public var succeeded:Boolean = false;
		
		/** If we are in process of selecting a level. */
		protected static var selecting_level:Boolean;
		
		/** True if this World has been solves and fireworks displayed, setting this will prevent euphoria from being displayed more than once */
		public var world_has_been_solved_before:Boolean = false;
		
		/** Set to true to only include pipes on normal boards in pipeIdDictionary, not pipes that appear on subboard clones */
		public static const ONLY_INCLUDE_ORIGINAL_PIPES_IN_PIPE_ID_DICTIONARY:Boolean = true;
		
		/** Map from board name to board */
		public var worldBoardNameDictionary:Dictionary = new Dictionary();
		
		protected var undoStack:Array;
		protected var redoStack:Array;
		
		private var m_layoutXML:XML;
		private var m_constraintsXML:XML;
		
		protected var right_arrow_button:Button;
		protected var left_arrow_button:Button;
		
		public static var SHOW_GAME_MENU:String = "show_game_menu";
		public static var SWITCH_TO_NEXT_LEVEL:String = "switch_to_next_level";
		
		public static var UNDO_EVENT:String = "undo_event";
				
		/**
		 * World that contains levels that each contain boards that each contain pipes
		 * @param	_x X coordinate, this is currently unused
		 * @param	_y Y coordinate, this is currently unused
		 * @param	_width Width, this is currently unused
		 * @param	_height Height, this is currently unused
		 * @param	_name Name of the level
		 * @param	_system The parent VerigameSystem instance
		 */
		public function World(_network:Network, _world_xml:XML, _layout:XML,  _constraints:XML)
		{
//			super(_x, _y, _width, _height);
			m_network = _network;
			world_xml = _world_xml;
			m_layoutXML = _layout;
			m_constraintsXML = _constraints;
			
			undoStack = new Array();
			redoStack = new Array();
			
			// create World
			var original_subboard_nodes:Vector.<Node> = new Vector.<Node>();
			for (var level_index:uint = 0; level_index < world_xml["level"].length(); level_index++) {
				var my_level_xml:XML = world_xml["level"][level_index];
				var my_level_name:String = m_network.obfuscator.getLevelName(my_level_xml.attribute("name").toString());
				if ((m_network.LevelNodesDictionary[my_level_name] == null) || (m_network.LevelNodesDictionary[my_level_name] == undefined)) {
					// This is true if there are no edges in the level, skip this level
					PipeJamGame.printDebug("No edges found on level " + my_level_name + " skipping this level and not creating...");
					continue;
				}
				var my_levelNodes:LevelNodes = (m_network.LevelNodesDictionary[my_level_name] as LevelNodes);
				PipeJamGame.printDebug("Creating level: " + my_level_name);
				
				var levelLayoutXML:XML = findLevelFile(my_levelNodes.original_level_name, m_layoutXML);
				var levelConstraintsXML:XML = findLevelFile(my_levelNodes.original_level_name, m_constraintsXML);
				var my_level:Level = new Level(my_level_name, my_levelNodes, levelLayoutXML, levelConstraintsXML);
				levels.push(my_level);
				
				if (!firstLevel) {
					firstLevel = my_level; //grab first one..
				}
			}
			
			//m_simulator = new Simulator(m_network);
			m_simulator = new PipeSimulator(m_network);
						
			addEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
			addEventListener(Event.REMOVED_FROM_STAGE, onRemovedFromStage);			
		}
		
		protected function onAddedToStage(event:Event):void
		{
			edgeSetGraphViewPanel = new GridViewPanel();
			addChild(edgeSetGraphViewPanel);
			
			gameControlPanel = new GameControlPanel();
			gameControlPanel.y = GridViewPanel.HEIGHT;
			addChild(gameControlPanel);
			
			if(PipeJamGameScene.inTutorial)
			{
				currentLevelNumber = PipeJamGameScene.numTutorialLevelsCompleted;
				firstLevel = levels[currentLevelNumber];
			}
			
			selectLevel(firstLevel);
			
			addEventListener(EdgeSetChangeEvent.LEVEL_EDGE_SET_CHANGED, onEdgeSetChange);
			addEventListener(Level.CENTER_ON_COMPONENT, onCenterOnComponentEvent);
			addEventListener(World.SHOW_GAME_MENU, onShowGameMenuEvent);
			addEventListener(World.SWITCH_TO_NEXT_LEVEL, onNextLevel);
			
			addEventListener(Level.SAVE_LAYOUT, onSaveLayoutFile);
			addEventListener(Level.SUBMIT_SCORE, onSubmitScore);
			addEventListener(Level.SAVE_LOCALLY, onSaveLocally);
			addEventListener(Level.SET_NEW_LAYOUT, setNewLayout);	
			
			stage.addEventListener(KeyboardEvent.KEY_UP, handleKeyUp);
			addEventListener(UNDO_EVENT, saveEvent);
			
			addEventListener(Level.ERROR_ADDED, onErrorAdded);
			addEventListener(Level.ERROR_REMOVED, onErrorRemoved);
			addEventListener(Level.ERROR_MOVED, onErrorMoved);
			addEventListener(Level.MOVE_TO_POINT, onMoveToPointEvent);

		}
		
		private function onShowGameMenuEvent(e:Event):void
		{
			if(e.data == true)
			{
				if(inGameMenuBox == null)
				{
					inGameMenuBox = new InGameMenuDialog();
					addChild(inGameMenuBox);
					inGameMenuBox.x = 0;
					inGameMenuBox.y = gameControlPanel.y - inGameMenuBox.height;
				}
				inGameMenuBox.visible = true;
			}
			else
				inGameMenuBox.visible = false;
				
		}
		
		public function onSaveLayoutFile(event:Event):void
		{
			if(active_level != null)
				active_level.onSaveLayoutFile(event);
		}
		
		public function onSubmitScore(event:Event):void
		{
			if(active_level != null)
				active_level.onSubmitScore(event);
		}
		
		public function onSaveLocally(event:Event):void
		{
			if(active_level != null)
				active_level.onSaveLocally(event);
		}
		
		public function setNewLayout(event:Event):void
		{
			if(active_level != null)
				active_level.setNewLayout(event, true);
		}
		
		private function onEdgeSetChange(evt:EdgeSetChangeEvent):void
		{
			m_simulator.updateOnBoxSizeChange(evt.edgeSetChanged.m_id, evt.level.level_name);
			var newScore:int = gameControlPanel.updateScore(evt.level);
			if (newScore >= evt.level.getTargetScore()) {
				edgeSetGraphViewPanel.displayNextButton();
			} else {
				edgeSetGraphViewPanel.hideNextButton();
			}
		}
		
		private function onCenterOnComponentEvent(e:Event):void
		{
			var component:GameComponent = e.data as GameComponent;
			if(component)
			{
				edgeSetGraphViewPanel.centerOnComponent(component);
			}
		}
		
		private function onNextLevel(e:Event):void
		{
			if(PipeJamGameScene.inTutorial)
			{
				currentLevelNumber = PipeJamGameScene.numTutorialLevelsCompleted;
				if(currentLevelNumber >= levels.length)
				{
					dispatchEvent(new NavigationEvent(NavigationEvent.CHANGE_SCREEN, "SplashScreen", true));
					return;
				}
			}
			else
				currentLevelNumber = (currentLevelNumber + 1) % levels.length;
			selectLevel(levels[currentLevelNumber]);
		}
		
		public function onErrorAdded(event:starling.events.Event):void
		{
			gameControlPanel.errorAdded(event.data, active_level);
		}
		
		public function onErrorRemoved(event:starling.events.Event):void
		{
			gameControlPanel.errorRemoved(event.data);
		}
		
		public function onErrorMoved(event:starling.events.Event):void
		{
			gameControlPanel.errorMoved(event.data);
		}
		
		private function onMoveToPointEvent(e:starling.events.Event):void
		{
			edgeSetGraphViewPanel.moveToPoint(e.data as Point);
		}
		
		private function saveEvent(e:starling.events.Event):void
		{
			//sometimes we need to remove the last event to add a complex event that includes that one
			if(e.data && e.data.data && e.data.data.hasOwnProperty("addToLast") == true && e.data.data.addToLast == true)
			{
				var lastEvent:Event = undoStack.pop();
				if(lastEvent.data is Array)
				{
					(lastEvent.data as Array).push(e.data.data);
					undoStack.push(lastEvent);
				}
				else
				{
					var event1:Event = new Event(lastEvent.type, true, lastEvent.data);
					var event2:Event = new Event(e.data.type, true, e.data.data);
					var newArray:Array = new Array(event1, event2);
					var newEvent:Event = new Event(World.UNDO_EVENT, true, newArray);
					undoStack.push(newEvent);
					
				}
			}
			else
				undoStack.push(e.data);
			//when we build on the undoStack, clear out the redoStack
			redoStack = new Array();
		}
		
		public function handleKeyUp(event:starling.events.KeyboardEvent):void
		{
			if(event.ctrlKey)
			{
				switch(event.keyCode)
				{
					case 90: //'z'
					{
						if(undoStack.length > 0)
						{
							var undoDataEvent:Event = undoStack.pop();
							if(undoDataEvent.data != null)
							{
								var undoData:Object;
								if(undoDataEvent.data is Array)
								{
									for each(var obj:Event in undoDataEvent.data)
									{
										undoData = obj.data;
										if(undoData == null) //handle locally
											handleUndoEvent(undoDataEvent, true);
										if(undoData.target is String)
										{
											if(undoData.target == "level")
											{
												if(this.active_level != null)
													active_level.handleUndoEvent(obj, true);
											}
										}
										else if(undoData.target is BaseComponent)
											(undoData.target as BaseComponent).handleUndoEvent(obj, true);
									}
									redoStack.push(undoDataEvent);
								}
								else
								{
									undoData = undoDataEvent.data;
									if(undoData == null) //handle locally
										handleUndoEvent(undoDataEvent, true);
									if(undoData.target is String)
									{
										if(undoData.target == "level")
										{
											if(this.active_level != null)
												active_level.handleUndoEvent(undoDataEvent, true);
										}
									}
									else if(undoData.target is BaseComponent)
										(undoData.target as BaseComponent).handleUndoEvent(undoDataEvent, true);
									redoStack.push(undoDataEvent);
								}
							}
						}
						break;
					}
					case 82: //'r'
					case 89: //'y'
					{
						if(redoStack.length > 0)
						{
							var redoDataEvent:Event = redoStack.pop();
							if(redoDataEvent.data != null)
							{
								if(redoDataEvent.data is Array)
								{
									for each(var obj1:Event in redoDataEvent.data)
									{
										var redoData:Object = obj1.data;
										if(redoData == null) //handle locally
											handleUndoEvent(redoDataEvent, false);
										if(redoData.target is String)
										{
											if(redoData.target == "level")
											{
												if(this.active_level != null)
													active_level.handleUndoEvent(obj1, false);
											}
										}
										else if(redoData.target is BaseComponent)
											(redoData.target as BaseComponent).handleUndoEvent(obj1, false);
									}
									undoStack.push(redoDataEvent);
								}
								else
								{
									var redoData1:Object = redoDataEvent.data;
									if(redoData1 == null) //handle locally
										handleUndoEvent(redoDataEvent, false);
									if(redoData1.target is String)
									{
										if(redoData.target == "level")
										{
											if(this.active_level != null)
												active_level.handleUndoEvent(redoDataEvent, false);
										}
									}
									else if(redoData1.target is BaseComponent)
										(redoData1.target as BaseComponent).handleUndoEvent(redoDataEvent, false);
									undoStack.push(redoDataEvent);
								}
							}
						}
						break;
					}
					case 72: //'h' for hide
					if(this.active_level != null)
						active_level.toggleUneditableStrings();
					break;
				}
			}
		}
		
		private function selectLevel(newLevel:Level):void
		{
			active_level = newLevel;
			
			edgeSetGraphViewPanel.loadLevel(newLevel);
			gameControlPanel.newLevelSelected(newLevel);
			trace("gcp: " + gameControlPanel.width + " x " + gameControlPanel.height);
			trace("vp: " + edgeSetGraphViewPanel.width + " x " + edgeSetGraphViewPanel.height);
			
			dispatchEvent(new Event(Game.STOP_BUSY_ANIMATION,true));
		}
		
		private function onRemovedFromStage():void
		{
			removeEventListener(Level.CENTER_ON_COMPONENT, onCenterOnComponentEvent);
			removeEventListener(EdgeSetChangeEvent.LEVEL_EDGE_SET_CHANGED, onEdgeSetChange);
			removeEventListener(Level.CENTER_ON_COMPONENT, onCenterOnComponentEvent);
			removeEventListener(World.SHOW_GAME_MENU, onShowGameMenuEvent);
			removeEventListener(World.SWITCH_TO_NEXT_LEVEL, onNextLevel);
			
			removeEventListener(Level.SAVE_LAYOUT, onSaveLayoutFile);
			removeEventListener(Level.SUBMIT_SCORE, onSubmitScore);
			removeEventListener(Level.SAVE_LOCALLY, onSaveLocally);
			removeEventListener(Level.SET_NEW_LAYOUT, setNewLayout);	
			removeEventListener(UNDO_EVENT, saveEvent);
			
			stage.removeEventListener(KeyboardEvent.KEY_UP, handleKeyUp);
			
			if(active_level)
				removeChild(active_level, true);
			m_network = null;
			world_xml = null;
			m_layoutXML = null;
		}
		
		public function findLevel(index:uint):Level
		{
			for (var my_level_index:uint = 0; my_level_index < levels.length; my_level_index++) {
				var level:Level = levels[my_level_index];
				if(level.levelNodes.metadata["index"] == index)
					return level;
			}	
			
			return null;
		}
		
		public function findLevelFile(name:String, xml:XML):XML
		{
			var xmlList:XMLList = xml.level;
			for each(var level:XML in xmlList)
			{
				var levelName:String = level.@id;
				if(levelName.length == 0)
					levelName = level.@name;
				
				var matchIndex:int = levelName.indexOf(name);
				if(matchIndex != -1 && matchIndex+(name).length == levelName.length)
					return level;
			}
			
			return null;
		}
	}
}
