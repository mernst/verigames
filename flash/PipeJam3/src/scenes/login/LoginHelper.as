package scenes.login
{

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
		protected var GAME_ID:int = 1;
		public var playerID:String = "51365e65e4b0ad10f4079c88";
		public var levelObject:Object = null;
		
		public var numLevels:int = 5;
		public var currentLevel:String;
		
		public var CREATE_PLAYER:int = 0;
		public var ACTIVATE_PLAYER:int = 1;
		public var DEACTIVATE_PLAYER:int = 71;
		public var DELETE_PLAYER:int = 2;
		public var CREATE_RANDOM_LEVEL:int = 3;
		public var REQUEST_LEVELS:int = 4;
		public var START_LEVEL:int = 5;
		public var STOP_LEVEL:int = 6;
		public var ACTIVATE_LEVEL:int = 7;
		public var DEACTIVATE_LEVEL:int = 8;
		public var ACTIVATE_ALL_LEVELS:int = 9;
		public var DEACTIVATE_ALL_LEVELS:int = 10;
		public var RANDOM_REQUEST:int = 11;
		public var GET_LEVEL_METADATA:int = 12;
		public var GET_ALL_LEVEL_METADATA:int = 13;
		public var SAVE_LAYOUT:int = 14;
		public var REFUSE_LEVELS:int = 15;
		
		protected var m_currentRequestType:int = 0;
		
		static public var EVENT_COMPLETE:int = 1;
		static public var EVENT_ERROR:int = 2;
		
		//the first address is verigames, the second my machine
		//static public var PROXY_URL:String = "http://128.208.6.231:8001";
		static public var PROXY_URL:String = "http://128.95.2.112:8001";
		//		protected var apiURL:String = "http://ec2-184-72-152-11.compute-1.amazonaws.com:80";
		
		private var m_currentCallback:Function;
		private var m_levelCallback:Function;
		private var onRequestLevelFinishedCallback:Function;
		
		protected static var loginHelper:LoginHelper = null;		

		protected var levelVector:Vector.<Object> = null;
		protected var currentJSONObjects:Vector.<Object> = null
		
		public static function getLoginHelper():LoginHelper
		{
			if(!loginHelper)
				loginHelper = new LoginHelper();
			
			return loginHelper;
		}
		
		public function LoginHelper()
		{
		}
		
		//connect to the db and get a list of levels
		public function getLevelMetadata():void
		{
			m_currentCallback = setLevelMetadataFromCurrent;
			sendMessage(GET_ALL_LEVEL_METADATA);
		}
		
		//called when level metadata is loaded 
		public function setLevelMetadataFromCurrent(result:int, e:flash.events.Event):void
		{
			levelVector = currentJSONObjects;
			m_currentCallback = null;
		}
		
		
		public function onGetLevelMetadata(callback:Function):void
		{
			if(levelVector == null)
			{
				m_levelCallback = callback;
				//wait for levelVector to be non-null
				var timer : Timer = new Timer (100, 1);
				timer.addEventListener (TimerEvent.TIMER, waitForLevelVector);
				timer.start();
			}
			else
				callback(levelVector);
		}
		
		protected function waitForLevelVector(event:flash.events.Event):void
		{
			onGetLevelMetadata(m_levelCallback);
		}
		
		public function saveLayoutFile(m_levelLayoutXML:XML):void
		{
			//need to set up proxy server to save this, and add in save constraints file when saving score
			//sendMessage(SAVE_LAYOUT, m_levelLayoutXML.toString());
		}
		
		protected function onCreateNewPlayer(callback:Function):void
		{
			sendMessage(CREATE_PLAYER);
			m_currentCallback = callback;
		}
		
		
		public function onActivatePlayer(callback:Function):void
		{
			sendMessage(ACTIVATE_PLAYER);
			m_currentCallback = callback;
		}
		
		public function onDeactivatePlayer(callback:Function):void
		{
			sendMessage(DEACTIVATE_PLAYER);
			m_currentCallback = callback;
		}
		
		protected function onDeletePlayer(callback:Function):void
		{
			sendMessage(DELETE_PLAYER);
			m_currentCallback = callback;
		}
		
		//store the callback, before calling we want to send a refuse message to the RA
		//so that levels can be played by more than one player at any one time
		//i.e. we don't care if there's duplication in level playing
		public function onRequestLevels(callback:Function):void
		{
			onRequestLevelFinishedCallback = callback;
			m_currentCallback = onRequestLevelFinished;
			sendMessage(REQUEST_LEVELS);
		}
		
		public function onRequestLevelFinished(result:int, e:flash.events.Event):void
		{
			//handle callback ourselves since we want to use request info, not refuse;
			m_currentCallback = null;
			m_currentRequestType = 0;
			onRequestLevelFinishedCallback(result, e);
			sendMessage(REFUSE_LEVELS);
		}
		
		private function onCreateRandomLevel(callback:Function):void
		{
			sendMessage(CREATE_RANDOM_LEVEL);	
			m_currentCallback = callback;
		}
		
		public function onStartLevel(callback:Function):void
		{
			sendMessage(START_LEVEL);	
			m_currentCallback = callback;
		}	
		
		public function onStopLevel(callback:Function):void
		{
			sendMessage(STOP_LEVEL);
			m_currentCallback = callback;
		}
		
		
		protected function onActivateLevel(callback:Function):void
		{
			sendMessage(ACTIVATE_LEVEL);
			m_currentCallback = callback;
		}
		
		private function onDeactivateLevel(callback:Function):void
		{
			sendMessage(DEACTIVATE_LEVEL);	
			m_currentCallback = callback;
		}
		
		private function onActivateAllLevels(callback:Function):void
		{
			sendMessage(ACTIVATE_ALL_LEVELS);
			m_currentCallback = callback;
		}	
		
		private function onDeactivateAllLevels(callback:Function):void
		{
			sendMessage(DEACTIVATE_ALL_LEVELS);
			m_currentCallback = callback;
		}
		
		private function onSpecificRequest(callback:Function):void
		{
			sendMessage(RANDOM_REQUEST);
			m_currentCallback = callback;
		}

		public static function log(msg:String, caller:Object = null):void{
			var str:String = "";
			if(caller){
				str = getQualifiedClassName(caller);
				str += ":: ";
			}
			str += msg;
			trace(str);
//			if(ExternalInterface.available){
//				ExternalInterface.call("console.log", str);
//			}
		}

		
		protected function sendMessage(type:int, info:String = null):void
		{
			var request:String;
			var method:String;
			//are we busy?
			if(m_currentRequestType != 0)
				return;
			
			log(Security.sandboxType);
			
			m_currentRequestType = type;
			
			switch(type)
			{
				case CREATE_PLAYER:
					request = "/ra/games/"+GAME_ID+"/players/random";
					method = URLRequestMethod.POST; 
					break;
				case ACTIVATE_PLAYER:
					request = "/ra/games/"+GAME_ID+"/players/"+playerID+"/activate&method=PUT"; 
					method = URLRequestMethod.POST; 
					break;
				case DEACTIVATE_PLAYER:
					request = "/ra/games/"+GAME_ID+"/players/"+playerID+"/deactivate&method=PUT"; 
					method = URLRequestMethod.PUT; 
					break;
				case DELETE_PLAYER:
					request = "/ra/games/"+GAME_ID+"/players/"+playerID+"&method=DELETE"; 
					method = URLRequestMethod.DELETE; 
					break;
				case CREATE_RANDOM_LEVEL:
					request = "/ra/games/"+GAME_ID+"/levels/random";
					method = URLRequestMethod.POST; 
					break;
				case REQUEST_LEVELS:
					request = "/ra/games/"+GAME_ID+"/players/"+playerID+"/count/"+numLevels+"/match";
					method = URLRequestMethod.POST; 
					break;
				case REFUSE_LEVELS:
					request = "/ra/games/"+GAME_ID+"/players/"+playerID+"/refused&method=PUT";
					method = URLRequestMethod.POST; 
					break;
				case START_LEVEL:
				request = "/ra/games/"+GAME_ID+"/players/"+playerID+"/levels/"+currentLevel+"/started&method=PUT";
					method = URLRequestMethod.POST; 
					break;
				case STOP_LEVEL:
					request = "/ra/games/"+GAME_ID+"/players/"+playerID+"/stopped&method=PUT";
					method = URLRequestMethod.POST; 
					break;
				case ACTIVATE_LEVEL:
					request = "/ra/games/"+GAME_ID+"/levels/"+currentLevel+"/activate&method=PUT";
					method = URLRequestMethod.POST; 
					break;
				case DEACTIVATE_LEVEL:
					request = "/ra/games/"+GAME_ID+"/levels/"+currentLevel+"/deactivate&method=PUT";
					method = URLRequestMethod.POST; 
					break;
				case ACTIVATE_ALL_LEVELS:
					request = "/ra/games/"+GAME_ID+"/activateAllLevels&method=PUT";
					method = URLRequestMethod.POST; 
					break;
				case DEACTIVATE_ALL_LEVELS:
					request = "/ra/games/"+GAME_ID+"/deactivateAllLevels&method=PUT";
					method = URLRequestMethod.POST; 
					break;
				case GET_LEVEL_METADATA:
					request = "/ra/games/"+GAME_ID+"/levels/"+currentLevel+"/metadata&method=GET";
					method = URLRequestMethod.POST; 
					break;
				case GET_ALL_LEVEL_METADATA:
					request = "/metadata&method=DATABASE";
					method = URLRequestMethod.POST; 
					break;
				case SAVE_LAYOUT:
					request = "/saveLayout&method=DATABASE";
					method = URLRequestMethod.POST; 
					break;
//				case RANDOM_REQUEST:
//					request = playerNumber.text;
//					method = URLRequestMethod.POST; 
//					break;
			}

			var urlRequest:URLRequest = new URLRequest(PROXY_URL+request);
			
			if(method == URLRequestMethod.GET)
				urlRequest.method = method;
			else
			{
				urlRequest.method = URLRequestMethod.POST;
				if(info != null)
					urlRequest.data = info;
			}
			var loader:URLLoader = new URLLoader();
			configureListeners(loader);
			
			try
			{
				trace(urlRequest);
				loader.load(urlRequest);
			}
			catch(error:Error)
			{
				trace("Unable to load requested document.");
			}
		}
		
		private function configureListeners(dispatcher:flash.events.IEventDispatcher):void
		{
			dispatcher.addEventListener(flash.events.Event.COMPLETE, completeHandler);
			dispatcher.addEventListener(SecurityErrorEvent.SECURITY_ERROR, securityErrorHandler);
			dispatcher.addEventListener(HTTPStatusEvent.HTTP_STATUS, httpStatusHandler);
			dispatcher.addEventListener(IOErrorEvent.IO_ERROR, ioErrorHandler);
		}
		
		private function securityErrorHandler(e:flash.events.SecurityErrorEvent):void
		{
			log(e.text);
		}
		
		private function httpStatusHandler(e:flash.events.HTTPStatusEvent):void
		{
			trace(e.status);
		}
		
		private function ioErrorHandler(e:flash.events.IOErrorEvent):void
		{
			log(e.text);
			m_currentRequestType = 0;
			m_currentCallback(EVENT_ERROR, e);
		}
		
		private function completeHandler(e:flash.events.Event):void
		{
			trace("in complete " + e.target.data);
			var objString:String = e.target.data;
			var startIndex:int = 0;
			var index:int = objString.indexOf("_id", 10); //skip past beginning of string
			if(index != -1) //assume it a JSON database string, and parse it
			{
				var endIndex:int = objString.lastIndexOf("}", index);
				currentJSONObjects = new Vector.<Object>;
				while(endIndex != -1)
				{
					currentJSONObjects.push(JSON.parse(objString.substring(startIndex, endIndex+1)));
					startIndex = endIndex+1;
					index = objString.indexOf("_id", endIndex+20);
					endIndex = objString.lastIndexOf("}", index);
				}
				currentJSONObjects.push(JSON.parse(objString.substring(startIndex)));
				
				setLevelMetadataFromCurrent(EVENT_COMPLETE, e);
			}
			else if(m_currentCallback != null)
				m_currentCallback(EVENT_COMPLETE, e);
			m_currentRequestType = 0;
		}
	}
}