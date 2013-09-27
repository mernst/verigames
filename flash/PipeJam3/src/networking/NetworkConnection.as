package networking
{
	import deng.fzip.FZip;
	import deng.fzip.FZipFile;
	
	import flash.events.*;
	import flash.net.*;
	import flash.system.Security;
	import flash.utils.ByteArray;
	import flash.utils.Dictionary;
	
	import scenes.game.display.GameComponent;
	import scenes.game.display.World;
	
	import utils.Base64Decoder;
	import utils.Base64Encoder;

	//one NetworkConnection object created for each connection and used only once
	public class NetworkConnection
	{
		public var done:Boolean = false;
		public var m_callback:Function = null;
		
		static public var postAlerts:Boolean = false;
		//the first address is verigames, the second the development environ, the third my machine
		//= "http://ec2-107-21-183-34.compute-1.amazonaws.com:8001";
		//this should be the proxy server url, not the MongoDB or RA instance URL. Might be the same, might not be.
		static public var stagingProxy:String = "http://ec2-54-226-188-147.compute-1.amazonaws.com:8001";
		static public var localProxy:String = "http://128.95.2.112:8001";
		static public var PROXY_URL:String = stagingProxy;
		
		static public var EVENT_COMPLETE:int = 1;
		static public var EVENT_ERROR:int = 2;
		
		public function NetworkConnection()
		{
			if(PipeJam3.USE_LOCAL_PROXY == true)
				PROXY_URL = localProxy;
		}
		
		/**
		 * args:
		 * callback - completion callback
		 * request - request to pass to host
		 * data - any data to send with message
		 * url - Specific URL to send message to. Defaults to proxy URL if null
		 * method - type of message (GET, POST, etc)
		 * */
		static public function sendMessage(callback:Function, request:String, data:String = null, url:String = null, method:String = URLRequestMethod.GET):void
		{
			if(url == null)
				url = PROXY_URL;
			
			var connection:NetworkConnection = new NetworkConnection();
			connection.m_callback = callback;
			connection.sendURL(request, data, method, url);
		}
			
		protected function sendURL(request:String, data:String, method:String, url:String):void
		{
			var urlRequest:URLRequest;
			var rand:String = "";
			 //IE caches all requests, so things don't update properly without this
			if(request.indexOf('&') != -1)
				rand = "&rand="+String(Math.round(Math.random()*1000));
			
			urlRequest = new URLRequest(url+request+rand);
			
			if(method == URLRequestMethod.GET)
				urlRequest.method = method;
			else
			{
				urlRequest.method = URLRequestMethod.POST;
				if(data != null)
				{
					urlRequest.contentType = URLLoaderDataFormat.TEXT;
					urlRequest.data = data+"\n"; //terminate line so Java can use readLine to get message
				}
				else
					urlRequest.data = null;
			}
			var loader:URLLoader = new URLLoader();
			configureListeners(loader);
			
			try
			{
				trace(urlRequest.url);
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
			trace(e.text);
			if(postAlerts)
				HTTPCookies.displayAlert(e.text);
		}
		
		private function httpStatusHandler(e:flash.events.HTTPStatusEvent):void
		{
			trace(e.status);
			if(postAlerts)
				HTTPCookies.displayAlert(String(e.status));
		}
		
		private function ioErrorHandler(e:flash.events.IOErrorEvent):void
		{
			trace(e.text);
			if(postAlerts)
				HTTPCookies.displayAlert(e.text);
			if(m_callback != null)
				m_callback(EVENT_ERROR, null);
		}
		
		private function completeHandler(e:flash.events.Event):void
		{
			if(postAlerts)
				HTTPCookies.displayAlert("complete");
			try
			{
				trace("in complete " + e.target.data);
				var objString:String = e.target.data;
				var messageTypeEnd:int = objString.indexOf("//");
				if(messageTypeEnd != -1)
				{
					var messageType:String = objString.substring(0, messageTypeEnd);
					var startIndex:int = messageTypeEnd + 2;
					var objEndIndex:int = findJSONObjectEnd(objString, startIndex);
					
					var currentJSONObjects:Vector.<Object> = new Vector.<Object>;
					while(objEndIndex != -1)
					{
						var JSONObjString:String = objString.substring(startIndex, objEndIndex+1);
						currentJSONObjects.push(JSON.parse(JSONObjString));
						startIndex = objEndIndex+1;
						objEndIndex = findJSONObjectEnd(objString, startIndex);
					}
					
					trace("return message " + messageType);
					m_callback(EVENT_COMPLETE, currentJSONObjects);
				}
				else if(m_callback != null)
					m_callback(EVENT_COMPLETE, e);
			}
			catch(err:Error)
			{
				trace("ERROR: failure in complete handler " + err);
			}
		}
		
		//when passed an array of JSON objects, or a single object, will
		//find the end of the first JSON object starting at startIndex
		//returns index of end character, or -1 if end not found
		public function findJSONObjectEnd(str:String, startIndex:int = 0):int
		{
			var currentIndex:int = startIndex;
			var strLength:int = str.length;
			
			//if we don't have a long enough string, return
			if(startIndex > strLength-2)
				return -1;
			
			var braceCount:int = 0;
			do{
				var currChar:String = str.charAt(currentIndex);
				if(currChar == '{')
					braceCount++;
				else if(currChar == '}')
					braceCount--;
				currentIndex++;	
			}while(braceCount != 0 && currentIndex < strLength);
			
			if(braceCount == 0)
				return currentIndex-1;
			else
				return -1;
		}
	}
}