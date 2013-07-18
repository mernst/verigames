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
	
	import networking.HTTPCookies;
	import networking.LoginHelper;
	import networking.PlayerValidation;
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
		
		/** Set to true if a build for the server */
		public static var RELEASE_BUILD:Boolean = true;
		public static var LOCAL_DEPLOYMENT:Boolean = false;
		public static var TUTORIAL_DEMO:Boolean = false;
		
		public static var logging:LoggingServerInterface;
		
		protected var hasBeenAddedToStage:Boolean = false;
		protected var sessionVerificationHasBeenAttempted:Boolean = false;
		//used to know if this is the inital launch, and the Play button should load a tutorial level or the level dialog instead
		public static var initialLevelDisplay:Boolean = true; 
		static public var pipeJam3:PipeJam3;
		
		public function PipeJam3() 
		{
			pipeJam3 = this;
			
			addEventListener(flash.events.Event.ADDED_TO_STAGE, onAddedToStage);
			
			if(RELEASE_BUILD == true)
			{
				if (LoggingServerInterface.LOGGING_ON) {
					logging = new LoggingServerInterface(LoggingServerInterface.SETUP_KEY_FRIENDS_AND_FAMILY_BETA, stage);
				}
				PlayerValidation.validatePlayerIsLoggedInAndActive(playerValidationAttempted);
			}
			else if(!LOCAL_DEPLOYMENT) //use baked in player id, so don't get cookie, but do try to validate id
			{
				if (LoggingServerInterface.LOGGING_ON) {
					logging = new LoggingServerInterface(LoggingServerInterface.SETUP_KEY_FRIENDS_AND_FAMILY_BETA, stage);
				}
				PlayerValidation.validatePlayerIsActive(playerValidationAttempted);
			}
			else
			{
				playerValidationAttempted();
			}
		}
		
		
		public function playerValidationAttempted():void
		{
			sessionVerificationHasBeenAttempted = true;
			initialize();
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