package scenes.game.components.dialogs
{
	import assets.AssetInterface;
	import assets.AssetsFont;
	
	import display.NineSliceBatch;
	import display.NineSliceButton;
	
	import scenes.BaseComponent;
	import starling.events.Event;

	public class SimpleAlertDialog extends BaseComponent
	{
		protected var ok_button:NineSliceButton;
		public function SimpleAlertDialog(text:String, _width:Number, _height:Number)
		{
			super();
			
			var background:NineSliceBatch = new NineSliceBatch(_width, _height, _width /6.0, _height / 6.0, "Game", "PipeJamSpriteSheetPNG", "PipeJamSpriteSheetXML", "MenuBoxFree");
			addChild(background);
			
			var label:TextFieldWrapper = TextFactory.getInstance().createTextField(text, AssetsFont.FONT_UBUNTU, 120, 14, 12, 0x0077FF);
			TextFactory.getInstance().updateAlign(label, 1, 1);
			addChild(label);
			label.x = (width - label.width)/2;
			label.y = 10;
			
			ok_button = ButtonFactory.getInstance().createDefaultButton("OK", 40, 20);
			ok_button.addEventListener(starling.events.Event.TRIGGERED, onOKButtonTriggered);
			addChild(ok_button);
			ok_button.x = (_width - ok_button.width)/2;
			ok_button.y = _height - 16 - 12;
		}
		
		private function onOKButtonTriggered(e:Event):void
		{
			visible = false;
		}
	}
}