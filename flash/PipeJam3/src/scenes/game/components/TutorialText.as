package scenes.game.components
{
	import assets.AssetInterface;
	import assets.AssetsFont;
	
	import display.NineSliceBatch;
	
	import flash.geom.Point;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFormat;
	
	import scenes.game.display.Level;
	import scenes.game.display.TutorialManagerTextInfo;
	
	import starling.display.DisplayObject;
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
		private static const PADDING_SZ:Number = ARROW_SZ + 2 * ARROW_BOUNCE + 4 * INSET;

		private var m_textContainer:Sprite;
		private var m_tutorialArrow:Image;
		
		private var m_pointAt:DisplayObject;
		private var m_pointFrom:String;
		private var m_pointTo:String;
		private var m_pointPos:Point = new Point();
		private var m_pointPosNeedsInit:Boolean = true;
		private var m_pointPosAlwaysUpdate:Boolean = true;
		
		public function TutorialText(level:Level, info:TutorialManagerTextInfo)
		{
			if (level.tutorialManager && !level.tutorialManager.getPanZoomAllowed() && level.tutorialManager.getLayoutFixed()) {
				m_pointPosAlwaysUpdate = false;
			}
				
			// get text
			var text:String = info.text;

			// estimate size
			var size:Point = info.size ? info.size : TextFactory.getInstance().estimateTextFieldSize(text, AssetsFont.FONT_UBUNTU, TUTORIAL_FONT_SIZE);

			// get pointing setup
			m_pointAt = (info.pointAtFn != null) ? info.pointAtFn(level) : null;
			m_pointFrom = info.pointFrom;
			m_pointTo = info.pointTo;
			
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
			var box:NineSliceBatch = new NineSliceBatch(size.x, size.y, 8, 8, "Game", "PipeJamSpriteSheetPNG", "PipeJamSpriteSheetXML", AssetInterface.PipeJamSubTexture_TutorialBoxPrefix);
			m_textContainer.addChild(box);
			
			// text field
			var textField:TextFieldWrapper = TextFactory.getInstance().createTextField(text, AssetsFont.FONT_UBUNTU, size.x - 2 * INSET, size.y - 2 * INSET, TUTORIAL_FONT_SIZE, 0xEEEEEE);
			textField.x = INSET;
			textField.y = INSET;
			m_textContainer.addChild(textField);
			
			// arrow
			if (m_pointAt) {
				var atlas:TextureAtlas = AssetInterface.getTextureAtlas("Game", "PipeJamSpriteSheetPNG", "PipeJamSpriteSheetXML");
				var arrowTexture:Texture = atlas.getTexture(AssetInterface.PipeJamSubTexture_TutorialArrow);
				m_tutorialArrow = new Image(arrowTexture);
				m_tutorialArrow.width = m_tutorialArrow.height = ARROW_SZ;
				XSprite.setPivotCenter(m_tutorialArrow);
				addChild(m_tutorialArrow);
			}
			
			addEventListener(Event.ADDED_TO_STAGE, onAdded);
		}
		
		public function isPointingToObject():Boolean
		{
			return m_pointTo != null;
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
			
			if (m_pointAt) {
				var pt:Point = new Point();
				var offset:Point = new Point();
				
				switch (m_pointFrom) {
					case NineSliceBatch.TOP_LEFT:
						offset.x = -1;
						offset.y = -1;
						break;
					
					case NineSliceBatch.BOTTOM_RIGHT:
						offset.x = 1;
						offset.y = 1;
						break;
					
					case NineSliceBatch.TOP_RIGHT:
						offset.x = 1;
						offset.y = -1;
						break;
					
					case NineSliceBatch.BOTTOM_LEFT:
						offset.x = -1;
						offset.y = 1;
						break;
					
					case NineSliceBatch.LEFT:
						offset.x = -1;
						offset.y = 0;
						break;
					
					case NineSliceBatch.RIGHT:
						offset.x = 1;
						offset.y = 0;
						break;
					
					case NineSliceBatch.BOTTOM:
						offset.x = 0;
						offset.y = 1;
						break;
					
					case NineSliceBatch.TOP:
					default:
						offset.x = 0;
						offset.y = -1;
						break;
				}
				
				switch (m_pointTo ? m_pointTo : m_pointFrom) {
					case NineSliceBatch.CENTER:
						pt = new Point(0.5 * (m_pointAt.bounds.left + m_pointAt.bounds.right), 0.5 * (m_pointAt.bounds.top + m_pointAt.bounds.bottom));
						break;
					
					case NineSliceBatch.TOP_LEFT:
						pt = m_pointAt.bounds.topLeft;
						break;
					
					case NineSliceBatch.BOTTOM_RIGHT:
						pt = m_pointAt.bounds.bottomRight;
						break;
					
					case NineSliceBatch.TOP_RIGHT:
						pt = new Point(m_pointAt.bounds.right, m_pointAt.bounds.top);
						break;
					
					case NineSliceBatch.BOTTOM_LEFT:
						pt = new Point(m_pointAt.bounds.left, m_pointAt.bounds.bottom);
						break;
					
					case NineSliceBatch.LEFT:
						pt = new Point(m_pointAt.bounds.left, 0.5 * (m_pointAt.bounds.bottom + m_pointAt.bounds.top));
						break;
					
					case NineSliceBatch.RIGHT:
						pt = new Point(m_pointAt.bounds.right, 0.5 * (m_pointAt.bounds.bottom + m_pointAt.bounds.top));
						break;
					
					case NineSliceBatch.BOTTOM:
						pt = new Point(0.5 * (m_pointAt.bounds.left + m_pointAt.bounds.right), m_pointAt.bounds.bottom);
						break;
					
					case NineSliceBatch.TOP:
					default:
						pt = new Point(0.5 * (m_pointAt.bounds.left + m_pointAt.bounds.right), m_pointAt.bounds.top);
						break;
				}
				
				if (m_pointAt.parent) {
					pt = m_pointAt.parent.localToGlobal(pt);
					pt = parent.globalToLocal(pt);
					
					if (m_pointPosNeedsInit || m_pointPosAlwaysUpdate) {
						m_pointPos = pt;
						m_pointPosNeedsInit = false;
					}
				}

				x = m_pointPos.x + offset.x * (width / 2 - PADDING_SZ + 2 * INSET + ARROW_SZ + ARROW_BOUNCE);
				y = m_pointPos.y + offset.y * (height / 2 - PADDING_SZ + 2 * INSET + ARROW_SZ + ARROW_BOUNCE);
				
				var arrowPos:Number = INSET + ARROW_SZ / 2 - timeArrowOffset;
				
				m_tutorialArrow.rotation = Math.atan2(-offset.y, -offset.x);
				m_tutorialArrow.x = -offset.x * (width / 2 - PADDING_SZ + arrowPos);
				m_tutorialArrow.y = -offset.y * (height / 2 - PADDING_SZ + arrowPos);
			} else {
				x = Constants.GameWidth / 2;
				y = height / 2 - PADDING_SZ + INSET;
			}
		}
		
		private function sign(x:Number):Number
		{
			if (x < 0.0) {
				return -1.0;
			} else if (x > 0.0) {
				return 1.0;
			} else {
				return 0.0;
			}
		}
		public function getConsoleY():Number
		{
			if (m_pointAt) {
				return 0;
			} else {
				return height;
			}
		}
	}
}
