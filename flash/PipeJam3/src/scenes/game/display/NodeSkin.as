package scenes.game.display
{
	import flash.utils.Dictionary;
	import utils.XMath;
	
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
		public var isBackground:Boolean = false;
		
		static protected var mAtlas:TextureAtlas;	
		static protected var DarkGrayCircle:Texture;
		static protected var LightGrayCircle:Texture;
		static public var DarkBlueCircle:Texture;
		static public var LightBlueCircle:Texture;
		static protected var DarkBlueCircleWithOutline:Texture;
		static protected var LightBlueCircleWithOutline:Texture;
		static protected var LightBlueSelectedCircle:Texture;
		static protected var DarkBlueSelectedCircle:Texture;
		
		static protected var SatisfiedConstraintTexture:Texture;
		static protected var UnsatisfiedConstraintTexture:Texture;
		static protected var UnsatisfiedConstraintBackgroundTexture:Texture;
		
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
				DarkBlueCircle = mAtlas.getTexture(AssetInterface.PipeJamSubTexture_VariableWide);
				LightBlueCircle = mAtlas.getTexture(AssetInterface.PipeJamSubTexture_VariableNarrow);
				DarkBlueCircleWithOutline = mAtlas.getTexture(AssetInterface.PipeJamSubTexture_BlueDarkOutline);
				LightBlueCircleWithOutline = mAtlas.getTexture(AssetInterface.PipeJamSubTexture_BlueLightOutline);
				LightBlueSelectedCircle = mAtlas.getTexture(AssetInterface.PipeJamSubTexture_VariableNarrowSelected);
				DarkBlueSelectedCircle = mAtlas.getTexture(AssetInterface.PipeJamSubTexture_VariableWideSelected);
				UnsatisfiedConstraintTexture = mAtlas.getTexture(AssetInterface.PipeJamSubTexture_ErrorConstraint);
				SatisfiedConstraintTexture = mAtlas.getTexture(AssetInterface.PipeJamSubTexture_SatisfiedConstraint);
				UnsatisfiedConstraintBackgroundTexture = mAtlas.getTexture(AssetInterface.PipeJamSubTexture_Conflict);
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
			if(!(associatedNode as ClauseNode))
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
				
				if(associatedNode.solved && associatedNode.isSelected)
				{
					textureImage.setVertexColor(0, 0x00ff00);
					textureImage.setVertexColor(1, 0x00ff00);
					textureImage.setVertexColor(2, 0x00ff00);
					textureImage.setVertexColor(3, 0x00ff00);
					associatedNode.solved = false;
				}
				else
				{
					textureImage.setVertexColor(0, 0xffffff);
					textureImage.setVertexColor(1, 0xffffff);
					textureImage.setVertexColor(2, 0xffffff);
					textureImage.setVertexColor(3, 0xffffff);
				}	
				
				if(associatedNode.isNarrow)
					textureImage.width = textureImage.height = 10;
				else
					textureImage.width = textureImage.height = 14;
				textureImage.x -= textureImage.width/2;
				textureImage.y -= textureImage.width/2; 
				addChild(textureImage);
			}
			else
			{
				// Is clause
				var associatedClauseNode:ClauseNode = associatedNode as ClauseNode;
				if(constraintImage)
				{
					constraintImage.removeFromParent(true);
				}
				if(associatedClauseNode.hasError())
				{
					if (isBackground)
					{
						constraintImage = new Image(UnsatisfiedConstraintBackgroundTexture);
						constraintImage.width = constraintImage.height = 40;
					}
					else
					{
						constraintImage = new Image(UnsatisfiedConstraintTexture);
						constraintImage.width = constraintImage.height = 10;
					}
					
					if(associatedClauseNode.hadError == false && associatedClauseNode == true)
					{
						//flash if changing
						flash(0x00ff00);
					}
					associatedClauseNode.hadError = true;
				}
				else
				{
					if (isBackground) return; // no background image for satisfied conflicts
					constraintImage = new Image(SatisfiedConstraintTexture);
					if(associatedClauseNode.hadError == true)
					{
						//flash if changing
						flash();
					}
					associatedClauseNode.hadError = false;
				}
				constraintImage.x -= constraintImage.width/2;
				constraintImage.y -= constraintImage.width/2; 
				addChild(constraintImage);
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
		
		public function setNode(_associatedNode:Node, _isBackground:Boolean = false):void
		{
			associatedNode = _associatedNode;
			isBackground = _isBackground;
		}
		
		private var tween:Tween;
		private var q:Quad;
		public function flash(color:int = 0x00ff00):void
		{
			q = new Quad(50, 50, color);
			if(parent)
			{
				q.x = x - 25;
				q.y = y - 25;
				parent.addChild(q);
				tween = new Tween(q, 2);
				tween.fadeTo(0);
				tween.onComplete = flashComplete;
				Starling.juggler.add(tween);
			}
		}
		
		protected function flashComplete():void
		{
			var saveParent:Sprite;
			if (q)
			{
				q.visible = false;
				if (q.parent != null)
				{
					saveParent = q.parent as Sprite;
					q.removeFromParent(true);
			//		if (saveParent) saveParent.flatten();
				}
			}
			if (tween) Starling.juggler.remove(tween);
			associatedNode.solved = true;
			draw();
		}
		
		public function scale(newScale:Number):void
		{
			if (isBackground) return;
			var currentWidth:Number;
			var newWidth:Number;
			if (textureImage != null)
			{
				currentWidth = textureImage.width;
				textureImage.scaleX = textureImage.scaleY = newScale * (associatedNode.isNarrow ? 0.5 : 0.9);
				newWidth = XMath.clamp(textureImage.width, 5, 50);
				textureImage.x -= (newWidth - currentWidth) / 2;
				textureImage.y -= (newWidth - currentWidth) / 2;
			}
			//if (constraintImage != null)
			//{
				//currentWidth = constraintImage.width;
				//constraintImage.scaleX = constraintImage.scaleY = newScale;
				//newWidth = XMath.clamp(constraintImage.width, 5, 50);
				//constraintImage.x -= (newWidth - currentWidth) / 2;
				//constraintImage.y -= (newWidth - currentWidth) / 2;
			//}
		}
	}
}