package scenes.splashscreen
{
	import assets.AssetInterface;
	
	import events.NavigationEvent;
	
	import flash.events.Event;
	import flash.events.HTTPStatusEvent;
	import flash.net.*;
	import scenes.login.LoginHelper;
	
	import scenes.Scene;
	
	import starling.core.Starling;
	import starling.display.*;
	import starling.events.Event;
	import starling.events.TouchEvent;
	import starling.textures.Texture;
	
	public class SplashScreenScene extends Scene
	{

		protected var startMenuBox:SplashScreenMenuBox;
		protected var background:Image;
		
		public function SplashScreenScene(game:PipeJamGame)
		{
			super(game);
		}
		
		protected override function addedToStage(event:starling.events.Event):void
		{
			super.addedToStage(event);
			
			background = new Image(AssetInterface.getTexture("Game", "BoxesStartScreenImageClass"));
			background.scaleX = stage.stageWidth/background.width;
			background.scaleY = stage.stageHeight/background.height;
			background.blendMode = BlendMode.NONE;
			addChild(background);
			
			addMenuBox();
		}
		
		protected function addMenuBox():void
		{	
			startMenuBox = new SplashScreenMenuBox(this);
			addChild(startMenuBox);
			startMenuBox.x = (background.width-startMenuBox.width)/2;
			startMenuBox.y = 40;
			
			addChild(startMenuBox);
		}
		
		protected  override function removedFromStage(event:starling.events.Event):void
		{
			
		}
	}
}