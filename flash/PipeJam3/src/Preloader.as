package 
{
	import display.TextBubble;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.ProgressEvent;
	import flash.display.MovieClip;
	import flash.events.TimerEvent;
	import flash.text.TextField;
	import flash.text.engine.TextBlock;
	import flash.utils.Timer;
	import flash.utils.getDefinitionByName;
	import flash.display.DisplayObject;
	import mx.controls.ProgressBar;
	import mx.controls.Alert;
	import mx.events.CloseEvent;
			
	public class Preloader extends MovieClip 
	{
		// An attempt to load some UI to display the loading section.
		private var preloaderUi:PreloaderUI;
		
		/**
		 * Basic constructor.
		 */
		public function Preloader()
		{
			trace("In Preloader's constructor.");
			
			// Preloader graphics, if needed
			if (stage)
				init();
			else 
				addEventListener(Event.ADDED_TO_STAGE, init);
			
			// Check loading progress
			this.loaderInfo.addEventListener(ProgressEvent.PROGRESS, onProgress);
		}
		
		/**
		 * Method called when something needs to be done on every tick of the progress..
		 * @param	progressPercent - The value from 1 to 100.0 indicating the percent completed.
		 */
		private function handleProgress(progressPercent:Number) : void 
		{
			// Do logging or anything else here..
			trace("Loading... " + progressPercent + "%");
		}
		
		/**
		 * Method called when loading is done. Progress has reached 100%.
		 */
		private function handleProgressComplete() : void
		{
			// Do Logging or anything else on completion of the ptogress..
			trace("Done Loading 100%");
		}
		
		// Initiate the UI for the progress bar.
		private function init(e:Event = null) : void 
		{
			removeEventListener(Event.ADDED_TO_STAGE, init);
			
			preloaderUi = new PreloaderUI();
			preloaderUi.visible = true;
			
			addChild(preloaderUi);
		}
		
		/** 
		 * On progress, update the UI, call handleProgress and when it's 100%, hide UI
		 * and finally call handleProgressComplete()
		 */
		private function onProgress(e:ProgressEvent):void 
		{				 
			var percent:Number = Math.round(e.bytesLoaded / e.bytesTotal * 100);
						
			handleProgress(percent);
						
			preloaderUi.Update(percent);
			
			if (percent == 100)
			{
				preloaderUi.Conclude();
				this.loaderInfo.removeEventListener(ProgressEvent.PROGRESS, onProgress);
				onLoaded();
			}
		}
		
		private function onLoaded():void
		{
			trace("In onLoaded..");
			nextFrame(); //go to next frame and start PipeJam3
			var App:Class = getDefinitionByName("PipeJam3") as Class; //class of your app
			addChild(new App() as DisplayObject);
		}
		
	}

}