package scenes.splashscreen
{
	import display.NineSliceButton;
	import events.NavigationEvent;
	import feathers.controls.List;
	import feathers.themes.*;
	import flash.events.Event;
	import flash.events.HTTPStatusEvent;
	import flash.net.*;
	import flash.text.*;
	import networking.*;
	import scenes.BaseComponent;
	import scenes.game.components.dialogs.SelectLevelDialog;
	import scenes.game.PipeJamGameScene;
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
		protected var loginHelper:LoginHelper;
		protected var m_parent:SplashScreenScene;
				
		protected var levelList:List = null;
		protected var levelMetadataArray:Array = null;
		protected var matchArrayObjects:Array = null;
		protected var matchArrayMetadata:Array = null;
		protected var savedLevelsMetadataArray:Array = null;
		protected var savedLevelsArrayMetadata:Array = null;
		
		public var inputInfo:flash.text.TextField;
		
		protected var selectLevelDialog:SelectLevelDialog;
		
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
		}
		
		protected function removedFromStage(event:starling.events.Event):void
		{
			
		}
		
		protected function buildMainMenu():void
		{
			m_mainMenu = new Sprite();
			
			play_button = ButtonFactory.getInstance().createDefaultButton("Play", 112, 42);
			play_button.x = 225 - play_button.width / 2;
			play_button.y = 240;
			
			if (!PipeJam3.TUTORIAL_DEMO) {
				signin_button = ButtonFactory.getInstance().createDefaultButton("Log In", 64, 24);
				signin_button.addEventListener(starling.events.Event.TRIGGERED, onSignInButtonTriggered);
				signin_button.x = 225 - signin_button.width / 2;
				signin_button.y = play_button.y + play_button.height + 10;
			}
			
			if(PipeJam3.RELEASE_BUILD)
			{			
				m_mainMenu.addChild(play_button);
				play_button.addEventListener(starling.events.Event.TRIGGERED, onPlayButtonTriggered);
				if(!PlayerValidation.playerLoggedIn && !PipeJam3.TUTORIAL_DEMO)
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
				m_mainMenu.addChild(signin_button);
			}
			
						
			//			inputInfo = new flash.text.TextField();
			//			// Create default text format
			//			var inputInfoTextFormat:TextFormat = new TextFormat("Arial", 12, 0x000000);
			//			inputInfoTextFormat.align = TextFormatAlign.LEFT;
			//			inputInfo.defaultTextFormat = inputInfoTextFormat;
			//			// Set text input type
			//			inputInfo.type = TextFieldType.INPUT;
			//			inputInfo.autoSize = TextFieldAutoSize.LEFT;
			//			inputInfo.multiline = true;
			//			inputInfo.wordWrap = true;
			//			inputInfo.x = width + 30;
			//			inputInfo.y = 110;
			//			inputInfo.height = 200;
			//			inputInfo.width = 100;
			//			// Set background just for testing needs
			//			inputInfo.background = true;
			//			inputInfo.backgroundColor = 0xffffff;
			//			inputInfo.text = PipeJam3.cookies;
			//			
			//			Starling.current.nativeOverlay.addChild(inputInfo);
			

			if(!PipeJam3.RELEASE_BUILD && !PipeJam3.TUTORIAL_DEMO)
			{
				tutorial_button = ButtonFactory.getInstance().createDefaultButton("Tutorial", 64, 24);
				tutorial_button.addEventListener(starling.events.Event.TRIGGERED, onTutorialButtonTriggered);
				tutorial_button.x = Constants.GameWidth - tutorial_button.width - 10;
				tutorial_button.y = Constants.GameHeight / 2;
				m_mainMenu.addChild(tutorial_button);
				
				demo_button = ButtonFactory.getInstance().createDefaultButton("Demo", 64, 24);
				demo_button.addEventListener(starling.events.Event.TRIGGERED, onDemoButtonTriggered);
				demo_button.x = Constants.GameWidth - demo_button.width - 10;
				demo_button.y = tutorial_button.y + 30;
				m_mainMenu.addChild(demo_button);
			}
		}
		
		protected function onRequestLevels(result:int):void
		{
			if(result == LoginHelper.EVENT_COMPLETE)
			{
				if(loginHelper.levelInfoVector != null && loginHelper.matchArrayObjects != null && loginHelper.savedMatchArrayObjects != null)
					onGetLevelMetadataComplete();
			}
		}
		
		protected function onGetLevelMetadataComplete():void
		{
			matchArrayMetadata = new Array;
			levelMetadataArray = new Array;
			for(var i:int = 0; i<loginHelper.matchArrayObjects.length; i++)
			{
				var match:Object = loginHelper.matchArrayObjects[i];
				var levelName:String = fileLevelNameFromMatch(match, loginHelper.levelInfoVector, matchArrayMetadata);
				if(levelName != null)
					levelMetadataArray.push(levelName);
			}
			
			selectLevelDialog.setNewLevelInfo(matchArrayMetadata);
			
			savedLevelsArrayMetadata = new Array;
			savedLevelsMetadataArray = new Array;
			for(var i:int = 0; i<loginHelper.savedMatchArrayObjects.length; i++)
			{
				var match:Object = loginHelper.savedMatchArrayObjects[i];
		//		var levelName:String = fileLevelNameFromMatch(match, loginHelper.levelInfoVector, savedLevelsArrayMetadata);
		//		if(levelName != null)
					savedLevelsMetadataArray.push(match.name);
					savedLevelsArrayMetadata.push(match);
			}
			
			selectLevelDialog.setSavedLevelsInfo(savedLevelsArrayMetadata);
			
			dispatchEvent(new starling.events.Event(Game.STOP_BUSY_ANIMATION,true));
		}
		protected static var levelCount:int = 1;
		protected function fileLevelNameFromMatch(match:Object, levelMetadataVector:Vector.<Object>, savedObjArray:Array):String
		{
			//find the level record based on id, and then find the levelID match
			var levelNotFound:Boolean = true;
			var index:int = 0;
			var foundObj:Object;
			
			var objID:String;
			var matchID:String;
			if(match.levelId is String)
				matchID = match.levelId;
			else
				matchID = match.levelId.$oid;
			
			while(levelNotFound)
			{
				if(index >= levelMetadataVector.length)
					break;
				
				foundObj = levelMetadataVector[index];
				if(foundObj.levelId is String)
					objID = foundObj.levelId;
				else
					objID = foundObj.levelId.$oid;
				
				if(matchID == objID)
				{
					levelNotFound = false;
					break;
				}
				index++;
			}
			if(levelNotFound)
			{
				//TODO -report error? or just skip?
				return null;
			}
			
			if(foundObj.levelId is String)
				objID = foundObj.levelId;
			else
				objID = foundObj.levelId.$oid;
			
			for(var i:int=0; i<levelMetadataVector.length;i++)
			{
				var levelObj:Object = levelMetadataVector[i];
				//we don't want ourselves
			//	if(levelObj == foundObj) there was a time when the RA info was stored here too, and as such we needed to skip this
			//		continue;
				var levelObjID:String;
				if(levelObj.levelId is String)
					levelObjID = levelObj.levelId;
				else
					levelObjID = levelObj.levelId.$oid;
				
				if(objID == levelObjID)
				{
					savedObjArray.push(levelObj);
					return levelObj.name;
				}
			}
			
			return null;
		}
		
		protected function onSignInButtonTriggered(e:starling.events.Event):void
		{
			//get client id
			Starling.current.nativeStage.addEventListener(flash.events.Event.ACTIVATE, onActivate);
			var myURL:URLRequest = new URLRequest("http://pipejam.verigames.com/login?redirect=http://pipejam.verigames.com/game/PipeJam3.html");
			navigateToURL(myURL, "_self");
		}
		
		protected function onLevelSelected(e:starling.events.Event):void
		{
			LoginHelper.getLoginHelper().levelObject = matchArrayMetadata[levelList.selectedIndex];
			
			dispatchEvent(new NavigationEvent(NavigationEvent.CHANGE_SCREEN, "PipeJamGame"));
		}
		
		private function onExitButtonTriggered():void
		{
			m_mainMenu.visible = true;
			removeChild(selectLevelDialog);
		}
		
		protected function callback(evt:flash.events.Event):void
		{
			loader = new URLLoader();
			var clientIDURL:URLRequest = new URLRequest(NetworkConnection.PROXY_URL+"/auth/csfv&method=AUTH");
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
			
			{
				dispatchEvent(new starling.events.Event(Game.START_BUSY_ANIMATION,true));
			}
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
				loginHelper.requestLevels(onRequestLevels);
				loginHelper.getLevelMetadata(onRequestLevels);
				loginHelper.getSavedLevels(onRequestLevels);
				
				selectLevelDialog = new SelectLevelDialog(this, 300, 250);
				parent.addChild(selectLevelDialog);
				selectLevelDialog.setTutorialXMLFile(PipeJamGameScene.tutorialXML);
				selectLevelDialog.visible = true;

				//do after adding to parent
				selectLevelDialog.x = (parent.width - 300)/2;
				selectLevelDialog.y = 30;// (parent.height - 100)/2 + 16;
				
				//do this after setting position, since we are setting a clip rect and it uses global coordinates
				selectLevelDialog.initialize();
				
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