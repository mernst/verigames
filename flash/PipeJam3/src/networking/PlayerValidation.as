package networking
{
	import flash.events.Event;
	import flash.net.URLRequestMethod;
	import flash.utils.Dictionary;
	
	import scenes.Scene;
	
	import server.LoggingServerInterface;
	
	import utils.XMath;

	//the steps are: 
	//	get the cookie with the express.sid value
	//  send that to validateSession, to see if it's still a valid session id
	//	if it is, you will get the player ID number, else null

	public class PlayerValidation
	{
		public static var GET_ACCESS_TOKEN:int = 1;
		public static var GET_PLAYER_ID:int = 2;
		public static var GET_PLAYER_INFO:int = 3;
		
		public static var AuthorizationAttempted:Boolean = false;
		public static var accessToken:String = null;
		
		public static var playerID:String = "";
		public static var playerIDForTesting:String = "51e5b3460240288229000026"; //hard code one for local testing
		public static var userNames:Dictionary = new Dictionary;
		public static var outstandingUserNamesRequests:int = 0;
		
		
		static public var validationObject:PlayerValidation = new PlayerValidation;
		
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
			AuthorizationAttempted = true;
			
			//this call is missing the client secret, which is added at the server level.
			var obj:Object = new Object;
			obj.code = accessCode;
			obj.client_id = client_id;
			obj.grant_type = "authorization_code";
			obj.redirect_uri = redirect_uri;
			var objStr:String = JSON.stringify(obj);
			sendMessage(GET_ACCESS_TOKEN, tokenCallback, objStr);
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
					getCurrentPlayerID(accessToken);
				}
			}
		}
		
		public function getCurrentPlayerID(accessToken:String):void
		{
			sendMessage(GET_PLAYER_ID, getCurrentPlayerIDCallback, accessToken);
		}
		
		private function getCurrentPlayerIDCallback(result:int, e:flash.events.Event):void
		{
			if(result == NetworkConnection.EVENT_COMPLETE)
			{
				var response:String = e.target.data;
				var jsonResponseObj:Object = JSON.parse(response);
				
				if(jsonResponseObj.userId != null)
				{
					playerID = jsonResponseObj.userId;
					getPlayerInfo(playerID);
				}
				else
					playerID = "rand" + XMath.randomInt(0, 100000);
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
				sendMessage(GET_PLAYER_INFO, playerInfoCallback, playerID);
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
				case GET_ACCESS_TOKEN:
					url = NetworkConnection.productionInterop + "?function=getTokenPOST&data_id='/token'&access_token='" + PlayerValidation.accessToken +"'";
					method = URLRequestMethod.POST; 
					break;
				case GET_PLAYER_ID:
					url = NetworkConnection.productionInterop + "?function=getPlayerIDPOST&data_id='/validate'&access_token='" + PlayerValidation.accessToken +"'";
					method = URLRequestMethod.POST; 
					break;
				case GET_PLAYER_INFO:
					url = NetworkConnection.productionInterop + "?function=passURL2&data_id='/api/users/" + data +"'&access_token='" + PlayerValidation.accessToken +"'";
					method = URLRequestMethod.GET; 
					request = "authorize";
					break;

			}
			
			NetworkConnection.sendMessage(callback, data, url, method, request);
		}
	}
}