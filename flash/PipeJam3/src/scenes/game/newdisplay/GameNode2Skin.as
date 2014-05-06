package scenes.game.newdisplay
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.geom.Point;
	
	import assets.AssetInterface;
	
	import constraints.ConstraintValue;
	import constraints.ConstraintVar;
	
	import display.NineSliceBatch;
	
	import graph.PropDictionary;
	
	import scenes.game.newdisplay.*;
	import scenes.game.display.GameEdgeContainer;
	import scenes.game.display.GameNode;
	import scenes.game.display.ScoreBlock;
	
	import starling.display.Image;
	import starling.display.Sprite;
	import starling.events.Event;
	import starling.filters.BlurFilter;
	import starling.text.TextField;
	import starling.textures.TextureAtlas;
	
	public class GameNode2Skin extends Sprite
	{
		
		public var currentColor:int;
		
		static protected var mAtlas:TextureAtlas;		
		static protected var wideSkin:Image;
		static protected var isInitialized:Boolean;
		
		public var isWide:Boolean;
		public var isEditable:Boolean;
		
		static public const wideLockedColor:int = 0x30302D;
		static public const narrowLockedColor:int = 0xA3A097;
		static public const wideColor:int = 0x14662F;
		static public const narrowColor:int = 0xABFFF2;

		
		public function GameNode2Skin()
		{
			
			if(!isInitialized)
			{
				if(!mAtlas)
					mAtlas = AssetInterface.getTextureAtlas("Game", "PipeJamSpriteSheetPNG", "PipeJamSpriteSheetXML");
				
				wideSkin = new Image(mAtlas.getTexture("DarkBlueCircle"));

				isInitialized = true;
			}
		}
		
		public function draw(_isWide:Boolean, _isEditable:Boolean):int
		{
			isWide = _isWide;
			isEditable = _isEditable;

			
			var img:Image = wideSkin;
			
			if(isWide && !this.isEditable)
			{
				img = wideSkin;
				currentColor = wideColor;
			}
			else if(!isWide && !this.isEditable)
			{
				img = wideSkin;
				
				currentColor = narrowColor;
			}
			else if(isWide && this.isEditable)
			{
				img = wideSkin;
				
				currentColor = wideColor;
			}
			else if(!isWide && this.isEditable)
			{
				img = wideSkin;
				
				currentColor = narrowColor;
			}
			
			addChild(img);
			
			return currentColor;
		}
	}
}