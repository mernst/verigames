package scenes.game.display
{
	import events.ToolTipEvent;
	import starling.events.Touch;
	
	import flash.events.TimerEvent;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.Timer;
	
	import graph.PropDictionary;
	
	import scenes.BaseComponent;
	
	import starling.display.DisplayObjectContainer;
	import starling.display.materials.StandardMaterial;
	import starling.events.Event;
	import starling.events.TouchEvent;
	import starling.events.TouchPhase;
	
	public class GameComponent extends BaseComponent
	{
		protected static const DEBUG_TRACE_IDS:Boolean = true;
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
		public var draggable:Boolean = true;
		protected var m_propertyMode:String = PropDictionary.PROP_NARROW;
		protected var m_props:PropDictionary = new PropDictionary();
		protected var m_hoverTimer:Timer;
		protected var m_hoverPointGlobal:Point;
		public var m_forceColor:Number = -1;
		
		public static const NARROW_COLOR:uint = 0x6ED4FF;
		public static const NARROW_COLOR_BORDER:uint = 0x1773B8
		public static const WIDE_COLOR:uint = 0x0077FF;
		public static const WIDE_COLOR_BORDER:uint = 0x1B3C86;
		public static const UNADJUSTABLE_WIDE_COLOR:uint = 0x808184;
		public static const UNADJUSTABLE_WIDE_COLOR_BORDER:uint = 0x404144;
		public static const UNADJUSTABLE_NARROW_COLOR:uint = 0xD0D2D3;
		public static const UNADJUSTABLE_NARROW_COLOR_BORDER:uint = 0x0;
		public static const ERROR_COLOR:uint = 0xF05A28;
		public static const SCORE_COLOR:uint = 0x0;
		public static const SELECTED_COLOR:uint = 0xFF0000;
		
		public function GameComponent(_id:String)
		{
			super();
			
			m_id = _id;
			m_isSelected = false;
			if (getToolTipEvent()) {
				addEventListener(TouchEvent.TOUCH, onTouch);
			}
		}
		
		public function componentMoved(delta:Point):void
		{
			x += delta.x;
			y += delta.y;
			m_boundingBox.x += delta.x;
			m_boundingBox.y += delta.y;
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
			
			return color;
		}
		
		public function updateSize():void
		{
		}
		
		protected function get hasProp():Boolean
		{
			return m_props.hasProp(m_propertyMode);
		}
		
		public function setProps(props:PropDictionary):void
		{
			m_props = props.clone();
			m_isDirty = true;
		}
		
		public function setPropertyMode(prop:String):void
		{
			m_propertyMode = prop;
			m_isDirty = true;
		}
		
		protected function onTouch(event:TouchEvent):void
		{
			if (event.getTouches(this, TouchPhase.HOVER).length || event.getTouches(this, TouchPhase.MOVED).length) {
				var touch:Touch = event.getTouches(this, TouchPhase.HOVER).length ? event.getTouches(this, TouchPhase.HOVER)[0] : event.getTouches(this, TouchPhase.MOVED)[0];
				m_hoverPointGlobal = new Point(touch.globalX, touch.globalY);
				if (!m_hoverTimer) {
					m_hoverTimer = new Timer(Constants.TOOL_TIP_DELAY_SEC * 1000, 1);
					m_hoverTimer.addEventListener(TimerEvent.TIMER, onHoverDetected);
					m_hoverTimer.start();
				}
			} else {
				if (m_hoverTimer) {
					m_hoverTimer.removeEventListener(TimerEvent.TIMER, onHoverDetected);
					m_hoverTimer.stop();
					m_hoverTimer = null;
				}
				m_hoverPointGlobal = null;
				onHoverEnd();
			}
		}
		
		override public function dispose():void
		{
			super.dispose();
			removeEventListener(TouchEvent.TOUCH, onTouch);
		}
		
		protected function getToolTipEvent():ToolTipEvent
		{
			return null; // implement in subclasses if toolTip text is desired
		}
		
		protected function onHoverEnd():void
		{
			dispatchEvent(new ToolTipEvent(ToolTipEvent.CLEAR_TOOL_TIP, this));
		}
		
		protected function onHoverDetected(evt:TimerEvent):void
		{
			var toolTipEvt:ToolTipEvent = getToolTipEvent();
			if (toolTipEvt) {
				if (m_hoverPointGlobal) toolTipEvt.point = m_hoverPointGlobal.clone();
				dispatchEvent(toolTipEvt);
			}
		}
	}
}