package display
{
	import assets.AssetInterface;
	import assets.AssetsFont;
	
	import flash.ui.Mouse;
	import flash.ui.MouseCursor;
	import starling.display.Sprite;
	import starling.events.Event;
	import starling.events.Touch;
	import starling.events.TouchEvent;
	import starling.events.TouchPhase;
	import flash.geom.Rectangle;
	import starling.display.Image;
	
	public class NineSliceToggleButton extends NineSliceButton
	{
		public var icon:Image;
		protected var label:TextFieldWrapper;
		protected var text:String;
		
		public function NineSliceToggleButton(_text:String, _width:Number, _height:Number, _cX:Number, _cY:Number, _atlasFile:String, _atlasImgName:String, _atlasXMLName:String, _atlasXMLButtonTexturePrefix:String, _fontName:String, _fontColor:uint, _atlasXMLButtonOverTexturePrefix:String="", _atlasXMLButtonClickTexturePrefix:String="", _fontColorOver:uint=0xFFFFFF, _fontColorClick:uint=0xFFFFFF)
		{
			super(_text, _width, _height, _cX, _cY, _atlasFile, _atlasImgName, _atlasXMLName, _atlasXMLButtonTexturePrefix, _fontName, _fontColor, _atlasXMLButtonOverTexturePrefix, _atlasXMLButtonClickTexturePrefix, _fontColorOver, _fontColorClick);
		
			addEventListener(TouchEvent.TOUCH, onTouch);
		}
		

		protected override function onTouch(event:TouchEvent):void
		{			
			var touch:Touch = event.getTouch(this);
			
			if(touch == null)
			{
				
			}
			else if (touch.phase == TouchPhase.ENDED)
			{
				if (!mIsDown) {
					dispatchEventWith(Event.TRIGGERED, true);
				}
			}
		}
		
		public function setToggleState(toggleOn:Boolean):void
		{
			mIsDown = toggleOn;
			if(mIsDown)
			{
				showButton(m_buttonClickSkin);
				setIcon(icon);
				setText(text);
			}
			else
			{
				showButton(m_buttonSkin);
				setIcon(icon);
				setText(text);
			}
		}
		
		public function setIcon(_icon:Image):void
		{
			icon = _icon;
			if(icon)
			{
				addChild(icon);
			}
		}
		
		public function setText(_text:String):void
		{
			text = _text;
			if(_text)
			{
				label = TextFactory.getInstance().createTextField(_text, AssetsFont.FONT_UBUNTU, width - 4, 10, 10, 0x0077FF);
				TextFactory.getInstance().updateAlign(label, 1, 1);
				addChild(label);
				label.x = 2;
				
				icon.y = label.height + 2;
			}
		}
	}
}