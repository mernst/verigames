package scenes.game.display
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.PixelSnapping;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.system.System;
	import flash.utils.ByteArray;
	import flash.utils.Dictionary;
	
	import assets.AssetsAudio;
	
	import audio.AudioManager;
	
	import constraints.ConstraintGraph;
	
	import dialogs.InGameMenuDialog;
	import dialogs.SaveDialog;
	import dialogs.SimpleAlertDialog;
	import dialogs.SubmitLevelDialog;
	
	import display.NineSliceBatch;
	import display.TextBubble;
	import display.ToolTipText;
	
	import events.ConflictChangeEvent;
	import events.ErrorEvent;
	import events.GameComponentEvent;
	import events.MenuEvent;
	import events.MiniMapEvent;
	import events.MoveEvent;
	import events.NavigationEvent;
	import events.ToolTipEvent;
	import events.UndoEvent;
	import events.WidgetChangeEvent;
	
	import networking.Achievements;
	import networking.GameFileHandler;
	import networking.PlayerValidation;
	import networking.TutorialController;
	
	import particle.ErrorParticleSystem;
	
	import scenes.BaseComponent;
	import scenes.game.PipeJamGameScene;
	import scenes.game.components.GameControlPanel;
	import scenes.game.components.GridViewPanel;
	import scenes.game.components.MiniMap;
	
	import starling.animation.Juggler;
	import starling.animation.Transitions;
	import starling.core.Starling;
	import starling.display.DisplayObject;
	import starling.display.DisplayObjectContainer;
	import starling.display.Image;
	import starling.events.EnterFrameEvent;
	import starling.events.Event;
	import starling.events.KeyboardEvent;
	import starling.textures.Texture;
	
	import system.Solver;
	import system.VerigameServerConstants;
	
	import utils.XMath;
	
	/**
	 * World that contains levels that each contain boards that each contain pipes
	 */
	public class World extends BaseComponent
	{
		protected var edgeSetGraphViewPanel:GridViewPanel;
		public var gameControlPanel:GameControlPanel;
		protected var miniMap:MiniMap;
		protected var inGameMenuBox:InGameMenuDialog;
		
		protected var shareDialog:SaveDialog;
		
		/** All the levels in this world */
		public var levels:Vector.<Level> = new Vector.<Level>();
		
		/** Current level being played by the user */
		public var active_level:Level = null;
		
		//shim to make it start with a level until we get servers up
		protected var firstLevel:Level = null;
		
		protected var m_currentLevelNumber:int;

		protected var undoStack:Vector.<UndoEvent>;
		protected var redoStack:Vector.<UndoEvent>;
		
		private var m_worldGraphDict:Dictionary;
		/** Original JSON used for this world */
		private var m_worldObj:Object;
		private var m_layoutObj:Object;
		private var m_assignmentsObj:Object;
		
		static public var m_world:World;
		private var m_activeToolTip:TextBubble;
		
		static protected var m_numWidgetsClicked:int = 0;
		
		public function World(_worldGraphDict:Dictionary, _worldObj:Object, _layout:Object, _assignments:Object)
		{
			m_worldGraphDict = _worldGraphDict;
			m_worldObj = _worldObj;
			m_layoutObj = _layout;
			m_assignmentsObj = _assignments;
			
			m_world = this;
			undoStack = new Vector.<UndoEvent>();
			redoStack = new Vector.<UndoEvent>();
			
			var allLevels:Array = m_worldObj["levels"];
			if (!allLevels) allLevels = [m_worldObj];
			trace("Creating World...");
			// create World
			for (var level_index:int = 0; level_index < allLevels.length; level_index++) {
				var levelObj:Object = allLevels[level_index];
				var levelName:String = levelObj["id"];
				var levelLayoutObj:Object = findLevelFile(levelName, m_layoutObj);
				var levelAssignmentsObj:Object = findLevelFile(levelName, m_assignmentsObj);
				// if we didn't find the level, assume this is a global constraints file
				if(levelAssignmentsObj == null) levelAssignmentsObj = m_assignmentsObj;
				
				var targetScore:int = int.MAX_VALUE;
				if ((levelAssignmentsObj["targetScore"] != undefined) && !isNaN(int(levelAssignmentsObj["targetScore"]))) {
					targetScore = int(levelAssignmentsObj["targetScore"]);
				}
				var levelNameFound:String = levelName;
				if (!PipeJamGameScene.inTutorial && PipeJamGame.levelInfo && PipeJamGame.levelInfo.name) {
					levelNameFound = PipeJamGame.levelInfo.name;
				}
				if (!m_worldGraphDict.hasOwnProperty(levelName)) {
					throw new Error("World level found without constriant graph:" + levelName);
				}
				var levelGraph:ConstraintGraph = m_worldGraphDict[levelName] as ConstraintGraph;
				var my_level:Level = new Level(levelName, levelGraph, levelObj, levelLayoutObj, levelAssignmentsObj, targetScore, levelNameFound);
				levels.push(my_level);
				
				if (!firstLevel) {
					firstLevel = my_level; //grab first one..
				}
			}
			trace("Done creating World...");
			addEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
			addEventListener(Event.REMOVED_FROM_STAGE, onRemovedFromStage);			
		}
		
		private var m_initQueue:Vector.<Function> = new Vector.<Function>();
		protected function onAddedToStage(event:Event):void
		{
			m_initQueue = new Vector.<Function>();
			m_initQueue.push(initGridViewPanel);
			m_initQueue.push(initGameControlPanel);
			m_initQueue.push(initMiniMap);
			m_initQueue.push(initScoring);
			m_initQueue.push(initTutorial);
			m_initQueue.push(initLevel);
			m_initQueue.push(initEventListeners);
			m_initQueue.push(initMusic);
			addEventListener(EnterFrameEvent.ENTER_FRAME, onEnterFrame);
		}
		
		protected function onEnterFrame(evt:EnterFrameEvent):void
		{
			if (m_initQueue.length > 0) {
				var func:Function = m_initQueue.shift();
				func.call();
			}
		}
		
		private function initGridViewPanel():void {
			trace("Initializing GridViewPanel...");
			edgeSetGraphViewPanel = new GridViewPanel(this);
			addChild(edgeSetGraphViewPanel);
			trace("Done initializing GridViewPanel.");
		}
		
		private function initGameControlPanel():void {
			trace("Initializing GameControlPanel...");
			gameControlPanel = new GameControlPanel();
			gameControlPanel.y = GridViewPanel.HEIGHT - GameControlPanel.OVERLAP;
			if (edgeSetGraphViewPanel.atMaxZoom()) {
				gameControlPanel.onMaxZoomReached();
			} else if (edgeSetGraphViewPanel.atMinZoom()) {
				gameControlPanel.onMinZoomReached();
			} else {
				gameControlPanel.onZoomReset();
			}
			addChild(gameControlPanel);
			setHighScores();
			trace("Done initializing GameControlPanel.");
		}
		
		private function initMiniMap():void {
			trace("Initializing Minimap....");
			miniMap = new MiniMap();
			miniMap.x = Constants.GameWidth - MiniMap.WIDTH;
			miniMap.y = MiniMap.HIDDEN_Y;
			edgeSetGraphViewPanel.addEventListener(MiniMapEvent.VIEWSPACE_CHANGED, miniMap.onViewspaceChanged);
			miniMap.visible = false;
			addChild(miniMap);
			trace("Done initializing Minimap.");
		}
		
		private function initScoring():void {
			trace("Initializing score...");
			onWidgetChange(); //update score
			trace("Done initializing score.");
		}
		
		private function initTutorial():void {
			trace("Initializing TutorialController...");
			if(PipeJamGameScene.inTutorial && levels && levels.length > 0)
			{
				var obj:Object = PipeJamGame.levelInfo;
				var tutorialController:TutorialController = TutorialController.getTutorialController();
				var nextLevelQID:int;
				if(!obj)
				{
					obj = new Object();
					PipeJamGame.levelInfo = obj;
					obj.tutorialLevelID = String(tutorialController.getFirstTutorialLevel());
					if(!tutorialController.isTutorialLevelCompleted(obj.tutorialLevelID))
						nextLevelQID = parseInt(obj.tutorialLevelID);
					else
						nextLevelQID = tutorialController.getNextUnplayedTutorial();
				}
				else
					nextLevelQID = parseInt(obj.tutorialLevelID);
				
				for each(var level:Level in levels)
				{
					if(level.m_levelQID == String(nextLevelQID))
					{
						firstLevel = level;
						obj.tutorialLevelID = String(nextLevelQID);
						break;
					}
				}
			}
			trace("Done initializing TutorialController.");
		}
		
		private function initLevel():void {
			trace("Initializing Level...");
			selectLevel(firstLevel);
			trace("Done initializing Level.");
		}
		
		private function initEventListeners():void {
			trace("Initializing event listeners...");
			addEventListener(Achievements.CLASH_CLEARED_ID, checkClashClearedEvent);
			addEventListener(WidgetChangeEvent.LEVEL_WIDGET_CHANGED, onWidgetChange);
			addEventListener(GameComponentEvent.CENTER_ON_COMPONENT, onCenterOnComponentEvent);
			addEventListener(NavigationEvent.SHOW_GAME_MENU, onShowGameMenuEvent);
			addEventListener(NavigationEvent.START_OVER, onLevelStartOver);
			addEventListener(NavigationEvent.SWITCH_TO_NEXT_LEVEL, onNextLevel);
			
			addEventListener(MenuEvent.POST_SAVE_DIALOG, postSaveDialog);
			addEventListener(MenuEvent.SAVE_LEVEL, onPutLevelInDatabase);
			addEventListener(MenuEvent.LEVEL_SAVED, onLevelUploadSuccess);
			
			addEventListener(MenuEvent.POST_SUBMIT_DIALOG, postSubmitDialog);
			addEventListener(MenuEvent.SUBMIT_LEVEL, onPutLevelInDatabase);
			addEventListener(MenuEvent.LEVEL_SUBMITTED, onLevelUploadSuccess);
			
			addEventListener(MenuEvent.SAVE_LAYOUT, onSaveLayoutFile);
			addEventListener(MenuEvent.LAYOUT_SAVED, onLevelUploadSuccess);
			
			addEventListener(MenuEvent.ACHIEVEMENT_ADDED, achievementAdded);
			addEventListener(MenuEvent.LOAD_BEST_SCORE, loadBestScore);
			addEventListener(MenuEvent.LOAD_HIGH_SCORE, loadHighScore);
			
			addEventListener(MenuEvent.SET_NEW_LAYOUT, setNewLayout);
			addEventListener(MenuEvent.ZOOM_IN, onZoomIn);
			addEventListener(MenuEvent.ZOOM_OUT, onZoomOut);
			addEventListener(MenuEvent.RECENTER, onRecenter);
			
			addEventListener(MenuEvent.MAX_ZOOM_REACHED, onMaxZoomReached);
			addEventListener(MenuEvent.MIN_ZOOM_REACHED, onMinZoomReached);
			addEventListener(MenuEvent.RESET_ZOOM, onZoomReset);
			
			addEventListener(MiniMapEvent.ERRORS_MOVED, onErrorsMoved);
			addEventListener(MiniMapEvent.VIEWSPACE_CHANGED, onViewspaceChanged);
			addEventListener(MiniMapEvent.LEVEL_RESIZED, onLevelResized);
			
			stage.addEventListener(KeyboardEvent.KEY_UP, handleKeyUp);
			addEventListener(UndoEvent.UNDO_EVENT, saveEvent);
			
			addEventListener(ErrorEvent.ERROR_ADDED, onErrorAdded);
			addEventListener(ErrorEvent.ERROR_REMOVED, onErrorRemoved);
			addEventListener(MoveEvent.MOVE_TO_POINT, onMoveToPointEvent);
			
			addEventListener(ToolTipEvent.ADD_TOOL_TIP, onToolTipAdded);
			addEventListener(ToolTipEvent.CLEAR_TOOL_TIP, onToolTipCleared);
			trace("Done initializing event listeners.");
		}
		
		private function initMusic():void {
			AudioManager.getInstance().reset();
			AudioManager.getInstance().playMusic(AssetsAudio.MUSIC_FIELD_SONG);
			trace("Playing music...");
		}
		
		private function onShowGameMenuEvent(evt:NavigationEvent):void
		{
			dispatchEvent(new NavigationEvent(NavigationEvent.CHANGE_SCREEN, "LevelSelectScene"));
			return;
			
			if (!gameControlPanel) return;
			var bottomMenuY:Number = gameControlPanel.y + GameControlPanel.OVERLAP + 5;
			var juggler:Juggler = Starling.juggler;
			var animateUp:Boolean = false;
			if(inGameMenuBox == null)
			{
				inGameMenuBox = new InGameMenuDialog();
				inGameMenuBox.x = 0;
				inGameMenuBox.y = bottomMenuY;
				var childIndex:int = numChildren - 1;
				if (gameControlPanel && gameControlPanel.parent == this) {
					childIndex = getChildIndex(gameControlPanel);
					trace("childindex:" + childIndex);
				} else {
					trace("not");
				}
				addChildAt(inGameMenuBox, childIndex);
				//add clip rect so box seems to slide up out of the gameControlPanel
				inGameMenuBox.clipRect = new Rectangle(0,gameControlPanel.y + GameControlPanel.OVERLAP - inGameMenuBox.height, inGameMenuBox.width, inGameMenuBox.height);
				animateUp = true;
			}
			else if (inGameMenuBox.visible && !inGameMenuBox.animatingDown)
				inGameMenuBox.onBackToGameButtonTriggered();
			else // animate up
			{
				animateUp = true;
			}
			if (animateUp) {
				if (!inGameMenuBox.visible) {
					inGameMenuBox.y = bottomMenuY;
					inGameMenuBox.visible = true;
				}
				juggler.removeTweens(inGameMenuBox);
				inGameMenuBox.animatingDown = false;
				inGameMenuBox.animatingUp = true;
				juggler.tween(inGameMenuBox, 1.0, {
					transition: Transitions.EASE_IN_OUT,
					y: bottomMenuY - inGameMenuBox.height, // -> tween.animate("x", 50)
					onComplete: function():void { if (inGameMenuBox) inGameMenuBox.animatingUp = false; }
				});
			}
			if (active_level) inGameMenuBox.setActiveLevelName(active_level.original_level_name);
		}
		
		public function onSaveLayoutFile(event:MenuEvent):void
		{
			if(active_level != null) {
				active_level.onSaveLayoutFile(event);
				if (PipeJam3.logging) {
					var details:Object = new Object();
					details[VerigameServerConstants.ACTION_PARAMETER_LEVEL_NAME] = active_level.original_level_name; // yes, we can get this from the quest data but include it here for convenience
					details[VerigameServerConstants.ACTION_PARAMETER_LAYOUT_NAME] = event.data.name;
					PipeJam3.logging.logQuestAction(VerigameServerConstants.VERIGAME_ACTION_SAVE_LAYOUT, details, active_level.getTimeMs());
				}
			}
		}
		
		protected function postSaveDialog(event:MenuEvent):void
		{
			if(shareDialog == null)
			{
				shareDialog = new SaveDialog(150, 100);
			}
			
			addChild(shareDialog);
		}
		
		protected function postSubmitDialog(event:MenuEvent):void
		{
			var submitLevelDialog:SubmitLevelDialog = new SubmitLevelDialog(150, 120);
			addChild(submitLevelDialog);
		}
		
		public function onPutLevelInDatabase(event:MenuEvent):void
		{
			//type:String, currentScore:int = event.type, currentScore
			if(active_level != null)
			{
				//update and collect all xml, and then bundle, zip, and upload
				var outputObj:Object = updateAssignments();
				active_level.updateLevelObj();
				
				var newAssignments:Object = active_level.m_levelAssignmentsObj;
				
				var zip:ByteArray = active_level.zipJsonFile(newAssignments, "assignments");
				var zipEncodedString:String = active_level.encodeBytes(zip);
				
				GameFileHandler.submitLevel(zipEncodedString, event.type, PipeJamGame.SEPARATE_FILES);	
				
				if (PipeJam3.logging) {
					var details:Object = new Object();
					details[VerigameServerConstants.ACTION_PARAMETER_LEVEL_NAME] = active_level.original_level_name; // yes, we can get this from the quest data but include it here for convenience
					details[VerigameServerConstants.ACTION_PARAMETER_SCORE] = active_level.currentScore;
					PipeJam3.logging.logQuestAction(VerigameServerConstants.VERIGAME_ACTION_SUBMIT_SCORE, details, active_level.getTimeMs());
				}
			}
			
			if(PipeJamGame.levelInfo.shareWithGroup == 1)
			{
				Achievements.checkAchievements(Achievements.SHARED_WITH_GROUP_ID, 0);
			}
		}
		
		public function onLevelUploadSuccess(event:MenuEvent):void
		{
			var dialogText:String;
			var dialogWidth:Number = 160;
			var dialogHeight:Number = 80;
			var socialText:String = "";
			var numLinesInText:int = 1;
			var callbackFunction:Function = null;
			
			if(event.type == MenuEvent.LEVEL_SAVED)
			{
				dialogText = "Level Saved.";
			}
			else if(event.type == MenuEvent.LAYOUT_SAVED)
			{
				dialogText = "Layout Saved.";
				callbackFunction = reportSavedLayoutAchievement;
			}
			else //MenuEvent.LEVEL_SUBMITTED
			{
				dialogText = "Level Submitted!";
			//	socialText = "I just finished a level!"; wait till social integration library
			//	dialogHeight = 130;
				callbackFunction = reportSubmitAchievement;
			}
			
			var alert:SimpleAlertDialog = new SimpleAlertDialog(dialogText, dialogWidth, dialogHeight, socialText, callbackFunction, numLinesInText);
			addChild(alert);
		}
		
		public function reportSubmitAchievement():void
		{
			Achievements.checkAchievements(MenuEvent.LEVEL_SUBMITTED, 0);
			
			if(PipeJamGame.levelInfo.layoutUpdated)
				Achievements.checkAchievements(MenuEvent.SET_NEW_LAYOUT, 0);
		}
		
		public function reportSavedLayoutAchievement():void
		{
			Achievements.checkAchievements(MenuEvent.SAVE_LAYOUT, 0);
		}
		
		public function achievementAdded(event:MenuEvent):void
		{
			var achievement:Achievements = event.data as Achievements;
			var dialogText:String = achievement.m_message;
			var achievementID:String = achievement.m_id;
			var dialogWidth:Number = 160;
			var dialogHeight:Number = 60;
			var socialText:String = "";
			
			var alert:SimpleAlertDialog;
			if(achievementID == Achievements.TUTORIAL_FINISHED_ID)
				alert = new SimpleAlertDialog(dialogText, dialogWidth, dialogHeight, socialText, switchToLevelSelect);
			else
				alert = new SimpleAlertDialog(dialogText, dialogWidth, dialogHeight, socialText, null);
			addChild(alert);
		}
		
		private function checkClashClearedEvent():void
		{
			if(active_level && active_level.m_targetScore != 0)
				Achievements.checkAchievements(Achievements.CLASH_CLEARED_ID, 0);
		}
		
		private function loadBestScore(event:MenuEvent):void
		{
			if (active_level) active_level.loadBestScoringConfiguration();
		}
		
		private function loadHighScore(event:MenuEvent):void
		{
			var highScoreAssignmentsID:String = PipeJamGame.levelInfo.highScores[0].assignmentsID;
			GameFileHandler.getFileByID(highScoreAssignmentsID, loadAssignmentsFile);
		}
		
		protected function loadAssignmentsFile(assignmentsObject:Object):void
		{
			if(active_level)
				active_level.loadAssignmentsConfiguration(assignmentsObject);
		}
		
		protected function switchToLevelSelect():void
		{
			dispatchEvent(new NavigationEvent(NavigationEvent.CHANGE_SCREEN, "LevelSelectScene"));
		}
		
		public function setNewLayout(event:MenuEvent):void
		{
			if(active_level != null && event.data.layoutFile) {
				active_level.setNewLayout(event.data.name, event.data.layoutFile, true);
				if (PipeJam3.logging) {
					var details:Object = new Object();
					details[VerigameServerConstants.ACTION_PARAMETER_LEVEL_NAME] = active_level.original_level_name; // yes, we can get this from the quest data but include it here for convenience
					details[VerigameServerConstants.ACTION_PARAMETER_LAYOUT_NAME] = event.data.layoutFile["id"];
					PipeJam3.logging.logQuestAction(VerigameServerConstants.VERIGAME_ACTION_LOAD_LAYOUT, details, active_level.getTimeMs());
				}
				PipeJamGame.levelInfo.layoutUpdated = true;
			}
		}
		
		public function updateAssignments(currentLevelOnly:Boolean = false):Object
		{
			// TODO: think about this more, when do we update WORLD assignments? Real-time or in this method?
			if (currentLevelOnly) {
				if (active_level) return m_worldObj["levels"][active_level.name]["assignments"];
				return { };
			}
			return m_assignmentsObj;
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
		
		public function onMaxZoomReached(event:MenuEvent):void
		{
			if (gameControlPanel) gameControlPanel.onMaxZoomReached();
		}
		
		public function onMinZoomReached(event:MenuEvent):void
		{
			if (gameControlPanel) gameControlPanel.onMinZoomReached();
		}
		
		public function onZoomReset(event:MenuEvent):void
		{
			if (gameControlPanel) gameControlPanel.onZoomReset();
		}
		
		public function onErrorsMoved(event:MiniMapEvent):void
		{
			if (miniMap) miniMap.isDirty = true;
		}
		
		public function onLevelResized(event:MiniMapEvent):void
		{
			if (miniMap) miniMap.isDirty = true;
		}
		
		public function onViewspaceChanged(event:MiniMapEvent):void
		{
			miniMap.onViewspaceChanged(event);
		}
		
		public function onWidgetChange(evt:WidgetChangeEvent = null):void
		{
			var level_changed:Level = evt ? evt.level : active_level;
			if (miniMap && evt && evt.widgetChanged) miniMap.addWidget(evt.widgetChanged); // removes prev widget, adds new colored widget
			if (!level_changed) return;
			var nodeId:String = "";
			if (evt && evt.widgetChanged && evt.widgetChanged.constraintVar) nodeId = evt.widgetChanged.constraintVar.id;
			level_changed.updateScore(true);
			gameControlPanel.updateScore(level_changed, false);
			var oldScore:int = level_changed.prevScore;
			var newScore:int = level_changed.currentScore;
			if (evt && !evt.silent) {
				// TODO: Fanfare for non-tutorial levels? We may want to encourage the players to keep optimizing
				if (newScore >= level_changed.getTargetScore()) {
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
				if (PipeJam3.logging) {
					var details:Object = new Object();
					if (evt.widgetChanged && evt.widgetChanged.constraintVar)
						details[VerigameServerConstants.ACTION_PARAMETER_VAR_ID] = evt.widgetChanged.constraintVar.id;
					details[VerigameServerConstants.ACTION_PARAMETER_PROP_CHANGED] = evt.prop;
					details[VerigameServerConstants.ACTION_PARAMETER_PROP_VALUE] = evt.propValue.toString();
					PipeJam3.logging.logQuestAction(VerigameServerConstants.VERIGAME_ACTION_CHANGE_EDGESET_WIDTH, details, level_changed.getTimeMs());
				}
			}
			
			if(!PipeJamGameScene.inTutorial && evt && !evt.silent)
			{
				m_numWidgetsClicked++;
				if(m_numWidgetsClicked == 1 || m_numWidgetsClicked == 50)
					Achievements.checkAchievements(evt.type, m_numWidgetsClicked);
				
				//beat the target score?
				if(newScore  > level_changed.getTargetScore())
				{
					
					Achievements.checkAchievements(Achievements.BEAT_THE_TARGET_ID, 0);
				}
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
			var level:Level = active_level;
			if (PipeJamGame.levelInfo != null) {
				var currentLevelID:String = PipeJamGame.levelInfo.RaLevelID;
				//find the level with the current ID
				for each(level in levels)
				{
					if(level.m_levelQID == currentLevelID)
						break;
				}
			}
			var callback:Function =
				function():void
				{
					selectLevel(level, true);
				};
			
			dispatchEvent(new NavigationEvent(NavigationEvent.FADE_SCREEN, "", false, callback));
		}
		
		private function onNextLevel(evt:NavigationEvent):void
		{
			var prevLevelNumber:Number = parseInt(PipeJamGame.levelInfo.RaLevelID);
			if(PipeJamGameScene.inTutorial)
			{
				var tutorialController:TutorialController = TutorialController.getTutorialController();
				if (evt.menuShowing && active_level) {
					// If using in-menu "Next Level" debug button, mark the current level as complete in order to move on. Don't mark as completed
					tutorialController.addCompletedTutorial(active_level.m_tutorialTag, false);
				}
				
				//should check if we are from the level select screen...
				var tutorialsDone:Boolean = tutorialController.isTutorialDone();
				//if there are no more unplayed levels, check next if we are in levelselect screen choice
				if(tutorialsDone == true && tutorialController.fromLevelSelectList)
				{
					//and if so, set to false, unless at the end of the tutorials
					var currentLevelId:int = tutorialController.getNextUnplayedTutorial();
					if(currentLevelId != 0)
						tutorialsDone = false;
					
				}
				
				//if this is the first time we've completed these, post the achievement, else just move on
				if(tutorialsDone)
				{
					if(Achievements.isAchievementNew(Achievements.TUTORIAL_FINISHED_ID) && PlayerValidation.playerLoggedIn)
						Achievements.addAchievement(Achievements.TUTORIAL_FINISHED_ID, Achievements.TUTORIAL_FINISHED_STRING);
					else
						switchToLevelSelect();
					return;
				}
				else
				{
					//get the next level to show, set the levelID, and currentLevelNumber
					var obj:Object = PipeJamGame.levelInfo;
					obj.tutorialLevelID = String(tutorialController.getNextUnplayedTutorial());
					
					m_currentLevelNumber = 0;
					for each(var level:Level in levels)
					{
						if(level.m_levelQID == obj.tutorialLevelID)
							break;
						
						m_currentLevelNumber++;
					}
					m_currentLevelNumber = m_currentLevelNumber % levels.length;
				}
			}
			else {
				m_currentLevelNumber = (m_currentLevelNumber + 1) % levels.length;
				updateAssignments(); // save world progress
			}
			var callback:Function =
				function():void
				{
					selectLevel(levels[m_currentLevelNumber], m_currentLevelNumber == prevLevelNumber);
				};
			dispatchEvent(new NavigationEvent(NavigationEvent.FADE_SCREEN, "", false, callback));
		}
		
		public function onErrorAdded(event:ErrorEvent):void
		{
			if (miniMap) miniMap.errorAdded(event.errorParticleSystem);
		}
		
		public function onErrorRemoved(event:ErrorEvent):void
		{
			if (miniMap) miniMap.errorRemoved(event.errorParticleSystem);
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
						if(this.active_level != null)// && !PipeJam3.RELEASE_BUILD)
						{
							active_level.updateLayoutObj(this);
							System.setClipboard(JSON.stringify(active_level.m_levelLayoutObjWrapper));
						}
						break;
					case 66: //'b' for load Best scoring config
						if(this.active_level != null)// && !PipeJam3.RELEASE_BUILD)
						{
							active_level.loadBestScoringConfiguration();
						}
						break;
					case 67: //'c' for copy constraints
						if(this.active_level != null && !PipeJam3.RELEASE_BUILD)
						{
							active_level.updateAssignmentsObj();
							System.setClipboard(JSON.stringify(active_level.m_levelAssignmentsObj));
						}
						break;
					case 65: //'a' for copy of ALL (world)
						if(this.active_level != null && !PipeJam3.RELEASE_BUILD)
						{
							var worldObj:Object = updateAssignments();
							System.setClipboard(JSON.stringify(worldObj));
						}
						break;
					case 88: //'x' for copy of level
						if(this.active_level != null && !PipeJam3.RELEASE_BUILD)
						{
							var levelObj:Object = updateAssignments(true);
							System.setClipboard(JSON.stringify(levelObj));
						}
						break;
				}
			}
		}
		
		public function getThumbnail(_maxwidth:Number, _maxheight:Number):ByteArray
		{
			return edgeSetGraphViewPanel.getThumbnail(_maxwidth, _maxheight);
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
		
		protected function selectLevel(newLevel:Level, restart:Boolean = false):void
		{
			if (!newLevel) {
				return;
			}
			
			if (PipeJam3.logging) {
				var details:Object, qid:int;
				if (active_level) {
					details = new Object();
					details[VerigameServerConstants.ACTION_PARAMETER_LEVEL_NAME] = active_level.original_level_name;
					qid = (active_level.levelGraph.qid == -1) ? VerigameServerConstants.VERIGAME_QUEST_ID_UNDEFINED_WORLD : active_level.levelGraph.qid;
					//if (PipeJamGame.levelInfo) {
					//	details[VerigameServerConstants.QUEST_PARAMETER_LEVEL_INFO] = PipeJamGame.levelInfo.createLevelObject();
					//}
					PipeJam3.logging.logQuestEnd(qid, details);
				}
				details = new Object();
				details[VerigameServerConstants.ACTION_PARAMETER_LEVEL_NAME] = newLevel.original_level_name;
				if (PipeJamGame.levelInfo) {
					details[VerigameServerConstants.QUEST_PARAMETER_LEVEL_INFO] = PipeJamGame.levelInfo.createLevelObject();
				}
				qid = (newLevel.levelGraph.qid == -1) ? VerigameServerConstants.VERIGAME_QUEST_ID_UNDEFINED_WORLD : newLevel.levelGraph.qid;
				PipeJam3.logging.logQuestStart(qid, details);
			}
			if (restart) {
				newLevel.restart();
			} else if (active_level) {
				active_level.dispose();
			}
			
			if (m_activeToolTip) {
				m_activeToolTip.removeFromParent(true);
				m_activeToolTip = null;
			}
			
			active_level = newLevel;
			
			if (newLevel.tutorialManager) {
				miniMap.visible = newLevel.tutorialManager.getMiniMapShown();
			} else {
				miniMap.visible = true;
			}
			
			if (inGameMenuBox) inGameMenuBox.setActiveLevelName(active_level.original_level_name);
			
			newLevel.initialize();
			
			onWidgetChange();
			edgeSetGraphViewPanel.loadLevel(newLevel);
			if (edgeSetGraphViewPanel.atMaxZoom()) {
				gameControlPanel.onMaxZoomReached();
			} else if (edgeSetGraphViewPanel.atMinZoom()) {
				gameControlPanel.onMinZoomReached();
			} else {
				gameControlPanel.onZoomReset();
			}
			newLevel.start();
			newLevel.updateScore();
			
			var startTime:Number = new Date().getTime();
			var isTutorialLevel:Boolean = (active_level.m_tutorialTag && active_level.m_tutorialTag.length);
			if (!isTutorialLevel && (active_level.getTargetScore() == int.MAX_VALUE)) {
				var newTarget:int = Solver.getInstance().findTargetScore(active_level);
				active_level.setTargetScore(newTarget);
				if(PipeJamGame.levelInfo != null) PipeJamGame.levelInfo.targetScore = newTarget;
				active_level.updateScore();
			}
			
			trace("Solver ran in " + (new Date().getTime() / 1000 - startTime / 1000) + " sec");
			active_level.resetBestScore();
			setHighScores();
			gameControlPanel.newLevelSelected(newLevel);
			miniMap.isDirty = true;
		}
		
		private function onRemovedFromStage():void
		{
			removeEventListener(EnterFrameEvent.ENTER_FRAME, onEnterFrame);
			AudioManager.getInstance().reset();
			
			if (m_activeToolTip) {
				m_activeToolTip.removeFromParent(true);
				m_activeToolTip = null;
			}
			
			removeEventListener(Achievements.CLASH_CLEARED_ID, checkClashClearedEvent);
			
			removeEventListener(GameComponentEvent.CENTER_ON_COMPONENT, onCenterOnComponentEvent);
			removeEventListener(WidgetChangeEvent.LEVEL_WIDGET_CHANGED, onWidgetChange);
			removeEventListener(NavigationEvent.SHOW_GAME_MENU, onShowGameMenuEvent);
			removeEventListener(NavigationEvent.SWITCH_TO_NEXT_LEVEL, onNextLevel);
			
			removeEventListener(MenuEvent.SAVE_LAYOUT, onSaveLayoutFile);
			removeEventListener(MenuEvent.LAYOUT_SAVED, onLevelUploadSuccess);
			
			removeEventListener(MenuEvent.SUBMIT_LEVEL, onPutLevelInDatabase);
			removeEventListener(MenuEvent.POST_SAVE_DIALOG, postSaveDialog);
			removeEventListener(MenuEvent.POST_SUBMIT_DIALOG, postSubmitDialog);
			removeEventListener(MenuEvent.SAVE_LEVEL, onPutLevelInDatabase);
			removeEventListener(MenuEvent.LEVEL_SUBMITTED, onLevelUploadSuccess);
			removeEventListener(MenuEvent.LEVEL_SAVED, onLevelUploadSuccess);
			removeEventListener(MenuEvent.ACHIEVEMENT_ADDED, achievementAdded);
			removeEventListener(MenuEvent.LOAD_BEST_SCORE, loadBestScore);
			removeEventListener(MenuEvent.LOAD_HIGH_SCORE, loadHighScore);
			
			removeEventListener(MenuEvent.SET_NEW_LAYOUT, setNewLayout);	
			removeEventListener(UndoEvent.UNDO_EVENT, saveEvent);
			removeEventListener(MenuEvent.ZOOM_IN, onZoomIn);
			removeEventListener(MenuEvent.ZOOM_OUT, onZoomOut);
			removeEventListener(MenuEvent.RECENTER, onRecenter);
			removeEventListener(MenuEvent.MAX_ZOOM_REACHED, onMaxZoomReached);
			removeEventListener(MenuEvent.MIN_ZOOM_REACHED, onMinZoomReached);
			removeEventListener(MenuEvent.RESET_ZOOM, onZoomReset);
			removeEventListener(MiniMapEvent.ERRORS_MOVED, onErrorsMoved);
			removeEventListener(MiniMapEvent.VIEWSPACE_CHANGED, onViewspaceChanged);
			removeEventListener(MiniMapEvent.LEVEL_RESIZED, onLevelResized);
			removeEventListener(ToolTipEvent.ADD_TOOL_TIP, onToolTipAdded);
			removeEventListener(ToolTipEvent.CLEAR_TOOL_TIP, onToolTipCleared);
			
			stage.removeEventListener(KeyboardEvent.KEY_UP, handleKeyUp);
			
			if(active_level)
				removeChild(active_level, true);
			m_worldObj = null;
			m_layoutObj = null;
		}
		
		public function findLevelFile(name:String, fileObj:Object):Object
		{
			var levels:Array = fileObj["levels"];
			if (!levels) return fileObj; // if no levels, assume global file
			for (var i:int = 0; i < levels.length; i++) {
				var levelName:String = levels[i]["id"];
				if (levelName == name) return levels[i];
			}
			return null;
		}
		
		public function hasDialogOpen():Boolean
		{
			if(inGameMenuBox && inGameMenuBox.visible)
				return true;
			else
				return false;
		}
		
		
		private function onToolTipAdded(evt:ToolTipEvent):void
		{
			if (evt.text && evt.text.length && evt.component && active_level && !m_activeToolTip) {
				function pointAt(lev:Level):DisplayObject {
					return evt.component;
				}
				var pointFrom:String = NineSliceBatch.TOP_LEFT;
				var onTop:Boolean = evt.point.y < 80;
				var onLeft:Boolean = evt.point.x < 80;
				if (onTop && onLeft) {
					// If in top left corner, move to bottom right
					pointFrom = NineSliceBatch.BOTTOM_RIGHT;
				} else if (onLeft) {
					// If on left, move to top right
					pointFrom = NineSliceBatch.TOP_RIGHT;
				} else if (onTop) {
					// If on top, move to bottom left
					pointFrom = NineSliceBatch.BOTTOM_LEFT;
				}
				m_activeToolTip = new ToolTipText(evt.text, active_level, false, pointAt, pointFrom);
				if (evt.point) m_activeToolTip.setGlobalToPoint(evt.point.clone());
				addChild(m_activeToolTip);
			}
		}
		
		private function onToolTipCleared(evt:ToolTipEvent):void
		{
			if (m_activeToolTip) m_activeToolTip.removeFromParent(true);
			m_activeToolTip = null;
		}
		
		public function setHighScores():void
		{
			gameControlPanel.setHighScores(PipeJamGame.levelInfo.highScores);
		}
	}
}
