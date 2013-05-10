 package scenes.game.display
{
	import assets.AssetInterface;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import starling.display.DisplayObject;
	import starling.display.Image;
	import starling.display.Quad;
	import starling.events.Event;
	import starling.events.Touch;
	import starling.events.TouchEvent;
	import starling.events.TouchPhase;
	import starling.textures.Texture;
	import utils.XMath;
	import utils.XSprite;
	
	public class GameEdgeSegment extends GameComponent
	{
		private static const ARROW_SCALEX:Number = 0.2;
		private static const MIN_ARROW_SIZE:Number = 10;
		
		private var m_quad:Quad;
		private var m_arrowImg:Image;
		protected var m_parentEdge:GameEdgeContainer;
		public var m_endPt:Point;
		public var m_currentRect:Rectangle;
		
		public var index:int;
		
		public var m_isNodeExtensionSegment:Boolean;
		public var m_isLastSegment:Boolean;
		
		public var currentTouch:Touch;
		public var currentDragSegment:Boolean = false;
		
		private static const ARROW_TEXT:Texture = AssetInterface.getTexture("Game", "ChevronClass");
		{
			ARROW_TEXT.repeat = true;
		}
		
		public function GameEdgeSegment(_parentEdge:GameEdgeContainer, _fromNode:GameNode, _toNode:GameNode, _isNodeExtensionSegment:Boolean = false, _isLastSegment:Boolean = false)
		{
			super();
			
			m_parentEdge = _parentEdge;
			m_fromComponent = _fromNode;
			m_toComponent = _toNode;
			
			m_isNodeExtensionSegment = _isNodeExtensionSegment;
			m_isLastSegment = _isLastSegment;
			m_isDirty = false;
			m_endPt = new Point(0,0);
			m_currentRect = new Rectangle(0, 0, 0, 0);
			addEventListener(Event.ENTER_FRAME, onEnterFrame);
			addEventListener(TouchEvent.TOUCH, onTouch);
		}
		
		override public function dispose():void
		{
			//if we are the currentDragSegment we will be re-added, so keep original values
			if (m_disposed || currentDragSegment) {
				return;
			}
			m_parentEdge = null;
			m_fromComponent = null;
			m_toComponent = null;
			if (hasEventListener(Event.ENTER_FRAME)) {
				removeEventListener(Event.ENTER_FRAME, onEnterFrame);
			}
			if (hasEventListener(TouchEvent.TOUCH)) {
				removeEventListener(TouchEvent.TOUCH, onTouch);
			}
			disposeChildren();
			super.dispose();
		}
		
		private var isMoving:Boolean = false;
		private var isHover:Boolean = false;
		private function onTouch(event:TouchEvent):void
		{
			if(m_isNodeExtensionSegment)
				return;
			
			var touches:Vector.<Touch> = event.touches;
			if(event.getTouches(this, TouchPhase.ENDED).length)
			{
				if (touches.length == 1)
				{
					m_isDirty = true;
					isMoving = false;
					isHover = false;
				}

				var touch:Touch = touches[0];
				if(touch.tapCount == 2)
				{
					this.currentTouch = touch;
					if(!this.m_isNodeExtensionSegment)
						dispatchEvent(new Event(GameEdgeContainer.CREATE_JOINT, true, this));
				}
			}
			
			if(event.getTouches(this, TouchPhase.HOVER).length)
			{
				if (touches.length == 1 && event.shiftKey && !m_parentEdge.m_originalEdge)
				{
					m_isDirty = true;
					isHover = true;
				}
			}
			else
			{
				m_isDirty = true;
				isMoving = false;
				isHover = false;
			}
			
			if(event.shiftKey && event.getTouches(this, TouchPhase.MOVED).length){
				if (touches.length == 1)
				{
					if(!isMoving)
						isMoving = true;
					
					var currentMoveLocation:Point = touches[0].getLocation(this);
					var previousLocation:Point = touches[0].getPreviousLocation(this);
					var updatePoint:Point = currentMoveLocation.subtract(previousLocation);	
					currentDragSegment = true;
					m_parentEdge.rubberBandEdgeSegment(updatePoint, this);
					currentDragSegment = false;

					
				}
			}
		}
		
		public function updateSegment(startPt:Point, endPt:Point):void
		{
			m_endPt = endPt.subtract(startPt);
			var lineSize:Number = isWide() ? GameEdgeContainer.WIDE_WIDTH : GameEdgeContainer.NARROW_WIDTH;
			if(m_endPt.x != 0)
			{
				m_currentRect.width = m_endPt.x;
				m_currentRect.height = lineSize;
			}
			else
			{
				m_currentRect.width = lineSize;
				m_currentRect.height = m_endPt.y;				
			}
			m_isDirty = true;
		}
		
		public function draw():void
		{
			var color:int = getColor();
			var lineSize:Number = isWide() ? GameEdgeContainer.WIDE_WIDTH : GameEdgeContainer.NARROW_WIDTH;
			
			if (m_arrowImg) {
				m_arrowImg.removeFromParent(true);
				m_arrowImg = null;
			}
			if (m_quad) {
				m_quad.removeFromParent(true);
				m_quad = null;
			}
			disposeChildren();
			
			var pctTextWidth:Number;
			var pctTextHeight:Number;
			if(m_endPt.x != 0 && m_endPt.y !=0)
			{
				var startPt:Point = new Point(0,0);
				m_quad = drawDiagonalLine(startPt, m_endPt, lineSize, color);
				m_quad.x = -lineSize/2.0;
				m_quad.y = 0;
			}
			else if(m_endPt.x != 0)
			{
				if(isHover)
				{
					m_quad = new Quad(Math.abs(m_endPt.x), lineSize + 1.0, 0xeeeeee);
					m_quad.rotation = (m_endPt.x > 0) ? 0 : Math.PI;
					m_quad.y = (m_endPt.x > 0) ? -(lineSize+1.0)/2.0 : (lineSize+1.0)/2.0;
					m_quad.x = 0;
					addChild(m_quad);
				}
				m_quad = new Quad(Math.abs(m_endPt.x), lineSize, color);
				m_quad.rotation = (m_endPt.x > 0) ? 0 : Math.PI;
				m_quad.y = (m_endPt.x > 0) ? -lineSize/2.0 : lineSize/2.0;
				m_quad.x = 0;
				
				// Create/add arrows if segment is long enough to display them
				if (Math.abs(m_endPt.x) > MIN_ARROW_SIZE) {
					m_arrowImg = new Image(ARROW_TEXT);
					pctTextWidth = Math.abs(m_endPt.x) / (ARROW_SCALEX * m_arrowImg.width);
					pctTextHeight = lineSize / (1.5 * GameEdgeContainer.WIDE_WIDTH);
					m_arrowImg.width = Math.abs(m_endPt.x);
					m_arrowImg.height = lineSize;
					
					m_arrowImg.setTexCoords(0, new Point(0, 0.5 - pctTextHeight/2.0)); //topleft
					m_arrowImg.setTexCoords(1, new Point(pctTextWidth, 0.5 - pctTextHeight/2.0)); //topright
					m_arrowImg.setTexCoords(2, new Point(0, 0.5 + pctTextHeight/2.0)); //bottomleft
					m_arrowImg.setTexCoords(3, new Point(pctTextWidth, 0.5 + pctTextHeight / 2.0)); //bottomright
					
					m_arrowImg.rotation = (m_endPt.x > 0) ? 0 : Math.PI;
					m_arrowImg.y = (m_endPt.x > 0) ? -lineSize/2.0 : lineSize/2.0;
					m_arrowImg.x = 0;
				}
			}
			else
			{
				if(isHover)
				{
					m_quad = new Quad(lineSize + 1.0, Math.abs(m_endPt.y), 0xeeeeee);
					m_quad.rotation = (m_endPt.y > 0) ? 0 : Math.PI;
					m_quad.y = -0.5;
					m_quad.x = (m_endPt.y > 0) ? -(lineSize+1.0)/2.0 : (lineSize+1.0)/2.0;
					addChild(m_quad);
				}
				m_quad = new Quad(lineSize, Math.abs(m_endPt.y), color);
				m_quad.rotation = (m_endPt.y > 0) ? 0 : Math.PI;
				m_quad.x = (m_endPt.y > 0) ? -lineSize/2.0 : lineSize/2.0;
				m_quad.y = 0;
				
				// Create/add arrows if segment is long enough to display them
				if (Math.abs(m_endPt.y) > MIN_ARROW_SIZE) {
					m_arrowImg = new Image(ARROW_TEXT);
					pctTextWidth = Math.abs(m_endPt.y) / (ARROW_SCALEX * m_arrowImg.width);
					pctTextHeight = lineSize / (1.5 * GameEdgeContainer.WIDE_WIDTH);
					m_arrowImg.width = Math.abs(m_endPt.y);
					m_arrowImg.height = lineSize;
					
					m_arrowImg.setTexCoords(0, new Point(0, 0.5 - pctTextHeight/2.0)); //topleft
					m_arrowImg.setTexCoords(1, new Point(pctTextWidth, 0.5 - pctTextHeight/2.0)); //topright
					m_arrowImg.setTexCoords(2, new Point(0, 0.5 + pctTextHeight/2.0)); //bottomleft
					m_arrowImg.setTexCoords(3, new Point(pctTextWidth, 0.5 + pctTextHeight / 2.0)); //bottomright
					
					m_arrowImg.rotation = (m_endPt.y > 0) ? Math.PI / 2 : -Math.PI / 2;
					m_arrowImg.x = (m_endPt.y > 0) ? lineSize/2.0 : -lineSize/2.0;
					m_arrowImg.y = 0;
				}
			}
			
			addChild(m_quad);
			if (m_arrowImg) {
				addChild(m_arrowImg);
			}
			
		}
		
		private static function fillUV(tx:Number, ty:Number, rot:Number, tex:Texture):Matrix
		{
			var ret:Matrix = new Matrix();
			ret.rotate(XMath.degreesToRadians(rot));
			ret.translate(tx, ty);
			ret.scale(1.0 / tex.width, 1.0 / tex.height);
			return ret;
		}
		
		public function drawDiagonalLine(p1:Point, p2:Point, width:Number=1, color:uint=0x000000):Quad
		{
			
			//a^2 + b^2 = c^2
			var a:Number = (p2.x - p1.x) * (p2.x - p1.x);
			var b:Number = (p2.y - p1.y) * (p2.y - p1.y);
			var hyp:Number = Math.sqrt(a +b);
			
			var q:Quad = new Quad(hyp, width);
			
			q.setVertexColor(0, color);
			q.setVertexColor(1, color);
			q.setVertexColor(2, color);
			q.setVertexColor(3, color);
			
			q.x = p1.x;
			q.y = p1.y;
			
			//get theta
			//Sin(x) = opp/hyp
			var theta:Number; // radians
			
			theta = Math.asin( (p2.y-p1.y) / hyp );  // radians
			
			// degrees:90 radians:1.5707963267948966
			// degrees:180 radians:3.141592653589793
			
			var dX:Number = p1.x - p2.x
			var dY:Number = p1.y - p2.y
			
			if(dX>0 && dY<0) // Q2
				theta = (Math.PI/2) + ((Math.PI/2) - theta);
			else if(dX>0 && dY>0) // Q3
				theta = -Math.PI - theta;
			
			q.rotation = theta;
			
			return q;
		}
		
		override public function isWide():Boolean
		{
			if(m_isLastSegment)
				return m_toComponent.isWide();
			else
				return m_fromComponent.isWide();
		}
		
		override public function getColor():int
		{
			if (m_parentEdge.hasError()) {
				return ERROR_COLOR;
			}
			if (m_isLastSegment) {
				return m_toComponent.getColor();
			} else {
				return m_fromComponent.getColor();
			}
		}
		
		public function onEnterFrame(event:Event):void
		{
			if(m_isDirty)
			{
				draw();
				m_isDirty = false;
			}
		}
	}
}