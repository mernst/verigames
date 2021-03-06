package display 
{
	import assets.AssetsAudio;
	import events.ToolTipEvent;
	import starling.textures.TextureAtlas;
	
	import audio.AudioManager;
	
	import flash.geom.Rectangle;
	import flash.ui.Mouse;
	import flash.ui.MouseCursor;
	
	import starling.display.Sprite;
	import starling.events.Event;
	import starling.events.Touch;
	import starling.events.TouchEvent;
	import starling.events.TouchPhase;
	
	public class NineSliceButton extends ToolTippableSprite 
	{
		private var m_buttonBatch:NineSliceBatch;
		private var m_buttonOverBatch:NineSliceBatch;
		private var m_buttonClickBatch:NineSliceBatch;
		protected var m_textField:TextFieldWrapper;
		protected var m_textFieldOver:TextFieldWrapper;
		protected var m_textFieldClick:TextFieldWrapper;
		protected var m_buttonSkin:Sprite;
		protected var m_buttonOverSkin:Sprite;
		protected var m_buttonClickSkin:Sprite;
		private var m_enabled:Boolean = true;
		
		protected static const TXT_PCT:Number = 0.9;
		protected static const MAX_DRAG_DIST:Number = 50;
		
		protected var fontName:String;
		protected var fontColor:uint;
		protected var m_toolTipText:String;
		
		//allow for setting other values
		public var alphaValue:Number = 0.3;
		
		public function NineSliceButton(_text:String, _width:Number, _height:Number, _cX:Number, _cY:Number, _atlas:TextureAtlas, 
										_atlasXMLButtonTexturePrefix:String, _fontName:String, _fontColor:uint, _atlasXMLButtonOverTexturePrefix:String = "", 
										_atlasXMLButtonClickTexturePrefix:String = "", _fontColorOver:uint = 0xFFFFFF, _fontColorClick:uint = 0xFFFFFF,
										_toolTipText:String = "")
		{
			fontName = _fontName;
			fontColor =  _fontColor;
			m_toolTipText = _toolTipText;
			
			m_buttonBatch = new NineSliceBatch(_width, _height, _cX, _cY, _atlas, _atlasXMLButtonTexturePrefix);
			m_textField = TextFactory.getInstance().createTextField(_text, _fontName, TXT_PCT * _width, TXT_PCT * _height, TXT_PCT * _height, _fontColor);
			m_textField.x = (1.0 - TXT_PCT) * _width / 2;
			m_textField.y = (1.0 - TXT_PCT) * _height / 2;
			TextFactory.getInstance().updateAlign(m_textField, 1, 1);
			m_buttonSkin = new Sprite();
			m_buttonSkin.addChild(m_buttonBatch);
			m_buttonSkin.addChild(m_textField);
			
			if (_atlasXMLButtonOverTexturePrefix) {
				m_buttonOverBatch = new NineSliceBatch(_width, _height, _cX, _cY, _atlas, _atlasXMLButtonOverTexturePrefix);
				m_textFieldOver = TextFactory.getInstance().createTextField(_text, _fontName, TXT_PCT * _width, TXT_PCT * _height, TXT_PCT * _height, _fontColorOver);
				m_textFieldOver.x = (1.0 - TXT_PCT) * _width / 2;
				m_textFieldOver.y = (1.0 - TXT_PCT) * _height / 2;
				TextFactory.getInstance().updateAlign(m_textFieldOver, 1, 1);
				m_buttonOverSkin = new Sprite();
				m_buttonOverSkin.addChild(m_buttonOverBatch);
				m_buttonOverSkin.addChild(m_textFieldOver);
			}
			
			if (_atlasXMLButtonClickTexturePrefix) {
				m_buttonClickBatch = new NineSliceBatch(_width, _height, _cX, _cY, _atlas, _atlasXMLButtonClickTexturePrefix);
				m_textFieldClick = TextFactory.getInstance().createTextField(_text, _fontName, TXT_PCT * _width, TXT_PCT * _height, TXT_PCT * _height, _fontColorClick);
				m_textFieldClick.x = (1.0 - TXT_PCT) * _width / 2;
				m_textFieldClick.y = (1.0 - TXT_PCT) * _height / 2;
				TextFactory.getInstance().updateAlign(m_textFieldClick, 1, 1);
				m_buttonClickSkin = new Sprite();
				m_buttonClickSkin.addChild(m_buttonClickBatch);
				m_buttonClickSkin.addChild(m_textFieldClick);
			}
			
			useHandCursor = true;
			addChild(m_buttonSkin);
			addEventListener(TouchEvent.TOUCH, onTouch);
		}
		
		public function removeTouchEvent():void
		{
			removeEventListener(TouchEvent.TOUCH, onTouch);
		}
		
		protected var mEnabled:Boolean = true;
		protected var mIsDown:Boolean = false;
		protected var mIsHovering:Boolean = false;
		// Adaptive from starling.display.Button
		protected override function onTouch(event:TouchEvent):void
        {
			super.onTouch(event);
			
            Mouse.cursor = (useHandCursor && mEnabled && event.interactsWith(this)) ? 
                MouseCursor.BUTTON : MouseCursor.AUTO;
            
            var touch:Touch = event.getTouch(this);
            if (!mEnabled) return;
            
			if (touch == null)
			{
				reset();
			}
            else if (touch.phase == TouchPhase.BEGAN)
            {
				mIsHovering = false;
				if (!mIsDown) {
					showButton(m_buttonClickSkin);
					mIsDown = true;
				}
            }
            else if (touch.phase == TouchPhase.HOVER)
            {
				if (!mIsHovering) {
					showButton(m_buttonOverSkin);
					//AudioManager.getInstance().audioDriver().playSfx(AssetsAudio.SFX_MENU_BUTTON);
				}
				mIsHovering = true;
				mIsDown = false;
            }
			else if (touch.phase == TouchPhase.MOVED && mIsDown)
            {
                // reset button when user dragged too far away after pushing
                var buttonRect:Rectangle = getBounds(stage);
                if (touch.globalX < buttonRect.x - MAX_DRAG_DIST ||
                    touch.globalY < buttonRect.y - MAX_DRAG_DIST ||
                    touch.globalX > buttonRect.x + buttonRect.width + MAX_DRAG_DIST ||
                    touch.globalY > buttonRect.y + buttonRect.height + MAX_DRAG_DIST)
                {
                    reset();
                }
            }
            else if (touch.phase == TouchPhase.ENDED)
            {
				if (mIsDown) {
					AudioManager.getInstance().audioDriver().playSfx(AssetsAudio.SFX_MENU_BUTTON);
					dispatchEventWith(Event.TRIGGERED, true);
				}
				reset();
            } else {
				reset();
			}
        }
		
		protected function reset():void
		{
			showButton(m_buttonSkin);
			mIsHovering = false;
			mIsDown = false;
		}
		
		protected function showButton(_skin:Sprite):void
		{
			this.removeChildren();
			addChild(_skin);
		}
		
		public function setButtonText(_text:String):void
		{
			//set all three stages for now - might want to allow for state differentiation
			m_buttonSkin.removeChild(m_textField);
			m_textField = TextFactory.getInstance().createTextField(_text, fontName, TXT_PCT * width, TXT_PCT * height, TXT_PCT * height, fontColor);
			m_textField.x = (1.0 - TXT_PCT) * width / 2;
			m_textField.y = (1.0 - TXT_PCT) * height / 2;
			TextFactory.getInstance().updateAlign(m_textField, 1, 1);
			m_buttonSkin.addChild(m_textField);
			
			m_buttonOverSkin.removeChild(m_textFieldOver);
			m_textFieldOver = TextFactory.getInstance().createTextField(_text, fontName, TXT_PCT * width, TXT_PCT * height, TXT_PCT * height, fontColor);
			m_textFieldOver.x = (1.0 - TXT_PCT) * width / 2;
			m_textFieldOver.y = (1.0 - TXT_PCT) * height / 2;
			TextFactory.getInstance().updateAlign(m_textFieldOver, 1, 1);
			m_buttonOverSkin.addChild(m_textFieldOver);
			
			m_buttonClickSkin.removeChild(m_textFieldClick);
			m_textFieldClick = TextFactory.getInstance().createTextField(_text, fontName, TXT_PCT * width, TXT_PCT * height, TXT_PCT * height, fontColor);
			m_textFieldClick.x = (1.0 - TXT_PCT) * width / 2;
			m_textFieldClick.y = (1.0 - TXT_PCT) * height / 2;
			TextFactory.getInstance().updateAlign(m_textFieldClick, 1, 1);
			m_buttonClickSkin.addChild(m_textFieldClick);
		}
		
		public function get enabled():Boolean
		{
			return m_enabled;
		}
		
		public function set enabled(value:Boolean):void
		{
			if (m_enabled == value) return;
			m_enabled = value;
			if (m_enabled) {
				useHandCursor = true;
				addEventListener(TouchEvent.TOUCH, onTouch);
				alpha = 1;
			} else {
				useHandCursor = false;
				removeEventListener(TouchEvent.TOUCH, onTouch);
				alpha = alphaValue;
			}
		}
		
		protected override function getToolTipEvent():ToolTipEvent
		{
			return new ToolTipEvent(ToolTipEvent.ADD_TOOL_TIP, this, m_toolTipText);
		}
	}
}