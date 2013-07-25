package display
{
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.ui.Mouse;
	import flash.ui.MouseCursor;
	
	import starling.display.DisplayObject;
	import starling.display.DisplayObjectContainer;
	import starling.display.Sprite;
	import starling.events.Event;
	import starling.events.Touch;
	import starling.events.TouchEvent;
	import starling.events.TouchPhase;
	
	import utils.XSprite;

	[Event(name="triggered", type="starling.events.Event")]
	[Event(name="hoverOver", type="starling.events.Event")]
	
	public class BasicButton extends DisplayObjectContainer
	{
		private static const DEBUG_HIT:Boolean = false;
		
		public static const HOVER_OVER:String = "hoverOver";
		
		protected var m_up:DisplayObject;
		protected var m_over:DisplayObject;
		protected var m_down:DisplayObject;
		private var m_current:DisplayObject;

		private var m_hitSubRect:Rectangle;

		private var m_enabled:Boolean;
		private var m_useHandCursor:Boolean;

		private var m_data:Object;
		
		public function BasicButton(up:DisplayObject, over:DisplayObject, down:DisplayObject, hitSubRect:Rectangle = null)
		{
			m_enabled = true;
			m_useHandCursor = false;
			
			m_hitSubRect = hitSubRect;
			
			var container:Sprite = new Sprite();
			addChild(container);
			
			m_up = up;
			m_up.visible = false;
			container.addChild(m_up);
			
			m_over = over;
			m_over.visible = false;
			container.addChild(m_over);
			
			m_down = down;
			m_down.visible = false;
			container.addChild(m_down);
			
			m_current = m_up;
			m_current.visible = true;
			
			addEventListener(TouchEvent.TOUCH, onTouch);
			
			if (DEBUG_HIT) {
				var hit:DisplayObject;
				if (m_hitSubRect) {
					hit = XSprite.createPolyRect(m_hitSubRect.width, m_hitSubRect.height, 0xFF00FF, 0, 0.25);
					hit.x = m_hitSubRect.x;
					hit.y = m_hitSubRect.y;
				} else {
					hit = XSprite.createPolyRect(width, height, 0xFF00FF, 0, 0.25);
				}
				container.addChild(hit);
			}
		}

		public override function dispose():void
		{
			removeEventListener(TouchEvent.TOUCH, onTouch);
			
			super.dispose();
		}
		
		public function get enabled():Boolean
		{
			return m_enabled;
		}
		
		public function set enabled(value:Boolean):void
		{
			if (m_enabled != value) {
				m_enabled = value;
				toState(m_up);
			}
		}
		
		public function set data(value:Object):void
		{
			m_data = value;
		}
		
		public override function hitTest(localPoint:Point, forTouch:Boolean=false):DisplayObject
		{
			var superHit:DisplayObject = super.hitTest(localPoint, forTouch);
			
			if (!m_hitSubRect) {
				return superHit;
			}
			
			if (superHit == null) {
				return null;
			}
			
			return m_hitSubRect.containsPoint(localPoint) ? this : null;
		}
		
		private function onTouch(event:TouchEvent):void
		{
			Mouse.cursor = (m_useHandCursor && m_enabled && event.interactsWith(this)) ? MouseCursor.BUTTON : MouseCursor.AUTO;
			
			var touch:Touch = event.getTouch(this);
			if (!m_enabled || touch == null) {
				toState(m_up);
				return;
			}
			
			if (touch.phase == TouchPhase.HOVER) {
				if (m_current != m_over) {
					toState(m_over);
					dispatchEventWith(HOVER_OVER, true, dispatchEventWith);
				}
			} else if (touch.phase == TouchPhase.MOVED) {
				if (hitTest(touch.getLocation(this))) {
					toState(m_down);
				} else {
					toState(m_up);
				}
			} else if (touch.phase == TouchPhase.BEGAN) {
				toState(m_down);
			} else if (touch.phase == TouchPhase.ENDED) {
				if (m_current == m_down) {
					if (hitTest(touch.getLocation(this))) {
						toState(m_over);
					} else {
						toState(m_up);
					}
					dispatchEventWith(Event.TRIGGERED, true, m_data);
				}
			}
		}
		
		public function toState(state:DisplayObject):void
		{
			if (m_current != state) {
				m_current.visible = false;
				m_current = state;
				m_current.visible = true;
			}
		}
	}
}
