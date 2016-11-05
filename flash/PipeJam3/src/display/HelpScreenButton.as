package display 
{
	import scenes.game.display.World;
	import starling.display.Image;
	import assets.AssetInterface;
	import starling.textures.TextureAtlas;
	import starling.display.DisplayObject;
	import starling.events.Event;
	
	
	/**
	 * ...
	 * @author ...
	 */
	public class HelpScreenButton extends ImageStateButton
	{
		public var m_world:World;
		public var m_splash:Image;
		
		
		public function HelpScreenButton(_world:World) 
		{
			m_toolTipText = "What's going on..?";
			
			// Need to know which world we're painting on..
			m_world = _world;
			
			var atlas:TextureAtlas = AssetInterface.ParadoxSpriteSheetAtlas;
			super(
				Vector.<DisplayObject>([new Image(atlas.getTexture(AssetInterface.ParadoxSubTexture_ButtonMaximize))]),
				Vector.<DisplayObject>([new Image(atlas.getTexture(AssetInterface.ParadoxSubTexture_ButtonMaximizeOver))]),
				Vector.<DisplayObject>([new Image(atlas.getTexture(AssetInterface.ParadoxSubTexture_ButtonMaximizeClick))])
			);	
			
			// Default splash screen
			m_splash = new Image(AssetInterface.getTexture("Game", "GameHelpSplashClass" + PipeJam3.ASSET_SUFFIX));
			
			this.addEventListener(Event.TRIGGERED, showHelpScreen);
		}
		
		public function showHelpScreen():void 
		{
			m_world.showSplashScreen(m_splash);
		}
	}

}