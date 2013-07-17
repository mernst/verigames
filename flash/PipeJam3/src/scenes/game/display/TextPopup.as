package scenes.game.display
{
	import assets.AssetsFont;
	
	import flash.filters.BitmapFilter;
	import flash.filters.BitmapFilterQuality;
	import flash.filters.GlowFilter;
	import flash.geom.Point;
	
	import starling.core.Starling;
	import starling.display.DisplayObjectContainer;
	import starling.display.Sprite;
	
	import utils.XSprite;

	public class TextPopup extends Sprite
	{
		private static var m_outlineFilter:BitmapFilter;
		
		public function TextPopup(str:String, color:uint)
		{
			var textField:TextFieldWrapper = TextFactory.getInstance().createTextField(str, AssetsFont.FONT_UBUNTU, 100, 25, 8, color);
			TextFactory.getInstance().updateAlign(textField, TextFactory.HCENTER, TextFactory.VCENTER);
			TextFactory.getInstance().updateFilter(textField, getOutlineFilter());
			XSprite.setPivotCenter(textField);
			addChild(textField);
		}
		
		private static function getOutlineFilter():BitmapFilter
		{
			if (!m_outlineFilter) {
				var glowFilter:GlowFilter = new GlowFilter();
				glowFilter.blurX = glowFilter.blurY = 2;
				glowFilter.color = 0x000000;
				glowFilter.quality = BitmapFilterQuality.HIGH;
				glowFilter.strength = 100;
				
				m_outlineFilter = glowFilter;
			}
			return m_outlineFilter;
		}
		
		public static function popupText(container:DisplayObjectContainer, pos:Point, str:String, color:uint):void
		{
			var text:TextPopup = new TextPopup(str, color);
			text.x = pos.x;
			text.y = pos.y - 8;
			
			container.addChild(text);
			
			Starling.juggler.tween(text, 1.5, {y:pos.y - 20, alpha:0.2, onComplete:function():void { text.removeFromParent(); }});
		}
	}
}
