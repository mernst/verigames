package 
{
	import flash.display.Sprite;
	import flash.text.TextField;
	import mx.controls.ProgressBar;
	
	public class PreloaderUI extends Sprite 
	{
		/**
		 * Set the constructor and a default values for the progress bar's start positions.
		 */
		public function PreloaderUI() 
		{
			super();			
			
			// Giving a small buffer..
			x = 10;
            y = 10;
		}
				
		/**
		 * Update the UI based on the percentage completed.
		 * @param	percent - The amount of load completed (0 to 100)
		 */
		public function Update(percent:int) : void
		{
			graphics.clear();
			// grey color
            graphics.beginFill(0xD4D4D4);
			// x, y, width, height, ellipseW, ellipseH
            graphics.drawRoundRect(0, 0, (percent * 9.60) - 20, 20, 10, 10); 
			graphics.endFill();
			
			// Add a label signifying how much is loaded.
			removeChildren();
			var tf:TextField = new TextField();
			tf.text = "Loading.. " + percent + "%";
			addChild(tf);
			
			visible = true;
		}
		
		/**
		 * Called when Preloader has loaded and we need to close/hide the UI
		 */
		public function Conclude() : void
		{
			graphics.clear();
			removeChildren();
		}
		
	}

}