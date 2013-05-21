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
		public static var DEACTIVATE_PLAYER:int = 71;
		public static var DELETE_PLAYER:int = 2;
		public static var CREATE_RANDOM_LEVEL:int = 3;
		public static var REQUEST_LEVELS:int = 4;
		public static var START_LEVEL:int = 5;
		public static var STOP_LEVEL:int = 6;
		public static var ACTIVATE_LEVEL:int = 7;
		public static var DEACTIVATE_LEVEL:int = 8;
		public static var ACTIVATE_ALL_LEVELS:int = 9;
		public static var DEACTIVATE_ALL_LEVELS:int = 10;
		public static var RANDOM_REQUEST:int = 11;
		public static var GET_LEVEL_METADATA:int = 12;
		public static var GET_ALL_LEVEL_METADATA:int = 13;
		public static var SAVE_LAYOUT:int = 14;
		public static var SAVE_CONSTRAINTS:int = 15;
		public static var REFUSE_LEVELS:int = 16;
		public static var REQUEST_LAYOUT_LIST:int = 17;
				
		static public var EVENT_COMPLETE:int = 1;
		static public var EVENT_ERROR:int = 2;
				
		public static var USE_LOCAL:int = 1;
		public static var USE_DATABASE:int = 2;
		public static var USE_URL:int = 3;
				
		private var m_levelCallback:Function;
		private var onRequestLevelFinishedCallback:Function;
		private var onRequestLevelMetadataFinishedCallback:Function;
		
		protected static var loginHelper:LoginHelper = null;		

		public static var levelObject:Object = null;
		
		public var levelInfoVector:Vector.<Object> = null;
		public var requestLevelVector:Vector.<Object> = null;
		
		public static function getLoginHelper():LoginHelper
		{
			if(!loginHelper)
				loginHelper = new LoginHelper();
			
			return loginHelper;
		}
		
		
		public function LoginHelper()
		{
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
			//need to set up proxy server to save this, and add in save constraints file when saving score
			sendMessage(SAVE_LAYOUT, m_levelLayoutXML.toString(), m_levelLayoutXML.@id);
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
			//handle callback ourselves since we want to use request info, not refuse;
			onRequestLevelFinishedCallback(result);
		//	JSON.parse(JSONObjString)
		//	requestLevelVector = levelObjects;
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
			trace("levelVector set");
			levelInfoVector = layoutObjects;
			onRequestLevelMetadataFinishedCallback(result);
		}
		
		//request a list of layouts associated with current levelObject xmlID
		public function onRequestLayoutList(callback:Function):void
		{
			sendMessage(REQUEST_LAYOUT_LIST, callback);
		}
		
		protected function sendMessage(type:int, callback:Function, info:String = null, name:String = null):void
		{
			var networkConnection:NetworkConnection = new NetworkConnection();
			networkConnection.sendMessage(type, callback, info, name);
			
		}
	}
}