package scenes.splashscreen
{
	import assets.AssetInterface;
	import scenes.Scene;
	import starling.display.BlendMode;
	import starling.display.Image;
	import starling.events.Event;
	
	public class SplashScreenScene extends Scene
	{
		
		public var startMenuBox:SplashScreenMenuBox;
		protected var background:Image;
		
		//would like to dispatch an event and end up here, but
		public static var splashScreenScene:SplashScreenScene;
		
		public function SplashScreenScene(game:PipeJamGame)
		{
			super(game);
			splashScreenScene = this;
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
			
		public function addMenuBox():void
		{	
			startMenuBox = new SplashScreenMenuBox(this);
			addChild(startMenuBox);
		}
		
		protected  override function removedFromStage(event:Event):void
		{
			
		}
	}
}