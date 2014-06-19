package scenes.game.display
{
	import flash.utils.Dictionary;
	
	import assets.AssetInterface;
		
	import starling.display.DisplayObject;
	import starling.display.Image;
	import starling.display.Sprite;
	import starling.filters.BlurFilter;
	import starling.textures.Texture;
	import starling.textures.TextureAtlas;
	import starling.display.Quad;
	
	public class NodeSkin extends Sprite
	{
		static protected var availableGameNodeSkins:Vector.<NodeSkin>;
		static protected var activeGameNodeSkins:Dictionary;
		
		public var associatedNode:Object;
		
		static protected var mAtlas:TextureAtlas;	
		static protected var DarkGrayCircle:Texture;
		static protected var LightGrayCircle:Texture;
		static protected var DarkBlueCircle:Texture;
		static protected var LightBlueCircle:Texture;
		
		protected var lockedIcon:Image;
		protected var lockedQuad:Quad;
		protected var textureImage:Image;
		protected var isInitialized:Boolean;
				
		static protected var levelAtlas:TextureAtlas;
		
		static public const WIDE_NONEDITABLE_COLOR:int = 0x30302D;
		static public const NARROW_NONEDITABLE_COLOR:int = 0xA3A097;
		static public const WIDE_COLOR:int = 0x0B80FF;
		static public const NARROW_COLOR:int = 0xABFFF2;

		static public const LOCKED_COLOR:int = 0x00FF00;
		
		public var id:int;
		public static var numSkins:int = 5000;
		
		static public function InitializeSkins():void
		{
			//generate skins
			availableGameNodeSkins = new Vector.<NodeSkin>;
			activeGameNodeSkins = new Dictionary();
			
			for(var numSkin:int = 0; numSkin < numSkins; numSkin++)
			{
				availableGameNodeSkins.push(new NodeSkin(numSkin));
			}
			
			levelAtlas = AssetInterface.getTextureAtlas("Game", "PipeJamLevelSelectSpriteSheetPNG", "PipeJamLevelSelectSpriteSheetXML");
		}
		
		static public function getNextSkin():NodeSkin
		{
			var nextSkin:NodeSkin;
			if(availableGameNodeSkins.length > 0)
				nextSkin = availableGameNodeSkins.pop();
			else
			{
				nextSkin = new NodeSkin(numSkins);
				numSkins++;
			}

			activeGameNodeSkins[nextSkin.id] = nextSkin;

			return nextSkin;
		}
		
		static public function getColor(node:Object):int
		{
			if(!node.isNarrow && !node.isEditable)
			{
				return WIDE_NONEDITABLE_COLOR;
			}
			else if(node.isNarrow && !node.isEditable)
			{
				return NARROW_NONEDITABLE_COLOR;
			}
			else if(!node.isNarrow && node.isEditable)
			{
				return WIDE_COLOR;
			}
			else
			{
				return NARROW_COLOR;
			}
		}
		
		public static function countKeys(myDictionary:flash.utils.Dictionary):int 
		{
			var n:int = 0;
			for (var key:* in myDictionary) {
				n++;
			}
			return n;
		}
		
		public function NodeSkin(numSkin:int)
		{
			id = numSkin;
			
			if(!mAtlas)
			{
				mAtlas = AssetInterface.getTextureAtlas("Game", "PipeJamSpriteSheetPNG", "PipeJamSpriteSheetXML");
				DarkGrayCircle = mAtlas.getTexture("DarkGrayCircle");
				LightGrayCircle = mAtlas.getTexture("LightGrayCircle");
				DarkBlueCircle = mAtlas.getTexture("DarkBlueCircle");
				LightBlueCircle = mAtlas.getTexture("LightBlueCircle");
			}
		}
		
		public function draw():void
		{
			if(textureImage)
			{
				removeChild(textureImage, true);
			}
			
			if(!associatedNode.isNarrow && !associatedNode.isEditable)
			{
				textureImage = new Image(DarkGrayCircle);
			}
			else if(associatedNode.isNarrow && !associatedNode.isEditable)
			{
				textureImage = new Image(LightGrayCircle);
			}
			else if(!associatedNode.isNarrow && associatedNode.isEditable)
			{
				textureImage = new Image(DarkBlueCircle);
			}
			else if(associatedNode.isNarrow && associatedNode.isEditable)
			{
				textureImage = new Image(LightBlueCircle);
			}
			
			textureImage.scaleX = 20*textureImage.scaleX/textureImage.width;
			textureImage.scaleY = 20*textureImage.scaleY/textureImage.height;
			
			addChild(textureImage);
				
			if(associatedNode.isSelected)
			{
				// Apply the glow filter if not already there
				if(!this.filter)
					this.filter = BlurFilter.createGlow();
			}
			else
			{
				if(this.filter)
				{
					this.filter.dispose();
					this.filter = null;
				}
			}
			
			if(associatedNode.isLocked)
			{
				lockedQuad = new Quad(20,20, LOCKED_COLOR);
				addChild(lockedQuad);
				if(!lockedIcon)
					lockedIcon = new Image(levelAtlas.getTexture("DocumentIconLocked"));
				lockedIcon.width = lockedIcon.height = 8;
				lockedIcon.x = lockedIcon.y = 12;
				addChild(lockedIcon);
			}
			else if(lockedIcon)
			{
				removeChild(lockedIcon);
				removeChild(lockedQuad);
			}
		}
		
		public function disableSkin():void
		{
			availableGameNodeSkins.push(this);
			associatedNode.skin = null;
			delete activeGameNodeSkins[id];
		}
		
		override public function removeChild(_child:DisplayObject, dispose:Boolean = false):DisplayObject
		{
			return super.removeChild(_child, dispose);
		}
		
		public function setNode(_associatedNode:Object):void
		{
			associatedNode = _associatedNode;
			
		}
	}
}