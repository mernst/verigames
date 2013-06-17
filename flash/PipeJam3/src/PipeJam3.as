package  
{
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	import flash.geom.Rectangle;
	
	import net.hires.debug.Stats;
	
	import scenes.login.LoginHelper;
	import scenes.splashscreen.SplashScreenScene;
	
	import starling.core.Starling;
	import starling.events.Event;
	
	//import mx.core.FlexGlobals;
	//import spark.components.Application;
	
	[SWF(width = "960", height = "640", frameRate = "30", backgroundColor = "#ffffff")]
	
	public class PipeJam3 extends flash.display.Sprite 
	{
		private var mStarling:Starling;
		
		public static var playerLoggedIn:Boolean = false;
		public static var playerID:String = "51365e65e4b0ad10f4079c88"; //can't currently log in as other people because of the split RA's
		static public var cookies:String;

		public static var LOGIN_STATUS_CHANGE:String = "login_status_change";
		
		protected var hasBeenAddedToStage:Boolean = false;
		protected var sessionVerificationHasBeenAttempted:Boolean = false;
		
		
		public function PipeJam3() 
		{
			var originalCookies:String = JSON.stringify(this.loaderInfo.parameters);
			var pattern:RegExp = /sid/;
			cookies = escape(originalCookies.replace(pattern, "express.sid"));
	//		LoginHelper.getLoginHelper().checkSessionID(cookies, sessionIDValid);
			sessionIDValid(null);
			addEventListener(flash.events.Event.ADDED_TO_STAGE, onAddedToStage);
		}
		
		//called if sessionID valid
		public function sessionIDValid(event:flash.events.Event):void
		{
			if(event)
			{
				//three cases, an Auth Required dialog
				//a blank userID,
				//a valid userID
				
				var response:String = event.target.data;
				if(response.indexOf("<html>") == -1) //else assume auth required dialog
				{
					var jsonResponseObj:Object = JSON.parse(response);
					
					if(jsonResponseObj.userId != null)
					{
						playerLoggedIn = true;
						playerID = jsonResponseObj.userId;
						PipeJamGame.RELEASE_BUILD = true;
					}
				}
			}
			sessionVerificationHasBeenAttempted = true;
			
			initialize();
		}
			
		
		public function onAddedToStage(evt:flash.events.Event):void {
			removeEventListener(flash.events.Event.ADDED_TO_STAGE, onAddedToStage);
			
			hasBeenAddedToStage = true;
			//at least try to initialize, although probably waiting on session verification
			initialize();
		}
		
		public function initialize():void
		{
			if(hasBeenAddedToStage && sessionVerificationHasBeenAttempted)
			{
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