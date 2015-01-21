package networking
{
	import flash.events.Event;
	import flash.net.URLRequestMethod;
	import flash.utils.Dictionary;
	
	import scenes.Scene;
	
	import server.LoggingServerInterface;

	//the steps are: 
	//	get the cookie with the express.sid value
	//  send that to validateSession, to see if it's still a valid session id
	//	if it is, you will get the player ID number, else null

	public class PlayerValidation
	{
		public static var VERIFY_SESSION:int = 1;
		public static var GET_ENCODED_COOKIES:int = 2;
		public static var PLAYER_INFO:int = 3;
		public static var ACCESS_TOKEN:int = 4;
		
		public static var AuthorizationAttempted:Boolean = false;
		public static var accessToken:String = null;
		
		public static var playerID:String = "";
		public static var playerIDForTesting:String = "51e5b3460240288229000026"; //hard code one for local testing
		public static var userNames:Dictionary = new Dictionary;
		public static var outstandingUserNamesRequests:int = 0;
		
		public static var LOGIN_STATUS_CHANGE:String = "login_status_change";
		
		static public var validationObject:PlayerValidation = new PlayerValidation;
		protected var pipejamCallbackFunction:Function;
		protected var controller:Scene = null;
		protected var encodedCookies:String;
		
		static public var GETTING_COOKIE:String = "Getting Cookie";
		static public var VALIDATING_SESSION:String = "Validating Session";
		static public var ACTIVATING_PLAYER:String = "Activating Player";
		static public var GETTING_PLAYER_INFO:String = "Getting Player ID";
		
		static public var VALIDATION_SUCCEEDED:String = "Player Logged In";
		static public var VALIDATION_FAILED:String = "Validation Failed";
		
		static public var authURL:String = "http://oauth.verigames.org/oauth2/authorize";
		static public var redirect_uri:String ="http://paradox.verigames.org/game/PipeJam3.html";
		static public var client_id:String = "54b97ebee0da42ff17b927c5";
		static public var oauthURL:String = "http://oauth.verigames.org/oauth2/token";
		
		
		public static function initiateAccessTokenAccess(accessCode:String):void
		{
			validationObject.getAccessToken(accessCode);
		}
		
		public function getAccessToken(accessCode:String):void
		{
			var obj:Object = new Object;
			obj.code = accessCode;
			obj.client_id = "54b97ebee0da42ff17b927c5";
			obj.client_secret = "3D89WG3WJHEW789WERQH34234";
			obj.grant_type = "authorization_code";
			obj.redirect_uri = redirect_uri;
			var objStr:String = JSON.stringify(obj);
			sendMessage(ACCESS_TOKEN, tokenCallback, objStr);
		}
		
		public function tokenCallback(result:int, e:flash.events.Event):void
		{
			if(result == NetworkConnection.EVENT_COMPLETE)
			{
				var response:String = e.target.data;
				var jsonResponseObj:Object = JSON.parse(response);
				
				if(jsonResponseObj.access_token != null)
				{
					accessToken = jsonResponseObj.access_token;
				}
			}
		}
		
		static public function accessGranted():Boolean
		{
			return AuthorizationAttempted && accessToken != null && accessToken != "denied";
		}
		
		public function getPlayerInfo(playerID:String):void
		{
			var temp:Dictionary = userNames;
			if(userNames[playerID] == null)
				sendMessage(PLAYER_INFO, playerInfoCallback, playerID);
		}
		
		public function playerInfoCallback(result:int, e:flash.events.Event):void
		{
			if(result == NetworkConnection.EVENT_COMPLETE)
			{
				var response:String = e.target.data;
				var jsonResponseObj:Object = JSON.parse(response);
					
				if(jsonResponseObj.username != null)
				{
					userNames[jsonResponseObj.id] = jsonResponseObj.username;
				}
			}
		}
		
		//?? do this or update, and/or limit list size??
		public static function countNeededUserNameRequests():void
		{
			
		//	outstandingUserNamesRequests
			
		}
		
		public static function getUserName(playerID:String, defaultNumber:int):String
		{
			if(userNames[playerID] != null)
				return userNames[playerID];
			else
				return 'Player' + defaultNumber;
		}
		
		public function sendMessage(type:int, callback:Function, data:String = null):void
		{
			var request:String;
			var method:String;
			var url:String = null;
			switch(type)
			{
				case ACCESS_TOKEN:
					url = NetworkConnection.productionInterop + "?function=passURLPOST2&data_id='" + data +"'&access_token='" + PlayerValidation.accessToken +"'";
					method = URLRequestMethod.POST; 
					break;
				case PLAYER_INFO:
					url = NetworkConnection.productionInterop + "?function=passURL2Args&data_id='/api/users/" + data +"'&access_token='" + PlayerValidation.accessToken +"'";
					method = URLRequestMethod.GET; 
					request = "authorize";
					break;

			}
			
			NetworkConnection.sendMessage(callback, data, url, method, request);
		}
	}
}