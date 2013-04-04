package scenes
{
	import flash.display.BitmapData;
	import flash.display3D.Context3D;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.Dictionary;
	
	import starling.core.RenderSupport;
	import starling.core.Starling;
	import starling.display.DisplayObject;
	import starling.display.Image;
	import starling.display.Sprite;
	import starling.errors.MissingContextError;
	import starling.textures.Texture;

	public class BaseComponent extends Sprite
	{	
		private var mClipRect:Rectangle;
		
		private var m_texture:Texture;
		private var m_image:Image;
				
		public function BaseComponent()
		{
			super();
		}
				
		public override function render(support:RenderSupport, alpha:Number):void
		{
			if (mClipRect == null) super.render(support, alpha);
			else
			{
				var context:Context3D = Starling.context;
				if (context == null) throw new MissingContextError();
				 
				support.finishQuadBatch();
				support.scissorRectangle = mClipRect;
				
				super.render(support, alpha);
				
				support.finishQuadBatch();
				support.scissorRectangle = null;
			}
		}
		
		public override function hitTest(localPoint:Point, forTouch:Boolean=false):DisplayObject
		{
			// without a clip rect, the sprite should behave just like before
			if (mClipRect == null) return super.hitTest(localPoint, forTouch); 
			
			// on a touch test, invisible or untouchable objects cause the test to fail
			if (forTouch && (!visible || !touchable)) return null;
			
			if (mClipRect.containsPoint(localToGlobal(localPoint)))
				return super.hitTest(localPoint, forTouch);
			else
				return null;
		}
		
		public function get clipRect():Rectangle { return mClipRect; }
		public function set clipRect(value:Rectangle):void
		{
			if (value) 
			{
				if (mClipRect == null) mClipRect = value.clone();
				else mClipRect.setTo(value.x, value.y, value.width, value.height);
			}
			else mClipRect = null;
		}
		
		//use this to force the size of the object
		//it adds a 'transparent' image of the specified size (you can make it non-transparent by changing the alpha value.)
		public function setPosition(_x:Number, _y:Number, _width:Number, _height:Number, _alpha:Number = 0.0, _color:Number = 0x000000):void
		{
			var shape:flash.display.Sprite = new flash.display.Sprite();
			shape.graphics.beginFill(_color,_alpha);
			shape.graphics.drawRect(0,0,_width, _height); 
			shape.graphics.endFill();
			var bmd:BitmapData = new BitmapData(_width, _height, true, 0x000000);
			bmd.draw(shape);
			m_texture = Texture.fromBitmapData(bmd);
			bmd.dispose();
			m_image = new Image(m_texture);
			this.addChildAt(m_image, 0);
			this.x = _x;
			this.y = _y;
		}
		
		public override function dispose():void
		{
			if(m_texture)
				m_texture.dispose();
			if(m_image)
				m_image.dispose();
			super.dispose();
		}
		
		public function findBoundingBox(edgeSetLayoutXML:XML):Rectangle
		{
			var i:int = 0;
			while(edgeSetLayoutXML.graph.attr[i].@name != "bb")
				i++;
			var edgeSetBBString:String = edgeSetLayoutXML.graph.attr[i].string;
			
			var bb:Rectangle = new Rectangle;
			var startPos:Number = 0;
			for(var index:int=0; index<4; index++)
			{
				var numEnd:int = edgeSetBBString.indexOf(',', startPos);
				var num:Number;
				if(numEnd != -1) 
					num = Number(edgeSetBBString.substring(startPos, numEnd));
				else
					num = Number(edgeSetBBString.substring(startPos));
				startPos = numEnd+1;
				switch(index)
				{
					case 0: bb.x = num; break;
					case 1: bb.y = num; break;
					case 2: bb.width = num - bb.x; break;
					case 3: bb.height = num - bb.y; break;
				}
			}
			return bb;
		}
		
		public function findNodePosition(edgeSetLayoutXML:XML):Point
		{
			var i:int = 0;
			var attrList:XMLList = edgeSetLayoutXML.attr;
			while(attrList[i].@name != "pos")
				i++;
			var edgeSetPosString:String = edgeSetLayoutXML.attr[i].string;
			
			var pos:Point = new Point;
			var numEnd:int = edgeSetPosString.indexOf(',');
			pos.x = Number(edgeSetPosString.substring(0, numEnd));
			pos.y = Number(edgeSetPosString.substring(numEnd+1));
			
			return pos;
		}
	}
}