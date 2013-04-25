package scenes.login
{
	import assets.AssetInterface;
	
	import flash.events.Event;
	import flash.net.*;
	
	import mx.controls.TextArea;
	
	import scenes.Scene;
	
	import flash.text.TextField;
	
	import starling.core.Starling;
	import starling.events.Event;

	public class LoginScene extends Scene
	{
		protected var htmlTextField:TextField;
		protected var loader:URLLoader;
		
		public function LoginScene(game:PipeJamGame)
		{
			super(game);
		}
		
		protected override function addedToStage(event:starling.events.Event):void
		{
//			htmlTextField = new TextField;
//			Starling.current.nativeStage.addChild(htmlTextField);
//			htmlTextField.width = width;
//			htmlTextField.height = height;
//			loader = new URLLoader;
//			loader.addEventListener(flash.events.Event.COMPLETE, onHTMLLoaded);
//			loader.load(new URLRequest("http://ec2-184-72-152-11.compute-1.amazonaws.com:3000/auth/csfv"));
		}
		
		
		protected  override function removedFromStage(event:starling.events.Event):void
		{
		}
		
		private function onHTMLLoaded(e:flash.events.Event):void 
		{
			htmlTextField.htmlText = e.target.data;
		}
	}
}