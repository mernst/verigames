package dialogs
{
	import assets.AssetInterface;
	import assets.AssetsFont;
	
	import display.BasicButton;
	import display.NineSliceBatch;
	import display.NineSliceButton;
	
	import events.MenuEvent;
	import networking.LevelInformation;
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
			
			var background:NineSliceBatch = new NineSliceBatch(_width*2, _height*2, 64, 64, "Game", "DialogWindowPNG", "DialogWindowXML", "DialogWindow");
			background.scaleX = background.scaleY = .5;

			addChild(background);
			
			var label:TextFieldWrapper = TextFactory.getInstance().createTextField("Share with\nyour group\nalso?", AssetsFont.FONT_UBUNTU, _width - 30, 32, 18, 0xFFFFFF);
			TextFactory.getInstance().updateAlign(label, 1, 1);
			addChild(label);
			label.x = 15;
			label.y = 15;
			
			cancel_button = ButtonFactory.getInstance().createButton("Cancel", 36, 16, 8, 8);
			cancel_button.addEventListener(starling.events.Event.TRIGGERED, onCancelButtonTriggered);
			addChild(cancel_button);
			cancel_button.x = _width - cancel_button.width - 15;
			cancel_button.y = _height - cancel_button.height - 18;	
			
			dont_share_button = ButtonFactory.getInstance().createButton("No", 36, 16, 8, 8);
			dont_share_button.addEventListener(starling.events.Event.TRIGGERED, onNoButtonTriggered);
			addChild(dont_share_button);
			dont_share_button.x = cancel_button.x - dont_share_button.width - 6;
			dont_share_button.y = _height - dont_share_button.height - 18;	
			
			share_button = ButtonFactory.getInstance().createButton("Yes", 36, 16, 8, 8);
			share_button.addEventListener(starling.events.Event.TRIGGERED, onYesButtonTriggered);
			addChild(share_button);
			share_button.x = dont_share_button.x - cancel_button.width - 6;
			share_button.y = _height - share_button.height - 18;
		}
		
		private function onCancelButtonTriggered(evt:Event):void
		{
			parent.removeChild(this);
		}
		
		private function onNoButtonTriggered(evt:Event):void
		{
			PipeJamGame.levelInfo.shareWithGroup = 0;
			dispatchEvent(new MenuEvent(MenuEvent.SAVE_LEVEL));
			parent.removeChild(this);
		}
		
		private function onYesButtonTriggered(evt:Event):void
		{
			PipeJamGame.levelInfo.shareWithGroup = 1;
			dispatchEvent(new MenuEvent(MenuEvent.SAVE_LEVEL));
			parent.removeChild(this);
		}
	}
}