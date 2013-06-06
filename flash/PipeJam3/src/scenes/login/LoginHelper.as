package scenes.login
{	
	import deng.fzip.FZip;
	import deng.fzip.FZipFile;
	
	import events.NavigationEvent;
	
	import flash.events.*;
	import flash.external.ExternalInterface;
	import flash.net.*;
	import flash.system.Security;
	import flash.text.*;
	import flash.utils.*;
	
	import starling.events.*;

	public class LoginHelper
	{				
		public static var CREATE_PLAYER:int = 0;
		public static var ACTIVATE_PLAYER:int = 1;
		public static var REQUEST_LEVELS:int = 2;
		public static var GET_LEVEL_METADATA:int = 3;
		public static var GET_ALL_LEVEL_METADATA:int = 4;
		public static var SAVE_LAYOUT:int = 5;
		public static var SAVE_CONSTRAINTS:int = 6;
		public static var REFUSE_LEVELS:int = 7;
		public static var REQUEST_LAYOUT_LIST:int = 8;
		public static var CREATE_RA_LEVEL:int = 9;	
		public static var VERIFY_SESSION:int = 10;	
		
		static public var EVENT_COMPLETE:int = 1;
		static public var EVENT_ERROR:int = 2;
				
		public static var USE_LOCAL:int = 1;
		public static var USE_DATABASE:int = 2;
		public static var USE_URL:int = 3;
				
		private var m_levelCallback:Function;
		private var onRequestLevelFinishedCallback:Function;
		private var onRequestLevelMetadataFinishedCallback:Function;
		private var onSessionValidatedCallback:Function;
		
		protected static var loginHelper:LoginHelper = null;		

		public static var levelObject:Object = null;
		
		public var levelInfoVector:Vector.<Object> = null;
		public var matchArrayObjects:Object = null;
		
		public var m_constraintsSaved:Boolean = false;
		public var m_levelCreated:Boolean = false;
		
		public static function getLoginHelper():LoginHelper
		{
			if(!loginHelper)
				loginHelper = new LoginHelper();
			
			return loginHelper;
		}
		
		
		public function LoginHelper()
		{
		}
		
		public function checkSessionID(cookies:String, callback:Function):void
		{	
			onSessionValidatedCallback = callback;
			//encode cookies
			var encodedCookies:String = escape(cookies);
			encodedCookies = cookies;
			sendMessage(VERIFY_SESSION, onSessionIDValidatingFinished, null, encodedCookies);
		}
		
		public function onSessionIDValidatingFinished(result:int, e:flash.events.Event):void
		{
			if(result == EVENT_COMPLETE)
			{
				onSessionValidatedCallback(e);
			}
			else //redirect to login page
			{
				
			}
				
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
		
		public function saveLayoutFile(m_levelLayoutXML:XML):void
		{
			//zip the file up, and then save
			var newZip:FZip = new FZip();
			var zipByteArray:ByteArray = new ByteArray();
			zipByteArray.writeUTFBytes(m_levelLayoutXML.toString());
			newZip.addFile("layout",  zipByteArray);
			var byteArray:ByteArray = new ByteArray;
			newZip.serialize(byteArray);

			sendMessage(SAVE_LAYOUT, null, byteArray, m_levelLayoutXML.@id);
		}
		
		public function saveConstraintsFile(m_levelConstraintsXML:XML):void
		{
			//need to set up proxy server to save this, and add in save constraints file when saving score
			sendMessage(SAVE_CONSTRAINTS, m_levelConstraintsXML.toString(), m_levelConstraintsXML.@id);
		}
		
		protected function onCreateNewPlayer(callback:Function):void
		{
			sendMessage(CREATE_PLAYER, callback);
		}
		
		
		public function onActivatePlayer(callback:Function):void
		{
			sendMessage(ACTIVATE_PLAYER, callback);
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
			matchArrayObjects = JSON.parse(e.target.data).matches;
			//handle callback ourselves since we want to use request info, not refuse;
			onRequestLevelFinishedCallback(result);
			sendMessage(LoginHelper.REFUSE_LEVELS, null);
		}
		
		//connect to the db and get a list of levels
		public function getLevelMetadata(callback:Function):void
		{
			levelInfoVector = null;
			onRequestLevelMetadataFinishedCallback = callback;
			sendMessage(GET_ALL_LEVEL_METADATA, setLevelMetadataFromCurrent);
		}
		
		//called when level metadata is loaded 
		public function setLevelMetadataFromCurrent(result:int, layoutObjects:Vector.<Object>):void
		{
			levelInfoVector = layoutObjects;
			onRequestLevelMetadataFinishedCallback(result);
		}
		
		//request a list of layouts associated with current levelObject xmlID
		public function onRequestLayoutList(callback:Function):void
		{
			sendMessage(REQUEST_LAYOUT_LIST, callback);
		}
		
		public function saveConstraintFile(levelConstraintsXML:XML, currentScore:int):void
		{
			//this involves:
			//saving the level
			//saving the score, level and player info
			//reporting the player performance/preference to the RA
			
			//currently we just do 1 and 2
			
			//create the graph wrapper
			
			var xmlFile:XML = <graph id="world"/>;
			xmlFile.appendChild(levelConstraintsXML);
			
			//zip the file up, and then save
			var newZip:FZip = new FZip();
			var zipByteArray:ByteArray = new ByteArray();
			zipByteArray.writeUTFBytes(xmlFile.toString());
			newZip.addFile("constraints",  zipByteArray);
			var byteArray:ByteArray = new ByteArray;
			newZip.serialize(byteArray);
			
			m_constraintsSaved = m_levelCreated = false;
			sendMessage(SAVE_CONSTRAINTS, onConstraintsFileSaved, byteArray, levelConstraintsXML.@name);
			
			sendMessage(CREATE_RA_LEVEL, onRALevelCreated, null, levelConstraintsXML.@name, new String(currentScore));
		}	
		
		public function onConstraintsFileSaved(result:int, e:flash.events.Event):void
		{
			var constraintsID:String = e.target.data;
			m_constraintsSaved  = true;
			onDBLevelCreated();
		}
		
		public function onRALevelCreated(result:int, e:flash.events.Event):void
		{
			var raLevelObj:Object = JSON.parse(e.target.data);
			var levelID:String = raLevelObj.id;
			m_levelCreated = true;
			onDBLevelCreated();
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
	
		protected function sendMessage(type:int, callback:Function, info:ByteArray = null, name:String = null, other:String = null):void
		{
			var networkConnection:NetworkConnection = new NetworkConnection();
			networkConnection.sendMessage(type, callback, info, name, other );
			
		}
	}
}	

