package scenes.game.display
{
	import assets.AssetInterface;
	
	import events.EdgeSetChangeEvent;
	
	import flash.events.Event;
	import flash.external.ExternalInterface;
	import flash.utils.Dictionary;
	
	import graph.LevelNodes;
	import graph.Network;
	import graph.Node;
	
	import scenes.BaseComponent;
	import scenes.game.components.GameControlPanel;
	import scenes.game.components.GridViewPanel;
	import scenes.game.components.dialogs.InGameMenuDialog;
	
	import starling.display.Button;
	import starling.display.Image;
	import starling.display.Quad;
	import starling.events.Event;
	import starling.events.KeyboardEvent;
	import starling.textures.Texture;
	
	import system.PipeSimulator;
	import system.Simulator;
	
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
			
			createWorld(m_network.LevelNodesDictionary);
			//m_simulator = new Simulator(m_network);
			m_simulator = new PipeSimulator(m_network);
			
			addEventListener(starling.events.Event.ADDED_TO_STAGE, onAddedToStage);
			addEventListener(starling.events.Event.REMOVED_FROM_STAGE, onRemovedFromStage);			
		}
		
		protected function onAddedToStage(event:starling.events.Event):void
		{
			edgeSetGraphViewPanel = new GridViewPanel();
			addChild(edgeSetGraphViewPanel);
			
			gameControlPanel = new GameControlPanel();
			gameControlPanel.y = GridViewPanel.HEIGHT;
			addChild(gameControlPanel);
			
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
		}
		
		private function onShowGameMenuEvent(e:starling.events.Event):void
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
		
		public function onSaveLayoutFile(event:starling.events.Event):void
		{
			if(active_level != null)
				active_level.onSaveLayoutFile(event);
		}
		
		public function onSubmitScore(event:starling.events.Event):void
		{
			if(active_level != null)
				active_level.onSubmitScore(event);
		}
		
		public function onSaveLocally(event:starling.events.Event):void
		{
			if(active_level != null)
				active_level.onSaveLocally(event);
		}
		
		public function setNewLayout(event:starling.events.Event):void
		{
			if(active_level != null)
				active_level.setNewLayout(event, true);
		}
		
		private function onEdgeSetChange(evt:EdgeSetChangeEvent):void
		{
			m_simulator.updateOnBoxSizeChange(evt.edgeSetChanged.m_id, evt.level.level_name);
			gameControlPanel.updateScore(evt.level);
		}
		
		private function onCenterOnComponentEvent(e:starling.events.Event):void
		{
			var component:GameComponent = e.data as GameComponent;
			if(component)
			{
				edgeSetGraphViewPanel.centerOnComponent(component);
			}
		}
		
		private function onNextLevel(e:starling.events.Event):void
		{
			currentLevelNumber = (currentLevelNumber + 1) % levels.length;
			selectLevel(levels[currentLevelNumber]);
		}
		
		private function saveEvent(e:starling.events.Event):void
		{
			//sometimes we need to remove the last event to add a complex event that includes that one
			if(e.data && e.data.data && e.data.data.hasOwnProperty("addToLast") == true && e.data.data.addToLast == true)
			{
				var lastEvent:starling.events.Event = undoStack.pop();
				if(lastEvent.data is Array)
				{
					(lastEvent.data as Array).push(e.data.data);
					undoStack.push(lastEvent);
				}
				else
				{
					var event1:starling.events.Event = new starling.events.Event(lastEvent.type, true, lastEvent.data);
					var event2:starling.events.Event = new starling.events.Event(e.data.type, true, e.data.data);
					var newArray:Array = new Array(event1, event2);
					var newEvent:starling.events.Event = new starling.events.Event(World.UNDO_EVENT, true, newArray);
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
							var undoDataEvent:starling.events.Event = undoStack.pop();
							if(undoDataEvent.data != null)
							{
								if(undoDataEvent.data is Array)
								{
									for each(var obj:starling.events.Event in undoDataEvent.data)
									{
										var undoData:Object = obj.data;
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
									var undoData:Object = undoDataEvent.data;
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
							var redoDataEvent:starling.events.Event = redoStack.pop();
							if(redoDataEvent.data != null)
							{
								if(redoDataEvent.data is Array)
								{
									for each(var obj:starling.events.Event in redoDataEvent.data)
									{
										var redoData:Object = obj.data;
										if(redoData == null) //handle locally
											handleUndoEvent(redoDataEvent, false);
										if(redoData.target is String)
										{
											if(redoData.target == "level")
											{
												if(this.active_level != null)
													active_level.handleUndoEvent(obj, false);
											}
										}
										else if(redoData.target is BaseComponent)
											(redoData.target as BaseComponent).handleUndoEvent(obj, false);
									}
									undoStack.push(redoDataEvent);
								}
								else
								{
									var redoData:Object = redoDataEvent.data;
									if(redoData == null) //handle locally
										handleUndoEvent(redoDataEvent, false);
									if(redoData.target is String)
									{
										if(redoData.target == "level")
										{
											if(this.active_level != null)
												active_level.handleUndoEvent(redoDataEvent, false);
										}
									}
									else if(redoData.target is BaseComponent)
										(redoData.target as BaseComponent).handleUndoEvent(redoDataEvent, false);
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
			if (newLevel == active_level) {
				return;
			}
			
			active_level = newLevel;
			
			edgeSetGraphViewPanel.loadLevel(newLevel);
			gameControlPanel.updateScore(newLevel);
			trace("gcp: " + gameControlPanel.width + " x " + gameControlPanel.height);
			trace("vp: " + edgeSetGraphViewPanel.width + " x " + edgeSetGraphViewPanel.height);
			dispatchEvent(new starling.events.Event(Game.STOP_BUSY_ANIMATION,true));
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
		
		public function createWorld(worldNodesDictionary:Dictionary):void
		{
			var original_subboard_nodes:Vector.<Node> = new Vector.<Node>();

			for (var my_level_name:String in worldNodesDictionary) {
				if (worldNodesDictionary[my_level_name] == null) {
					// This is true if there are no edges in the level, skip this level
					PipeJamGame.printDebug("No edges found on level " + my_level_name + " skipping this level and not creating...");
					continue;
				}
				var my_levelNodes:LevelNodes = (worldNodesDictionary[my_level_name] as LevelNodes);
				PipeJamGame.printDebug("Creating level: " + my_level_name);
				
				var levelLayoutXML:XML = findLevelFile(my_levelNodes.original_level_name, m_layoutXML);
				var levelConstraintsXML:XML = findLevelFile(my_levelNodes.original_level_name, m_constraintsXML);
				var my_level:Level = new Level(my_level_name, my_levelNodes, levelLayoutXML, levelConstraintsXML);
				levels.push(my_level);
									
		//		if(my_levelNodes.original_level_name == "Application2") //KhakiDunes
					firstLevel = my_level; //grab last one..
			}
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
				//contains the name, and it's at the end to avoid matches like level_name1
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
