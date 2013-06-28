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
	import scenes.splashscreen.SplashScreenMenuBox;
	
	public class SelectLevelDialog extends CustomScreen
	{
		protected var levelList:List = null;
		
				
		public function SelectLevelDialog(_dialogParent:SplashScreenMenuBox)
		{
			super(_dialogParent);
		}
		
		//runs once when screen is first added to the stage.
		//a good place to add children and things.
		override protected function initialize():void
		{
			super.initialize();
			header.title = "Select a Level";
			
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
		}
		
		public override function setDialogInfo(_levelListCollection:ListCollection, _matchArrayMetadata:Array):void
		{			
			super.setDialogInfo(_levelListCollection, _matchArrayMetadata);
			levelList.dataProvider = levelListCollection;
		}
		
		protected override function onLevelSelected(e:starling.events.Event):void
		{
			LoginHelper.levelObject = matchArrayMetadata[levelList.selectedIndex];
			
			dispatchEvent(new NavigationEvent(NavigationEvent.CHANGE_SCREEN, "PipeJamGame"));
		}
		
		protected override function onExitButtonTriggered():void
		{
			parent.removeChild(this);
			dialogParent.showMainMenu(true);
		}
	}
}