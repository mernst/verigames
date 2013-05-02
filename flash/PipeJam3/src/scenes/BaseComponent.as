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

	public class BaseComponent extends starling.display.Sprite
	{	
		private var mClipRect:Rectangle;
		
		private var m_texture:Texture;
		private var m_image:Image;
		
		protected var m_disposed:Boolean;
		
		public function BaseComponent()
		{
			m_disposed = false;
			super();
		}
		
		override public function dispose():void
		{
			if (m_disposed) {
				return;
			}
			m_disposed = true;
			disposeChildren();
			if(m_texture)
				m_texture.dispose();
			if(m_image)
				m_image.dispose();
			super.dispose();
		}
		
		public function disposeChildren():void
		{
			while (this.numChildren > 0) {
				var obj:DisplayObject = getChildAt(0);
				if (obj is BaseComponent) {
					(obj as BaseComponent).disposeChildren();
				}
				obj.removeFromParent(true);
			}
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
		
		public function findBoundingBox(componentXML:XML):Rectangle
		{			
			var bb:Rectangle = new Rectangle;
			bb.x = componentXML.@left;
			bb.y = componentXML.@top;
			bb.width = componentXML.@right - componentXML.@left;
			bb.height = componentXML.@bottom - componentXML.@top;

			return bb;
		}
		
		public function findNodePosition(componentXML:XML):Point
		{
			var pos:Point = new Point(componentXML.@top, componentXML.@left);
			
			return pos;
		}
	}
}