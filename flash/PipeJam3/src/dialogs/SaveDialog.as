package dialogs
{
	import assets.AssetInterface;
	import assets.AssetsFont;
	
	import display.BasicButton;
	import display.NineSliceBatch;
	import display.NineSliceButton;
	
	import events.MenuEvent;
	import networking.LoginHelper;
	import flash.geom.Rectangle;
	
	import scenes.BaseComponent;
	
	import starling.display.Image;
	import starling.events.Event;
	import starling.events.Touch;
	import starling.events.TouchEvent;
	import starling.events.TouchPhase;
	import starling.textures.Texture;
	import starling.textures.TextureAtlas;
	
	public class SaveDialog extends BaseComponent
	{
		protected var cancel_button:NineSliceButton;
		protected var dont_share_button:NineSliceButton;
		protected var share_button:NineSliceButton;
				
		public function SaveDialog(_width:Number, _height:Number)
		{
			super();
			
			var background:NineSliceBatch = new NineSliceBatch(_width, _height, _width /6.0, _height / 6.0, "Game", "PipeJamSpriteSheetPNG", "PipeJamSpriteSheetXML", "MenuBoxFree");
			addChild(background);
			
			var label:TextFieldWrapper = TextFactory.getInstance().createTextField("Share with your group also?", AssetsFont.FONT_UBUNTU, _width - 10, 16, 12, 0x0077FF);
			TextFactory.getInstance().updateAlign(label, 0, 1);
			addChild(label);
			label.x = 5;
			label.y = 5;
			
			cancel_button = ButtonFactory.getInstance().createButton("Cancel", 40, 16, 8, 8);
			cancel_button.addEventListener(starling.events.Event.TRIGGERED, onCancelButtonTriggered);
			addChild(cancel_button);
			cancel_button.x = _width - cancel_button.width - 8;
			cancel_button.y = _height - cancel_button.height - 8;	
			
			dont_share_button = ButtonFactory.getInstance().createButton("No", 40, 16, 8, 8);
			dont_share_button.addEventListener(starling.events.Event.TRIGGERED, onNoButtonTriggered);
			addChild(dont_share_button);
			dont_share_button.x = cancel_button.x - dont_share_button.width - 8;
			dont_share_button.y = _height - dont_share_button.height - 8;	
			
			share_button = ButtonFactory.getInstance().createButton("Yes", 40, 16, 8, 8);
			share_button.addEventListener(starling.events.Event.TRIGGERED, onYesButtonTriggered);
			addChild(share_button);
			share_button.x = dont_share_button.x - cancel_button.width - 8;
			share_button.y = _height - share_button.height - 8;
		}
		
		private function onCancelButtonTriggered(evt:Event):void
		{
			parent.removeChild(this);
		}
		
		private function onNoButtonTriggered(evt:Event):void
		{
			parent.removeChild(this);
			var levelObject:Object = LoginHelper.getLoginHelper().levelObject;
			levelObject.shareWithGroup = 0;
			dispatchEvent(new MenuEvent(MenuEvent.SAVE_LEVEL));
		}
		
		private function onYesButtonTriggered(evt:Event):void
		{
			parent.removeChild(this);
			var levelObject:Object = LoginHelper.getLoginHelper().levelObject;
			levelObject.shareWithGroup = 1;
			dispatchEvent(new MenuEvent(MenuEvent.SAVE_LEVEL));
		}
	}
}