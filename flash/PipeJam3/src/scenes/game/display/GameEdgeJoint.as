package scenes.game.display
{
	import display.RoundedRect;
	
	import flash.geom.Point;
	
	import scenes.BaseComponent;
	
	import starling.display.DisplayObject;
	import starling.display.Quad;
	import starling.events.Event;
	import starling.events.Touch;
	import starling.events.TouchEvent;
	import starling.events.TouchPhase;
	import starling.text.TextField;
	
	import utils.XSprite;

	public class GameEdgeJoint extends GameComponent
	{		
		public var m_jointType:int;
		
		//used when moving connection points to allow for snapping back to start, or swapping positions with other connections
		public var m_originalPoint:Point;
		public var m_position:int;
		
		protected var m_parentEdge:GameEdgeContainer;
		public var m_closestWall:int = 0;
		
		public var count:int = 0;
		private var m_quad:DisplayObject;
		private var m_hoverQuad:DisplayObject;
		
		static public var STANDARD_JOINT:int = 0;
		static public var MARKER_JOINT:int = 1;
		static public var END_JOINT:int = 2;
		static public var INNER_CIRCLE_JOINT:int = 3;
		
		public function GameEdgeJoint(jointType:int = 0, _isWide:Boolean = false)
		{
			super("");
			m_isWide = _isWide;
			m_jointType = jointType;
			m_originalPoint = new Point;
			m_isDirty = true;
			
			//default to true
			m_isEditable = true;
			
			addEventListener(Event.ENTER_FRAME, onEnterFrame);
			addEventListener(TouchEvent.TOUCH, onTouch);
		}
		
		override public function dispose():void
		{
			if (m_disposed) {
				return;
			}
			if (hasEventListener(Event.ENTER_FRAME)) {
				removeEventListener(Event.ENTER_FRAME, onEnterFrame);
			}

			disposeChildren();
			if (m_quad) {
				m_quad.removeFromParent(true);
			}
			if (m_hoverQuad) {
				m_hoverQuad.removeFromParent(true);
			}
			super.dispose();
		}
		
		private function onTouch(event:TouchEvent):void
		{
			var touches:Vector.<Touch> = event.touches;
			
			if(event.getTouches(this, TouchPhase.MOVED).length)
			{

			}
			else if(event.getTouches(this, TouchPhase.ENDED).length)
			{

			}
			else if(event.getTouches(this, TouchPhase.HOVER).length)
			{
				if (touches.length == 1)
				{
					m_isDirty = true;
					dispatchEvent(new Event(GameEdgeContainer.HOVER_EVENT_OVER, true));
				}
			}
			else if(event.getTouches(this, TouchPhase.BEGAN).length)
			{
			}
			else
			{
				m_isDirty = true;
				dispatchEvent(new Event(GameEdgeContainer.HOVER_EVENT_OUT, true));
			}
		}
		
		protected function sortOutgoingXPositions(x:GameEdgeContainer, y:GameEdgeContainer):Number
		{
			var pt1:Point = x.localToGlobal(new Point(x.m_startJoint.x, x.m_startJoint.y));
			var pt2:Point = y.localToGlobal(new Point(y.m_startJoint.x, y.m_startJoint.y));
			//	trace(pt1.x + " " +pt2.x);
			if(pt1.x < pt2.x)
				return -1;
			else
				return 1;
		}
			
		protected function sortIncomingXPositions(x:GameEdgeContainer, y:GameEdgeContainer):Number
		{
			var pt1:Point = x.localToGlobal(new Point(x.m_endJoint.x, x.m_endJoint.y));
			var pt2:Point = y.localToGlobal(new Point(y.m_endJoint.x, y.m_endJoint.y));
			trace(pt1.x + " " +pt2.x);
			if(pt1.x < pt2.x)
				return -1;
			else
				return 1;
		}
		
		public function draw():void
		{
			var lineSize:Number = m_isWide ? GameEdgeContainer.WIDE_WIDTH : GameEdgeContainer.NARROW_WIDTH;
			var color:int = getColor();
			var err:Boolean = hasError();
			
			var roundRadius:Number;
			if (m_jointType == INNER_CIRCLE_JOINT) {
				lineSize *= 1.5;
				roundRadius = lineSize / 3.0;
			} else if (err) {
				lineSize = GameEdgeContainer.ERROR_WIDTH;
				roundRadius = lineSize / 2.0;
			}
			
			if (m_quad) {
				m_quad.removeFromParent(true);
			}
			
			if (m_hoverQuad) {
				m_hoverQuad.removeFromParent(true);
			}
			
			var isRound:Boolean = ((m_jointType == INNER_CIRCLE_JOINT) || err);
			
			
			if (isRound) {
				m_quad = new RoundedRect(lineSize, lineSize, roundRadius, color);
			} else {
				m_quad = new Quad(lineSize, lineSize, color);
				if(isHoverOn)
				{
					(m_quad as Quad).setVertexColor(0, color + 0x333333);
					(m_quad as Quad).setVertexColor(1, color + 0x333333);
					(m_quad as Quad).setVertexColor(2, color + 0x333333);
					(m_quad as Quad).setVertexColor(3, color + 0x333333);
				}
			}
			
			m_quad.x = -lineSize/2;
			m_quad.y = -lineSize/2;
			addChild(m_quad);

//			var number:String = ""+count;
//			var txt:TextField = new TextField(10, 10, number, "Veranda", 6,0x00ff00); 
//			txt.y = 1;
//			txt.x = 1;
//			m_shape.addChild(txt);
//			addChild(m_shape);
		}
		
		override public function hasError():Boolean
		{
			return m_hasError;
		}
		
		public function onEnterFrame(event:Event):void
		{
			if(m_isDirty)
			{
				draw();
				m_isDirty = false;
			}
		}
		
		// Make edge joints slightly darker to be more visible
		override public function getColor():int
		{
			var color:int = super.getColor();
			var red:int = XSprite.extractRed(color);
			var green:int = XSprite.extractGreen(color);
			var blue:int = XSprite.extractBlue(color);
			return  ( ( Math.round(red * 0.8) << 16 ) | ( Math.round(green * 0.8) << 8 ) | Math.round(blue * 0.8) );
		}
	}
}