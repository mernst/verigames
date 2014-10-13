package scenes.game.display
{
	import starling.display.Quad;
	import starling.display.Sprite;
	import starling.filters.BlurFilter;
	
	public class EdgeSkin extends Quad
	{
		public var parentEdge:Edge;
		
		public function EdgeSkin(width:Number, height:Number, _parentEdge:Edge, color:uint=0xffffff, premultipliedAlpha:Boolean=true)
		{
			super(width, height, color, premultipliedAlpha);
			
			parentEdge = _parentEdge;
			//move position 1 to make an isoceles triangle
			mVertexData.setPosition(1,width, height/2);
			//Move vertex 2 to the center of the from side, 3 to the old 2 position
			mVertexData.setPosition(2, -3, height/2);
			mVertexData.setPosition(3, 0, height);
			mVertexData.setUniformColor(color);
			
			onVertexDataChanged();
		}
		
		public function setColor(toColor:uint, fromColor:uint, fromColorComplement:uint):void
		{
			setVertexColor(0, fromColorComplement);
			setVertexColor(1, toColor);
			setVertexColor(2, fromColor);
			setVertexColor(3, fromColorComplement);

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