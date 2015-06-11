package server 
{
	import flash.events.Event;
	import flash.events.HTTPStatusEvent;
	import flash.events.IOErrorEvent;
	import flash.events.SecurityErrorEvent;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.net.URLRequestHeader;
	import flash.net.URLRequestMethod;
	import flash.net.URLVariables;
	
	import utils.PM_PRNG;
	
	public class MTurkAPI 
	{
		private static const TURK_API:String = "https://mturk-api.verigames.org";
		private static const REFRESH_TOKEN_PATH:String = "/oauth/token";
		private static var m_instance:MTurkAPI;
		
		public var initialized:Boolean = false;
		public var workerToken:String;
		public var taskId:String = "101";
		private var m_accessToken:String;
		
		
		public static function getInstance():MTurkAPI
		{
			if (m_instance == null) {
				m_instance = new MTurkAPI(new SingletonLock());
			}
			return m_instance;
		}
		
		public function MTurkAPI(lock:SingletonLock) 
		{
			getToken(onTokenResponse);
		}
		
		private function getToken(callback:Function):void
		{
			var urlVars:URLVariables = new URLVariables();
			urlVars.grant_type = "refresh_token";
			urlVars.refresh_token = "45P4TjNciiPqShyR5LK0w5rF8YapNY";
			var req:URLRequest = new URLRequest(TURK_API + REFRESH_TOKEN_PATH);
			//req.contentType = "application/json";
			req.data = urlVars;
			var header:URLRequestHeader = new URLRequestHeader("Authorization", "Basic MTpkZW1vLXNlY3JldA==");
			req.requestHeaders.push(header);
			req.method = URLRequestMethod.POST;
			var loader:URLLoader = new URLLoader();
			
			function completeHandler(e:Event):void
			{
				callback(loader.data);
			}
			
			function httpStatusHandler(e:HTTPStatusEvent):void
			{
				trace(e.status);
			}
			
			function securityErrorHandler(e:SecurityErrorEvent):void
			{
				trace(e.text);
				callback(null);
			}
			
			function ioErrorHandler(e:IOErrorEvent):void
			{
				trace(e.text);
				callback(null);
			}
			
			loader.addEventListener(Event.COMPLETE, completeHandler);
			loader.addEventListener(HTTPStatusEvent.HTTP_STATUS, httpStatusHandler);
			loader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, securityErrorHandler);
			loader.addEventListener(IOErrorEvent.IO_ERROR, ioErrorHandler);
			loader.load(req);
		}
		
		private function onTokenResponse(data:Object):void
		{
			if (data == null) return;
			data = JSON.parse(data as String);
			if (data.hasOwnProperty("access_token"))
			{
				m_accessToken = data["access_token"] as String;
				initialized = true;
			}
		}
		
		public function onTaskComplete():void
		{
			var newCode:String = "";
			var rand:PM_PRNG = new PM_PRNG((new Date()).time);
			var hexChars:String = new String("0123456789abcdef");
			for (var i:int = 0; i < 10; i++)
			{
				var indx:int = rand.nextIntRange(0, hexChars.length - 1);
				newCode += hexChars.charAt(indx);
			}
			
			var data:Object = {
				"token": workerToken,
				"code": newCode
			};
		}
		
	}

}

internal class SingletonLock {} // to prevent outside construction of singleton