package  
{
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	import flash.geom.Rectangle;
	import net.hires.debug.Stats;
	import starling.core.Starling;
	
	//import mx.core.FlexGlobals;
	//import spark.components.Application;
	
	[SWF(width = "1024", height = "768", frameRate = "30", backgroundColor = "#ffffff")]
	
	public class PipeJam3 extends flash.display.Sprite 
	{
		private var mStarling:Starling;
		
		public function PipeJam3() 
		{
			addEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
		}
		
		public function onAddedToStage(evt:Event):void {
			removeEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
			
			//set up the main controller
			stage.scaleMode = StageScaleMode.NO_SCALE;
			stage.align = StageAlign.TOP_LEFT;
			
			Starling.multitouchEnabled = true; // useful on mobile devices
			Starling.handleLostContext = true; // deactivate on mobile devices (to save memory)
			
			var stats:Stats = new Stats;
		//		stage.addChild(stats);
			
		//	mStarling = new Starling(PipeJamGame, stage, null, null,Context3DRenderMode.SOFTWARE);
			mStarling = new Starling(PipeJamGame, stage);
			mStarling.simulateMultitouch = true;
			mStarling.enableErrorChecking = false;
			mStarling.start();
			
			// this event is dispatched when stage3D is set up
			mStarling.stage3D.addEventListener(Event.CONTEXT3D_CREATE, onContextCreated);
			
			//FlexGlobals.topLevelApplication.stage.addEventListener(Event.RESIZE, updateSize);
			stage.addEventListener(Event.RESIZE, updateSize);
			stage.dispatchEvent(new Event(Event.RESIZE));
		}
		
		private function onContextCreated(event:Event):void
		{
			// set framerate to 30 in software mode
			
			if (Starling.context.driverInfo.toLowerCase().indexOf("software") != -1)
				Starling.current.nativeStage.frameRate = 30;
		}
		
		public function updateSize(e:Event):void {
			// Compute max view port size
			var fullViewPort:Rectangle = new Rectangle(0, 0, stage.stageWidth, stage.stageHeight)
			const DES_WIDTH:Number = 1024;
			const DES_HEIGHT:Number = 768;
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