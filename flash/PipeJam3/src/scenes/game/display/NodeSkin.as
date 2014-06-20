package scenes.game.display
{
	import constraints.ConstraintValue;
	import flash.utils.Dictionary;
	
	import assets.AssetInterface;
	
	import constraints.ConstraintVar;
	
	import graph.PropDictionary;
	
	import starling.display.DisplayObject;
	import starling.display.Image;
	import starling.display.Sprite;
	import starling.filters.BlurFilter;
	import starling.textures.Texture;
	import starling.textures.TextureAtlas;
	
	public class NodeSkin extends Sprite
	{
		static protected var availableGameNodeSkins:Vector.<NodeSkin>;
		static protected var activeGameNodeSkins:Dictionary;
		
		public var associatedNode:Node;
		
		static protected var mAtlas:TextureAtlas;	
		static protected var DarkGrayCircle:Texture;
		static protected var LightGrayCircle:Texture;
		static protected var DarkBlueCircle:Texture;
		static protected var LightBlueCircle:Texture;
		static protected var DarkBlueOutline:Texture;
		static protected var LightBlueOutline:Texture;
		
		protected var textureImage:Image;
		protected var outlineTextureImage:Image;
		protected var isInitialized:Boolean;
				
		static public const WIDE_LOCKED_COLOR:int = 0x30302D;
		static public const NARROW_LOCKED_COLOR:int = 0xA3A097;
		static public const WIDE_COLOR:int = 0x0B80FF;
		static public const NARROW_COLOR:int = 0xABFFF2;

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
				return WIDE_LOCKED_COLOR;
			}
			else if(node.isNarrow && !node.isEditable)
			{
				return NARROW_LOCKED_COLOR;
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
				DarkGrayCircle = mAtlas.getTexture(AssetInterface.PipeJamSubTexture_GrayDarkStart);
				LightGrayCircle = mAtlas.getTexture(AssetInterface.PipeJamSubTexture_GrayLightStart);
				DarkBlueCircle = mAtlas.getTexture(AssetInterface.PipeJamSubTexture_BlueDarkStart);
				LightBlueCircle = mAtlas.getTexture(AssetInterface.PipeJamSubTexture_BlueLightStart);
				DarkBlueOutline = mAtlas.getTexture(AssetInterface.PipeJamSubTexture_BlueDarkOutline);
				LightBlueOutline = mAtlas.getTexture(AssetInterface.PipeJamSubTexture_BlueLightOutline);
			}
		}
		
		public function draw():void
		{
			if(textureImage)
			{
				removeChild(textureImage, true);
			}
			
			if (outlineTextureImage)
			{
				removeChild(outlineTextureImage, true);
				outlineTextureImage = null;
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
			
			var wideScore:Number = associatedNode.graphVar.scoringConfig.getScoringValue(ConstraintValue.VERBOSE_TYPE_1);
			var narrowScore:Number = associatedNode.graphVar.scoringConfig.getScoringValue(ConstraintValue.VERBOSE_TYPE_0);
			if (wideScore > narrowScore && associatedNode.isNarrow) {
				outlineTextureImage = new Image(DarkBlueOutline);
			} else if (narrowScore > wideScore && !associatedNode.isNarrow) {
				outlineTextureImage = new Image(LightBlueOutline);
			}
			if (outlineTextureImage)
			{
				outlineTextureImage.scaleX = 20*outlineTextureImage.scaleX/outlineTextureImage.width;
				outlineTextureImage.scaleY = 20 * outlineTextureImage.scaleY / outlineTextureImage.height;
				addChild(outlineTextureImage);
			}
			
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
		
		public function setNode(_associatedNode:Node):void
		{
			associatedNode = _associatedNode;
			
		}
	}
}