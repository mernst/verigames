package scenes.game.components.dialogs
{
	import feathers.controls.Screen;
	import feathers.controls.ImageLoader;
	import feathers.display.Scale9Image;
	import feathers.data.ListCollection;
	import feathers.controls.Header;
	import feathers.controls.text.TextFieldTextRenderer;
	import feathers.core.ITextRenderer;
	import flash.text.TextFormat;
	import feathers.controls.GroupedList;
	import feathers.data.HierarchicalCollection;
	import starling.events.Event;
	import feathers.controls.Button;
	import starling.display.Sprite;
	import starling.display.Quad;
	import feathers.controls.List;
	import events.NavigationEvent;
	import scenes.login.LoginHelper;
	
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
			footer.height = 30;
			footer.width = width;
			this.addChild( footer );
			footer.scaleX = .5;
			footer.scaleY = .10;
			
			exitButton = new Button();
			exitButton.label = "Exit";
			exitButton.addEventListener(starling.events.Event.TRIGGERED, onExitButtonTriggered);
//			exitButton.height = 40;
//			exitButton.width = 70;
			footer.addChild( exitButton );
			
			var obj:Object = exitButton.defaultLabelProperties;
			obj.textFormat = new TextFormat("Arial",24, 0xffffff);
			exitButton.defaultLabelProperties = obj;
			
			footer.y = height - footer.height;
			footer.x = (width - footer.width)/2;
///			
			exitButton.y = -height;
			exitButton.x = -105;
			
//			var list:GroupedList = new GroupedList();
//			
//			list.dataProvider = new HierarchicalCollection();
//			
//			list.addEventListener( Event.CHANGE, list_changeHandler );
//			list.y = header.height;
		//	this.addChild( list );
			
			levelList = new List;
			levelList.y = 75;
			levelList.x = 10;
			levelList.width = 125;
			levelList.itemRendererProperties.height = 10;
			
			addChild(levelList);
			levelList.addEventListener( starling.events.Event.CHANGE, onLevelSelected);
			levelList.validate();
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