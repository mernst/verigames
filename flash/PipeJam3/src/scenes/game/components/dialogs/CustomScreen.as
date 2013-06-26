package scenes.game.components.dialogs
{
	import feathers.controls.Screen;
	import feathers.controls.ImageLoader;
	import feathers.display.Scale9Image;
	
	public class CustomScreen extends Screen
	{
		
		public var backgroundSkin:Scale9Image;
		public function CustomScreen()
		{
		}
		
		//runs once when screen is first added to the stage.
		//a good place to add children and things.
		override protected function initialize():void
		{
			
		}
		
		override protected function draw():void
		{
			//runs every time invalidate() is called
			//a good place for measurement and layout
		}
		
		public function centerDialog():void
		{
			x = (parent.width - width)/2;
			y = (parent.height - height)/2;
		}
	}
}