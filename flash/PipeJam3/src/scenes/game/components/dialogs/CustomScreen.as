package scenes.game.components.dialogs
{
	import feathers.controls.Screen;
	import feathers.controls.ImageLoader;
	import feathers.display.Scale9Image;
	
	import assets.AssetsFont;
	import events.NavigationEvent;
	
	import feathers.controls.Button;
	import feathers.controls.GroupedList;
	import feathers.controls.Header;
	import feathers.controls.ImageLoader;
	import feathers.controls.List;
	import feathers.controls.Screen;
	import feathers.controls.text.TextFieldTextRenderer;
	import feathers.core.ITextRenderer;
	import feathers.data.HierarchicalCollection;
	import feathers.data.ListCollection;
	import feathers.display.Scale9Image;
	
	import flash.text.TextFormat;
	
	import networking.LoginHelper;
	
	import starling.display.Quad;
	import starling.display.Sprite;
	import starling.events.Event;
	import scenes.splashscreen.SplashScreenMenuBox;
	
	public class CustomScreen extends Screen
	{
		public var backgroundSkin:Scale9Image;
		 
		public var levelListCollection:ListCollection;
		public var matchArrayMetadata:Array = null;
		
		protected var header:Header;
		protected var exitButton:Button;
		protected var dialogParent:SplashScreenMenuBox;
		
		public function CustomScreen(_dialogParent:SplashScreenMenuBox)
		{
			super();
			dialogParent = _dialogParent;
		}
		
		//runs once when screen is first added to the stage.
		//a good place to add children and things.
		override protected function initialize():void
		{
			super.initialize();
			header = new Header();
			this.addChild( header );
			
			var footer:Sprite = new Sprite();
			this.addChild( footer );
			exitButton = new Button();
			exitButton.label = "Exit";
			exitButton.addEventListener(starling.events.Event.TRIGGERED, onExitButtonTriggered);
			footer.scaleX = .25;
			footer.scaleY = .25;
			var q:Quad = new Quad(width*4, 30*4, 0xff0000);
			q.alpha = 0;
			footer.addChild(q);
			footer.y = height - footer.height;
			footer.addChild( exitButton );
			var obj:Object = exitButton.defaultLabelProperties;
			obj.textFormat = new TextFormat(AssetsFont.FONT_UBUNTU,36, 0xffffff);
			exitButton.defaultLabelProperties = obj;
			
			
			
			exitButton.height = 100;
			exitButton.width = 350;
			exitButton.x = ((footer.width - exitButton.width*footer.scaleX)/2)/footer.scaleX;
		}
		
		public function setDialogInfo(_levelListCollection:ListCollection, _matchArrayMetadata:Array):void
		{
			levelListCollection = _levelListCollection;
			matchArrayMetadata = _matchArrayMetadata;
		}
		
		protected function onLevelSelected(e:starling.events.Event):void
		{

		}
		
		protected function onExitButtonTriggered():void
		{

		}
		
		public function centerDialog():void
		{
			x = (parent.width - width)/2;
			y = (parent.height - height)/2;
		}
	}
}