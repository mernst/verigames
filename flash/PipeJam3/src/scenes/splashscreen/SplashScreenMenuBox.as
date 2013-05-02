package scenes.splashscreen
{
	import assets.AssetInterface;
	import assets.AssetsFont;
	
	import events.NavigationEvent;
	
	import feathers.controls.List;
	import feathers.data.ListCollection;
	import feathers.themes.*;
	
	import flash.events.Event;
	import flash.events.HTTPStatusEvent;
	import flash.net.*;
	
	import scenes.BaseComponent;
	import scenes.Scene;
	import scenes.login.LoginHelper;
	
	import starling.core.Starling;
	import starling.display.*;
	import starling.events.Event;
	import starling.events.TouchEvent;
	import starling.text.TextField;
	import starling.textures.Texture;

	public class SplashScreenMenuBox extends BaseComponent
	{
		protected var m_mainMenu:starling.display.Sprite;
		protected var m_levelMenu:starling.display.Sprite;
		
		protected var play_button:starling.display.Button;
		protected var signin_button:starling.display.Button;
		protected var tutorial_button:starling.display.Button;
		protected var demo_button:starling.display.Button;
		
		protected var loader:URLLoader;
		protected var loginHelper:LoginHelper;
		protected var m_parent:SplashScreenScene;
		
		protected var theme:AeonDesktopTheme;
		
		protected var levelList:List = null;
		protected var levelMetadataArray:Array = null;
		protected var matchArrayObjects:Array = null;
		
		public function SplashScreenMenuBox(parent:SplashScreenScene)
		{
			super();
			
			parent = m_parent;
			loginHelper = LoginHelper.getLoginHelper();
			buildMainMenu();
			
			addEventListener(starling.events.Event.ADDED_TO_STAGE, addedToStage);
			addEventListener(starling.events.Event.REMOVED_FROM_STAGE, removedFromStage);
		}
		
		protected function addedToStage(event:starling.events.Event):void
		{
			addChild(m_mainMenu);
			
			theme = new AeonDesktopTheme( this.stage );
		}
		
		protected function removedFromStage(event:starling.events.Event):void
		{
			
		}
		
		protected function buildMainMenu():void
		{
			m_mainMenu = new Sprite();
			
			var signinButtonUp:Texture = AssetInterface.getTexture("Menu", "SignInButtonClass");
			var signinButtonClick:Texture = AssetInterface.getTexture("Menu", "SignInButtonClickClass");
			
			signin_button = new Button(signinButtonUp, "", signinButtonClick);
			signin_button.addEventListener(starling.events.Event.TRIGGERED, onSignInButtonTriggered);
			signin_button.x = 0;
			signin_button.y = 60;
			signin_button.width *= .6;
			signin_button.height *= .6;
			m_mainMenu.addChild(signin_button);
			
			var playButtonUp:Texture = AssetInterface.getTexture("Menu", "PlayButtonClass");
			var playButtonClick:Texture = AssetInterface.getTexture("Menu", "PlayButtonClickClass");
			
			play_button = new Button(playButtonUp, "", playButtonClick);
			play_button.addEventListener(starling.events.Event.TRIGGERED, onPlayButtonTriggered);
			play_button.x = 0;
			play_button.y = 110;
			play_button.width *= .6;
			play_button.height *= .6;
			m_mainMenu.addChild(play_button);
			
			var tutorialButtonUp:Texture = AssetInterface.getTexture("Menu", "TutorialButtonClass");
			var tutorialButtonClick:Texture = AssetInterface.getTexture("Menu", "TutorialButtonClickClass");
			
			tutorial_button = new Button(tutorialButtonUp, "", tutorialButtonClick);
			tutorial_button.addEventListener(starling.events.Event.TRIGGERED, onTutorialButtonTriggered);
			tutorial_button.x = 0;
			tutorial_button.y = 160;
			tutorial_button.width *= .6;
			tutorial_button.height *= .6;
			m_mainMenu.addChild(tutorial_button);
			
			var demoButtonUp:Texture = AssetInterface.getTexture("Menu", "DemoButtonClass");
			var demoButtonClick:Texture = AssetInterface.getTexture("Menu", "DemoButtonClickClass");
			
			demo_button = new Button(demoButtonUp, "", demoButtonClick);
			demo_button.addEventListener(starling.events.Event.TRIGGERED, onDemoButtonTriggered);
			demo_button.x = 0;
			demo_button.y = 210;
			demo_button.width *= .6;
			demo_button.height *= .6;
			m_mainMenu.addChild(demo_button);
		}
		
		protected function buildLevelMenu():void
		{
			m_levelMenu = new Sprite();
			var background:Texture = AssetInterface.getTexture("Game", "GameControlPanelBackgroundImageClass");
			var backgroundImage:Image = new Image(background);
			backgroundImage.width = 150;
			backgroundImage.height = 200;
			m_levelMenu.addChild(backgroundImage);
			
			//create a title
			var titleTextfield:TextFieldWrapper = TextFactory.getInstance().createTextField("Levels", AssetsFont.FONT_NUMERIC, width, 40, 25, 0xeeeeee);
			titleTextfield.x = -5; 
			TextFactory.getInstance().updateAlign(titleTextfield, 1, 1);
			m_levelMenu.addChild(titleTextfield);

			levelList = new List;
			levelList.y = 75;
			levelList.x = 10;
			levelList.width = 125;
			levelList.itemRendererProperties.height = 10;
			
			m_levelMenu.addChild(levelList);
			levelList.addEventListener( starling.events.Event.CHANGE, onLevelSelected);
			levelList.validate();
			
			var exitButtonUp:Texture = AssetInterface.getTexture("Menu", "ExitButtonClass");
			var exitButtonClick:Texture = AssetInterface.getTexture("Menu", "ExitButtonClass");
			
			var exit_button:Button = new Button(exitButtonUp, "", exitButtonClick);
			exit_button.addEventListener(starling.events.Event.TRIGGERED, onExitButtonTriggered);
			exit_button.x = 10;
			exit_button.y = 150;
			exit_button.width *= .38;
			exit_button.height *= .38;
			m_levelMenu.addChild(exit_button);
			
			m_levelMenu.visible = false;
			//use this for testing without any connection
//			onRequestLevels(LoginHelper.EVENT_COMPLETE, null)
		}
		
		protected function onRequestLevels(result:int, e:flash.events.Event):void
		{
			if(result == LoginHelper.EVENT_COMPLETE)
			{
				levelMetadataArray = new Array("test", "bob", "joe", "fred"); //dummy values for testing
				if(e != null)
				{
					var levels:Object = JSON.parse(e.target.data);
					matchArrayObjects = levels.matches;
					//clear out old metadata
					levelMetadataArray = new Array;
					//now query for the metadata for those levels
					trace(matchArrayObjects.length);
					//can't send these all at once (login helper wouldn't like it), so send first here
					if(matchArrayObjects.length > 0)
						loginHelper.onGetLevelMetadata(onGetLevelMetadataComplete, matchArrayObjects[0].levelId);
				}
				else
					onGetLevelMetadataComplete(LoginHelper.EVENT_COMPLETE, null);
			}
		}
		
		protected function onGetLevelMetadataComplete(result:int, e:flash.events.Event):void
		{
			if(result == LoginHelper.EVENT_COMPLETE)
			{
				if(e != null)
				{
					var levels:Object = JSON.parse(e.target.data);
					var levelMetadata:Object = levels.metadata;
					
					if(levelMetadata && levelMetadata.properties && levelMetadata.properties.name)
						levelMetadataArray.push(levelMetadata.properties.name);
					else
						levelMetadataArray.push("Foo");
				}
			
				if(levelMetadataArray.length == matchArrayObjects.length)
				{
					//we are done, show everything
					// Creating the dataprovider
					var matchCollection:ListCollection = new ListCollection(levelMetadataArray);
					levelList.dataProvider = matchCollection;
					
					m_mainMenu.visible = false;
					m_levelMenu.visible = true;
				}
				else //send the next request
					loginHelper.onGetLevelMetadata(onGetLevelMetadataComplete,  matchArrayObjects[levelMetadataArray.length].levelId);
			}
			else
			{
				//report error!
			}
		}
		
		protected function onSignInButtonTriggered(e:starling.events.Event):void
		{
			//get client id
			//Starling.current.nativeStage.addEventListener(flash.events.Event.ACTIVATE, onActivate);
			//var myURL:URLRequest = new URLRequest("http://ec2-184-72-152-11.compute-1.amazonaws.com:3000/auth/csfv");
			//navigateToURL(myURL, "_blank");
			dispatchEvent(new NavigationEvent(NavigationEvent.CHANGE_SCREEN, "LoginScene"));
		}
		
		protected function onLevelSelected(e:starling.events.Event):void
		{
			LoginHelper.levelNumberString = matchArrayObjects[levelList.selectedIndex].levelID;
			
			dispatchEvent(new NavigationEvent(NavigationEvent.CHANGE_SCREEN, "PipeJamGame"));
			
			//null this out after use
			LoginHelper.levelNumberString = null;
		}
		
		private function onExitButtonTriggered():void
		{
			m_mainMenu.visible = true;
			m_levelMenu.visible = false;
		}
		
		protected function callback(evt:flash.events.Event):void
		{
			loader = new URLLoader();
			var clientIDURL:URLRequest = new URLRequest(LoginHelper.PROXY_URL+"/auth/csfv&method=AUTH");
			loader.addEventListener(flash.events.Event.COMPLETE, callback);
			loader.addEventListener(flash.events.HTTPStatusEvent.HTTP_STATUS, status);
			loader.load(clientIDURL);
		}
		
		protected function onActivate(evt:flash.events.Event):void
		{
			Starling.current.nativeStage.removeEventListener(flash.events.Event.ACTIVATE, onActivate);
			var s:String = evt.target as String;
			var x:int = 4;
			
		}
		
		protected function status(evt:flash.events.Event):void
		{
			//			var s:String = evt.status as String;
			//			var x:int = 4;
			
		}
		
		protected function onPlayButtonTriggered(e:starling.events.Event):void
		{
			if(m_levelMenu == null)
			{
				buildLevelMenu();
				addChild(m_levelMenu);
				m_levelMenu.x = m_mainMenu.x;
				m_levelMenu.y = m_mainMenu.y;
				
			}
			
			loginHelper.onRequestLevels(onRequestLevels);
		}
		
		protected function onTutorialButtonTriggered(e:starling.events.Event):void
		{
			dispatchEvent(new NavigationEvent(NavigationEvent.CHANGE_SCREEN, "PipeJamGame"));
		}
		
		protected function onDemoButtonTriggered(e:starling.events.Event):void
		{
			dispatchEvent(new NavigationEvent(NavigationEvent.CHANGE_SCREEN, "PipeJamGame"));
		}
	}
}