package scenes.splashscreen
{
	import display.NineSliceButton;
	import events.NavigationEvent;
	import feathers.themes.*;
	import flash.events.Event;
	import flash.events.HTTPStatusEvent;
	import flash.net.*;
	import flash.text.*;
	import scenes.BaseComponent;
	import scenes.game.PipeJamGameScene;
	import starling.core.Starling;
	import starling.display.*;
	import starling.events.Event;
	import starling.text.*;
	import networking.PlayerValidation;
	import networking.HTTPCookies;
	
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
		
		protected function buildMainMenu():void
		{
			m_mainMenu = new Sprite();
			
			const BUTTON_CENTER_X:Number = 241; // center point to put Play and Log In buttons
			
			play_button = ButtonFactory.getInstance().createDefaultButton("Play", 112, 42);
			play_button.x = BUTTON_CENTER_X - play_button.width / 2;
			play_button.y = 230;
			
			if (!PipeJam3.TUTORIAL_DEMO && !PipeJam3.LOCAL_DEPLOYMENT) {
				signin_button = ButtonFactory.getInstance().createDefaultButton("Log In", 96, 32);
				signin_button.addEventListener(starling.events.Event.TRIGGERED, onSignInButtonTriggered);
				signin_button.x = BUTTON_CENTER_X - signin_button.width / 2;
				signin_button.y = play_button.y + play_button.height + 10;
			}
			
			if(PipeJam3.RELEASE_BUILD)
			{			
				m_mainMenu.addChild(play_button);
				play_button.addEventListener(starling.events.Event.TRIGGERED, onPlayButtonTriggered);
				if(!PlayerValidation.playerLoggedIn && !PipeJam3.TUTORIAL_DEMO && !PipeJam3.LOCAL_DEPLOYMENT)
					m_mainMenu.addChild(signin_button);
			}
			else if (PipeJam3.TUTORIAL_DEMO)
			{
				m_mainMenu.addChild(play_button);
				play_button.addEventListener(starling.events.Event.TRIGGERED, getNextPlayerLevelDebug);
			}
			else if (!PipeJam3.TUTORIAL_DEMO) //not release, not tutorial demo
			{
				m_mainMenu.addChild(play_button);
				play_button.addEventListener(starling.events.Event.TRIGGERED, onPlayButtonTriggered);
				if(!PlayerValidation.playerLoggedIn && !PipeJam3.TUTORIAL_DEMO && !PipeJam3.LOCAL_DEPLOYMENT)
					m_mainMenu.addChild(signin_button);
			}
			
			if(!PipeJam3.RELEASE_BUILD && !PipeJam3.TUTORIAL_DEMO)
			{
				tutorial_button = ButtonFactory.getInstance().createDefaultButton("Tutorial", 64, 24);
				tutorial_button.addEventListener(starling.events.Event.TRIGGERED, onTutorialButtonTriggered);
				tutorial_button.x = Constants.GameWidth - tutorial_button.width - 10;
				tutorial_button.y = 50;
				m_mainMenu.addChild(tutorial_button);
				
				demo_button = ButtonFactory.getInstance().createDefaultButton("Demo", 64, 24);
				demo_button.addEventListener(starling.events.Event.TRIGGERED, onDemoButtonTriggered);
				demo_button.x = Constants.GameWidth - demo_button.width - 10;
				demo_button.y = tutorial_button.y + 30;
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
			PipeJamGameScene.numTutorialLevels = PipeJamGameScene.tutorialXML["level"].length();
			
			var tutorialStatus:String = PipeJam3.LOCAL_DEPLOYMENT ? "0" : HTTPCookies.getCookie(HTTPCookies.TUTORIALS_COMPLETED);
			if(!isNaN(parseInt(tutorialStatus)))
				PipeJamGameScene.maxTutorialLevelCompleted = parseInt(tutorialStatus);
			
			if(PipeJamGameScene.maxTutorialLevelCompleted >= PipeJamGameScene.numTutorialLevels)
				return true;
			else
				return false;
		}
		
		protected function onTutorialButtonTriggered(e:starling.events.Event):void
		{
			//go to the beginning
			PipeJamGameScene.resetTutorialStatus();
			
			loadTutorial();
			
		}
		
		protected function loadTutorial():void
		{
			PipeJamGameScene.inTutorial = true;
			PipeJam3.initialLevelDisplay = false;
			
			dispatchEvent(new NavigationEvent(NavigationEvent.CHANGE_SCREEN, "PipeJamGame"));
		}
		
		protected static var fileNumber:int = 0;
		protected function onDemoButtonTriggered(e:starling.events.Event):void
		{
			if(PipeJamGameScene.dArray.length == fileNumber)
				fileNumber = 0;
			PipeJamGameScene.worldFile = PipeJamGameScene.dArray[fileNumber];
			PipeJamGameScene.layoutFile = PipeJamGameScene.dArray[fileNumber+2];
			PipeJamGameScene.constraintsFile = PipeJamGameScene.dArray[fileNumber+1];
			fileNumber+=3;
			dispatchEvent(new NavigationEvent(NavigationEvent.CHANGE_SCREEN, "PipeJamGame"));
		}
		
		public function showMainMenu(show:Boolean):void
		{
			m_mainMenu.visible = show;
		}
	}
}