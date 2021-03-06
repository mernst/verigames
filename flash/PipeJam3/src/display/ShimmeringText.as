package display 
{
	import assets.AssetInterface;
	import flash.geom.Rectangle;
	import starling.animation.Transitions;
	import starling.core.Starling;
	import starling.display.Image;
	import starling.display.Sprite;
	import starling.events.Event;
	import starling.extensions.pixelmask.PixelMaskDisplayObject;
	import starling.textures.Texture;
	
	public class ShimmeringText extends Sprite 
	{
		
		private static const m_shimmerTexture:Texture = AssetInterface.getTexture("Game", "ShimmerClass");
		
		private var m_textField:TextFieldWrapper;
		private var m_textFieldShadow:TextFieldWrapper;
		private var m_shimmerImage:Image;
		private var m_maskedContainer:PixelMaskDisplayObject;
		
		public function ShimmeringText(_text:String, _fontName:String, _width:Number, _height:Number, _fontSize:Number, _color:uint) 
		{
			super();
			
			m_textField = TextFactory.getInstance().createTextField(_text, _fontName, _width, _height, _fontSize, _color);
			m_textFieldShadow = TextFactory.getInstance().createTextField(_text, _fontName, _width, _height, _fontSize, 0x0);
			m_textFieldShadow.y = m_textFieldShadow.x = 0.05 * _height;
			m_shimmerImage = new Image(m_shimmerTexture);
			m_shimmerImage.alpha = 1;
			m_shimmerImage.width = m_shimmerImage.height = _height;// * 2.0;
			//m_shimmerImage.y = - _height / 2.0;
			m_maskedContainer = new PixelMaskDisplayObject();
			addEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
		}
		
		private function onAddedToStage(evt:Event):void
		{
			addChild(m_textFieldShadow);
			addChild(m_textField);
			m_maskedContainer.addChild(m_shimmerImage);
			m_maskedContainer.mask = m_textField;
			addChild(m_maskedContainer);
			m_maskedContainer.visible = true;
		}
		
		public function shimmer(shimmerDelaySec:Number, shimmerTimeSec:Number, repeat:Boolean = false):void
		{
			Starling.juggler.removeTweens(m_shimmerImage);
			var textBounds:Rectangle = (m_textField as TextFieldHack).textBounds;
			m_shimmerImage.x = textBounds.left - 0.1 * textBounds.width - m_shimmerImage.width;
			Starling.juggler.tween(m_shimmerImage, shimmerTimeSec, { x:(textBounds.right + 0.1 * textBounds.width), delay:shimmerDelaySec, onComplete:function():void { if (repeat) shimmer(shimmerDelaySec, shimmerTimeSec); } } );
		}
		
		public function showLineShimmer(shimmerDelaySec:Number, shimmerTimeSec:Number, fadeDelaySec:Number = -1, fadeTimeSec:Number = 1.0):void
		{
			visible = true;
			shimmer(shimmerDelaySec, shimmerTimeSec);
			if (fadeDelaySec > 0) {
				fadeOut(fadeDelaySec, fadeTimeSec);
			}
		}
		
		public function fadeOut(fadeDelaySec:Number, fadeTimeSec:Number):void
		{
			Starling.juggler.removeTweens(this);
			Starling.juggler.tween(this, fadeTimeSec, { delay:fadeDelaySec, alpha:0, transition:Transitions.EASE_IN } );
		}
	}

}