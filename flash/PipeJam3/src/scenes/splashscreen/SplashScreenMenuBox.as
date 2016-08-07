package scenes.splashscreen
{
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
				
		protected var currentDisplayString:String = "Begin"
		public var inputInfo:flash.text.TextField;
		private var m_infoTextfield:TextFieldWrapper;
		private var m_scoreTextfield:TextFieldWrapper;
		
		public static var MTurkVersion:Boolean = true;
		public static var userStudyVersion:Boolean = false;


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
				
						
					//------------------------------------------------------------------
					World.gameTimer.stop();
					World.realLevelsTimer.stop();
					var dataLog:Object = new Object();
					dataLog["playerID"] = World.playerID;
					dataLog["levelsCompleted"] = World.realLevelsCompleted;
					dataLog["levelsSkipped"] = World.realLevelsSkipped;
					dataLog["levelsAttempted"] = World.realLevelsAttempted;
					dataLog["totalMoves"] = World.totalMoves;
					dataLog["gameTime"] = World.gameTimer.currentCount;
					dataLog["realLevelsTime"] = World.realLevelsTimer.currentCount;
					dataLog["levelsPlayedAfterTarget"] = World.levelsContinuedAfterTargetScore;
					
					NULogging.log(dataLog);
					//------------------------------------------------------------------
					
					play_button.addEventListener(starling.events.Event.TRIGGERED, onSurveyButtonTriggered);
					
					m_infoTextfield.width = 300;
					
					
					if (MTurkVersion) {
						TextFactory.getInstance().updateText(m_infoTextfield, "Complete the following survey for your completion code.");
						m_mainMenu.addChild(play_button);
					}
					
					if (userStudyVersion) {
						TextFactory.getInstance().updateText(m_infoTextfield, "Thank you for playing!");
					}
					
					TextFactory.getInstance().updateAlign(m_infoTextfield, 1, 1);
					
				}
				else{
					if (currentDisplayString == "Begin"){
						play_button.addEventListener(starling.events.Event.TRIGGERED, onTutorialButtonTriggered);
						m_mainMenu.addChild(play_button);
					
						if (MTurkVersion) {
							TextFactory.getInstance().updateText(m_infoTextfield, "The first set of levels introduces how to play.  You must play all levels for credit.");
						}
						if (userStudyVersion) {
							TextFactory.getInstance().updateText(m_infoTextfield, "The first set of levels introduces how to play. ");
						}
						
						TextFactory.getInstance().updateAlign(m_infoTextfield, 1, 1);
					}
					else{
						play_button.addEventListener(starling.events.Event.TRIGGERED, onPlayButtonTriggered);
						m_mainMenu.addChild(play_button);
						
						m_infoTextfield.width = 450;
						m_infoTextfield.x = m_parent.width/2 - m_infoTextfield.width/2;

						if (MTurkVersion) {
							TextFactory.getInstance().updateText(m_infoTextfield, "Use the skills you have learnt to play the upcoming levels. You now have the option to skip levels, or skip to the end if you wish.");
						}
						if (userStudyVersion) {
							TextFactory.getInstance().updateText(m_infoTextfield, "Use the skills you have learnt to play the upcoming levels.");
						}
						
						TextFactory.getInstance().updateAlign(m_infoTextfield, 1, 1);
					}	
				}
				
				
			}
		}
		
		protected function onPlayButtonTriggered(e:starling.events.Event):void
		{			
			trace("Function triggered on play button press");
			if(!PlayerValidation.AuthorizationAttempted && PipeJam3.RELEASE_BUILD)
			{
				trace("Inside first if");
				if (PipeJam3.PRODUCTION_BUILD)
					
					{
						trace("Inside second if");
						navigateToURL(new URLRequest("http://oauth.verigames.com/oauth2/authorize?response_type=code&redirect_uri=http://paradox.verigames.com/game/Paradox.html&client_id=" + PlayerValidation.production_client_id), "");
					}
				else
					{
						trace("Inside first else");
						navigateToURL(new URLRequest("http://oauth.verigames.org/oauth2/authorize?response_type=code&redirect_uri=http://paradox.verigames.org/game/Paradox.html&client_id=" + PlayerValidation.staging_client_id), "");
					}
			}
			else
				{
					trace("Inside second else");
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
				currentDisplayString = "Continue";
				return "Continue";
			}
			if (World.gamePlayDone){
				currentDisplayString = "Continue to survey"
				return "Continue to survey"
			}
			else return "Begin"
			
			
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
			navigateToURL(new URLRequest("http://viridian.ccs.neu.edu/api/survey/" + World.playerID));
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