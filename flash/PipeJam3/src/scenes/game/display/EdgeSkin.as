package scenes.game.display
{
	import assets.AssetInterface;
	import constraints.ConstraintVar;
	
	import starling.display.Image;
	import starling.display.Quad;
	import starling.display.Sprite;
	import starling.filters.BlurFilter;
	import starling.textures.TextureAtlas;
	
	import utils.PropDictionary;
	
	public class EdgeSkin extends Sprite
	{
		public var parentEdge:Edge;
		static protected var mAtlas:TextureAtlas;	
		
		protected var skinHeight:Number;
		protected var skinWidth:Number;
		
		protected var textureImage:Image;
		protected var preferenceQuad:Quad;
				
		public function EdgeSkin(_width:Number, _height:Number, _parentEdge:Edge)
		{
			skinHeight = _height;
			skinWidth = _width;
			
			parentEdge = _parentEdge;

			mAtlas = AssetInterface.getTextureAtlas("Game", "ParadoxSpriteSheetPNG", "ParadoxSpriteSheetPNG");
		}
		
		public function setColor(newGroup:Boolean = false):void
		{
			var skinQuad:Quad;
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
			var edge1:Quad;
			var edge2:Quad;
			if (edgeMatch) //(parentEdge.graphConstraint.isSatisfied())
			{
				skinQuad = new Quad(skinWidth, skinHeight, Constants.SATISFIED_EDGE);
				edge1 = new Quad(skinWidth, 1, Constants.SATISFIED_EDGE_HIGHLIGHT);
				edge2 = new Quad(skinWidth, 1, Constants.SATISFIED_EDGE_HIGHLIGHT);
			}
			else
			{
				skinQuad = new Quad(skinWidth, skinHeight, Constants.UNSATISFIED_EDGE);
				edge1 = new Quad(skinWidth, 1, Constants.UNSATISFIED_EDGE_HIGHLIGHT);
				edge2 = new Quad(skinWidth, 1, Constants.UNSATISFIED_EDGE_HIGHLIGHT);
			}
			addChild(skinQuad);
			addChild(edge1);
			edge2.y = skinHeight - 1;
			addChild(edge2);
			
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
		//	this.flatten();
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