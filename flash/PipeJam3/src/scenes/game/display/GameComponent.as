package scenes.game.display
{
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import scenes.BaseComponent;
	
	import starling.display.DisplayObjectContainer;
	import starling.display.materials.StandardMaterial;
	import starling.events.Event;
	
	public class GameComponent extends BaseComponent
	{
		
		public var m_id:String;
		
		public var m_isSelected:Boolean;
		public var m_isDirty:Boolean = false;
		
		public var m_boundingBox:Rectangle;
				
		//these are here in that they determine color, so all screen objects need them set
		public var m_isWide:Boolean = false;
		public var m_hasError:Boolean = false;
		public var m_isEditable:Boolean;
		public var m_shouldShowError:Boolean = true;
		public var isHoverOn:Boolean = false;

		
		public var m_forceColor:Number = -1;
		
		public static var NARROW_COLOR:uint = 0x6ED4FF;// 0x1A85FF;
		public static var NARROW_COLOR_BORDER:uint = 0x1773B8
		public static var WIDE_COLOR:uint = 0x0077FF;// 0x3427FF;
		public static var WIDE_COLOR_BORDER:uint = 0x1B3C86;
		public static var UNADJUSTABLE_WIDE_COLOR:uint = 0x808184;// 0x3A3F4C;
		public static var UNADJUSTABLE_WIDE_COLOR_BORDER:uint = 0x404144;
		public static var UNADJUSTABLE_NARROW_COLOR:uint = 0xD0D2D3;// 0x3A3F4C;
		public static var UNADJUSTABLE_NARROW_COLOR_BORDER:uint = 0x909293;
		public static var ERROR_COLOR:uint = 0xF05A28;// 0xE92227;
		public static var SCORE_COLOR:uint = 0x0;// 0xFFDC1A;
		public static var SELECTED_COLOR:uint = 0xff0000;
		
		public function GameComponent(_id:String)
		{
			super();
			
			m_id = _id;
			m_isSelected = false;
		}
		
		public function componentMoved(delta:Point):void
		{
			x += delta.x;
			y += delta.y;
		}
		
		public function getScore():Number
		{
			return m_isWide ? getWideScore() : getNarrowScore();
		}
		
		public function getWideScore():Number
		{
			return 0;
		}
		
		public function getNarrowScore():Number
		{
			return 0;
		}
		
		public function hasError():Boolean
		{
			return m_hasError;
		}
		
		
		public function componentSelected(isSelected:Boolean):void
		{
			m_isDirty = true;
			m_isSelected = isSelected;
		}
		
		public function hideComponent(hide:Boolean):void
		{
			visible = !hide;
			m_isDirty = true;
		}
		
		public function getGlobalScaleFactor():Point
		{
			var pt:Point = new Point(1,1);
			var currentParent:DisplayObjectContainer = parent;
			while(currentParent != null)
			{
				pt.x *= currentParent.scaleX;
				pt.y *= currentParent.scaleY;
				
				currentParent =  currentParent.parent;
			}
			
			return pt;
		}
		
		public function isEditable():Boolean
		{
			return m_isEditable;
		}
		
		//override this
		public function isWide():Boolean
		{
			return m_isWide;
		}
		
		public function setIsWide(b:Boolean):void
		{
			m_isWide = b;
		}
		
		public function forceColor(color:Number):void
		{
			m_forceColor = color;
			m_isDirty = true;
		}
		
		//set children's color, based on incoming and outgoing component and error condition
		public function getColor():int
		{
			var color:int;
			if (m_forceColor > -1) {
				color = m_forceColor;
			}
			else if(m_shouldShowError && hasError())
				color = ERROR_COLOR;
			else if(m_isEditable == true)
			{
				if(m_isWide == true)
					color = WIDE_COLOR;
				else
					color = NARROW_COLOR;
			}
			else //not adjustable
			{
				if(m_isWide == true)
					color = UNADJUSTABLE_WIDE_COLOR;
				else
					color = UNADJUSTABLE_NARROW_COLOR;				
			}
			if(m_isSelected)
				color -= 0x222222;
			
			return color;
		}
		
		public function updateSize():void
		{
		}
	}
}