package scenes.game.display
{
	import assets.AssetsAudio;
	import system.VerigameServerConstants;
	
	import audio.AudioManager;
	
	import events.EdgeSetChangeEvent;
	import events.NavigationEvent;
	
	import flash.geom.Point;
	import flash.system.System;
	import flash.utils.Dictionary;
	
	import graph.LevelNodes;
	import graph.Network;
	import graph.Node;
	
	import scenes.BaseComponent;
	import scenes.game.PipeJamGameScene;
	import scenes.game.components.GameControlPanel;
	import scenes.game.components.GridViewPanel;
	import scenes.game.components.dialogs.InGameMenuDialog;
	
	import starling.display.Button;
	import starling.display.Image;
	import starling.events.Event;
	import starling.events.KeyboardEvent;
	
	import system.PipeSimulator;
	
	import utils.XMath;
	
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
		
		protected var undoStack:Array;
		protected var redoStack:Array;
		
		private var m_layoutXML:XML;
		private var m_constraintsXML:XML;
		
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
			
			if(PipeJamGameScene.inTutorial && levels && levels.length > 0)
			{
				currentLevelNumber = PipeJamGameScene.numTutorialLevelsCompleted;
				var levelNumberToUse:Number = XMath.clamp(currentLevelNumber, 0, levels.length - 1);
				firstLevel = levels[levelNumberToUse];
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
			
			AudioManager.getInstance().audioDriver().reset();
			AudioManager.getInstance().audioDriver().playMusic(AssetsAudio.MUSIC_FIELD_SONG);
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
				inGameMenuBox.onBackToGameButtonTriggered();
				
		}
		
		public function onSaveLayoutFile(event:Event):void
		{
			if(active_level != null) {
				active_level.onSaveLayoutFile(event);
				if (PipeJam3.logging) {
					var details:Object = new Object();
					details[VerigameServerConstants.ACTION_PARAMETER_LEVEL_NAME] = active_level.original_level_name; // yes, we can get this from the quest data but include it here for convenience
					details[VerigameServerConstants.ACTION_PARAMETER_LAYOUT_NAME] = event.data as String;
					PipeJam3.logging.logQuestAction(VerigameServerConstants.VERIGAME_ACTION_SAVE_LAYOUT, details, active_level.getTimeMs());
				}
			}
		}
		
		public function onSubmitScore(event:Event):void
		{
			if(active_level != null)
			{
				var currentScore:int = gameControlPanel.getCurrentScore();
				active_level.onSubmitScore(event, currentScore);
				if (PipeJam3.logging) {
					var details:Object = new Object();
					details[VerigameServerConstants.ACTION_PARAMETER_LEVEL_NAME] = active_level.original_level_name; // yes, we can get this from the quest data but include it here for convenience
					details[VerigameServerConstants.ACTION_PARAMETER_SCORE] = currentScore;
					PipeJam3.logging.logQuestAction(VerigameServerConstants.VERIGAME_ACTION_SUBMIT_SCORE, details, active_level.getTimeMs());
				}
			}
		}
		
		public function onSaveLocally(event:Event):void
		{
			if(active_level != null)
				active_level.onSaveLocally(event);
		}
		
		public function setNewLayout(event:Event):void
		{
			if(active_level != null) {
				active_level.setNewLayout(event, true);
				if (PipeJam3.logging) {
					var details:Object = new Object();
					details[VerigameServerConstants.ACTION_PARAMETER_LEVEL_NAME] = active_level.original_level_name; // yes, we can get this from the quest data but include it here for convenience
					details[VerigameServerConstants.ACTION_PARAMETER_LAYOUT_NAME] = (event.data as XML).@id;
					PipeJam3.logging.logQuestAction(VerigameServerConstants.VERIGAME_ACTION_LOAD_LAYOUT, details, active_level.getTimeMs());
				}
			}
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
			if (PipeJam3.logging) {
				var details:Object = new Object();
				details[VerigameServerConstants.ACTION_PARAMETER_EDGESET_ID] = evt.edgeSetChanged.m_id;
				details[VerigameServerConstants.ACTION_PARAMETER_EDGESET_WIDTH] = evt.edgeSetChanged.isWide() ? VerigameServerConstants.ACTION_VALUE_EDGE_WIDTH_WIDE : VerigameServerConstants.ACTION_VALUE_EDGE_WIDTH_NARROW;
				PipeJam3.logging.logQuestAction(VerigameServerConstants.VERIGAME_ACTION_CHANGE_EDGESET_WIDTH, details, evt.level.getTimeMs());
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
			//addToLastSimilar adds to the last event if they are of the same type (i.e. successive mouse wheel events should all undo at the same time)
			//addToLast adds to last event in any case (undo move node event also should put edges back where they were)
			if(e.data) //should always exist, but...
			{
				if(e.data.data)
				{
					var lastEvent:Event;
					var newArray:Array;
					var newEvent:Event;
					
					if(e.data.data.hasOwnProperty("addToLastSimilar") == true && e.data.data.addToLastSimilar == true)
					{
						lastEvent = undoStack.pop();
						if(lastEvent)
						{
							if(lastEvent.type == e.data.type)
							{
								if(lastEvent.data is Array)
								{
									(lastEvent.data as Array).push(e.data);
									undoStack.push(lastEvent);
								}
								else
								{
									newArray = new Array(lastEvent, e.data);
									newEvent = new Event(e.data.type, true, newArray);
									undoStack.push(newEvent);
									
								}
							}
							else //no match, just push, adding back lastEvent also
							{
								undoStack.push(lastEvent);
								undoStack.push(e.data);
							}
							
						}
						else
							undoStack.push(e.data);
					}
					else if(e.data.data.hasOwnProperty("addToLast") == true && e.data.data.addToLast == true)
					{
						lastEvent = undoStack.pop();
						if(lastEvent)
						{
							if(lastEvent.data is Array)
							{
								(lastEvent.data as Array).push(e.data);
								undoStack.push(lastEvent);
							}
							else
							{
								newArray = new Array(lastEvent, e.data);
								newEvent = new Event(e.data.type, true, newArray);
								undoStack.push(newEvent);
								
							}
						}
						else
							undoStack.push(e.data);
					}
					else
						undoStack.push(e.data);
				}
				else
					undoStack.push(e.data);
			}
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
								handleUndoRedoEvent(undoDataEvent, true);
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
								handleUndoRedoEvent(redoDataEvent, false);
							}
						}
						break;
					}
					case 72: //'h' for hide
					if(this.active_level != null)
						active_level.toggleUneditableStrings();
					break;
					case 76: //'l' for copy layout
						if(this.active_level != null && !PipeJam3.RELEASE_BUILD)
						{
							active_level.updateLayoutXML();
							System.setClipboard(active_level.m_levelLayoutXMLWrapper.toString());
						}
						break;
					case 67: //'c' for copy constraints
						if(this.active_level != null && !PipeJam3.RELEASE_BUILD)
						{
							active_level.updateConstraintXML();
							System.setClipboard(active_level.m_levelConstraintsXMLWrapper.toString());
						}
						break;
				}
			}
		}
		
		protected function handleUndoRedoEvent(event:Event, isUndo:Boolean):void
		{
			if(event.data != null)
			{
				if(event.data is Array)
				{
					//added newest at the end, so start at the end
					for(var i:int = (event.data as Array).length-1; i>=0; i--)
					{
						var eventObj:Event = (event.data as Array)[i];
						handleUndoRedoEventObject(eventObj, isUndo);
					}
				}
				else
					handleUndoRedoEventObject(event, isUndo);
			}
			
			if(isUndo)
				redoStack.push(event);
			else
				undoStack.push(event);
		}
		
		protected function handleUndoRedoEventObject(event:Event, isUndo:Boolean):void
		{
			var data:Object = event.data;
			if(data == null) //handle locally
				handleUndoEvent(event, isUndo);
			if(event.data.target is String)
			{
				if((event.data.target as String) == "level")
				{
					if(this.active_level != null)
						active_level.handleUndoEvent(event, isUndo);
				}
			}
			else if(event.data.target is BaseComponent)
				(event.data.target as BaseComponent).handleUndoEvent(event, isUndo);
		}
		
		private function selectLevel(newLevel:Level):void
		{
			if (!newLevel) {
				return;
			}
			if (PipeJam3.logging) {
				var details:Object;
				if (active_level) {
					details = new Object();
					details[VerigameServerConstants.ACTION_PARAMETER_LEVEL_NAME] = active_level.original_level_name;
					PipeJam3.logging.logQuestEnd(VerigameServerConstants.VERIGAME_QUEST_ID_UNDEFINED_WORLD, details);
				}
				details = new Object();
				details[VerigameServerConstants.ACTION_PARAMETER_LEVEL_NAME] = newLevel.original_level_name;
				PipeJam3.logging.logQuestStart(VerigameServerConstants.VERIGAME_QUEST_ID_UNDEFINED_WORLD, details);
			}
			active_level = newLevel;
			newLevel.start();
			edgeSetGraphViewPanel.loadLevel(newLevel);
			gameControlPanel.newLevelSelected(newLevel);
			trace("gcp: " + gameControlPanel.width + " x " + gameControlPanel.height);
			trace("vp: " + edgeSetGraphViewPanel.width + " x " + edgeSetGraphViewPanel.height);
			
			dispatchEvent(new Event(Game.STOP_BUSY_ANIMATION,true));
		}
		
		private function onRemovedFromStage():void
		{
			AudioManager.getInstance().audioDriver().reset();
			
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
