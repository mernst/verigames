package scenes.game.newdisplay
{
	import assets.AssetInterface;
	

	import starling.display.Image;
	import starling.display.Sprite;
	import starling.textures.TextureAtlas;
	import flash.utils.Dictionary;
	
	public class GameNode2Skin extends Sprite
	{
		static protected var availableGameNodeSkins:Vector.<GameNode2Skin>;
		static protected var activeGameNodeSkins:Dictionary;

		public var currentColor:int;
		
		static protected var mAtlas:TextureAtlas;		
		protected var skin:Image;
		protected var isInitialized:Boolean;
		
		public var isWide:Boolean;
		public var isEditable:Boolean;
		
		static public const wideLockedColor:int = 0x30302D;
		static public const narrowLockedColor:int = 0xA3A097;
		static public const wideColor:int = 0x14662F;
		static public const narrowColor:int = 0xABFFF2;

		var id:int;
		
		static public function InitializeSkins():void
		{
			//generate skins
			availableGameNodeSkins = new Vector.<GameNode2Skin>;
			activeGameNodeSkins = new Dictionary();
			
			for(var numSkin:int = 0; numSkin < 5000; numSkin++)
			{
				availableGameNodeSkins.push(new GameNode2Skin(numSkin));
			}
		}
		
		static public function getNextSkin():GameNode2Skin
		{
			var nextSkin:GameNode2Skin;
			if(availableGameNodeSkins.length > 0)
				nextSkin = availableGameNodeSkins.pop();
			else
				nextSkin = new GameNode2Skin(5001);
			
			activeGameNodeSkins[nextSkin.id] = nextSkin;
//			
//			var skinCount:int = countKeys(activeGameNodeSkins);
//			if(skinCount % 100 == 0)
//				trace("skin count ", skinCount);
			
			return nextSkin;
		}
		
		public static function countKeys(myDictionary:flash.utils.Dictionary):int 
		{
			var n:int = 0;
			for (var key:* in myDictionary) {
				n++;
			}
			return n;
		}
		
		public function GameNode2Skin(numSkin:int)
		{
			id = numSkin;
			
			if(!mAtlas)
				mAtlas = AssetInterface.getTextureAtlas("Game", "PipeJamSpriteSheetPNG", "PipeJamSpriteSheetXML");
		}
		
		public function setSkin(_isWide:Boolean, _isEditable:Boolean):void
		{
			if(skin && isWide == _isWide && isEditable == _isEditable)
				return;
			else
			{
				isWide = _isWide;
				isEditable = _isEditable;
			}
			
			if(skin)
			{
				skin.removeFromParent(true);
			}
			
			if(isWide && !this.isEditable)
			{
				skin = new Image(mAtlas.getTexture("DarkGrayCircle"));
				currentColor = wideColor;
			}
			else if(!isWide && !this.isEditable)
			{
				skin = new Image(mAtlas.getTexture("LightGrayCircle"));
				currentColor = narrowColor;
			}
			else if(isWide && this.isEditable)
			{
				skin = new Image(mAtlas.getTexture("DarkBlueCircle"));
				currentColor = wideColor;
			}
			else if(!isWide && !this.isEditable)
			{
				skin = new Image(mAtlas.getTexture("LightBlueCircle"));
				currentColor = narrowColor;
			}
			
			skin.scaleX = 20*skin.scaleX/skin.width;
			skin.scaleY = 20*skin.scaleY/skin.height;
			
			addChild(skin);
		}
		
		public function disableSkin():void
		{
			availableGameNodeSkins.push(this);
			delete activeGameNodeSkins[id];
		}
		
		public function draw(_isWide:Boolean, _isEditable:Boolean):int
		{
			setSkin(_isWide, _isEditable);
			
			return currentColor;
		}
	}
}