package scenes.game.display
{
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import scenes.BaseComponent;
	import scenes.login.NetworkConnection;
	
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
		protected var m_isWide:Boolean;
		public var m_hasError:Boolean = false;
		public var m_isEditable:Boolean;
		public var m_shouldShowError:Boolean = true;

		public static var NARROW_COLOR:uint = 0x5B74B8;// 0x1A85FF;
		public static var WIDE_COLOR:uint = 0xAEBEE0;// 0x3427FF;
		public static var UNADJUSTABLE_WIDE_COLOR:uint = 0x6E6F71;// 0x3A3F4C;
		public static var UNADJUSTABLE_NARROW_COLOR:uint = 0xAAAAAA;// 0x3A3F4C;
		public static var ERROR_COLOR:uint = 0xE92227;
		public static var SCORE_COLOR:uint = 0xFFDC1A;
		
		static protected var fillMaterial:StandardMaterial = null;
		static protected var lightColorMaterial:StandardMaterial = null;
		static protected var darkColorMaterial:StandardMaterial = null;
		static protected var unadjustableWideColorMaterial:StandardMaterial = null;
		static protected var unadjustableNarrowColorMaterial:StandardMaterial = null;
		static protected var selectedColorMaterial:StandardMaterial = null;
		
		public function GameComponent(_id:String)
		{
			super();
			
			m_id = _id;
			m_isSelected = false;
			
			if(fillMaterial == null)
			{
				fillMaterial = new StandardMaterial;
				fillMaterial.color = 0xeeeeee;
				
				lightColorMaterial = new StandardMaterial;
				lightColorMaterial.color = NARROW_COLOR;
				
				darkColorMaterial = new StandardMaterial;
				darkColorMaterial.color = WIDE_COLOR;
				
				unadjustableWideColorMaterial = new StandardMaterial;
				unadjustableWideColorMaterial.color = UNADJUSTABLE_WIDE_COLOR;
				
				unadjustableNarrowColorMaterial = new StandardMaterial;
				unadjustableNarrowColorMaterial.color = UNADJUSTABLE_NARROW_COLOR;
				
				selectedColorMaterial = new StandardMaterial;
				selectedColorMaterial.color = 0xeeeeee;
			}
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
			
			if(m_isSelected)
				dispatchEvent(new starling.events.Event(Level.COMPONENT_SELECTED, true, this));
			else
				dispatchEvent(new starling.events.Event(Level.COMPONENT_UNSELECTED, true, this));
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
		
		//set children's color, based on incoming and outgoing component and error condition
		public function getColor():int
		{
			if(m_shouldShowError && hasError())
				return ERROR_COLOR;
			if(m_isEditable == true)
			{
				if(m_isWide == true)
					return WIDE_COLOR;
				else
					return NARROW_COLOR;
			}
			else //not adjustable
			{
				if(m_isWide == true)
					return UNADJUSTABLE_WIDE_COLOR;
				else
					return UNADJUSTABLE_NARROW_COLOR;				
			}
		}
	}
}