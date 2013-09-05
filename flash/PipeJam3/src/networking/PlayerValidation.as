package networking
{
	import scenes.Scene;
	import flash.events.Event;
	
	import server.LoggingServerInterface;
	
	import starling.core.Starling;
	import starling.events.Event;
	
	import utils.XString;


	//the steps are: 
	//	get the cookie with the express.sid value
	//  send that to validateSession, to see if it's still a valid session id
	//	if it is, you will get the player ID number, else null
	//If you have a valid player ID number, then the fun begins
	//	first you have to check to see if the player exists in the RA (why log In doesn't add the player to the RA is beyond me)
	//		If they don't exist, add them
	//	Then you have to make sure they are active by activating them
	public class PlayerValidation
	{
		public static var playerLoggedIn:Boolean = false;
		
		public static var playerID:String = "";
		public static var playerIDForTesting:String = "51e5b3460240288229000026"; //hard code one for local testing
		
		public static var LOGIN_STATUS_CHANGE:String = "login_status_change";
		
		static protected var validationObject:PlayerValidation = null;
		protected var pipejamCallbackFunction:Function;
		protected var controller:Scene;
		
		static public var GETTING_COOKIE:String = "Getting Cookie";
		static public var VALIDATING_SESSION:String = "Validating Session";
		static public var ACTIVATING_PLAYER:String = "Activating Player";
		static public var GETTING_PLAYER_INFO:String = "Getting Player ID";
		
		static public var VALIDATION_SUCCEEDED:String = "Player Logged In";
		static public var VALIDATION_FAILED:String = "Validation Failed";
		
		//callback function should check PlayerValidation.playerLoggedIn for success or not - for use in release builds
		static public function validatePlayerIsLoggedInAndActive(callback:Function, _controller:Scene):void
		{
			if(validationObject == null)
			{
				validationObject = new PlayerValidation;
				validationObject.controller = _controller;
			}
						
			validationObject.pipejamCallbackFunction = callback;
			validationObject.controller.setStatus(GETTING_COOKIE);
			validationObject.checkForCookie();
		}
		
		//callback function should check PlayerValidation.playerLoggedIn for success or not - for use when debugging locally
		static public function validatePlayerIsActive(callback:Function):void
		{
			if(validationObject == null)
				validationObject = new PlayerValidation;
			
			validationObject.pipejamCallbackFunction = callback;
			validationObject.checkPlayerExistence();
		}
		
		protected var count:int = 0;
		//check for session ID cookie, and if found, try to validate it
		protected function checkForCookie():void
		{
			LoginHelper.getLoginHelper().getEncodedCookies(cookieCallback);
		}
		
		public function cookieCallback(result:int, event:flash.events.Event):void
		{
			if(result == LoginHelper.EVENT_COMPLETE)
			{
				var cookies:String = event.target.data;
				if(cookies.indexOf("<html>") == -1 && cookies.length > 10) //not an error message or empty cookie string = {} = %7B%7D
				{
					controller.setStatus(VALIDATING_SESSION);
					LoginHelper.getLoginHelper().checkSessionID(cookies, sessionIDValidityCallback);
					return;
				}
			}
			
			//if we make it this far, just exit
			controller.setStatus(VALIDATION_FAILED);
			pipejamCallbackFunction();
		}

		//callback for checking the validity of the session id
		//if the session id is valid, then get the player id and make sure they are in the RA
		public function sessionIDValidityCallback(result:int, event:flash.events.Event):void
		{
			if(result == LoginHelper.EVENT_COMPLETE)
			{
				var response:String = event.target.data;
				if(response.indexOf("<html>") == -1) //else assume auth required dialog
				{
					var jsonResponseObj:Object = JSON.parse(response);
					
					if(jsonResponseObj.userId != null)
					{
						playerID = jsonResponseObj.userId;
						
						if (LoggingServerInterface.LOGGING_ON) {
							PipeJam3.logging = new LoggingServerInterface(LoggingServerInterface.SETUP_KEY_FRIENDS_AND_FAMILY_BETA, PipeJam3.pipeJam3.stage, LoggingServerInterface.CGS_VERIGAMES_PREFIX + playerID);
						}
						controller.setStatus(ACTIVATING_PLAYER);
						checkPlayerExistence();
						return; //wait for callback to continue
					}
				}
			}
			//if we make it this far, just exit
			controller.setStatus(VALIDATION_FAILED);
			pipejamCallbackFunction();
		}
		
		public function checkPlayerExistence():void
		{
			LoginHelper.getLoginHelper().checkPlayerExistence(playerExistsCallback);
		}
		
		public function playerExistsCallback(result:int, e:flash.events.Event):void
		{
			if(e != null)
			{
				if(e.target.data.indexOf("<html>") == -1) //if the RA is down, we get a html page telling us something or other
				{
					var exists:String = JSON.parse(e.target.data).existsInRepo;
					if(XString.stringToBool(exists) == false)
					{
						//create player, assume it works?
						LoginHelper.getLoginHelper().createPlayer(JSON.parse(e.target.data).id, createPlayerCallback);
					}
					else
						LoginHelper.getLoginHelper().activatePlayer(JSON.parse(e.target.data).id, activatePlayerCallback);
					return;
				}
			}
			//if we make it this far, just exit
			controller.setStatus(VALIDATION_FAILED);
			pipejamCallbackFunction();

		}
		
		public function createPlayerCallback(result:int, e:flash.events.Event):void
		{
			if(e != null)
			{
				if(e.target.data.indexOf("<html>") == -1) //if the RA is down, we get a html page telling us something or other
				{
					//if we get this far, assume the player got created
					LoginHelper.getLoginHelper().activatePlayer(JSON.parse(e.target.data).id, activatePlayerCallback);
					
					return;
				}
			}
			//if we make it this far, just exit
			controller.setStatus(VALIDATION_FAILED);
			pipejamCallbackFunction();
			
		}
		
		public function activatePlayerCallback(result:int, e:flash.events.Event):void
		{
			if(result == LoginHelper.EVENT_COMPLETE)
			{
				playerLoggedIn = true; //whee
				Achievements.getAchievementsEarnedForPlayer();
				controller.setStatus(VALIDATION_SUCCEEDED);
			}
			else
				controller.setStatus(VALIDATION_FAILED);
			
			
			pipejamCallbackFunction();
		}
	}
}