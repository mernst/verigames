package scenes.login
{
	import scenes.game.display.GameComponent;
	import flash.net.*;
	import deng.fzip.FZip;
	import flash.system.Security;
	import flash.events.*;
	import deng.fzip.FZipFile;
	import flash.utils.ByteArray;
	import utils.Base64Encoder;

	//used by LoginHelper, one NetworkConnection object created for each connection and used only once
	//attached to the parent object, which is responsible for cleanup
	public class NetworkConnection
	{
		public var done:Boolean = false;
		public var m_callback:Function = null;
		
		protected var GAME_ID:int = 1;
		public var numLevels:int = 5;
		
		static public var METADATA_GET_ALL_REQUEST:String = "/level/metadata/get/all";
		static public var LAYOUTS_GET_ALL_REQUEST:String = "/layout/get/all/";

		//the first address is verigames, the second the development environ, the third my machine
	//	static public var PROXY_URL:String = "http://ec2-107-21-183-34.compute-1.amazonaws.com:8001";
	//	static public var PROXY_URL:String = "http://ec2-184-72-152-11.compute-1.amazonaws.com:8001";
		static public var PROXY_URL:String = "http://128.95.2.112:8001";

		
		public function NetworkConnection()
		{
			PipeJamGame.addNetworkConnection(this);
		}
		
		public function dispose():void
		{
			
		}
		
		
		//load files from disk or database
		public function loadFile(loadType:int, loader:URLLoader, fileName:String, callback:Function, fz:FZip = null):void
		{
			switch(loadType)
			{
				case LoginHelper.USE_DATABASE:
				{
					fz.addEventListener(flash.events.Event.COMPLETE, callback);
					fz.load(new URLRequest(PROXY_URL +fileName+ "&method=DATABASE"));
					break;
				}
				case LoginHelper.USE_LOCAL:
				{
					fz.addEventListener(flash.events.Event.COMPLETE, callback);
					fz.load(new URLRequest(fileName));
					break;
				}
				case LoginHelper.USE_URL:
				{
					loader.addEventListener(flash.events.Event.COMPLETE, callback);
					loader.load(new URLRequest(fileName + "?version=" + Math.round(1000000*Math.random())));
					break;
				}
			}
		}
		
		protected var fzip:FZip;
		public function getNewLayout(layoutID:String, callback:Function):void
		{
			m_callback = callback;
			LoginHelper.levelObject.layout = layoutID;
			
			var layoutFileURL:String = "/level/get/" + layoutID +"/layout";
			
			fzip = new FZip();
			loadFile(LoginHelper.USE_DATABASE, null, layoutFileURL, layoutZipLoaded, fzip);
		}
		
		private function layoutZipLoaded(e:flash.events.Event):void {
			fzip.removeEventListener(flash.events.Event.COMPLETE, layoutZipLoaded);
			if(fzip.getFileCount() > 0)
			{
				var zipFile:FZipFile = fzip.getFileAt(0);
				trace(zipFile.filename);
				m_callback(zipFile.content);
			}
			else
				trace("zip failed");
		}
		
		public function sendMessage(type:int, callback:Function, info:ByteArray = null, name:String = null, other:String = null):void
		{
			var request:String;
			var specificURL:String = null;
			var method:String;
			var playerID:String = PipeJam3.playerID;
			
			m_callback = callback;
			
			switch(type)
			{
				case LoginHelper.CREATE_PLAYER:
					request = "/ra/games/"+GAME_ID+"/players/random";
					method = URLRequestMethod.POST; 
					break;
				case LoginHelper.ACTIVATE_PLAYER:
					request = "/ra/games/"+GAME_ID+"/players/"+playerID+"/activate&method=PUT"; 
					method = URLRequestMethod.POST; 
					break;
				case LoginHelper.REQUEST_LEVELS:
					request = "/ra/games/"+GAME_ID+"/players/"+playerID+"/count/"+numLevels+"/match";
					method = URLRequestMethod.POST; 
					break;
				case LoginHelper.REFUSE_LEVELS:
					request = "/ra/games/"+GAME_ID+"/players/"+playerID+"/refused&method=PUT";
					method = URLRequestMethod.POST; 
					break;
				case LoginHelper.CREATE_RA_LEVEL:
					request = "/ra/games/"+GAME_ID+"/levels/new";
					method = URLRequestMethod.POST; 
					break;

				//database messages
				case LoginHelper.GET_ALL_LEVEL_METADATA:
					request = METADATA_GET_ALL_REQUEST+"&method=DATABASE";
					method = URLRequestMethod.POST; 
					break;
				case LoginHelper.GET_LEVEL_METADATA:
					request = "/level/metadata/get/"+name+"&method=DATABASE";
					method = URLRequestMethod.POST; 
					break;
				case LoginHelper.REQUEST_LAYOUT_LIST:
					request = LAYOUTS_GET_ALL_REQUEST+LoginHelper.levelObject.xmlID+"&method=DATABASE";
					method = URLRequestMethod.POST; 
					break;
				case LoginHelper.SAVE_LAYOUT:
					request = "/layout/save/"+LoginHelper.levelObject.xmlID+"/"+name+"&method=DATABASE";
					method = URLRequestMethod.POST; 
					break;
				case LoginHelper.SAVE_CONSTRAINTS:
					var scoreASString:String = other;
					request = "/level/save/"+LoginHelper.levelObject.xmlID+"/"+name+"/"+scoreASString+"&method=DATABASE";
					method = URLRequestMethod.POST; 
					break;
				case LoginHelper.VERIFY_SESSION:
				//	request = "/"+name+"&method=VERIFY";
					specificURL = "http://trafficjam.verigames.com/verifySession";
					request = "?cookies="+name;
					method = URLRequestMethod.POST; 
					break;
			}
			
			var urlRequest:URLRequest;
			if(specificURL != null)
				urlRequest = new URLRequest(specificURL+request);
			else
				urlRequest = new URLRequest(PROXY_URL+request);
			
			if(method == URLRequestMethod.GET)
				urlRequest.method = method;
			else
			{
				urlRequest.method = URLRequestMethod.POST;
				if(info != null)
				{
					var encoder:Base64Encoder = new Base64Encoder();
					encoder.encodeBytes(info);
					var encodedString:String = encoder.toString();
					urlRequest.contentType = URLLoaderDataFormat.TEXT;
					trace(encodedString.length);
					trace(encodedString);
					urlRequest.data = encodedString+"\n"; //terminate line so Java can use readLine to get message
				}
				else
					urlRequest.data = null;
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
			trace(e.text);
		}
		
		private function httpStatusHandler(e:flash.events.HTTPStatusEvent):void
		{
			trace(e.status);
		}
		
		private function ioErrorHandler(e:flash.events.IOErrorEvent):void
		{
			trace(e.text);
			if(m_callback != null)
				m_callback(LoginHelper.EVENT_ERROR, e);
		}
		
		private function completeHandler(e:flash.events.Event):void
		{
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
					m_callback(LoginHelper.EVENT_COMPLETE, currentJSONObjects);
				}
				else if(m_callback != null)
					m_callback(LoginHelper.EVENT_COMPLETE, e);
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