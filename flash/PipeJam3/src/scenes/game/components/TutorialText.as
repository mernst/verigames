package scenes.game.components
{
	import assets.AssetInterface;
	import assets.AssetsFont;
	
	import display.NineSliceBatch;
	
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import starling.display.DisplayObject;
	import starling.display.DisplayObjectContainer;
	import starling.display.Image;
	import starling.display.Quad;
	import starling.display.Sprite;
	import starling.events.Event;
	import starling.textures.Texture;
	import starling.textures.TextureAtlas;
	
	import utils.XSprite;
	
	public class TutorialText extends Sprite
	{
		private static const TUTORIAL_FONT_SIZE:Number = 10;
		private static const ARROW_SZ:Number = 10;
		private static const ARROW_BOUNCE:Number = 2;
		private static const ARROW_BOUNCE_SPEED:Number = 0.5;
		private static const INSET:Number = 3;
		private static const PADDING_SZ:Number = ARROW_SZ + ARROW_BOUNCE + 3 * INSET;

		private var m_tutorialTextFields:Vector.<TextFieldWrapper> = new Vector.<TextFieldWrapper>();
		private var m_textContainer:Sprite;
		private var m_tutorialBox:NineSliceBatch;
		private var m_tutorialArrow:Image;
		private var m_tutorialCursor:Quad;
		
		private var m_pointTo:DisplayObject;
		
		public function TutorialText(text:String, pointTo:DisplayObject)
		{
			var size:Point = new Point(200, 40);
			m_pointTo = pointTo;
			
			// a transparent sprite with padding around the edges so we can put the arrow outside the text box
			var padding:Quad = new Quad(10, 10, 0xff00ff);
			padding.alpha = 0.0;
			padding.touchable = false;
			padding.x = -size.x / 2 - PADDING_SZ;
			padding.y = -size.y / 2 - PADDING_SZ;
			padding.width = size.x + 2 * PADDING_SZ;
			padding.height = size.y + 2 * PADDING_SZ;
			addChild(padding);

			// to hold text
			m_textContainer = new Sprite();
			m_textContainer.x = -size.x / 2;
			m_textContainer.y = -size.y / 2;
			addChild(m_textContainer);
			
			// background box
			var box:NineSliceBatch = new NineSliceBatch(size.x, size.y, 8, 8, "Game", "PipeJamSpriteSheetPNG", "PipeJamSpriteSheetXML", AssetInterface.PipeJamSubTexture_MenuButtonOverPrefix);
			m_textContainer.addChild(box);
			
			// text field
			var textField:TextFieldWrapper = TextFactory.getInstance().createTextField(text, AssetsFont.FONT_UBUNTU, size.x - 2 * INSET, size.y - 2 * INSET, TUTORIAL_FONT_SIZE, 0x0077FF);
			textField.x = INSET;
			textField.y = INSET;
			m_textContainer.addChild(textField);
			
			// arrow
			var atlas:TextureAtlas = AssetInterface.getTextureAtlas("Game", "PipeJamSpriteSheetPNG", "PipeJamSpriteSheetXML");
			var arrowTexture:Texture = atlas.getTexture(AssetInterface.PipeJamSubTexture_MenuArrowHorizonal);
			m_tutorialArrow = new Image(arrowTexture);
			m_tutorialArrow.width = m_tutorialArrow.height = ARROW_SZ;
			XSprite.setPivotCenter(m_tutorialArrow);
			addChild(m_tutorialArrow);
			
			addEventListener(Event.ADDED_TO_STAGE, onAdded);
		}

		public function onAdded(evt:Event):void
		{
			removeEventListener(Event.ADDED_TO_STAGE, onAdded);
			
			addEventListener(Event.ENTER_FRAME, onEnterFrame);
			addEventListener(Event.REMOVED_FROM_STAGE, onRemoved);
		}
		
		public function onRemoved(evt:Event):void
		{
			removeEventListener(Event.ENTER_FRAME, onEnterFrame);
			removeEventListener(Event.REMOVED_FROM_STAGE, onRemoved);
		}

		private function onEnterFrame(evt:Event):void
		{
			var timeSec:Number = new Date().time / 1000.0;
			var timeArrowOffset:Number = ARROW_BOUNCE * (int(timeSec / ARROW_BOUNCE_SPEED) % 2);
			
			if (m_pointTo) {
				var pt:Point = new Point(0.5 * (m_pointTo.bounds.left + m_pointTo.bounds.right), m_pointTo.bounds.top);
				pt = m_pointTo.parent.localToGlobal(pt);
				pt = parent.globalToLocal(pt);

				x = pt.x;
				y = pt.y - height / 2;
				
				m_tutorialArrow.rotation = Math.PI / 2;
				m_tutorialArrow.x = 0;
				m_tutorialArrow.y = height / 2 - INSET - ARROW_SZ / 2 + timeArrowOffset;
			} else {
				x = Constants.GameWidth / 2;
				y = height / 2 - PADDING_SZ;
				
				m_tutorialArrow.x = -width / 2 + INSET + ARROW_SZ / 2 + timeArrowOffset;
				m_tutorialArrow.y = 0;
			}
		}
		
		public function getConsoleY():Number
		{
			if (m_pointTo) {
				return 0;
			} else {
				return height;
			}
		}
	}
}
