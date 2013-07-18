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
		private static const TUTORIAL_FONT_SIZE:Number = 12;
		private static const ARROW_SZ:Number = 8;
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
			padding.width = size.x + 2 * PADDING_SZ;
			padding.height = size.y + 2 * PADDING_SZ;
			addChild(padding);
			
			m_textContainer = new Sprite();
			m_textContainer.x = PADDING_SZ;
			m_textContainer.y = PADDING_SZ;
			addChild(m_textContainer);
			
			// background box
			var box:NineSliceBatch = new NineSliceBatch(size.x, size.y, 8, 8, "Game", "PipeJamSpriteSheetPNG", "PipeJamSpriteSheetXML", AssetInterface.PipeJamSubTexture_MenuButtonOverPrefix);
			m_textContainer.addChild(box);
			
			// text field
			var textField:TextFieldWrapper = TextFactory.getInstance().createTextField(text, AssetsFont.FONT_UBUNTU, size.x - 2 * INSET - (m_pointTo ? 0 : (ARROW_SZ + ARROW_BOUNCE + INSET)), size.y - 2 * INSET, TUTORIAL_FONT_SIZE, 0x0077FF);
			textField.x = INSET + (m_pointTo ? 0 : (ARROW_SZ + ARROW_BOUNCE + 2 * INSET));
			textField.y = INSET;
			m_textContainer.addChild(textField);
			
			// arrow
			var atlas:TextureAtlas = AssetInterface.getTextureAtlas("Game", "PipeJamSpriteSheetPNG", "PipeJamSpriteSheetXML");
			var arrowTexture:Texture = atlas.getTexture(AssetInterface.PipeJamSubTexture_MenuArrowHorizonal);
			m_tutorialArrow = new Image(arrowTexture);
			m_tutorialArrow.width = m_tutorialArrow.height = ARROW_SZ;
			addChild(m_tutorialArrow);
			
			XSprite.setPivotCenter(this);
			
			/*
			var textLines:Array = text.split("\n\n");
			const TEXT_SPACING:Number = 1.1; // i.e. 1.1 = 10% spacing between lines
			var lineHeight:Number = Math.min(TUTORIAL_FONT_SIZE, TUTORIAL_TEXT_AREA.height / textLines.length * TEXT_SPACING);
			const SEC_PER_CHAR:Number = 0.1; // seconds per character to calculate reading time
			var maxTextWidth:Number = 0;
			for (var i:uint = 0; i < textLines.length; i++) {
				var levelTextLine:String = textLines[i] as String;
				var textFieldLine:TextFieldWrapper = TextFactory.getInstance().createTextField(levelTextLine, AssetsFont.FONT_UBUNTU, WIDTH, lineHeight, lineHeight, 0x0077FF);
				TextFactory.getInstance().updateAlign(textFieldLine, 0, 0);
				textFieldLine.x = TUTORIAL_TEXT_AREA.x;
				textFieldLine.y = i * TEXT_SPACING * lineHeight + TUTORIAL_TEXT_AREA.y;
				textFieldLine.touchable = false;
				m_tutorialTextFields.push(textFieldLine);
				m_tutorialTextboxContainer.addChild(textFieldLine);
				maxTextWidth = Math.max(maxTextWidth, (textFieldLine as TextFieldHack).textBounds.width);
			}
			maxTextWidth += 2 * TUTORIAL_TEXT_AREA.x;
			var textHeight:Number = textLines.length * TEXT_SPACING * lineHeight + 2 * TUTORIAL_TEXT_AREA.y;
			var cXY:Number = Math.min(textHeight / 2.0, 16);
			m_tutorialBox = new NineSliceBatch(maxTextWidth, textHeight, cXY, cXY, "Game", "PipeJamSpriteSheetPNG", "PipeJamSpriteSheetXML", AssetInterface.PipeJamSubTexture_MenuButtonOverPrefix);
			m_tutorialTextboxContainer.x = (WIDTH - m_tutorialBox.width) / 2.0;
			m_tutorialTextboxContainer.addChildAt(m_tutorialBox, 0);
			addChild(m_tutorialTextboxContainer);
			if (!m_tutorialArrow) {
			}
			const ARROW_HEIGHT:Number = 19.0;
			m_tutorialArrow.scaleX = m_tutorialArrow.scaleY = lineHeight * 0.5 / ARROW_HEIGHT / TEXT_SPACING;
			m_tutorialArrow.x = TUTORIAL_TEXT_AREA.x - m_tutorialArrow.width;
			m_tutorialArrow.y = TUTORIAL_TEXT_AREA.y + (lineHeight - m_tutorialArrow.height) / 2.0;
			m_tutorialTextboxContainer.addChild(m_tutorialArrow);
			*/
			
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
				
				XSprite.setPivotCenter(m_tutorialArrow);
				m_tutorialArrow.rotation = Math.PI / 2;
				m_tutorialArrow.x = width / 2;
				m_tutorialArrow.y = height - INSET - ARROW_SZ / 2 + timeArrowOffset;
			} else {
				x = Constants.GameWidth / 2;
				y = height / 2 - PADDING_SZ;
				
				m_tutorialArrow.x = PADDING_SZ + INSET + timeArrowOffset;
				m_tutorialArrow.y = PADDING_SZ + INSET;
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
