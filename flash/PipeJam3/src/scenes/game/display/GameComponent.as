package scenes.game.display
{
	import flash.geom.Point;
	
	import scenes.BaseComponent;
	
	import starling.display.DisplayObjectContainer;
	import starling.display.materials.StandardMaterial;
	import starling.events.Event;
	
	public class GameComponent extends BaseComponent
	{
		public var m_isSelected:Boolean;
		public var m_isDirty:Boolean = false;
		
		protected var m_fromComponent:GameComponent;
		protected var m_toComponent:GameComponent;
		
		public static var NARROW_COLOR:uint = 0x5B74B8;// 0x1A85FF;
		public static var WIDE_COLOR:uint = 0xAEBEE0;// 0x3427FF;
		public static var UNADJUSTABLE_COLOR:uint = 0x6E6F71;// 0x3A3F4C;
		public static var ERROR_COLOR:uint = 0xE92227;
		public static var SCORE_COLOR:uint = 0xFFDC1A;
		
		static protected var fillMaterial:StandardMaterial = null;
		static protected var lightColorMaterial:StandardMaterial = null;
		static protected var darkColorMaterial:StandardMaterial = null;
		static protected var unadjustableColorMaterial:StandardMaterial = null;
		static protected var selectedColorMaterial:StandardMaterial = null;
		
		public function GameComponent()
		{
			super();
			m_isSelected = false;
			
			if(fillMaterial == null)
			{
				fillMaterial = new StandardMaterial;
				fillMaterial.color = 0xeeeeee;
				
				lightColorMaterial = new StandardMaterial;
				lightColorMaterial.color = NARROW_COLOR;
				
				darkColorMaterial = new StandardMaterial;
				darkColorMaterial.color = WIDE_COLOR;
				
				unadjustableColorMaterial = new StandardMaterial;
				unadjustableColorMaterial.color = UNADJUSTABLE_COLOR;
				
				selectedColorMaterial = new StandardMaterial;
				selectedColorMaterial.color = 0xeeeeee;
			}
		}
		
		public function isWide():Boolean
		{
			return false;
		}
		
		public function componentMoved(delta:Point):void
		{
			x += delta.x;
			y += delta.y;
		}
		
		public function getColor():int
		{
			return 0;
		}
		
		public function getScore():Number
		{
			return isWide() ? getWideScore() : getNarrowScore();
		}
		
		public function getWideScore():Number
		{
			return 0;
		}
		
		public function getNarrowScore():Number
		{
			return 0;
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
	}
}