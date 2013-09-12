package networking
{	
	import deng.fzip.FZip;
	import deng.fzip.FZipFile;
	
	import events.MenuEvent;
	import events.NavigationEvent;
	
	import flash.events.*;
	import flash.net.*;
	import flash.system.Security;
	import flash.text.*;
	import flash.utils.*;
	
	import scenes.game.display.World;
	
	import starling.events.*;
	
	import utils.XString;

	public class LoginHelper
	{				
		public static var CREATE_PLAYER:int = 0;
		public static var ACTIVATE_PLAYER:int = 1;
		public static var REQUEST_LEVELS:int = 2;
		public static var GET_LEVEL_METADATA:int = 3;
		public static var GET_ALL_LEVEL_METADATA:int = 4;
		public static var SAVE_LAYOUT:int = 5;
		public static var REFUSE_LEVELS:int = 7;
		public static var REQUEST_LAYOUT_LIST:int = 8;
		public static var CREATE_RA_LEVEL:int = 9;	
		public static var VERIFY_SESSION:int = 10;
		public static var PLAYER_EXISTS:int = 11;
		public static var SAVE_LEVEL:int = 12;
		public static var GET_ENCODED_COOKIES:int = 13;
		public static var GET_ALL_SAVED_LEVELS:int = 14;
		public static var DELETE_SAVED_LEVEL:int = 15;
		public static var START_LEVEL:int = 16;
		public static var STOP_LEVEL:int = 17;
		public static var REPORT_PERFORMANCE:int = 18;
		public static var REPORT_PREFERENCE:int = 19;
		public static var ADD_ACHIEVEMENT:int = 20;
		public static var REPORT_LEADERBOARD_SCORE:int = 21;
		public static var GET_ACHIEVEMENTS:int = 22;
		public static var TUTORIAL_LEVEL_COMPLETE:int = 23;
		public static var GET_COMPLETED_TUTORIAL_LEVELS:int = 24;
		
		static public var EVENT_COMPLETE:int = 1;
		static public var EVENT_ERROR:int = 2;
				
		public static var USE_LOCAL:int = 1;
		public static var USE_DATABASE:int = 2;
		public static var USE_URL:int = 3;
		
		public static var LEVEL_SAVED:String = "LEVEL_SAVED";
		public static var LEVEL_SUBMITTED:String = "LEVEL_SUBMITTED";
		
		private var m_levelCallback:Function;
		private var onRequestLevelFinishedCallback:Function;
		private var onRequestLevelMetadataFinishedCallback:Function;
		private var onRequestSavedLevelsFinishedCallback:Function;
		
		protected static var loginHelper:LoginHelper = null;		

		public var levelObject:Object = null;
		
		public var levelInfoVector:Vector.<Object> = null;
		public var matchArrayObjects:Object = null;
		public var savedMatchArrayObjects:Vector.<Object> = null;
		
		public var m_constraintsSaved:Boolean = false;
		public var m_levelCreated:Boolean = false;
		public var m_levelSubmitted:Boolean = false;
		
		protected var m_world:World;
		public var m_layoutName:String;
		
		public static function getLoginHelper():LoginHelper
		{
			if(!loginHelper)
				loginHelper = new LoginHelper();
			
			//make sure this is set, since we are created before the world
			loginHelper.m_world = World.m_world;
			return loginHelper;
		}
		
		
		public function LoginHelper()
		{

		}
		
		public function getEncodedCookies(callback:Function):void
		{	
			sendMessage(GET_ENCODED_COOKIES, callback);
		}
		
		public function checkSessionID(cookies:String, callback:Function):void
		{	
			//encode cookies
			var encodedCookies:String = escape(cookies);
			encodedCookies = cookies;
			sendMessage(VERIFY_SESSION, callback, null, encodedCookies);
		}
		
		public function checkPlayerExistence(callback:Function):void
		{
			sendMessage(PLAYER_EXISTS, callback);
		}
		
		public function createPlayer(playerID:String, callback:Function):void
		{
			sendMessage(CREATE_PLAYER, callback);
		}
		
		public function activatePlayer(playerID:String, callback:Function):void
		{
			sendMessage(ACTIVATE_PLAYER, callback);
		}
		
		//load files from disk or database
		public function loadFile(loadType:int, loader:URLLoader, fileName:String, callback:Function, fz:FZip = null):void
		{
			var networkConnection:NetworkConnection = new NetworkConnection();
			networkConnection.loadFile(loadType, loader, fileName, callback, fz);
		}
		
		public function getNewLayout(layoutID:String, callback:Function):void
		{
			var networkConnection:NetworkConnection = new NetworkConnection();
			networkConnection.getNewLayout(layoutID, callback);
		}
		
		public function saveLayoutFile(callback:Function, _levelLayoutString:String):void
		{
			var layoutDescription:String = levelObject.layoutName + "::" + levelObject.layoutDescription;

			var encodedLayoutDescription:String = encodeURIComponent(layoutDescription);
			sendMessage(SAVE_LAYOUT, callback, _levelLayoutString, encodedLayoutDescription);
		}
		
		public function deleteSavedLevel(_levelIDString:String):void
		{
			sendMessage(DELETE_SAVED_LEVEL, null, null, _levelIDString);
		}
		
		//store the callback, before calling we want to send a refuse message to the RA
		//so that levels can be played by more than one player at any one time
		//i.e. we don't care if there's duplication in level playing
		public function requestLevels(callback:Function):void
		{
			onRequestLevelFinishedCallback = callback;
			sendMessage(REQUEST_LEVELS, onRequestLevelFinished);
		}
		
		public function onRequestLevelFinished(result:int, e:flash.events.Event):void
		{
			if(e != null)
			{
				matchArrayObjects = JSON.parse(e.target.data).matches;
				//handle callback ourselves since we want to use request info, not refuse;
				onRequestLevelFinishedCallback(result);
				sendMessage(LoginHelper.REFUSE_LEVELS, null);
			}
		}
		
		public function refuseLevels():void
		{
			sendMessage(LoginHelper.REFUSE_LEVELS, null);
		}
		
		public function startLevel(levelObj:Object):void
		{
			this.levelObject = levelObj;
			sendMessage(LoginHelper.START_LEVEL, null);
		}
		
		public function stopLevel():void
		{
			sendMessage(LoginHelper.STOP_LEVEL, null);
		}
		
		public function reportPlayerPerformance(score:String):void
		{
			sendMessage(LoginHelper.REPORT_PERFORMANCE, null, null, score);
		}
		
		public function reportPlayerPreference(score:String):void
		{
			sendMessage(LoginHelper.REPORT_PREFERENCE, null, null, score);
		}
		
		//connect to the db and get a list of all levels
		public function getLevelMetadata(callback:Function):void
		{
			levelInfoVector = null;
			onRequestLevelMetadataFinishedCallback = callback;
			sendMessage(GET_ALL_LEVEL_METADATA, setLevelMetadataFromCurrent);
		}
		
		//connect to the db and get a list of all saved levels
		public function getSavedLevels(callback:Function):void
		{
			savedMatchArrayObjects = null;
			onRequestSavedLevelsFinishedCallback = callback;
			sendMessage(GET_ALL_SAVED_LEVELS, onRequestSavedLevelsFinished);
		}
		
		public function onRequestSavedLevelsFinished(result:int, layoutObjects:Vector.<Object>):void
		{
			savedMatchArrayObjects = layoutObjects;
			onRequestSavedLevelsFinishedCallback(result);

		}
		
		//called when level metadata is loaded 
		public function setLevelMetadataFromCurrent(result:int, layoutObjects:Vector.<Object>):void
		{
			levelInfoVector = layoutObjects;
			onRequestLevelMetadataFinishedCallback(result);
		}
		
		//request a list of layouts associated with current levelObject xmlID
		public function getLayoutList(callback:Function):void
		{
			sendMessage(REQUEST_LAYOUT_LIST, callback);
		}
		
		protected var m_levelFilesString:String;
		protected var m_currentMessageType:String;
		protected var m_fileType:int;
		public function submitLevel(_levelFilesString:String, type:String, fileType:int = 1):void
		{
			//this involves:
			//saving the level (layout and constraints, on either save or submit/share)
			//saving the score, level and player info
			//reporting the player performance/preference to the RA
			
			//currently we just do 1 and 2
			m_levelFilesString = _levelFilesString;
			m_currentMessageType = type;
			m_fileType = fileType;
		
			//need to create an RA Level so we can use the levelID
			if(type == MenuEvent.SUBMIT_LEVEL)
				sendMessage(CREATE_RA_LEVEL, onRALevelCreated, null, levelObject.name);
			else //save level
				submitLevelWithID(null, fileType);
		}	
		
		//if levelID == null, we are just saving, not submitting (which creates a new level id for future use...)
		public function submitLevelWithID(levelID:String, fileType:int):void
		{
			sendMessage(SAVE_LEVEL, onLevelSubmitted, m_levelFilesString, levelObject.name, levelID, fileType);
		}
	
		public function onLevelSubmitted(result:int, e:flash.events.Event):void
		{
			if(m_currentMessageType == MenuEvent.SAVE_LEVEL)
				m_world.dispatchEvent(new MenuEvent(LEVEL_SAVED));
			else
				m_world.dispatchEvent(new MenuEvent(LEVEL_SUBMITTED));
		}
		
		public function reportScore():void
		{
			sendMessage(LoginHelper.REPORT_LEADERBOARD_SCORE, null);
		}
		
		public function onRALevelCreated(result:int, e:flash.events.Event):void
		{
			var raLevelObj:Object = JSON.parse(e.target.data);
			var levelID:String = raLevelObj.id;
			m_levelCreated = true;
			submitLevelWithID(levelID, m_fileType);
		}
		
	
		
		public function onDBLevelCreated():void
		{
			//need the constraints file id and the level id to create a db level (reuse the current xmlID and layoutID)
			//also should add user id, so we can track who did what
			if(m_constraintsSaved == true && m_levelCreated == true)
			{
			//	sendMessage(CREATE_DB_LEVEL, null, ??????);
			}
		}
	
		//save the current level id and the player id for lookup later.
		public function reportTutorialLevelComplete():void
		{
			sendMessage(TUTORIAL_LEVEL_COMPLETE, null);
			
		}
		
		public function sendMessage(type:int, callback:Function, data:String = null, name:String = null, infoObj:Object = null, filetype:int = 0):void
		{
			var networkConnection:NetworkConnection = new NetworkConnection();
			networkConnection.sendMessage(type, callback, data, name, infoObj, filetype);
		}
		

	}
}	

