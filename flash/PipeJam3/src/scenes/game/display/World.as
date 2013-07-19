package scenes.game.display
{
	import assets.AssetsAudio;
	
	import audio.AudioManager;
	
	import events.EdgeSetChangeEvent;
	import events.ErrorEvent;
	import events.GameComponentEvent;
	import events.MenuEvent;
	import events.MoveEvent;
	import events.NavigationEvent;
	import events.UndoEvent;
	
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.system.System;
	
	import graph.LevelNodes;
	import graph.Network;
	import graph.Node;
	
	import networking.LoginHelper;
	
	import scenes.BaseComponent;
	import scenes.game.PipeJamGameScene;
	import scenes.game.components.GameControlPanel;
	import scenes.game.components.GridViewPanel;
	import scenes.game.components.dialogs.InGameMenuDialog;
	
	import starling.animation.Juggler;
	import starling.animation.Transitions;
	import starling.core.Starling;
	import starling.display.DisplayObjectContainer;
	import starling.events.Event;
	import starling.events.KeyboardEvent;
	
	import system.PipeSimulator;
	import system.VerigameServerConstants;
	
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
		
		protected var undoStack:Vector.<UndoEvent>;
		protected var redoStack:Vector.<UndoEvent>;
		
		private var m_layoutXML:XML;
		private var m_constraintsXML:XML;
		
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
			
			undoStack = new Vector.<UndoEvent>();
			redoStack = new Vector.<UndoEvent>();
			
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
				if(LoginHelper.levelObject is int)
					currentLevelNumber = LoginHelper.levelObject as int;
				else
					currentLevelNumber = PipeJamGameScene.maxTutorialLevelCompleted;
				var levelNumberToUse:Number = XMath.clamp(currentLevelNumber, 0, levels.length - 1);
				firstLevel = levels[levelNumberToUse];
			}
			
			selectLevel(firstLevel);
			
			addEventListener(EdgeSetChangeEvent.LEVEL_EDGE_SET_CHANGED, onEdgeSetChange);
			addEventListener(GameComponentEvent.CENTER_ON_COMPONENT, onCenterOnComponentEvent);
			addEventListener(NavigationEvent.SHOW_GAME_MENU, onShowGameMenuEvent);
			addEventListener(NavigationEvent.START_OVER, onLevelStartOver);
			addEventListener(NavigationEvent.SWITCH_TO_NEXT_LEVEL, onNextLevel);
			
			addEventListener(MenuEvent.SAVE_LAYOUT, onSaveLayoutFile);
			addEventListener(MenuEvent.SUBMIT_SCORE, onSubmitScore);
			addEventListener(MenuEvent.SAVE_LOCALLY, onSaveLocally);
			addEventListener(MenuEvent.SET_NEW_LAYOUT, setNewLayout);
			addEventListener(MenuEvent.ZOOM_IN, onZoomIn);
			addEventListener(MenuEvent.ZOOM_OUT, onZoomOut);
			addEventListener(MenuEvent.RECENTER, onRecenter);
			
			stage.addEventListener(KeyboardEvent.KEY_UP, handleKeyUp);
			addEventListener(UndoEvent.UNDO_EVENT, saveEvent);
			
			addEventListener(ErrorEvent.ERROR_ADDED, onErrorAdded);
			addEventListener(ErrorEvent.ERROR_REMOVED, onErrorRemoved);
			addEventListener(ErrorEvent.ERROR_MOVED, onErrorMoved);
			addEventListener(MoveEvent.MOVE_TO_POINT, onMoveToPointEvent);
			
			AudioManager.getInstance().audioDriver().reset();
			AudioManager.getInstance().audioDriver().playMusic(AssetsAudio.MUSIC_FIELD_SONG);
		}
		
		private function onShowGameMenuEvent(evt:NavigationEvent):void
		{
			if(evt.menuShowing)
			{
				if(inGameMenuBox == null)
				{
					inGameMenuBox = new InGameMenuDialog();
					addChild(inGameMenuBox);
					inGameMenuBox.x = 0;
					//add clip rect so box seems to slide up out of the gameControlPanel
					inGameMenuBox.clipRect = new Rectangle(0,gameControlPanel.y - inGameMenuBox.height, inGameMenuBox.width, inGameMenuBox.height);
				}
				inGameMenuBox.y = gameControlPanel.y;
				inGameMenuBox.visible = true;
				var juggler:Juggler = Starling.juggler;
				juggler.tween(inGameMenuBox, 1.0, {
					transition: Transitions.EASE_IN_OUT,
					y: gameControlPanel.y - inGameMenuBox.height // -> tween.animate("x", 50)
				});
 
			}
			else
				inGameMenuBox.onBackToGameButtonTriggered();
				
		}
		
		public function onSaveLayoutFile(event:MenuEvent):void
		{
			if(active_level != null) {
				active_level.onSaveLayoutFile(event);
				if (PipeJam3.logging) {
					var details:Object = new Object();
					details[VerigameServerConstants.ACTION_PARAMETER_LEVEL_NAME] = active_level.original_level_name; // yes, we can get this from the quest data but include it here for convenience
					details[VerigameServerConstants.ACTION_PARAMETER_LAYOUT_NAME] = event.layoutName;
					PipeJam3.logging.logQuestAction(VerigameServerConstants.VERIGAME_ACTION_SAVE_LAYOUT, details, active_level.getTimeMs());
				}
			}
		}
		
		public function onSubmitScore(event:MenuEvent):void
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
		
		public function onSaveLocally(event:MenuEvent):void
		{
			if(active_level != null)
				active_level.onSaveLocally(event);
		}
		
		public function setNewLayout(event:MenuEvent):void
		{
			if(active_level != null) {
				active_level.setNewLayout(event.layoutXML, true);
				if (PipeJam3.logging) {
					var details:Object = new Object();
					details[VerigameServerConstants.ACTION_PARAMETER_LEVEL_NAME] = active_level.original_level_name; // yes, we can get this from the quest data but include it here for convenience
					details[VerigameServerConstants.ACTION_PARAMETER_LAYOUT_NAME] = event.layoutXML.@id;
					PipeJam3.logging.logQuestAction(VerigameServerConstants.VERIGAME_ACTION_LOAD_LAYOUT, details, active_level.getTimeMs());
				}
			}
		}

		public function onZoomIn(event:MenuEvent):void
		{
			edgeSetGraphViewPanel.zoomInDiscrete();
		}
		
		public function onZoomOut(event:MenuEvent):void
		{
			edgeSetGraphViewPanel.zoomOutDiscrete();
		}
		
		public function onRecenter(event:MenuEvent):void
		{
			edgeSetGraphViewPanel.recenter();
		}
		
		private function onEdgeSetChange(evt:EdgeSetChangeEvent):void
		{
			m_simulator.updateOnBoxSizeChange(evt.edgeSetChanged.m_id, evt.level.level_name);
			var oldScore:int = gameControlPanel.getCurrentScore();
			var newScore:int = gameControlPanel.updateScore(evt.level, false);
			if (newScore >= evt.level.getTargetScore()) {
				edgeSetGraphViewPanel.displayContinueButton(true);
			} else {
				edgeSetGraphViewPanel.hideContinueButton();
			}
			if (evt.point) {
				if (oldScore != newScore) {
					var thisPt:Point = globalToLocal(evt.point);
					TextPopup.popupText(this, thisPt, (newScore > oldScore ? "+" : "") + (newScore - oldScore).toString(), newScore > oldScore ? 0x99FF99 : 0xFF9999);
				}
			}
			if (!evt.silent && PipeJam3.logging) {
				var details:Object = new Object();
				details[VerigameServerConstants.ACTION_PARAMETER_EDGESET_ID] = evt.edgeSetChanged.m_id;
				details[VerigameServerConstants.ACTION_PARAMETER_EDGESET_WIDTH] = evt.edgeSetChanged.isWide() ? VerigameServerConstants.ACTION_VALUE_EDGE_WIDTH_WIDE : VerigameServerConstants.ACTION_VALUE_EDGE_WIDTH_NARROW;
				PipeJam3.logging.logQuestAction(VerigameServerConstants.VERIGAME_ACTION_CHANGE_EDGESET_WIDTH, details, evt.level.getTimeMs());
			}
		}
		
		private function onCenterOnComponentEvent(evt:GameComponentEvent):void
		{
			var component:GameComponent = evt.component;
			if(component)
			{
				edgeSetGraphViewPanel.centerOnComponent(component);
			}
		}
		
		private function onLevelStartOver(evt:NavigationEvent):void
		{
			var callback:Function =
				function():void
				{
					selectLevel(levels[currentLevelNumber], true);
				};
			dispatchEvent(new NavigationEvent(NavigationEvent.FADE_SCREEN, "", false, callback));
		}
		
		private function onNextLevel(evt:NavigationEvent):void
		{
			if(PipeJamGameScene.inTutorial)
			{
				if (evt.menuShowing && active_level) {
					// If using in-menu "Next Level" debug button, mark the current level as complete in order to move on
					PipeJamGameScene.solvedTutorialLevel(active_level.m_tutorialTag);
				}
				if(LoginHelper.levelObject is int)
				{
					if(currentLevelNumber != LoginHelper.levelObject as int) //first time through I'm supposing these are different
						currentLevelNumber = LoginHelper.levelObject as int;
					else
					{
						currentLevelNumber++;
						LoginHelper.levelObject = int(currentLevelNumber);
						if(currentLevelNumber > PipeJamGameScene.maxTutorialLevelCompleted)
							PipeJamGameScene.maxTutorialLevelCompleted = currentLevelNumber;
					}
				}
				else
					currentLevelNumber = PipeJamGameScene.maxTutorialLevelCompleted;
				if(currentLevelNumber >= levels.length)
				{
					dispatchEvent(new NavigationEvent(NavigationEvent.CHANGE_SCREEN, "SplashScreen"));
					return;
				}
			}
			else
				currentLevelNumber = (currentLevelNumber + 1) % levels.length;
			var callback:Function =
				function():void
				{
					selectLevel(levels[currentLevelNumber]);
				};
			dispatchEvent(new NavigationEvent(NavigationEvent.FADE_SCREEN, "", false, callback));
		}
		
		public function onErrorAdded(event:ErrorEvent):void
		{
			gameControlPanel.errorAdded(event.errorParticleSystem, active_level);
		}
		
		public function onErrorRemoved(event:ErrorEvent):void
		{
			gameControlPanel.errorRemoved(event.errorParticleSystem);
		}
		
		public function onErrorMoved(event:ErrorEvent):void
		{
			gameControlPanel.errorMoved(event.errorParticleSystem);
		}
		
		private function onMoveToPointEvent(evt:MoveEvent):void
		{
			edgeSetGraphViewPanel.moveToPoint(evt.startLoc);
		}
		
		private function saveEvent(evt:UndoEvent):void
		{
			if (evt.eventsToUndo.length == 0) {
				return;
			}
			//sometimes we need to remove the last event to add a complex event that includes that one
			//addToLastSimilar adds to the last event if they are of the same type (i.e. successive mouse wheel events should all undo at the same time)
			//addToLast adds to last event in any case (undo move node event also should put edges back where they were)
			var lastEvent:UndoEvent;
			if(evt.addToSimilar)
			{
				lastEvent = undoStack.pop();
				if(lastEvent && (lastEvent.eventsToUndo.length > 0))
				{
					if(lastEvent.eventsToUndo[0].type == evt.eventsToUndo[0].type)
					{
						// Add these to end of lastEvent's list of events to undo
						lastEvent.eventsToUndo = lastEvent.eventsToUndo.concat(evt.eventsToUndo);
					}
					else //no match, just push, adding back lastEvent also
					{
						undoStack.push(lastEvent);
						undoStack.push(evt);
					}
				}
				else
					undoStack.push(evt);
			}
			else if(evt.addToLast)
			{
				lastEvent = undoStack.pop();
				if(lastEvent)
				{
					// Add these to end of lastEvent's list of events to undo
					lastEvent.eventsToUndo = lastEvent.eventsToUndo.concat(evt.eventsToUndo);
				}
				else
					undoStack.push(evt);
			}
			else
				undoStack.push(evt);
			//when we build on the undoStack, clear out the redoStack
			redoStack = new Vector.<UndoEvent>();
		}
		
		public function handleKeyUp(event:starling.events.KeyboardEvent):void
		{
			if(event.ctrlKey)
			{
				switch(event.keyCode)
				{
					case 90: //'z'
					{
						if ((undoStack.length > 0) && !PipeJam3.RELEASE_BUILD)//high risk item, don't allow undo/redo until well tested
						{
							var undoDataEvent:UndoEvent = undoStack.pop();
							handleUndoRedoEvent(undoDataEvent, true);
						}
						break;
					}
					case 82: //'r'
					case 89: //'y'
					{
						if ((redoStack.length > 0) && !PipeJam3.RELEASE_BUILD)//high risk item, don't allow undo/redo until well tested
						{
							var redoDataEvent:UndoEvent = redoStack.pop();
							handleUndoRedoEvent(redoDataEvent, false);
						}
						break;
					}
					case 72: //'h' for hide
					if ((this.active_level != null) && !PipeJam3.RELEASE_BUILD)
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
		
		protected function handleUndoRedoEvent(event:UndoEvent, isUndo:Boolean):void
		{
			//added newest at the end, so start at the end
			for(var i:int = event.eventsToUndo.length-1; i>=0; i--)
			{
				var eventObj:Event = event.eventsToUndo[i];
				handleUndoRedoEventObject(eventObj, isUndo, event.levelEvent, event.component);
			}
			if(isUndo)
				redoStack.push(event);
			else
				undoStack.push(event);
		}
		
		protected function handleUndoRedoEventObject(evt:Event, isUndo:Boolean, levelEvent:Boolean, component:BaseComponent):void
		{
			if (active_level && levelEvent)
			{
				active_level.handleUndoEvent(evt, isUndo);
			}
			else if (component)
			{
				component.handleUndoEvent(evt, isUndo);
			}
		}
		
		private function selectLevel(newLevel:Level, restart:Boolean = false):void
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
			if (restart) {
				newLevel.restart();
			} else if (active_level) {
				active_level.dispose();
			}
			
			active_level = newLevel;
			newLevel.start();
			edgeSetGraphViewPanel.loadLevel(newLevel);
			gameControlPanel.newLevelSelected(newLevel);
			dispatchEvent(new Event(Game.STOP_BUSY_ANIMATION,true));
		}
		
		private function onRemovedFromStage():void
		{
			AudioManager.getInstance().audioDriver().reset();
			
			removeEventListener(GameComponentEvent.CENTER_ON_COMPONENT, onCenterOnComponentEvent);
			removeEventListener(EdgeSetChangeEvent.LEVEL_EDGE_SET_CHANGED, onEdgeSetChange);
			removeEventListener(NavigationEvent.SHOW_GAME_MENU, onShowGameMenuEvent);
			removeEventListener(NavigationEvent.SWITCH_TO_NEXT_LEVEL, onNextLevel);
			
			removeEventListener(MenuEvent.SAVE_LAYOUT, onSaveLayoutFile);
			removeEventListener(MenuEvent.SUBMIT_SCORE, onSubmitScore);
			removeEventListener(MenuEvent.SAVE_LOCALLY, onSaveLocally);
			removeEventListener(MenuEvent.SET_NEW_LAYOUT, setNewLayout);	
			removeEventListener(UndoEvent.UNDO_EVENT, saveEvent);
			removeEventListener(MenuEvent.ZOOM_IN, onZoomIn);
			removeEventListener(MenuEvent.ZOOM_OUT, onZoomOut);
			removeEventListener(MenuEvent.RECENTER, onRecenter);
			
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
