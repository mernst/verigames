package
{
	import assets.AssetInterface;
	import assets.AssetsFont;
	import display.NineSliceButton;
	
	public class ButtonFactory
	{
		private static var m_instance:ButtonFactory;
		
		public static function getInstance():ButtonFactory
		{
			if (m_instance == null) {
				m_instance = new ButtonFactory(new SingletonLock());
			}
			return m_instance;
		}
		
		public function ButtonFactory(lock:SingletonLock):void
		{
		}
		
		public function createDefaultButton(text:String, width:Number, height:Number):NineSliceButton
		{
			return createButton(text, width, height, height / 3.0, height / 3.0);
		}
		
		public function createButton(text:String, width:Number, height:Number, cX:Number, cY:Number):NineSliceButton
		{
			return new NineSliceButton(text, width, height, cX, cY, "Game", "PipeJamSpriteSheetPNG", "PipeJamSpriteSheetXML", 
									  AssetInterface.PipeJamSubTexture_MenuButtonPrefix, AssetsFont.FONT_UBUNTU, 0x0077FF,
									  AssetInterface.PipeJamSubTexture_MenuButtonOverPrefix, AssetInterface.PipeJamSubTexture_MenuButtonSelectedPrefix);
		}
	}
}

internal class SingletonLock {} // to prevent outside construction of singleton
