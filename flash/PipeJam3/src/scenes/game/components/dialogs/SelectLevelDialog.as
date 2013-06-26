package scenes.game.components.dialogs
{
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
	
	import scenes.login.LoginHelper;
	
	import starling.display.Quad;
	import starling.display.Sprite;
	import starling.events.Event;
	
	public class SelectLevelDialog extends CustomScreen
	{
		public var levelListCollection:ListCollection;
		public var matchArrayMetadata:Array = null;
		protected var levelList:List = null;
		
		protected var exitButton:Button;
		
		public function SelectLevelDialog()
		{
			super();
		}
		
		//runs once when screen is first added to the stage.
		//a good place to add children and things.
		override protected function initialize():void
		{
			super.initialize();
			var header:Header = new Header();
			header.title = "Select a Level";
			this.addChild( header );
			
			var footer:Sprite = new Sprite();
			this.addChild( footer );
			trace(footer.x, footer.y, footer.height, footer.width);
			exitButton = new Button();
			exitButton.label = "Exit";
			exitButton.addEventListener(starling.events.Event.TRIGGERED, onExitButtonTriggered);
//			exitButton.x = 250;
//			exitButton.y = 250;
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
		//	exitButton.y = -10;
			trace(footer.x, footer.y, footer.height, footer.width);
			
//			var list:GroupedList = new GroupedList();
//			
//			list.dataProvider = new HierarchicalCollection();
//			
//			list.addEventListener( Event.CHANGE, list_changeHandler );
//			list.y = header.height;
		//	this.addChild( list );
			
			levelList = new List;
			levelList.y = 75;
			levelList.width = 125;
			levelList.x = (width - levelList.width)/2;
			levelList.itemRendererProperties.height = 10;
			
			addChild(levelList);
			levelList.addEventListener( starling.events.Event.CHANGE, onLevelSelected);
			levelList.validate();
//			levelListCollection = new ListCollection();
//			levelListCollection.push("test1");
//			levelListCollection.push("test2");
//			levelListCollection.push("test3");
//			levelList.dataProvider = levelListCollection;
		}
		
		public function setDialogInfo(_levelListCollection:ListCollection, _matchArrayMetadata:Array):void
		{
		//	levelListCollection = _levelListCollection;
			matchArrayMetadata = _matchArrayMetadata;
	//		levelList.dataProvider = levelListCollection;
		}
		
		protected function onLevelSelected(e:starling.events.Event):void
		{
			LoginHelper.levelObject = matchArrayMetadata[levelList.selectedIndex];
			
			dispatchEvent(new NavigationEvent(NavigationEvent.CHANGE_SCREEN, "PipeJamGame"));
		}
		
		private function onExitButtonTriggered():void
		{
		//	m_mainMenu.visible = true;
			parent.removeChild(this);
		}
		
		private function list_changeHandler(e:Event):void
		{
			// TODO Auto Generated method stub
			
			
		}
		
		override protected function draw():void
		{
			//runs every time invalidate() is called
			//a good place for measurement and layout


		}
	}
}