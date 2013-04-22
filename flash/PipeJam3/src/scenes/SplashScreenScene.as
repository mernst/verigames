package scenes
{
	import assets.AssetInterface;
	
	import events.NavigationEvent;
	
	import flash.events.Event;
	import flash.events.HTTPStatusEvent;
	import flash.net.*;
	import starling.core.Starling;
	import starling.display.*;
	import starling.events.Event;
	import starling.events.TouchEvent;
	import starling.textures.Texture;
	
	public class SplashScreenScene extends Scene
	{
		/** Start button image */
		protected var play_button:Button;
		protected var signin_button:Button;
		protected var tutorial_button:Button;
		protected var demo_button:Button;
		
		protected var loader:URLLoader;
	
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
			
			var signinButtonUp:Texture = AssetInterface.getTexture("Menu", "SignInButtonClass");
			var signinButtonClick:Texture = AssetInterface.getTexture("Menu", "SignInButtonClass");

			signin_button = new Button(signinButtonUp, "", signinButtonClick);
			signin_button.addEventListener(starling.events.Event.TRIGGERED, onSignInButtonTriggered);
			signin_button.x = width/2 - signin_button.width/2;
			signin_button.y = 60;
			addChild(signin_button);
			
			var playButtonUp:Texture = AssetInterface.getTexture("Menu", "PlayButtonClass");
			var playButtonClick:Texture = AssetInterface.getTexture("Menu", "PlayButtonClass");
			
			play_button = new Button(playButtonUp, "", playButtonClick);
			play_button.addEventListener(starling.events.Event.TRIGGERED, onPlayButtonTriggered);
			play_button.x = width/2 - play_button.width/2;
			play_button.y = 110;
			addChild(play_button);
			
			var tutorialButtonUp:Texture = AssetInterface.getTexture("Menu", "TutorialButtonClass");
			var tutorialButtonClick:Texture = AssetInterface.getTexture("Menu", "TutorialButtonClass");
			
			tutorial_button = new Button(tutorialButtonUp, "", tutorialButtonClick);
			tutorial_button.addEventListener(starling.events.Event.TRIGGERED, onTutorialButtonTriggered);
			tutorial_button.x = width/2 - tutorial_button.width/2;
			tutorial_button.y = 160;
			addChild(tutorial_button);
			
			var demoButtonUp:Texture = AssetInterface.getTexture("Menu", "DemoButtonClass");
			var demoButtonClick:Texture = AssetInterface.getTexture("Menu", "DemoButtonClass");
			
			demo_button = new Button(demoButtonUp, "", demoButtonClick);
			demo_button.addEventListener(starling.events.Event.TRIGGERED, onDemoButtonTriggered);
			demo_button.x = width/2 - demo_button.width/2;
			demo_button.y = 210;
			addChild(demo_button);
		}
		
		protected  override function removedFromStage(event:starling.events.Event):void
		{
			
		}
		
		protected function onSignInButtonTriggered(e:starling.events.Event):void
		{
			//get client id
			Starling.current.nativeStage.addEventListener(flash.events.Event.ACTIVATE, onActivate);
			var myURL:URLRequest = new URLRequest("http://ec2-184-72-152-11.compute-1.amazonaws.com:3000/auth/csfv");
			navigateToURL(myURL, "_blank");
			
		}
		
		protected function callback(evt:flash.events.Event):void
		{
			loader = new URLLoader();
			var clientIDURL:URLRequest = new URLRequest(Scene.PROXY_URL+"/auth/csfv&method=AUTH");
			loader.addEventListener(flash.events.Event.COMPLETE, callback);
			loader.addEventListener(flash.events.HTTPStatusEvent.HTTP_STATUS, status);
			loader.load(clientIDURL);
		}
		
		protected function onActivate(evt:flash.events.Event):void
		{
			Starling.current.nativeStage.removeEventListener(flash.events.Event.ACTIVATE, onActivate);
			var s:String = evt.target as String;
			var x:int = 4;
			
		}
		
		protected function status(evt:flash.events.Event):void
		{
//			var s:String = evt.status as String;
//			var x:int = 4;
			
		}
		
		protected function onPlayButtonTriggered(e:starling.events.Event):void
		{
			dispatchEvent(new NavigationEvent(NavigationEvent.CHANGE_SCREEN, "PipeJamGame"));
		}
		
		protected function onTutorialButtonTriggered(e:starling.events.Event):void
		{
			dispatchEvent(new NavigationEvent(NavigationEvent.CHANGE_SCREEN, "PipeJamGame"));
		}
		
		protected function onDemoButtonTriggered(e:starling.events.Event):void
		{
			dispatchEvent(new NavigationEvent(NavigationEvent.CHANGE_SCREEN, "PipeJamGame"));
		}
	}
}