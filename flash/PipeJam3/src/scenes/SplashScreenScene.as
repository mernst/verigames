package scenes
{
	import starling.display.*;
	import starling.events.Event;
	import starling.textures.Texture;
	import events.NavigationEvent;
	import assets.AssetInterface;
	import starling.events.TouchEvent;
	
	public class SplashScreenScene extends Scene
	{
		/** Start button image */
		protected var start_button:Button;
		protected var login_button:Button;
	
		public function SplashScreenScene(game:PipeJamGame)
		{
			super(game);
			

		}
		
		protected override function addedToStage(event:starling.events.Event):void
		{
			super.addedToStage(event);
			var background:Image = new Image(AssetInterface.getTexture("Game", "BoxesStartScreenImageClass"));
			background.scaleX = stage.stageWidth/background.width;
			background.scaleY = stage.stageHeight/background.height;
			background.blendMode = BlendMode.NONE;
			addChild(background);
			
			var startButtonUp:Texture = AssetInterface.getTexture("Game", "StartButtonTrafficImageClass");
			var startButtonClick:Texture = AssetInterface.getTexture("Game", "StartButtonTrafficClickImageClass");

			start_button = new Button(startButtonUp, "", startButtonClick);
			start_button.addEventListener(Event.TRIGGERED, onStartBoxButtonTriggered);
			start_button.x = width/2 - start_button.width/2;
			start_button.y = height - 100;
			addChild(start_button);
			
			login_button = new Button(startButtonUp, "", startButtonClick);
			login_button.addEventListener(Event.TRIGGERED, onLoginButtonTriggered);
			login_button.x = width/2 - start_button.width/2;
			login_button.y = height - 50;
			addChild(login_button);
		}
		
		protected  override function removedFromStage(event:starling.events.Event):void
		{
		}
		
		
		protected function onStartBoxButtonTriggered(e:Event):void
		{
			dispatchEvent(new NavigationEvent(NavigationEvent.CHANGE_SCREEN, "PipeJamGame"));
		}
		
		protected function onLoginButtonTriggered(e:Event):void
		{
	//		if(e.)
	//			dispatchEvent(new NavigationEvent(NavigationEvent.CHANGE_SCREEN, "LoginTestScene"));
	//		else
				dispatchEvent(new NavigationEvent(NavigationEvent.CHANGE_SCREEN, "LoginScene"));
		}
	}
}