package  
{
	import audio.AudioManager;
	
	import com.spikything.utils.MouseWheelTrap;
	
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	import flash.events.TimerEvent;
	import flash.geom.Rectangle;
	import flash.utils.Timer;
	
	import net.hires.debug.Stats;
	
	import scenes.login.HTTPCookies;
	import scenes.login.LoginHelper;
	import scenes.splashscreen.SplashScreenScene;
	
	import server.LoggingServerInterface;
	
	import starling.core.Starling;
	import starling.events.Event;
	
	//import mx.core.FlexGlobals;
	//import spark.components.Application;
	
	[SWF(width = "960", height = "640", frameRate = "30", backgroundColor = "#ffffff")]
	
	public class PipeJam3 extends flash.display.Sprite 
	{
		private var mStarling:Starling;
		
		public static var playerLoggedIn:Boolean = false;
		public static var playerID:String = "51cb6fc7ddfe66b65d000021";
		public static var playerActivated:Boolean = false;
		static public var cookies:String;
		
		public static var LOGIN_STATUS_CHANGE:String = "login_status_change";
		
		/** Set to true if a build for the server */
		public static var RELEASE_BUILD:Boolean = false;
		public static var LOCAL_DEPLOYMENT:Boolean = false;
		public static var TUTORIAL_DEMO:Boolean = true;
		
		public static var logging:LoggingServerInterface;
		
		protected var hasBeenAddedToStage:Boolean = false;
		protected var sessionVerificationHasBeenAttempted:Boolean = false;
		
		public function PipeJam3() 
		{
			addEventListener(flash.events.Event.ADDED_TO_STAGE, onAddedToStage);

			if(RELEASE_BUILD == true && !LOCAL_DEPLOYMENT)
			{
				HTTPCookies.callGetEncodedCookie();
				checkForCookie();
			}
			else
			{
				sessionIDValid(null);
			}
		}
		
		protected var count:int = 0;
		protected function checkForCookie(e:TimerEvent = null):void
		{
			//this makes an asyncronous call in this case, so I need the timer to poll
			var cookie:Object = null;
			if(count > 0)
				cookie = HTTPCookies.getEncodedCookieResult();
			var timer:Timer;
			count++;
			if(count < 10 && (cookie == null || cookie.length < 12))
			{
				timer = new Timer(500, 1);
				timer.addEventListener(TimerEvent.TIMER, checkForCookie);
				timer.start();
			}
			else 
			{
				if(cookie)
					startup(cookie.toString());
				else
					sessionIDValid(null);
			}
		}
		
		protected function startup(cookie:String):void
		{
//			HTTPCookies.deleteCookie("Cookie" + cookie);
			//var expressID:String = JSON.stringify(this.loaderInfo.parameters);
//			var pattern:RegExp = /sid/;
//			cookies = escape(expressID.replace(pattern, "express.sid"));
//			var pattern1:RegExp = /\+/;
//			cookies = cookies.replace(pattern1, "\%2B");
//			var pattern2:RegExp = /\//;
//			cookies = cookies.replace(pattern2, "\%2F");
			if (LoggingServerInterface.LOGGING_ON) {
				logging = new LoggingServerInterface(LoggingServerInterface.SETUP_KEY_FRIENDS_AND_FAMILY_BETA, stage);
			}
			LoginHelper.getLoginHelper().checkSessionID(cookie, sessionIDValid);
		}
		
		//called if sessionID valid
		public function sessionIDValid(event:flash.events.Event):void
		{
		//	HTTPCookies.displayAlert("session");
			if(event && event is flash.events.IOErrorEvent)
			{
				
			}
			else if(event)
			{
				//three cases, an Auth Required dialog
				//a blank userID,
				//a valid userID
		//		HTTPCookies.displayAlert("valid");
				
				var response:String = event.target.data;
				if(response.indexOf("<html>") == -1) //else assume auth required dialog
				{
					var jsonResponseObj:Object = JSON.parse(response);
					
					if(jsonResponseObj.userId != null)
					{
						playerLoggedIn = true;
						playerID = jsonResponseObj.userId;
						
						if (LoggingServerInterface.LOGGING_ON) {
							logging = new LoggingServerInterface(LoggingServerInterface.SETUP_KEY_FRIENDS_AND_FAMILY_BETA, stage, LoggingServerInterface.CGS_VERIGAMES_PREFIX + playerID);
						}
						
						PipeJamGame.PLAYER_LOGGED_IN = true;
						//activate player to make sure
			//			HTTPCookies.displayAlert("checking");
						sessionVerificationHasBeenAttempted = true;

						LoginHelper.getLoginHelper().checkPlayerID(setSessionBooleanAndInitialize);
						playerActivated = true; //or at least attempted
						
					}
					else
						setSessionBooleanAndInitialize();
				}
				else
					setSessionBooleanAndInitialize();
			}
			else
				setSessionBooleanAndInitialize();
		}
			
		
		public function onAddedToStage(evt:flash.events.Event):void {
			if(hasBeenAddedToStage == false)
			{
				removeEventListener(flash.events.Event.ADDED_TO_STAGE, onAddedToStage);
				hasBeenAddedToStage = true;
				//at least try to initialize, although probably waiting on session verification
				initialize();
			}
		}
		
		public function setSessionBooleanAndInitialize(result:int = 0, e:flash.events.Event = null):void
		{
			sessionVerificationHasBeenAttempted = true;
			initialize();
		}
		
		public function initialize(result:int = 0, e:flash.events.Event = null):void
		{
		//	HTTPCookies.displayAlert("init");

			if(hasBeenAddedToStage && sessionVerificationHasBeenAttempted)
			{
				MouseWheelTrap.setup(stage);

				//set up the main controller
				stage.scaleMode = StageScaleMode.NO_SCALE;
				stage.align = StageAlign.TOP_LEFT;
				
				Starling.multitouchEnabled = false; // useful on mobile devices
				Starling.handleLostContext = true; // deactivate on mobile devices (to save memory)
				
				var stats:Stats = new Stats;
				//		stage.addChild(stats);
				
				//	mStarling = new Starling(PipeJamGame, stage, null, null,Context3DRenderMode.SOFTWARE);
				mStarling = new Starling(PipeJamGame, stage);
				//mostly just an annoyance in desktop mode, so turn off...
				mStarling.simulateMultitouch = false;
				mStarling.enableErrorChecking = false;
				mStarling.start();
				
				// this event is dispatched when stage3D is set up
				mStarling.stage3D.addEventListener(flash.events.Event.CONTEXT3D_CREATE, onContextCreated);
				
				//FlexGlobals.topLevelApplication.stage.addEventListener(Event.RESIZE, updateSize);
				stage.addEventListener(flash.events.Event.RESIZE, updateSize);
				stage.dispatchEvent(new flash.events.Event(flash.events.Event.RESIZE));
			}
		}
		
		private function onContextCreated(event:flash.events.Event):void
		{
			// set framerate to 30 in software mode
			
			if (Starling.context.driverInfo.toLowerCase().indexOf("software") != -1)
				Starling.current.nativeStage.frameRate = 30;
		}
		
		public function updateSize(e:flash.events.Event):void {
			// Compute max view port size
			var fullViewPort:Rectangle = new Rectangle(0, 0, stage.stageWidth, stage.stageHeight);
			const DES_WIDTH:Number = Constants.GameWidth;
			const DES_HEIGHT:Number = Constants.GameHeight;
			var scaleFactor:Number = Math.min(stage.stageWidth / DES_WIDTH, stage.stageHeight / DES_HEIGHT);
			
			// Compute ideal view port
			var viewPort:Rectangle = new Rectangle();
			viewPort.width = scaleFactor * DES_WIDTH;
			viewPort.height = scaleFactor * DES_HEIGHT;
			viewPort.x = 0.5 * (stage.stageWidth - viewPort.width);
			viewPort.y = 0.5 * (stage.stageHeight - viewPort.height);

			// Ensure the ideal view port is not larger than the max view port (could cause a crash otherwise)
			viewPort = viewPort.intersection(fullViewPort);
			
			// Set the updated view port
			Starling.current.viewPort = viewPort;
		}
	}

}