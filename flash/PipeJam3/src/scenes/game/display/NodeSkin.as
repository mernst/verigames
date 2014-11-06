package scenes.game.display
{
	import flash.utils.Dictionary;
	
	import assets.AssetInterface;
	
	import constraints.ConstraintValue;
	
	import starling.animation.Transitions;
	import starling.animation.Tween;
	import starling.core.Starling;
	import starling.display.DisplayObject;
	import starling.display.DisplayObjectContainer;
	import starling.display.Image;
	import starling.display.Quad;
	import starling.display.Sprite;
	import starling.filters.BlurFilter;
	import starling.textures.Texture;
	import starling.textures.TextureAtlas;
	
	public class NodeSkin extends Sprite
	{
		static protected var availableGameNodeSkins:Vector.<NodeSkin>;
		static protected var activeGameNodeSkins:Dictionary;
		
		// TODO: Circular dependency
		public var associatedNode:Node;
		
		static protected var mAtlas:TextureAtlas;	
		static protected var DarkGrayCircle:Texture;
		static protected var LightGrayCircle:Texture;
		static public var DarkBlueCircle:Texture;
		static public var LightBlueCircle:Texture;
		static protected var DarkBlueCircleWithOutline:Texture;
		static protected var LightBlueCircleWithOutline:Texture;
		static protected var LightBlueSelectedCircle:Texture;
		static protected var DarkBlueSelectedCircle:Texture;
		
		static protected var GreenSquare:Texture;
		static protected var RedSquare:Texture;
		
		protected var lockedIcon:Image;
		protected var lockedQuad:Quad;
		protected var textureImage:Image;
		protected var constraintImage:Image;

		protected var isInitialized:Boolean;
		
		static protected var levelAtlas:TextureAtlas;
		
		static public const WIDE_NONEDITABLE_COLOR:int = 0x30302D;
		static public const NARROW_NONEDITABLE_COLOR:int = 0xA3A097;
		static public const WIDE_COLOR:int = 0x0B80FF;
		static public const NARROW_COLOR:int = 0xABFFF2;

		static public const WIDE_COLOR_COMPLEMENT:int = 0x0B90FF;
		static public const NARROW_COLOR_COMPLEMENT:int = 0x89DDD0;
		
		static public const LOCKED_COLOR:int = 0x00FF00;
		
		public var id:int;
		public static var numSkins:int = 2000;
		// TODO: Move to factory
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
		
		private static var nextId:int = 0;
		static public function getNextSkin():NodeSkin
		{
			var nextSkin:NodeSkin;
			if(availableGameNodeSkins.length > 0)
				nextSkin = availableGameNodeSkins.pop();
			else
			{
				if (false) // attempt limiting the number of skins
				{
					var attempts:int = 0;
					while (!activeGameNodeSkins[nextId])
					{
						if (nextId > numSkins) nextId = 0;
						nextId++;
						attempts++;
						if (attempts > numSkins) break;
					}
					nextSkin = activeGameNodeSkins[nextId];
					nextId++;
					if (nextSkin) nextSkin.disableSkin();
				}
				else
				{
					nextSkin = new NodeSkin(numSkins);
					numSkins++;
				}
			}

			if (nextSkin) activeGameNodeSkins[nextSkin.id] = nextSkin;

			return nextSkin;
		}
		
		static public function getColor(node:Node, edge:Edge = null):int
		{
			//ask the node if it's a clause, and if it is, figure out if the end is wide or not
			if(edge)
			{
				if(edge.graphConstraint.lhs.id.indexOf('c') == 0)
					return WIDE_COLOR;
				else
					return NARROW_COLOR;
			}
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
		
		static public function getComplementColor(node:Object):int
		{
			if(!node.isNarrow)
				return WIDE_COLOR_COMPLEMENT;
			else
				return NARROW_COLOR_COMPLEMENT;
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
				DarkBlueCircleWithOutline = mAtlas.getTexture(AssetInterface.PipeJamSubTexture_BlueDarkOutline);
				LightBlueCircleWithOutline = mAtlas.getTexture(AssetInterface.PipeJamSubTexture_BlueLightOutline);
				LightBlueSelectedCircle = mAtlas.getTexture(AssetInterface.PipeJamSubTexture_BlueLightSelected);
				DarkBlueSelectedCircle = mAtlas.getTexture(AssetInterface.PipeJamSubTexture_BlueDarkSelected);
				RedSquare = mAtlas.getTexture(AssetInterface.PipeJamSubTexture_ErrorConstraint);
				GreenSquare = mAtlas.getTexture(AssetInterface.PipeJamSubTexture_SatisfiedConstraint);
			}
		}
		
		public function draw():void
		{
			if(textureImage)
			{
				removeChild(textureImage, true);
			}
			
			var wideScore:Number = 1;
			var narrowScore:Number = 0;
			if(!associatedNode.isClause)
			{
				if (associatedNode.isNarrow && associatedNode.isSelected)
				{
					textureImage = new Image(LightBlueSelectedCircle);
				}
				else if (!associatedNode.isNarrow && associatedNode.isSelected)
				{
					textureImage = new Image(DarkBlueSelectedCircle);
				}
				else if (wideScore > narrowScore && associatedNode.isNarrow && associatedNode.isEditable)
				{
					textureImage = new Image(DarkBlueCircleWithOutline);
				}
				else if (narrowScore > wideScore && !associatedNode.isNarrow && associatedNode.isEditable)
				{
					textureImage = new Image(LightBlueCircleWithOutline);
				}
				else if(!associatedNode.isNarrow && !associatedNode.isEditable)
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
				addChild(textureImage);
			} else
			{
				if(constraintImage)
				{
					removeChild(constraintImage, true);
				}
				if(associatedNode.hasError())
				{
					constraintImage = new Image(RedSquare);
					
					if(associatedNode._hadError == false)
					{
						//flash if changing
						flash(0x00ff00);
					}
					associatedNode._hadError = true;
				}
				else
				{
					constraintImage = new Image(GreenSquare);
					
					if(associatedNode._hadError == true)
					{
						//flash if changing
						flash(0x00ff00);
					}
					associatedNode._hadError = false;
				}
				constraintImage.width = constraintImage.height = 20;
				addChild(constraintImage);
			}
			if(textureImage)
				textureImage.width = textureImage.height = (associatedNode.isNarrow ? 14 : 20);
			for each(var connectorImage:Image in associatedNode.connectors)
			{
				addChild(connectorImage);
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
		
		override public function set scaleX(newScale:Number):void
		{
			super.scaleX = newScale;
		}
		
		public function disableSkin():void
		{
			availableGameNodeSkins.push(this);
			associatedNode.skin = null;
			if (tween) Starling.juggler.remove(tween);
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
		
		private var saveParent:DisplayObjectContainer;
		private var tween:Tween;
		private var q:Quad;
		public function flash(color:int = 0xffff00):void
		{
			q = new Quad(50, 50, color);
			if(parent)
				saveParent = parent.parent;
			else
				saveParent = null;
			if(saveParent)
			{
				q.x = x + parent.x;// + 25;
				q.y = y + parent.y;// + 25;
				saveParent.addChild(q);
				tween = new Tween(q, 2);
				tween.fadeTo(0);
				tween.onComplete = flashComplete;
				Starling.juggler.add(tween);
			}
		}
		
		protected function flashComplete():void
		{
			if (q)
			{
				q.visible = false;
				if (q.parent) q.parent.removeChild(q);
			}
			if (tween) Starling.juggler.remove(tween);
			draw();
		}
	}
}