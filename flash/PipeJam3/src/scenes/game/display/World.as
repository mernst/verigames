package scenes.game.display
{
	import assets.AssetsAudio;
	import events.MiniMapEvent;
	import particle.ErrorParticleSystem;
	import scenes.game.components.MiniMap;
	
	import audio.AudioManager;
	
	import dialogs.InGameMenuDialog;
	import dialogs.SaveDialog;
	import dialogs.SimpleAlertDialog;
	import dialogs.SubmitLevelDialog;
	
	import display.NineSliceBatch;
	import display.TextBubble;
	import display.ToolTipText;
	
	import events.ConflictChangeEvent;
	import events.EdgeSetChangeEvent;
	import events.ErrorEvent;
	import events.GameComponentEvent;
	import events.MenuEvent;
	import events.MoveEvent;
	import events.NavigationEvent;
	import events.ToolTipEvent;
	import events.UndoEvent;
	
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.PixelSnapping;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.system.System;
	import flash.utils.ByteArray;
	
	import graph.ConflictDictionary;
	import graph.Edge;
	import graph.EdgeSetRef;
	import graph.LevelNodes;
	import graph.Network;
	import graph.Node;
	import graph.Port;
	import graph.PropDictionary;
	
	import networking.*;
	
	import scenes.BaseComponent;
	import scenes.game.PipeJamGameScene;
	import scenes.game.components.GameControlPanel;
	import scenes.game.components.GridViewPanel;
	
	import starling.animation.Juggler;
	import starling.animation.Transitions;
	import starling.core.Starling;
	import starling.display.DisplayObject;
	import starling.display.DisplayObjectContainer;
	import starling.display.Image;
	import starling.events.Event;
	import starling.events.KeyboardEvent;
	import starling.textures.Texture;
	
	import system.PipeSimulator;
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
		
		static public var m_world:World;
		private var m_activeToolTip:TextBubble;
		
		static protected var m_numWidgetsClicked:int = 0;
		
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
			
			m_world = this;
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
				
				var targetScore:int = int.MAX_VALUE;
				if ((levelConstraintsXML.attribute("targetScore") != undefined) && !isNaN(int(levelConstraintsXML.attribute("targetScore")))) {
					targetScore = int(levelConstraintsXML.attribute("targetScore"));
				}
				var levelNameFound:String = my_levelNodes.original_level_name;
				if (!PipeJamGameScene.inTutorial && PipeJamGame.levelInfo && PipeJamGame.levelInfo.m_name) {
					levelNameFound = PipeJamGame.levelInfo.m_name;
				}
				var my_level:Level = new Level(my_level_name, my_levelNodes, levelLayoutXML, levelConstraintsXML, targetScore, levelNameFound);
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
			edgeSetGraphViewPanel = new GridViewPanel(this);
			addChild(edgeSetGraphViewPanel);
			
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
			
			miniMap = new MiniMap();
			miniMap.width = 100;
			miniMap.height = 80;
			miniMap.x = Constants.GameWidth - miniMap.width - 2;
			miniMap.y = 2;
			edgeSetGraphViewPanel.addEventListener(MiniMapEvent.VIEWSPACE_CHANGED, miniMap.onViewspaceChanged);
			addChild(miniMap);
			
			onEdgeSetChange(); //update score
			
			if(PipeJamGameScene.inTutorial && levels && levels.length > 0)
			{
				var obj:LevelInformation = PipeJamGame.levelInfo;
				var tutorialController:TutorialController = TutorialController.getTutorialController();
				var nextLevelQID:int;
				if(!obj)
				{
					obj = new LevelInformation();
					PipeJamGame.levelInfo = obj;
					obj.m_levelId = String(tutorialController.getFirstTutorialLevel());
					if(!tutorialController.isTutorialLevelCompleted(obj.m_levelId))
						nextLevelQID = parseInt(obj.m_levelId);
					else
						nextLevelQID = tutorialController.getNextUnplayedTutorial();
				}
				else
					nextLevelQID = parseInt(obj.m_levelId);
				
				for each(var level:Level in levels)
				{
					if(level.m_levelQID == String(nextLevelQID))
					{
						firstLevel = level;
						obj.m_levelId = String(nextLevelQID);
						break;
					}
				}
			}
			
			selectLevel(firstLevel);
			
			addEventListener(Achievements.CLASH_CLEARED_ID, checkClashClearedEvent);
			addEventListener(EdgeSetChangeEvent.LEVEL_EDGE_SET_CHANGED, onEdgeSetChange);
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
			
			addEventListener(MenuEvent.SET_NEW_LAYOUT, setNewLayout);
			addEventListener(MenuEvent.ZOOM_IN, onZoomIn);
			addEventListener(MenuEvent.ZOOM_OUT, onZoomOut);
			addEventListener(MenuEvent.RECENTER, onRecenter);
			
			addEventListener(MenuEvent.MAX_ZOOM_REACHED, onMaxZoomReached);
			addEventListener(MenuEvent.MIN_ZOOM_REACHED, onMinZoomReached);
			addEventListener(MenuEvent.RESET_ZOOM, onZoomReset);
			
			addEventListener(MiniMapEvent.ERRORS_MOVED, onErrorsMoved);
			addEventListener(MiniMapEvent.VIEWSPACE_CHANGED, onViewspaceChanged);
			
			stage.addEventListener(KeyboardEvent.KEY_UP, handleKeyUp);
			addEventListener(UndoEvent.UNDO_EVENT, saveEvent);
			
			addEventListener(ErrorEvent.ERROR_ADDED, onErrorAdded);
			addEventListener(ErrorEvent.ERROR_REMOVED, onErrorRemoved);
			addEventListener(MoveEvent.MOVE_TO_POINT, onMoveToPointEvent);
			
			addEventListener(ToolTipEvent.ADD_TOOL_TIP, onToolTipAdded);
			addEventListener(ToolTipEvent.CLEAR_TOOL_TIP, onToolTipCleared);
			
			AudioManager.getInstance().reset();
			AudioManager.getInstance().playMusic(AssetsAudio.MUSIC_FIELD_SONG);
		}
		
		private function onShowGameMenuEvent(evt:NavigationEvent):void
		{
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
			var submitLevelDialog:SubmitLevelDialog = new SubmitLevelDialog(150, 150);
			addChild(submitLevelDialog);
		}
		
		public function onPutLevelInDatabase(event:MenuEvent):void
		{
			//type:String, currentScore:int = event.type, currentScore
			if(active_level != null)
			{
				//update and collect all xml, and then bundle, zip, and upload
				var outputXML:XML = updateXML();
				active_level.updateLevelXML();
				
				var collectionXML:XML = <container version="1"/>;
				collectionXML.@qid = outputXML.qid;
				collectionXML.appendChild(active_level.m_levelLayoutXMLWrapper);
				collectionXML.appendChild(active_level.m_levelConstraintsXMLWrapper);
				collectionXML.appendChild(outputXML);
				
				var zip:ByteArray = active_level.zipXMLFile(collectionXML, "container");
				var zipEncodedString:String = active_level.encodeBytes(zip);
				
				GameFileHandler.submitLevel(zipEncodedString, event.type, PipeJamGame.ALL_IN_ONE);	
				
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
			else
			{
				dialogText = "Level Submitted!\n(You can access that level in the future\n from the saved level list.)";
				numLinesInText = 3;
				socialText = "I just finished a level!";
				dialogHeight = 130;
				callbackFunction = reportSubmitAchievement;
			}
			
			var alert:SimpleAlertDialog = new SimpleAlertDialog(dialogText, dialogWidth, dialogHeight, socialText, callbackFunction, numLinesInText);
			addChild(alert);
		}
		
		public function reportSubmitAchievement():void
		{
			Achievements.checkAchievements(MenuEvent.LEVEL_SUBMITTED, 0);
			
			if(PipeJamGame.levelInfo.m_layoutUpdated)
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
					details[VerigameServerConstants.ACTION_PARAMETER_LAYOUT_NAME] = event.data.layoutFile.@id;
					PipeJam3.logging.logQuestAction(VerigameServerConstants.VERIGAME_ACTION_LOAD_LAYOUT, details, active_level.getTimeMs());
				}
				PipeJamGame.levelInfo.m_layoutUpdated = true;
			}
		}
		
		/**
		 * Updates XML with edge information (widths, etc)
		 * @param	overwriteWorldXML: True to preserve changes across multiple levels and overwrite local XML, false to create new XML and return that
		 * @return Instance of current world XML if overwritten, new instance with new updates if not
		 */
		public function updateXML(overwriteWorldXML:Boolean = true, returnLevelXMLOnly:Boolean = false):XML {
			//update xml from original
			var output_xml:XML = overwriteWorldXML ? world_xml : new XML(world_xml);
			var activeLevelXML:XML;
			for each (var my_level:Level in levels) {
				// Find this level in XML
				if (my_level.levelNodes == null) {
					continue;
				}
				var my_level_xml_indx:int = -1;
				for (var level_indx:uint = 0; level_indx < output_xml["level"].length(); level_indx++) {
					if (output_xml["level"][level_indx].attribute("name").toString() == my_level.levelNodes.original_level_name) {
						my_level_xml_indx = level_indx;
						break;
					}
				}
				//found xml representation?
				if (my_level_xml_indx > -1) {
					//loop through all boards, find the edges. Update these with new buzzsaw and width info.
					for (var board_index:uint = 0; board_index < output_xml["level"][my_level_xml_indx]["boards"][0]["board"].length(); board_index++) {
						for (var edge_index:uint = 0; edge_index < output_xml["level"][my_level_xml_indx]["boards"][0]["board"][board_index]["edge"].length(); edge_index++) {
							var my_edge_id:String = output_xml["level"][my_level_xml_indx]["boards"][0]["board"][board_index]["edge"][edge_index].attribute("id").toString();
							var my_edge:Edge = my_level.levelNodes.getEdge(my_edge_id);
							if (my_edge) {
								var my_width:String = my_edge.linked_edge_set.getProps().hasProp(PropDictionary.PROP_NARROW) ? "narrow" : "wide";
								// For buzzsaw, only consider narrowness - no concept of a keyfor buzzsaw at this point
								var edgeHasJam:Boolean = my_edge.hasConflictProp(PropDictionary.PROP_NARROW);
								var portHasJam:Boolean = my_edge.to_port.hasConflictProp(PropDictionary.PROP_NARROW);
								output_xml["level"][my_level_xml_indx]["boards"][0]["board"][board_index]["edge"][edge_index].@width = my_width;
								output_xml["level"][my_level_xml_indx]["boards"][0]["board"][board_index]["edge"][edge_index].@buzzsaw = (edgeHasJam || portHasJam).toString();// classic: my_edge.has_buzzsaw.toString();
							} else {
								throw new Error("World.getUpdatedXML(): Edge pipe not found for edge id: " + my_edge_id);
							}
						}
					}
				} else {
					throw new Error("World.getUpdatedXML(): Level not found: " + my_level.level_name);
				}
				if ((m_network.world_version == "1") || (m_network.world_version == "2")) {
					//Update the xml with the stamp state information. Only update existing stamps, not adding new ones
					var edgeSetXML:XMLList = output_xml["level"][my_level_xml_indx]["linked-edges"][0]["edge-set"];
					var numEdgeSets:uint = edgeSetXML.length();
					for (var edgeSetIndex:uint = 0; edgeSetIndex<numEdgeSets; edgeSetIndex++) {
						var edgeSetID:String = edgeSetXML[edgeSetIndex].attribute("id").toString();
						if (my_level.levelNodes.edge_set_dictionary.hasOwnProperty(edgeSetID)) {
							var linkedEdgeSet:EdgeSetRef = my_level.levelNodes.edge_set_dictionary[edgeSetID] as EdgeSetRef;
							for (var stampIndex:uint = 0; stampIndex < edgeSetXML[edgeSetIndex]["stamp"].length(); stampIndex++) {
								var stampID:String = edgeSetXML[edgeSetIndex]["stamp"][stampIndex].@id;
								edgeSetXML[edgeSetIndex]["stamp"][stampIndex].@active = linkedEdgeSet.hasActiveStampOfEdgeSetId(stampID).toString();
							}
						}
					}
				} else {
					// TODO: stamp support not implemented in XML version 3
				}
				if (my_level == active_level) {
					activeLevelXML = output_xml["level"][my_level_xml_indx];
				}
			}	
			return returnLevelXMLOnly ? activeLevelXML : output_xml;
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
		
		public function onViewspaceChanged(event:MiniMapEvent):void
		{
			miniMap.onViewspaceChanged(event);
		}
		
		public function onEdgeSetChange(evt:EdgeSetChangeEvent = null):void
		{
			var level_changed:Level = evt ? evt.level : active_level;
			if (!level_changed) return;
			var edgeSetId:String = "";
			if (evt && evt.edgeSetChanged && evt.edgeSetChanged.m_edgeSet) edgeSetId = evt.edgeSetChanged.m_edgeSet.id;
			m_simulator.updateOnBoxSizeChange(edgeSetId, level_changed.level_name);
			level_changed.updateScore(true);
			gameControlPanel.updateScore(level_changed, false);
			if (evt && !evt.silent) {
				var oldScore:int = level_changed.prevScore;
				var newScore:int = level_changed.currentScore;
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
					if (evt.edgeSetChanged && evt.edgeSetChanged.m_edgeSet)
						details[VerigameServerConstants.ACTION_PARAMETER_EDGESET_ID] = evt.edgeSetChanged.m_edgeSet.id;
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
				var currentLevelID:String = PipeJamGame.levelInfo.m_levelId;
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
			var prevLevelNumber:Number = parseInt(PipeJamGame.levelInfo.m_levelId);
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
					if(Achievements.isAchievementNew(Achievements.TUTORIAL_FINISHED_ID))
						Achievements.addAchievement(Achievements.TUTORIAL_FINISHED_ID, Achievements.TUTORIAL_FINISHED_STRING);
					else
						switchToLevelSelect();
					return;
				}
				else
				{
					//get the next level to show, set the levelID, and currentLevelNumber
					var obj:LevelInformation = PipeJamGame.levelInfo;
					obj.m_levelId = String(tutorialController.getNextUnplayedTutorial());
					
					m_currentLevelNumber = 0;
					for each(var level:Level in levels)
					{
						if(level.m_levelQID == obj.m_levelId)
							break;
						
						m_currentLevelNumber++;
					}
					
				}
			}
			else {
				m_currentLevelNumber = (m_currentLevelNumber + 1) % levels.length;
				updateXML(); // save world progress
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
			miniMap.errorAdded(event.errorParticleSystem);
		}
		
		public function onErrorRemoved(event:ErrorEvent):void
		{
			miniMap.errorRemoved(event.errorParticleSystem);
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
							active_level.updateLayoutXML(this);
							System.setClipboard(active_level.m_levelLayoutXMLWrapper.toString());
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
							active_level.updateConstraintXML();
							System.setClipboard(active_level.m_levelConstraintsXMLWrapper.toString());
						}
						break;
					case 65: //'a' for copy of ALL (world) xml
						if(this.active_level != null && !PipeJam3.RELEASE_BUILD)
						{
							var outputXML:XML = updateXML();
							System.setClipboard(outputXML.toString());
						}
						break;
					case 88: //'x' for copy of level xml
						if(this.active_level != null && !PipeJam3.RELEASE_BUILD)
						{
							var levelXML:XML = updateXML(true, true);
							System.setClipboard(levelXML.toString());
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
			ErrorParticleSystem.resetList();
			
			if (PipeJam3.logging) {
				var details:Object, qid:int;
				if (active_level) {
					details = new Object();
					details[VerigameServerConstants.ACTION_PARAMETER_LEVEL_NAME] = active_level.original_level_name;
					qid = (active_level.levelNodes.qid == -1) ? VerigameServerConstants.VERIGAME_QUEST_ID_UNDEFINED_WORLD : active_level.levelNodes.qid;
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
				qid = (newLevel.levelNodes.qid == -1) ? VerigameServerConstants.VERIGAME_QUEST_ID_UNDEFINED_WORLD : newLevel.levelNodes.qid;
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
			
			if (inGameMenuBox) inGameMenuBox.setActiveLevelName(active_level.original_level_name);
			
			newLevel.initialize();
			onEdgeSetChange();
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
				var newTarget:int = Solver.getInstance().findTargetScore(active_level, m_simulator);
				active_level.setTargetScore(newTarget);
				if(PipeJamGame.levelInfo != null)
					PipeJamGame.levelInfo.m_targetScore = newTarget;
				m_simulator.updateOnBoxSizeChange("", active_level.level_name);
				active_level.updateScore();
			}
			trace("Solver ran in " + (new Date().getTime() / 1000 - startTime / 1000) + " sec");
			active_level.resetBestScore();
			
			gameControlPanel.newLevelSelected(newLevel);
			miniMap.isDirty = true;
			//	newLevel.setConstraints();
			//	m_simulator.updateOnBoxSizeChange(null, newLevel.level_name);
		}
		
		private function onRemovedFromStage():void
		{
			AudioManager.getInstance().reset();
			
			if (m_activeToolTip) {
				m_activeToolTip.removeFromParent(true);
				m_activeToolTip = null;
			}
			
			removeEventListener(Achievements.CLASH_CLEARED_ID, checkClashClearedEvent);
			
			removeEventListener(GameComponentEvent.CENTER_ON_COMPONENT, onCenterOnComponentEvent);
			removeEventListener(EdgeSetChangeEvent.LEVEL_EDGE_SET_CHANGED, onEdgeSetChange);
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
			removeEventListener(ToolTipEvent.ADD_TOOL_TIP, onToolTipAdded);
			removeEventListener(ToolTipEvent.CLEAR_TOOL_TIP, onToolTipCleared);
			
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
		
	}
}
