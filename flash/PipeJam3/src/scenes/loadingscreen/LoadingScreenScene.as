package scenes.loadingscreen
{
	import assets.AssetInterface;
	import assets.AssetsFont;
	
	import display.NineSliceButton;
	
	import events.NavigationEvent;
	
	import flash.events.TimerEvent;
	import flash.utils.Timer;
	
	import networking.PlayerValidation;
	import networking.TutorialController;
	
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
		
		/**Used to hold final message open so it's visible */
		protected var timer:Timer;
		/** Set timeout of entire process to not have it feel like it's hanging. */
		protected var timeoutTimer:Timer;
		
		public var loading_button:NineSliceButton;
		
		protected var sessionVerificationHasBeenAttempted:Boolean = false;

		
		//would like to dispatch an event and end up here, but
		protected static var loadingScreenScene:LoadingScreenScene;
		
		public function LoadingScreenScene(game:PipeJamGame)
		{
			super(game);
			loadingScreenScene = this;
		}
		
		public static function getLoadingScreenScene():LoadingScreenScene
		{
			if(loadingScreenScene != null)
				return loadingScreenScene;
			else
				return new LoadingScreenScene(null);
		}
		
		protected override function addedToStage(event:starling.events.Event):void
		{
			super.addedToStage(event);
			
			background = new Image(AssetInterface.getTexture("Game", "BoxesStartScreenImageClass"));
			background.scaleX = stage.stageWidth/background.width;
			background.scaleY = stage.stageHeight/background.height;
			background.blendMode = BlendMode.NONE;
			addChild(background);
			
			const BUTTON_CENTER_X:Number = 241; // center point to put Play and Log In buttons
			
			loading_button = ButtonFactory.getInstance().createButton("Loading...", 150, 42, 42 / 3.0, 42 / 3.0);
			loading_button.x = BUTTON_CENTER_X - loading_button.width / 2;
			loading_button.y = 230;
			loading_button.removeTouchEvent(); //we want a non-responsive button look
			addChild(loading_button);
		}
			
		public function changeScene(e:TimerEvent = null):void
		{	
			var tutorialController:TutorialController = TutorialController.getTutorialController();

			if (tutorialController.completedTutorialDictionary != null) {

			}
			else if (tutorialController.completedTutorialDictionary == null && PlayerValidation.accessGranted())
			{
				timer = new Timer(200, 1);
				timer.addEventListener(TimerEvent.TIMER, changeScene);
				timer.start(); //repeat until tutorial list is returned
				return;
			}
			timer == null;
			
			if(tutorialController.completedTutorialDictionary != null || PlayerValidation.accessGranted() == false)
				dispatchEvent(new NavigationEvent(NavigationEvent.CHANGE_SCREEN, "SplashScreen"));
		}
		
		override public function setStatus(text:String):void
		{
			loading_button.setButtonText(text);
		}
	}
}