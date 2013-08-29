package dialogs
{
	import assets.AssetInterface;
	import assets.AssetsFont;
	
	import display.NineSliceBatch;
	import display.NineSliceButton;
	
	import scenes.BaseComponent;
	
	import starling.events.Event;
	
	public class SimpleTwoButtonDialog extends BaseComponent
	{
		protected var button1_button:NineSliceButton;
		protected var button2_button:NineSliceButton;
		
		protected var m_answerCallback:Function;
		
		//answerCallback takes an int, specifying if button one or button two was clicked
		public function SimpleTwoButtonDialog(text:String, button1String:String, button2String:String, _width:Number, _height:Number, answerCallback:Function)
		{
			super();
			
			m_answerCallback = answerCallback;
			
			var background:NineSliceBatch = new NineSliceBatch(_width, _height, _width /6.0, _height / 6.0, "Game", "PipeJamSpriteSheetPNG", "PipeJamSpriteSheetXML", "MenuBoxFree");
			addChild(background);
			
			var label:TextFieldWrapper = TextFactory.getInstance().createTextField(text, AssetsFont.FONT_UBUNTU, 120, 14, 12, 0x0077FF);
			TextFactory.getInstance().updateAlign(label, 1, 1);
			addChild(label);
			label.x = (width - label.width)/2;
			label.y = 10;
			
			button2_button = ButtonFactory.getInstance().createButton(button2String, 40, 20, 8, 8);
			button2_button.addEventListener(starling.events.Event.TRIGGERED, onButtonTriggered);
			addChild(button2_button);
			button2_button.x = _width - button2_button.width - 12;
			button2_button.y = _height - 16 - 12;
			
			button1_button = ButtonFactory.getInstance().createButton(button1String, 40, 20, 8, 8);
			button1_button.addEventListener(starling.events.Event.TRIGGERED, onButtonTriggered);
			addChild(button1_button);
			button1_button.x = _width - button1_button.width - 12 - button2_button.width - 12;
			button1_button.y = _height - 16 - 12;
		}
		
		private function onButtonTriggered(event:Event):void
		{
			if(event.target == button1_button)
				m_answerCallback(1);
			else
				m_answerCallback(2);
			
			this.removeFromParent(true);
		}
	}
}