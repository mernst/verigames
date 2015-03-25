package display
{
	import assets.AssetInterface;
	import starling.display.DisplayObject;
	import starling.display.Image;
	import starling.textures.TextureAtlas;
	
	public class FullScreenButton extends ImageStateButton
	{
		public function FullScreenButton()
		{
			m_toolTipText = "Make full screen";
			var atlas:TextureAtlas = AssetInterface.getTextureAtlas("Game", "ParadoxSpriteSheetPNG", "ParadoxSpriteSheetXML");
			super(
				Vector.<DisplayObject>([new Image(atlas.getTexture(AssetInterface.ParadoxSubTexture_ButtonMaximize))]),
				Vector.<DisplayObject>([new Image(atlas.getTexture(AssetInterface.ParadoxSubTexture_ButtonMaximizeOver))]),
				Vector.<DisplayObject>([new Image(atlas.getTexture(AssetInterface.ParadoxSubTexture_ButtonMaximizeClick))])
			);			
		}
	}
}
