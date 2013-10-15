package scenes.splashscreen
{
	import display.NineSliceButton;
	
	import events.NavigationEvent;
	
	import feathers.themes.*;
	
	import flash.events.Event;
	import flash.events.HTTPStatusEvent;
	import flash.net.*;
	import flash.text.*;
	
	import networking.HTTPCookies;
	import networking.LevelInformation;
	import networking.PlayerValidation;
	import networking.TutorialController;
	
	import scenes.BaseComponent;
	import scenes.game.PipeJamGameScene;
	import scenes.game.display.Level;
	
	import starling.core.Starling;
	import starling.display.*;
	import starling.events.Event;
	import starling.text.*;
	
	public class SplashScreenMenuBox extends BaseComponent
	{
		protected var m_mainMenu:Sprite;
		
		protected var play_button:NineSliceButton;
		protected var signin_button:NineSliceButton;
		protected var tutorial_button:NineSliceButton;
		protected var demo_button:NineSliceButton;
		
		protected var loader:URLLoader;

		protected var m_parent:SplashScreenScene;
				
		
		public var inputInfo:flash.text.TextField;

		public function SplashScreenMenuBox(parent:SplashScreenScene)
		{
			super();
			
			parent = m_parent;
			buildMainMenu();
			
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
			
			const BUTTON_CENTER_X:Number = 252; // center point to put Play and Log In buttons
			
			play_button = ButtonFactory.getInstance().createDefaultButton("Play", 88, 32);
			play_button.x = BUTTON_CENTER_X - play_button.width / 2;
			play_button.y = 230;
			
			if (!PipeJam3.TUTORIAL_DEMO && !PipeJam3.LOCAL_DEPLOYMENT) {
				signin_button = ButtonFactory.getInstance().createDefaultButton("Log In", 72, 32);
				signin_button.addEventListener(starling.events.Event.TRIGGERED, onSignInButtonTriggered);
				signin_button.x = BUTTON_CENTER_X - signin_button.width / 2;
				signin_button.y = play_button.y + play_button.height + 10;
			}
			
			if(PipeJam3.RELEASE_BUILD)
			{			
				m_mainMenu.addChild(play_button);
				play_button.addEventListener(starling.events.Event.TRIGGERED, onPlayButtonTriggered);
				if(!PlayerValidation.playerLoggedIn && !PipeJam3.TUTORIAL_DEMO && !PipeJam3.LOCAL_DEPLOYMENT && !DEMO_ONLY)
					m_mainMenu.addChild(signin_button);
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
				if(!PlayerValidation.playerLoggedIn && !PipeJam3.TUTORIAL_DEMO && !PipeJam3.LOCAL_DEPLOYMENT && !DEMO_ONLY)
					m_mainMenu.addChild(signin_button);
			}
			
			if(!PipeJam3.RELEASE_BUILD && !PipeJam3.TUTORIAL_DEMO)
			{
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
			}
		}
		

		
		protected function onSignInButtonTriggered(e:starling.events.Event):void
		{
			//get client id
			Starling.current.nativeStage.addEventListener(flash.events.Event.ACTIVATE, onActivate);
			var myURL:URLRequest = new URLRequest("http://flowjam.verigames.com/login?redirect=http://flowjam.verigames.com/game1/PipeJam3.html");
			navigateToURL(myURL, "_self");
		}
		
		private function onExitButtonTriggered():void
		{
			m_mainMenu.visible = true;
		}
		
		protected function onActivate(evt:flash.events.Event):void
		{
			Starling.current.nativeStage.removeEventListener(flash.events.Event.ACTIVATE, onActivate);
			var s:String = evt.target as String;
			var x:int = 4;
			
		}
		
		protected function onPlayButtonTriggered(e:starling.events.Event):void
		{			
			onPlayerActivated(0, null);
		}
		
		protected function onPlayerActivated(result:int, e:flash.events.Event):void
		{
			m_mainMenu.visible = false;
			getNextPlayerLevel();
		}
		
		//serve either the next tutorial level, or give the full level select screen if done
		protected function getNextPlayerLevelDebug(e:starling.events.Event):void
		{
			//load tutorial file just in case
			onTutorialButtonTriggered(null);
		}
		
		//serve either the next tutorial level, or give the full level select screen if done
		protected function getNextPlayerLevel():void
		{
			if(isTutorialDone() || !PipeJam3.initialLevelDisplay)
			{
				dispatchEvent(new NavigationEvent(NavigationEvent.CHANGE_SCREEN, "LevelSelectScene"));
				PipeJamGameScene.inTutorial = false;
			}
			else
				loadTutorial();
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
			PipeJam3.initialLevelDisplay = false;
			
			dispatchEvent(new NavigationEvent(NavigationEvent.CHANGE_SCREEN, "PipeJamGame"));
		}
		
		protected static var fileNumber:int = 0;
		protected function onDemoButtonTriggered(e:starling.events.Event):void
		{
			PipeJamGameScene.inTutorial = false;
			PipeJamGameScene.inDemo = true;
			if(PipeJamGameScene.demoArray.length == fileNumber)
				fileNumber = 0;
			PipeJamGame.levelInfo = new LevelInformation;
			PipeJamGame.levelInfo.m_baseFileName = PipeJamGameScene.demoArray[fileNumber];
			fileNumber++;
			dispatchEvent(new NavigationEvent(NavigationEvent.CHANGE_SCREEN, "PipeJamGame"));
		}
		
		public function showMainMenu(show:Boolean):void
		{
			m_mainMenu.visible = show;
		}
	}
}