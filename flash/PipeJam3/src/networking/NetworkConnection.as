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

		static public var postAlerts:Boolean = false;
		//the first address is verigames, the second the development environ, the third my machine
		//= "http://ec2-107-21-183-34.compute-1.amazonaws.com:8001";
		//this should be the proxy server url, not the MongoDB or RA instance URL. Might be the same, might not be.
		static public var stagingProxy:String = "http://ec2-54-226-188-147.compute-1.amazonaws.com:8001";
		static public var localProxy:String = "http://128.95.2.112:8001";
		static public var PROXY_URL:String = stagingProxy;

		
		public function NetworkConnection()
		{
			if(PipeJam3.USE_LOCAL_PROXY == true)
				PROXY_URL = localProxy;
				
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
					fz.load(new URLRequest(fileName + "?version=" + Math.round(1000000*Math.random())));
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
			LoginHelper.getLoginHelper().levelObject.layout = layoutID;
			
			var layoutFileURL:String = "/layout/get/" + layoutID;
			
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
		
		public function sendMessage(type:int, callback:Function, data:String = null, name:String = null, info:Object = null, filetype:int = 0):void
		{
			var request:String;
			var levelObj:Object = LoginHelper.getLoginHelper().levelObject;
			var enc:Base64Encoder = Base64Encoder.getEncoder();
			var specificURL:String = null;
			var method:String;
			var playerID:String = PlayerValidation.playerID;
			var levelID:String
				if(levelObj != null)
					levelID = levelObj.levelId;
				
			var dataObj:Object;

			
			m_callback = callback;
			
			switch(type)
			{
				case LoginHelper.CREATE_PLAYER:
					request = "/ra/games/"+GAME_ID+"/players/"+playerID+"/new&method=POST";
					method = URLRequestMethod.POST; 
					break;
				case LoginHelper.ACTIVATE_PLAYER:
					request = "/ra/games/"+GAME_ID+"/players/"+playerID+"/activate&method=PUT"; 
					method = URLRequestMethod.POST; 
					break;
				case LoginHelper.PLAYER_EXISTS:
					request = "/ra/games/"+GAME_ID+"/players/" + playerID + "/exists&method=GET";
					method = URLRequestMethod.GET; 
					break;
				case LoginHelper.REQUEST_LEVELS:
					request = "/ra/games/"+GAME_ID+"/players/"+playerID+"/count/"+numLevels+"/match&method=POST";
					method = URLRequestMethod.POST; 
					break;
				case LoginHelper.REFUSE_LEVELS:
					request = "/ra/games/"+GAME_ID+"/players/"+playerID+"/refused&method=PUT";
					method = URLRequestMethod.POST; 
					break;
				case LoginHelper.START_LEVEL:
					request = "/ra/games/"+GAME_ID+"/players/"+playerID+"/levels/"+ levelID+"/started&method=PUT";
					method = URLRequestMethod.POST; 
					break;
				case LoginHelper.STOP_LEVEL:
					request = "/ra/games/"+GAME_ID+"/players/"+playerID+"/stopped&method=PUT";
					method = URLRequestMethod.POST; 
					break;
				case LoginHelper.REPORT_PREFERENCE:
					request = "/ra/games/"+GAME_ID+"/players/"+playerID+"/levels/"+ levelID+"/preference/"+name+"/report&method=POST";
					method = URLRequestMethod.POST; 
					break;
				case LoginHelper.REPORT_PERFORMANCE:
					request = "/ra/games/"+GAME_ID+"/players/"+playerID+"/levels/"+ levelID +"/performance/"+name+"/report&method=POST";
					method = URLRequestMethod.POST; 
					break;
				case LoginHelper.CREATE_RA_LEVEL:
					request = "/ra/games/"+GAME_ID+"/levels/new&method=POST";
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
					request = LAYOUTS_GET_ALL_REQUEST+LoginHelper.getLoginHelper().levelObject.xmlID+"&method=DATABASE";
					method = URLRequestMethod.POST; 
					break;
				case LoginHelper.GET_ALL_SAVED_LEVELS:
					request = "/level/get/saved/"+playerID+"&method=DATABASE";
					method = URLRequestMethod.POST; 
					break;
				case LoginHelper.SAVE_LAYOUT:
					levelObj =  LoginHelper.getLoginHelper().levelObject;
					request = "/layout/save/"+playerID+"/"+levelObj.xmlID+"/"+name+"&method=DATABASE";
					method = URLRequestMethod.POST; 
					break;
				case LoginHelper.DELETE_SAVED_LEVEL:
					request = "/level/delete/"+name+"&method=DATABASE";
					method = URLRequestMethod.POST; 
					break;
				case LoginHelper.SAVE_LEVEL:
					var props:Object = levelObj.metadata.properties;
					var scoreASString:String = levelObj.score;
					levelID = info as String;
					method = URLRequestMethod.POST;
					var requestStart:String = "";
					var requestMiddle:String = "";
					var requestEnd:String = "";
					//var paramObject:String = ""; maybe in the future json params and add as a param on end of request?
					if(info == null) //we are just saving the level, because we don't have a new ID
					{
						requestStart = "/level/save/";
						levelID = levelObj.levelId;
						requestEnd = "/"+filetype;
					}
					else
					{
						requestStart = "/level/submit/";
						var eRating:int = int(Math.round(levelObj.enjoymentRating*20));
						var dRating:int = int(Math.round(levelObj.difficultyRating*20));
						requestEnd = "/" + eRating+ "/"+ dRating+"/"+filetype;
					}
					
					//these need to match the proxy server, or we need to figure out json transfer...
					requestMiddle = playerID+"/"+levelObj.xmlID+"/"+encodeURIComponent(levelObj.layoutName)+"/"+levelObj.layoutID
							+ "/"+encodeURIComponent(levelObj.name)
							+ "/" + levelID +"/"+scoreASString
							+ "/" + props.boxes + "/" + props.lines+ "/"+ props.visibleboxes
							+ "/" + props.visiblelines + "/" + props.conflicts+ "/"+ props.bonusnodes;
					
					request = requestStart + requestMiddle + requestEnd + "&method=DATABASE";

					break;
				case LoginHelper.VERIFY_SESSION:
					specificURL = "http://flowjam.verigames.com/verifySession";
					request = "?cookies="+name;
					method = URLRequestMethod.POST; 
					break;
				case LoginHelper.GET_ENCODED_COOKIES:
					specificURL = "http://flowjam.verigames.com/encodeCookies";
					request = "";
					method = URLRequestMethod.POST; 
					break;
				case LoginHelper.GET_ACHIEVEMENTS:
					request = "/api/achievements/search/player?playerId=" + playerID + "&method=URL";
					method = URLRequestMethod.GET; 
					break;
				case LoginHelper.ADD_ACHIEVEMENT:
					request = "/api/achievement/assign&method=URL";
					dataObj = new Object;
					dataObj.playerId = playerID;
					dataObj.gameId = GAME_ID;
					dataObj.achievementId = name;
					dataObj.earnedOn = (new Date()).time;
					
					data = JSON.stringify(dataObj);
					enc.encode(data);
					data = enc.toString();
					method = URLRequestMethod.POST; 
					break;
				case LoginHelper.REPORT_LEADERBOARD_SCORE:
					var leaderboardScore:int = 1;
					var levelScore:int = parseInt(levelObj.score);
					var targetScore:int = parseInt(levelObj.targetScore);
					if(levelScore > targetScore)
					leaderboardScore = 2;
					request = "/api/scores&method=URL";
					dataObj = new Object;
					dataObj.playerId = playerID;
					dataObj.gameId = GAME_ID;
					dataObj.levelId = levelID;
					var parameters:Array = new Array;
					var paramScoreObj:Object = new Object;
					paramScoreObj.name = "score";
					paramScoreObj.value = levelObj.score;
					var paramLeaderScoreObj:Object = new Object;
					paramLeaderScoreObj.name = "leaderboardScore";
					paramLeaderScoreObj.value = leaderboardScore;
					parameters.push(paramScoreObj);
					parameters.push(paramLeaderScoreObj);
					dataObj.parameter = parameters;
					data = JSON.stringify(dataObj);
					enc.encode(data);
					data = enc.toString();
					method = URLRequestMethod.POST; 
					break;
				default:
					trace("message not found " + type);
					return;
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
				m_callback(LoginHelper.EVENT_ERROR, null);
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