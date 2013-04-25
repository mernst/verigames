package scenes.game.display 
{
	import assets.AssetInterface;
	import assets.AssetsFont;
	import starling.display.Image;
	import starling.display.Sprite;
	import starling.events.Event;
	import starling.filters.BlurFilter;
	import starling.filters.ColorMatrixFilter;
	import starling.textures.Texture;
	
	public class ScoreStar extends Sprite 
	{
		private static const SIZE:Number = 25;
		private var m_score:String;
		private var m_color:uint;
		private var m_starImage:Image;
		private var m_text:TextFieldWrapper;
		
		public function ScoreStar(score:String, color:uint) 
		{
			super();
			m_score = score;
			m_color = color;
			
			var colorWithAlpha:uint = 0xFF000000 + m_color;
			var starTexture:Texture = AssetInterface.getTextureColorAll("Game", "StarClass", colorWithAlpha);
			m_starImage = new Image(starTexture);
			m_starImage.width = m_starImage.height = SIZE;
			m_starImage.filter = BlurFilter.createDropShadow(1, Math.PI/4, 0x0, 1, 1.0, 0.5);
			addChildAt(m_starImage, 0);
			
			m_text = TextFactory.getInstance().createTextField(m_score.toString(), AssetsFont.FONT_NUMERIC, 0.8*SIZE, 0.8*SIZE, 0.6*SIZE, 0xFFFFFF);
			m_text.x = m_text.y = 0.1 * SIZE; 
			TextFactory.getInstance().updateAlign(m_text, 1, 1);
			addChild(m_text);
			
			scaleX = scaleY = 0.2;
		}
		
		override public function dispose():void
		{
			removeChildren(0, -1, true);
			if (m_text) {
				m_text.dispose();
				m_text = null;
			}
			if (m_starImage) {
				m_starImage.dispose();
				m_starImage = null;
			}
			super.dispose();
		}
		
		public function setScore(newScore:String):void
		{
			TextFactory.getInstance().updateText(m_text, newScore);
		}
		
	}

}