package scenes.loadingscreen
{
	import assets.AssetInterface;
	import assets.AssetsFont;
	
	import display.NineSliceButton;
	
	import events.NavigationEvent;
	
	import flash.utils.Timer;
	import flash.events.TimerEvent;
	
	import networking.PlayerValidation;
	
	import particle.ErrorParticleSystem;
	
	import scenes.Scene;
	
	import starling.display.BlendMode;
	import starling.display.Image;
	import starling.events.Event;
	import starling.events.Touch;
	import starling.events.TouchEvent;
	
	public class LoadingScreenScene extends Scene
	{
		
		protected var background:Image;
		protected var particleSystem:ErrorParticleSystem;
		protected var foreground:Image;
		
		protected var timer:Timer;
		
		public var loading_button:NineSliceButton;
		
		protected var sessionVerificationHasBeenAttempted:Boolean = false;

		
		//would like to dispatch an event and end up here, but
		public static var loadingScreenScene:LoadingScreenScene;
		
		public function LoadingScreenScene(game:PipeJamGame)
		{
			super(game);
			loadingScreenScene = this;
		}
		
		protected override function addedToStage(event:starling.events.Event):void
		{
			super.addedToStage(event);
			
			background = new Image(AssetInterface.getTexture("Game", "BoxesStartScreenImageClass"));
			background.scaleX = stage.stageWidth/background.width;
			background.scaleY = stage.stageHeight/background.height;
			background.blendMode = BlendMode.NONE;
			addChild(background);
			
			particleSystem = new ErrorParticleSystem();
			particleSystem.x = 395.5 * background.width / Constants.GameWidth;
			particleSystem.y = 302.0 * background.height / Constants.GameHeight;
			particleSystem.scaleX = particleSystem.scaleY = 8.0;
			addChild(particleSystem);
			
			foreground = new Image(AssetInterface.getTexture("Game", "BoxesStartScreenForegroundImageClass"));
			foreground.scaleX = background.scaleX;
			foreground.scaleY = background.scaleY;
			addChild(foreground);
			
			const BUTTON_CENTER_X:Number = 241; // center point to put Play and Log In buttons
			
			loading_button = ButtonFactory.getInstance().createButton("Loading...", 150, 42, 42 / 3.0, 42 / 3.0);
			loading_button.x = BUTTON_CENTER_X - loading_button.width / 2;
			loading_button.y = 230;
			loading_button.removeTouchEvent(); //we want a non-responsive button look
			addChild(loading_button);

			PlayerValidation.validatePlayerIsLoggedInAndActive(playerValidationAttempted, this);

			
		}
		
		public function playerValidationAttempted():void
		{
			sessionVerificationHasBeenAttempted = true;
			//burn a quarter of a second to let last loading message be visible
			timer = new Timer(250, 1);
			timer.addEventListener(TimerEvent.TIMER, changeScene);
			timer.start();
		}
			
		public function changeScene(e:TimerEvent = null):void
		{	
			if (timer) {
				timer.stop();
				timer.removeEventListener(TimerEvent.TIMER, changeScene);
			}
			timer == null;
			dispatchEvent(new NavigationEvent(NavigationEvent.CHANGE_SCREEN, "SplashScreen"));
		}
		
		override public function setStatus(text:String):void
		{
			loading_button.setButtonText(text);
		}
	}
}