package scenes.game.display
{
	import assets.AssetInterface;
	import constraints.ConstraintClause;
	import constraints.ConstraintVar;
	import utils.PropDictionary;
	
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
		protected var skinQuad:Quad;
		protected var preferenceQuad:Quad;
		
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
			mAtlas = AssetInterface.getTextureAtlas("Game", "PipeJamSpriteSheetPNG", "PipeJamSpriteSheetXML");
			DarkConnector = mAtlas.getTexture(AssetInterface.PipeJamSubTexture_DarkConnector);
			LightConnector = mAtlas.getTexture(AssetInterface.PipeJamSubTexture_LightConnector);
		}
		
		public function setColor():void
		{
			if (skinQuad) skinQuad.removeFromParent(true);
			
			var edgeMatch:Boolean = false;
			if (parentEdge.graphConstraint.lhs is ConstraintVar)
			{
				edgeMatch = (parentEdge.graphConstraint.lhs as ConstraintVar).getProps().hasProp(PropDictionary.PROP_NARROW);
			}
			else if (parentEdge.graphConstraint.rhs is ConstraintVar)
			{
				edgeMatch = !(parentEdge.graphConstraint.rhs as ConstraintVar).getProps().hasProp(PropDictionary.PROP_NARROW);
			}
			
			//if we match, normal line. if not, bright red line
			if (edgeMatch) //(parentEdge.graphConstraint.isSatisfied())
			{
				skinQuad = new Quad(skinWidth, skinHeight, Constants.SATISFIED_EDGE);
			}
			else
			{
				skinQuad = new Quad(skinWidth, skinHeight, Constants.UNSATISFIED_EDGE);
			}
			addChild(skinQuad);
			
			if (preferenceQuad) preferenceQuad.removeFromParent(true);
			const PREF_LENGTH:Number = Math.min(0.5 * skinWidth, 10.0);
			if (parentEdge.graphConstraint.lhs.id.substr(0, 1) == "c")
			{
				preferenceQuad = new Quad(PREF_LENGTH, skinHeight, Constants.WIDE_BLUE);
			}
			else
			{
				preferenceQuad = new Quad(PREF_LENGTH, skinHeight, Constants.NARROW_BLUE);
			}
			preferenceQuad.x = skinWidth - PREF_LENGTH;
			addChild(preferenceQuad);
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
		
	}
}