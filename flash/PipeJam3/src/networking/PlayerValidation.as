package networking
{
	import flash.events.Event;
	import flash.events.TimerEvent;
	import flash.utils.Timer;
	import utils.XString;
		
	import starling.core.Starling;
	import starling.events.Event;
	
	import server.LoggingServerInterface;


	//the steps are: 
	//	get the cookie with the express.sid value
	//  send that to validateSession, to see if it's still a valid session id
	//	if it is, you will get the player ID number, else null
	//If you have a valid player ID number, then the fun begins
	//	first you have to check to see if the player exists in the RA (why log in doesn't add the player to the RA is beyond me)
	//		If they don't exist, add them
	//	Then you have to make sure they are active by activating them
	public class PlayerValidation
	{
		public static var playerLoggedIn:Boolean = false;
		public static var playerID:String = "51e5b3460240288229000026"; //hard code one for local testing
		
		public static var LOGIN_STATUS_CHANGE:String = "login_status_change";
		
		static protected var validationObject:PlayerValidation = null;
		protected var pipejamCallbackFunction:Function;
		
		//callback function should check PlayerValidation.playerLoggedIn for success or not
		static public function validatePlayerIsLoggedInAndActive(callback:Function):void
		{
			if(validationObject == null)
				validationObject = new PlayerValidation;
			
			HTTPCookies.callGetEncodedCookie();
			
			validationObject.pipejamCallbackFunction = callback;
			validationObject.checkForCookie();
		}
		
		//callback function should check PlayerValidation.playerLoggedIn for success or not
		static public function validatePlayerIsActive(callback:Function):void
		{
			if(validationObject == null)
				validationObject = new PlayerValidation;
			
			validationObject.pipejamCallbackFunction = callback;
			validationObject.checkPlayerExistence();
		}
		
		protected var count:int = 0;
		//check for session ID cookie, and if found, try to validate it
		protected function checkForCookie(e:TimerEvent = null):void
		{
			//callGetEncodedCookie makes an asyncronous call, so I need the timer to poll for a valid return
			var cookie:Object = null;
			if(count > 0)
				cookie = HTTPCookies.getEncodedCookieResult();
			var timer:Timer;
			count++; //do max
			if(count < 10 && (cookie == null || cookie.length < 12))
			{
				timer = new Timer(500, 1);
				timer.addEventListener(TimerEvent.TIMER, checkForCookie);
				timer.start();
			}
			else 
			{
				if(cookie)
					LoginHelper.getLoginHelper().checkSessionID(cookie as String, sessionIDValidityCallback);
				else
					pipejamCallbackFunction();
			}
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
						checkPlayerExistence();
						return; //wait for callback to continue
					}
				}
			}
			//if we make it this far, just exit
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
			pipejamCallbackFunction();
			
		}
		
		public function activatePlayerCallback(result:int, e:flash.events.Event):void
		{
			if(result == LoginHelper.EVENT_COMPLETE)
				playerLoggedIn = true; //whee
			
			
			pipejamCallbackFunction();
		}
	}
}