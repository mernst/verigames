package scenes.splashscreen
{
	import assets.StringTable;
	import flash.events.Event;
	import flash.events.TimerEvent;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.net.navigateToURL;
	import flash.text.TextField;
	import flash.utils.Timer;
	
	import assets.AssetInterface;
	import assets.AssetsFont;
		
	import display.NineSliceButton;
	
	import events.NavigationEvent;
	import events.ToolTipEvent;
	
	import networking.GameFileHandler;
	import networking.PlayerValidation;
	import networking.TutorialController;
	
	import scenes.BaseComponent;
	import scenes.game.PipeJamGameScene;
	import scenes.game.display.Level;
	import scenes.game.display.World;
	
	import starling.core.Starling;
	import starling.display.Sprite;
	import starling.events.Event;
	
	import server.NULogging;
	import scenes.game.display.World;
	
	public class SplashScreenMenuBox extends BaseComponent
	{
		protected var m_mainMenu:Sprite;
		
		//main screen buttons
		protected var play_button:NineSliceButton;
		protected var continue_tutorial_button:NineSliceButton;
		
		//These are visible in demo mode only (PipeJam3.RELEASE_BUILD == false)
		protected var tutorial_button:NineSliceButton;
		protected var demo_button:NineSliceButton;
		
		protected var loader:URLLoader;

		protected var m_parent:SplashScreenScene;
		
		
		private static const ST_BEGIN:int     = 0;
		private static const ST_CONTINUE:int  = 1;
		private static const ST_SURVEY:int    = 2;
		
		private var m_currentDisplayState:int = ST_BEGIN;
		
		public var inputInfo:flash.text.TextField;
		private var m_infoTextfield:TextFieldWrapper;
		private var m_scoreTextfield:TextFieldWrapper;
		
		public function SplashScreenMenuBox(_parent:SplashScreenScene)
		{
			super();
			
			m_parent = _parent;
			buildMainMenu();
			trace("TutorialsDone", TutorialController.tutorialsDone);

			addEventListener(starling.events.Event.ADDED_TO_STAGE, addedToStage);
			addEventListener(starling.events.Event.REMOVED_FROM_STAGE, removedFromStage);
		}
		
		protected function addedToStage(event:starling.events.Event):void
		{
			addChild(m_mainMenu);
		}
		
		protected function removedFromStage(event:starling.events.Event):void
		{
			
		}
		
		private static const DEMO_ONLY:Boolean = false; // True to only show demo button
		protected function buildMainMenu():void
		{
			m_mainMenu = new Sprite();
			
			var BUTTON_CENTER_X:Number = m_parent.width/2; // center point to put Play and Log In buttons
			var TOP_BUTTON_Y:int = 205;
			
			play_button = ButtonFactory.getInstance().createDefaultButton(stringToDisplay(), 88, 32);
			play_button.x = BUTTON_CENTER_X - play_button.width / 2;
			play_button.y = TOP_BUTTON_Y + 15; //if only two buttons center them
			
			
			
			m_infoTextfield = TextFactory.getInstance().createTextField("", AssetsFont.FONT_DEFAULT, 300, 2.0 * 20, 15, 0x000000);
			m_infoTextfield.touchable = false;
			m_infoTextfield.x = m_parent.width/2 - m_infoTextfield.width/2;
			m_infoTextfield.y = play_button.y - 85;
			TextFactory.getInstance().updateAlign(m_infoTextfield, 2, 1);
			m_mainMenu.addChild(m_infoTextfield);
			
			
			
			trace("isTutorialDone?", isTutorialDone());
			
			// Not happening//
			/*
			if(!isTutorialDone())
			{
				continue_tutorial_button = ButtonFactory.getInstance().createDefaultButton("Tutorial", 88, 32);
				continue_tutorial_button.addEventListener(starling.events.Event.TRIGGERED, onContinueTutorialTriggered);
				continue_tutorial_button.x = BUTTON_CENTER_X - continue_tutorial_button.width / 2;
				continue_tutorial_button.y = play_button.y + play_button.height + 5;
			}
			
			
			trace("RELEASE_BUILD=", PipeJam3.RELEASE_BUILD);
			trace("PipeJam3.TUTORIAL_DEMO=",PipeJam3.TUTORIAL_DEMO);
			if(PipeJam3.RELEASE_BUILD)
			{			
				m_mainMenu.addChild(play_button);
				play_button.addEventListener(starling.events.Event.TRIGGERED, onPlayButtonTriggered);
				if(continue_tutorial_button)
					m_mainMenu.addChild(continue_tutorial_button);
			}
			else if (PipeJam3.TUTORIAL_DEMO)
			{
				if (!DEMO_ONLY) m_mainMenu.addChild(play_button);
				play_button.addEventListener(starling.events.Event.TRIGGERED, getNextPlayerLevelDebug);
			}
			else if (!PipeJam3.TUTORIAL_DEMO) //not release, not tutorial demo
			{
				if (!DEMO_ONLY) m_mainMenu.addChild(play_button);
				play_button.addEventListener(starling.events.Event.TRIGGERED, onPlayButtonTriggered);
			}
			// Not happening//
			*/
			if(!PipeJam3.RELEASE_BUILD && !PipeJam3.TUTORIAL_DEMO)
			{
				/*
				tutorial_button = ButtonFactory.getInstance().createDefaultButton("Tutorial", 56, 22);
				tutorial_button.addEventListener(starling.events.Event.TRIGGERED, onTutorialButtonTriggered);
				tutorial_button.x = Constants.GameWidth - tutorial_button.width - 4;
				tutorial_button.y = 110;
				if (!DEMO_ONLY) m_mainMenu.addChild(tutorial_button);
				
				if (DEMO_ONLY) {
					demo_button = ButtonFactory.getInstance().createDefaultButton("Demo", play_button.width, play_button.height);
					demo_button.addEventListener(starling.events.Event.TRIGGERED, onDemoButtonTriggered);
					demo_button.x = play_button.x;
					demo_button.y = play_button.y;
				} else {
					demo_button = ButtonFactory.getInstance().createDefaultButton("Demo", 56, 22);
					demo_button.addEventListener(starling.events.Event.TRIGGERED, onDemoButtonTriggered);
					demo_button.x = Constants.GameWidth - demo_button.width - 4;
					demo_button.y = tutorial_button.y + 30;
				}
				m_mainMenu.addChild(demo_button);
				*/
				
				if (World.gamePlayDone) {
					
					// Calclulate total Brush count used.
					World.totalBrushUsageCount = World.totalHexagonBrushCount + World.totalDiamondBrushCount 
						+ World.totalCircleBrushCount + World.totalSquareBrushCount;
					
					World.tutorialBrushUsageCount = World.tutorialHexagonBrushCount + World.tutorialDiamondBrushCount 
						+ World.tutorialCircleBrushCount + World.tutorialSquareBrushCount;
						
					// Calculate total Levels Seen
					World.totallevelsSeen = World.totallevelsCompleted + World.totallevelsAbandoned + World.totalLevelsAttempted;
					
										
					//------------------------------------------------------------------
					World.gameTimer.stop();
					World.realLevelsTimer.stop();
					var dataLog:Object = new Object();
					dataLog["playerID"] = World.playerID;
					dataLog["workerID"] = World.workerId;
					dataLog["HitId"] = World.hitId;
					dataLog["source"] = World.src;
					dataLog["totalLevelsInGame"] = World.totalLevelCount;
					dataLog["levelsCompleted"] = World.totallevelsCompleted;
					dataLog["levelsAbandoned"] = World.totallevelsAbandoned;
					dataLog["levelsAttempted"] = World.totalLevelsAttempted;
					dataLog["tutLevelsCompleted"] = World.tutorialLevelsCompleted;
					dataLog["tutLevelsAbandoned"] = World.tutorialLevelsAbandoned;
					dataLog["tutLevelsAttempted"] = World.tutorialLevelsAttempted;
					//dataLog["levelsSkipped"] = World.totalLevelCount - World.totallevelsSeen;
					dataLog["levelsDoneSomething"] = World.totallevelsSeen - World.totallevelsAbandoned;
					dataLog["levelsSeen"] = World.totallevelsSeen;
					dataLog["totalMoves"] = World.totalBrushUsageCount;
					dataLog["totalTutorialMoves"] = World.tutorialBrushUsageCount;
					dataLog["gameTime"] = World.gameTimer.currentCount;
					dataLog["realLevelsTime"] = World.realLevelsTimer.currentCount;
					dataLog["tutorialTime"] = World.gameTimer.currentCount - World.realLevelsTimer.currentCount;
					dataLog["tutorialOverCompletion"] = World.tutorialOverCompletion;
					dataLog["tutorialMoves"] = World.tutorialMoves;
					dataLog["levelsPlayedAfterTarget"] = World.levelsContinuedAfterTargetScore;
					dataLog["remainingTotalLevels"] = World.remainingTotalLevels;
					//dataLog["LevelsIgnored"] = World.levelNumberArray.length;
					dataLog["MaxTimeSpentOnLevel"] = (World.maxTimeInLevel == -1 ? "" : World.maxTimeInLevel);
					dataLog["MaxTimelevelName"] = World.maxTimeLevelName;
					dataLog["MinTimeSpentOnLevel"] = (World.minTimeInLevel == Number.MAX_VALUE ? "" : World.minTimeInLevel);
					dataLog["MinTimeLevelName"] = World.minTimeLevelName;
					dataLog["WidenBrushCount"] = World.totalHexagonBrushCount;
					dataLog["Solver2_DiamondBrushCount"] = World.totalDiamondBrushCount;
					dataLog["Solver1_CircleBrushCount"] = World.totalCircleBrushCount;
					dataLog["NarrowBrushCount"] = World.totalSquareBrushCount;
					dataLog["MaxTutTimeSpentOnLevel"] = (World.maxTimeInTutLevel == -1 ? "" : World.maxTimeInTutLevel);
					dataLog["MaxTutTimelevelName"] = World.maxTimeTutLevelName;
					dataLog["MinTutTimeSpentOnLevel"] = (World.minTimeInTutLevel == Number.MAX_VALUE ? "" : World.minTimeInTutLevel);
					dataLog["MinTutTimeLevelName"] = World.minTimeTutLevelName;
					dataLog["TutWidenBrushCount"] = World.tutorialHexagonBrushCount;
					dataLog["TutSolver2_DiamondBrushCount"] = World.tutorialDiamondBrushCount;
					dataLog["TutSolver1_CircleBrushCount"] = World.tutorialCircleBrushCount;
					dataLog["TutNarrowBrushCount"] = World.tutorialSquareBrushCount;
					dataLog["IsSummaryData"] = true;
					var displayMode:String;
					if (World.LevelDisplayMode == 1)
						displayMode = "Random Order";
					else if (World.LevelDisplayMode == 2)
						displayMode = "Rating Order";
					else
						displayMode = "Increasing Order";
					dataLog["LevelDisplayMode"] = displayMode;
					var ratingsMode:String;
					if (World.RatingsDisplayMode == 1)
						ratingsMode = "Blind";
					else if (World.RatingsDisplayMode == 2)
						ratingsMode = "Ratings";
					else if (World.RatingsDisplayMode == 3)
						ratingsMode = "Choice";
					else
						ratingsMode = "Blind Choice";
					dataLog["RatingsDisplayMode"] = ratingsMode;
					//dataLog["LevelDisplayMode"] = World.LevelDisplayMode == 1 ? "Random Order" : "Rating Order";
					dataLog["PlayerRating"] = World.player.getRating();
					dataLog["Metaphor"] = GameConfig.GAME_METAPHOR == 0 ? "Original" : "Powerplant";
					dataLog["stage"] = "pre-survey";
					NULogging.log(dataLog);
					//------------------------------------------------------------------
					
					// End Session here.
					NULogging.sessionEnd();
					
					play_button.addEventListener(starling.events.Event.TRIGGERED, onSurveyButtonTriggered);
					
					m_infoTextfield.width = 300;
					
					TextFactory.getInstance().updateText(m_infoTextfield, StringTable.lookup(StringTable.SPLASH_DONE));
					TextFactory.getInstance().updateAlign(m_infoTextfield, 1, 1);
					
					if (GameConfig.IS_MTURK) {
						m_mainMenu.addChild(play_button);
					}
				}
				else{
					if (m_currentDisplayState == ST_BEGIN) {
						play_button.addEventListener(starling.events.Event.TRIGGERED, onTutorialButtonTriggered);
						m_mainMenu.addChild(play_button);
					
						TextFactory.getInstance().updateText(m_infoTextfield, StringTable.lookup(StringTable.SPLASH_TUTORIAL));
						TextFactory.getInstance().updateAlign(m_infoTextfield, 1, 1);
					}
					else{
						play_button.addEventListener(starling.events.Event.TRIGGERED, onPlayButtonTriggered);
						m_mainMenu.addChild(play_button);
						
						m_infoTextfield.width = 450;
						m_infoTextfield.x = m_parent.width/2 - m_infoTextfield.width/2;

						TextFactory.getInstance().updateText(m_infoTextfield, StringTable.lookup(StringTable.SPLASH_CHALLENGE));
						TextFactory.getInstance().updateAlign(m_infoTextfield, 1, 1);
					}	
				}
				
				
			}
		}
		
		protected function onPlayButtonTriggered(e:starling.events.Event):void
		{	
			if(!PlayerValidation.AuthorizationAttempted && PipeJam3.RELEASE_BUILD)
			{
				if (PipeJam3.PRODUCTION_BUILD)
					
					{
						navigateToURL(new URLRequest("http://oauth.verigames.com/oauth2/authorize?response_type=code&redirect_uri=http://paradox.verigames.com/game/Paradox.html&client_id=" + PlayerValidation.production_client_id), "");
					}
				else
					{
						navigateToURL(new URLRequest("http://oauth.verigames.org/oauth2/authorize?response_type=code&redirect_uri=http://paradox.verigames.org/game/Paradox.html&client_id=" + PlayerValidation.staging_client_id), "");
					}
			}
			else
				{
					//getNextRandomLevel(null);
					
					PipeJamGameScene.inTutorial = false;
					PipeJamGameScene.inDemo = false;
					World.realLevelsTimer.start();
					
					dispatchEvent(new NavigationEvent(NavigationEvent.CHANGE_SCREEN, "PipeJamGame"));
					

				}
		}
		
		protected function stringToDisplay():String
		{
			if (TutorialController.tutorialsDone) {
				m_currentDisplayState = ST_CONTINUE;
				return StringTable.lookup(StringTable.SPLASH_CONTINUE);
			}
			if (World.gamePlayDone) {
				m_currentDisplayState = ST_SURVEY;
				return StringTable.lookup(StringTable.SPLASH_SURVEY);
			}
			m_currentDisplayState = ST_BEGIN;
			return StringTable.lookup(StringTable.SPLASH_BEGIN);
		}

		protected function onContinueTutorialTriggered(e:starling.events.Event):void
		{
			loadTutorial();
		}
		
		private function onExitButtonTriggered():void
		{
			m_mainMenu.visible = true;
		}
		
		protected function onActivate(evt:flash.events.Event):void
		{
			Starling.current.nativeStage.removeEventListener(flash.events.Event.ACTIVATE, onActivate);
		}
		
		//serve either the next tutorial level, or give the full level select screen if done
		protected function getNextPlayerLevelDebug(e:starling.events.Event):void
		{
			//load tutorial file just in case
			onTutorialButtonTriggered(null);
		}
		
		protected function getNextRandomLevel(evt:TimerEvent):void
		{
			//check to see if we have the level list yet, if not, stall
			trace("Inside random level function");
			if(GameFileHandler.levelInfoVector == null)
			{
				trace("GameFileHandler.levelInfoVector is null");
				var timer:Timer = new Timer(200, 1);
				timer.addEventListener(TimerEvent.TIMER, getNextRandomLevel);
				timer.start();
				return;
			}
			
			dispatchEvent(new NavigationEvent(NavigationEvent.CHANGE_SCREEN, "PipeJamGame"));
			//dispatchEvent(new NavigationEvent(NavigationEvent.GET_RANDOM_LEVEL));
		}
		
		protected function onSurveyButtonTriggered(e:starling.events.Event):void {
			navigateToURL(new URLRequest("http://viridian.ccs.neu.edu/api/survey/:" + World.playerID + "/:" + World.hitId),"_self");
			parent.removeChild(play_button);
		}
		
		protected function isTutorialDone():Boolean
		{
			//check on next level, returns -1 if 
			var isDone:Boolean = TutorialController.getTutorialController().isTutorialDone();
			
			if(isDone)
				return true;
			else
				return false;
		}
		
		protected function onTutorialButtonTriggered(e:starling.events.Event):void
		{
			//go to the beginning
			TutorialController.getTutorialController().resetTutorialStatus();
			
			loadTutorial();
			
		}
		
		protected function loadTutorial():void
		{
			PipeJamGameScene.inTutorial = true;
			PipeJamGameScene.inDemo = false;
			
			dispatchEvent(new NavigationEvent(NavigationEvent.CHANGE_SCREEN, "PipeJamGame"));
		}
		
		protected static var fileNumber:int = 0;
		protected function onDemoButtonTriggered(e:starling.events.Event):void
		{
			PipeJamGameScene.inTutorial = false;
			PipeJamGameScene.inDemo = true;
			if(PipeJamGameScene.demoArray.length == fileNumber)
				fileNumber = 0;
			PipeJamGame.levelInfo = new Object;
			PipeJamGame.levelInfo.baseFileName = PipeJamGameScene.demoArray[fileNumber];
			fileNumber++;
			dispatchEvent(new NavigationEvent(NavigationEvent.CHANGE_SCREEN, "PipeJamGame"));
		}
		
		public function showMainMenu(show:Boolean):void
		{
			m_mainMenu.visible = show;
		}
	}
}