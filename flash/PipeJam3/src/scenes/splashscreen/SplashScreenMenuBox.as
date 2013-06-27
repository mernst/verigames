package scenes.splashscreen
{
	import assets.AssetInterface;
	import assets.AssetsFont;
	import display.NineSliceButton;
	
	import display.NineSliceBatch;
	
	import events.NavigationEvent;
	
	import feathers.controls.Button;
	import feathers.controls.List;
	import feathers.data.ListCollection;
	import feathers.themes.*;
	
	import flash.events.Event;
	import flash.events.HTTPStatusEvent;
	import flash.net.*;
	import flash.text.*;
	
	import scenes.BaseComponent;
	import scenes.Scene;
	import scenes.game.PipeJamGameScene;
	import scenes.login.*;
	
	import starling.core.Starling;
	import starling.display.*;
	import starling.events.Event;
	import starling.events.TouchEvent;
	import starling.text.*;
	import starling.textures.Texture;
	import deng.fzip.FZip;
	import deng.fzip.FZipFile;
	import scenes.game.components.dialogs.SelectLevelDialog;
	
	public class SplashScreenMenuBox extends BaseComponent
	{
		protected var m_mainMenu:starling.display.Sprite;
		
		protected var play_button:feathers.controls.Button;
		protected var signin_button:feathers.controls.Button;
		protected var tutorial_button:NineSliceButton;
		protected var demo_button:NineSliceButton;
		
		protected var loader:URLLoader;
		protected var loginHelper:LoginHelper;
		protected var m_parent:SplashScreenScene;
				
		protected var levelList:List = null;
		protected var levelMetadataArray:Array = null;
		protected var matchArrayObjects:Array = null;
		protected var matchArrayMetadata:Array = null;
		
		public var inputInfo:flash.text.TextField;
		protected var tutorialZipFile:FZip;
		
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
			
		//	play_button.x = (this.stage.stageWidth - play_button.width) / 2;
		//	play_button.y = (this.stage.stageHeight - play_button.height) / 2;
			var obj:Object =play_button.defaultLabelProperties;
			obj.textFormat = new TextFormat(AssetsFont.FONT_UBUNTU, 36, 0xffffff);
			play_button.defaultLabelProperties = obj;
			signin_button.defaultLabelProperties = obj;

		}
		
		protected function removedFromStage(event:starling.events.Event):void
		{
			
		}
		
		protected function buildMainMenu():void
		{
			m_mainMenu = new Sprite();
			
			var playButtonUp:Texture = AssetInterface.getTexture("Menu", "PlayButtonClass");
			var playButtonClick:Texture = AssetInterface.getTexture("Menu", "PlayButtonClickClass");
			
			//change scale to get buttons to (mostly) look right. Should figure out why they look wrong and fix that...
			scaleX = .25;
			scaleY = .25;
			
			play_button = new feathers.controls.Button();
			play_button.label = " Play ";
			play_button.addEventListener(starling.events.Event.TRIGGERED, onPlayButtonTriggered);
			play_button.x = 1300;
			play_button.y = 950;
			
			play_button.width = 400;
			play_button.height = 150;
			
			signin_button = new feathers.controls.Button();
			signin_button.label = " Log In ";
			signin_button.addEventListener(starling.events.Event.TRIGGERED, onSignInButtonTriggered);
			signin_button.x = 1300;
			signin_button.y = 950;
			
			signin_button.width = 400;
			signin_button.height = 150;

			
			if(PipeJamGame.PLAYER_LOGGED_IN || !PipeJam3.RELEASE_BUILD)
			{			
				m_mainMenu.addChild(play_button);
				m_mainMenu.removeChild(signin_button);
			}
			else
			{
				m_mainMenu.removeChild(play_button);
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
			

			if(!PipeJam3.RELEASE_BUILD)
			{
				tutorial_button = ButtonFactory.getInstance().createDefaultButton("Tutorial", 256, 96);
				tutorial_button.addEventListener(starling.events.Event.TRIGGERED, onTutorialButtonTriggered);
				tutorial_button.x = 16;
				tutorial_button.y = 32;
				m_mainMenu.addChild(tutorial_button);
				
				demo_button = ButtonFactory.getInstance().createDefaultButton("Demo", 256, 96);
				demo_button.addEventListener(starling.events.Event.TRIGGERED, onDemoButtonTriggered);
				demo_button.x = 16;
				demo_button.y = 312;
				m_mainMenu.addChild(demo_button);
			}
		}
		
		protected function onRequestLevels(result:int):void
		{
			if(result == LoginHelper.EVENT_COMPLETE)
			{
				if(loginHelper.levelInfoVector != null && loginHelper.matchArrayObjects != null)
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
				var levelName:String = fileLevelNameFromMatch(match, loginHelper.levelInfoVector);
				if(levelName != null)
					levelMetadataArray.push(levelName);
			}
			
			//we are done, show everything
			// Creating the dataprovider
			var matchCollection:ListCollection = new ListCollection(levelMetadataArray);
			selectLevelDialog.setDialogInfo(matchCollection, matchArrayMetadata);
			
			dispatchEvent(new starling.events.Event(Game.STOP_BUSY_ANIMATION,true));
			
			m_mainMenu.visible = false;
			selectLevelDialog.visible = true;
			
		}
		protected static var levelCount:int = 1;
		protected function fileLevelNameFromMatch(match:Object, levelMetadataVector:Vector.<Object>):String
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
					matchArrayMetadata.push(levelObj);
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
			LoginHelper.levelObject = matchArrayMetadata[levelList.selectedIndex];
			
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
			dispatchEvent(new starling.events.Event(Game.START_BUSY_ANIMATION,true));
			
			//do this, although player probably is already be activated
			if(!PipeJam3.playerActivated)
				loginHelper.activatePlayer(onPlayerActivated);
			else
				onPlayerActivated(0, null);
		}
		
		protected function onPlayerActivated(result:int, e:flash.events.Event):void
		{
			//check for tutorial cookies, and if not found, or incomplete, do that, else load real levels
			//get Tutorial file
			tutorialZipFile = new FZip();
			LoginHelper.getLoginHelper().loadFile(LoginHelper.USE_LOCAL, null, PipeJamGameScene.tutorialButtonWorldFile, getLevels, tutorialZipFile);
		}
		
		protected function getLevels(e:flash.events.Event):void
		{
			if(isTutorialDone())
			{
				loginHelper.requestLevels(onRequestLevels);
				loginHelper.getLevelMetadata(onRequestLevels);
				
				selectLevelDialog = new SelectLevelDialog(this);
				//the containing menubox is scaled wierdly
				selectLevelDialog.width = 175;
				selectLevelDialog.height = 250;
				
				parent.addChild(selectLevelDialog);
				
				//do after adding to parent
				selectLevelDialog.centerDialog();
			//	m_levelMenu.x = m_mainMenu.x;
			//	m_levelMenu.y = m_mainMenu.y;
				PipeJamGameScene.inTutorial = false;
			}
			else
				loadTutorial();
		}
		
		protected function isTutorialDone():Boolean
		{
			//unpack tutorial zip file, and count levels
			if(tutorialZipFile.getFileCount() > 0)
			{
				var zipFile:FZipFile = tutorialZipFile.getFileAt(0);
				trace(zipFile.filename);
				var tutorialXML:XML = new XML(zipFile.content);
				PipeJamGameScene.numTutorialLevels = tutorialXML["level"].length();
			}
			
			var tutorialStatus:String = HTTPCookies.getCookie("tutorialLevelCompleted");
			if(!isNaN(parseInt(tutorialStatus)))
				PipeJamGameScene.numTutorialLevelsCompleted = parseInt(tutorialStatus);
			
			if(PipeJamGameScene.numTutorialLevelsCompleted >= PipeJamGameScene.numTutorialLevels)
				return true;
			else
				return false;
		}
		
		protected function onTutorialButtonTriggered(e:starling.events.Event):void
		{
			loadTutorial();
		}
		
		protected function loadTutorial():void
		{
			PipeJamGameScene.inTutorial = true;
			PipeJamGameScene.worldFile = PipeJamGameScene.tutorialButtonWorldFile;
			PipeJamGameScene.layoutFile = PipeJamGameScene.tutorialButtonLayoutFile;
			PipeJamGameScene.constraintsFile = PipeJamGameScene.tutorialButtonConstraintsFile;
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