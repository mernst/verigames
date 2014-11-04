package scenes.game.display
{
	import assets.AssetInterface;
	
	import starling.display.Quad;
	import starling.display.Sprite;
	import starling.filters.BlurFilter;
	import starling.textures.Texture;
	import starling.textures.TextureAtlas;
	import starling.display.Image;
	
	public class EdgeSkin extends Sprite
	{
		public var parentEdge:Edge;
		static protected var mAtlas:TextureAtlas;	
		static protected var DarkConnector:Texture;
		static protected var LightConnector:Texture;
		
		protected var skinHeight:Number;
		protected var skinWidth:Number;
		
		protected var textureImage:Image;
		
		public function EdgeSkin(_width:Number, _height:Number, _parentEdge:Edge, color:uint=0xffffff, premultipliedAlpha:Boolean=true)
		{
//			super(width, height, color, premultipliedAlpha);
			skinHeight = _height;
			skinWidth = _width;
			
			parentEdge = _parentEdge;
			//move position 1 to make an isoceles triangle
//			mVertexData.setPosition(1,width, height/2);
//			//Move vertex 2 to the center of the from side, 3 to the old 2 position
//			mVertexData.setPosition(2, -3, height/2);
//			mVertexData.setPosition(3, 0, height);
//			mVertexData.setUniformColor(color);
			
//			onVertexDataChanged();
			mAtlas = AssetInterface.getTextureAtlas("Game", "NewSkinPNG", "NewSkinXML");
			DarkConnector = mAtlas.getTexture(AssetInterface.PipeJamSubTexture_LightConnector);
			LightConnector = mAtlas.getTexture(AssetInterface.PipeJamSubTexture_DarkConnector);
		}
		
		public function setColor():void
		{
			if(textureImage)
			{
				removeChild(textureImage, true);
			}
			
			if (parentEdge.fromNode.isNarrow)
			{
				textureImage = new Image(LightConnector);
			}
			else
			{
				textureImage = new Image(DarkConnector);
			}
			textureImage.width = skinWidth;
			textureImage.height = skinHeight;
			addChild(textureImage);
		}
		
		public function getConnectorTexture():Image
		{
			if(parentEdge.graphConstraint.lhs.id.indexOf('c') == 0)
				return new Image(DarkConnector);
			else
				return new Image(LightConnector);
		}
		
		public function setHighlight(highlightColor:uint):void
		{
			filter = BlurFilter.createGlow(highlightColor);
//			trace("skin", x,y);
		}
		
		public function removeHighlight():void
		{
			if(filter)
			{
				filter.dispose();
				filter = null;
			}
		}
		
		public override function set x(newX:Number):void
		{
			super.x = newX;
		}
		
		public function addToParent(parent:Sprite):void
		{
			parent.addChild(this);
		}
	}
}