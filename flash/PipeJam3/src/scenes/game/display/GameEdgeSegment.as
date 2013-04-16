package scenes.game.display
{
	import assets.AssetInterface;
	import flash.geom.Point;
	import starling.display.Image;
	import starling.textures.Texture;
	import utilities.XSprite;
	
	import scenes.BaseComponent;
	
	import starling.display.Quad;
	import starling.display.Shape;
	import starling.events.Event;
	import starling.events.Touch;
	import starling.events.TouchEvent;
	import starling.events.TouchPhase;


	public class GameEdgeSegment extends GameComponent
	{
		private static const ARROW_SPACING:Number = 5.0;
		private static const ARROW_WIDTH:Number = 2.0;
		
		private var m_quad:Quad;
		protected var m_parentEdge:GameEdgeContainer;
		public var m_endPt:Point;
		
		public var index:int;
		
		public var m_isNodeExtensionSegment:Boolean;
		public var m_isLastSegment:Boolean;
		
		public var currentTouch:Touch;
		private var m_arrows:Vector.<Image> = new Vector.<Image>();
		
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
			addEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
			addEventListener(Event.REMOVED_FROM_STAGE, onRemovedFromStage);	
		}
		
		public function onAddedToStage(event:starling.events.Event):void
		{
			addEventListener(Event.ENTER_FRAME, onEnterFrame);
			addEventListener(TouchEvent.TOUCH, onTouch);
		}
		
		private function onRemovedFromStage():void
		{
			this.removeChildren(0, -1, true);
			removeEventListener(Event.ENTER_FRAME, onEnterFrame);
			removeEventListener(TouchEvent.TOUCH, onTouch);
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
					m_parentEdge.rubberBandEdgeSegment(updatePoint, this);

					
				}
			}
		}
		
		public function updateSegment(startPt:Point, endPt:Point):void
		{
			m_endPt = endPt.subtract(startPt);
			
			m_isDirty = true;
		}
		
		public function draw():void
		{
			// Remove/dispose of arrows
			for each (var arr:Image in m_arrows) {
				if (arr.parent) {
					arr.parent.removeChild(arr);
					arr = null;
				}
			}
			m_arrows = new Vector.<Image>();
			
			var color:int = getColor();
			var lineSize:Number = isWide() ? GameEdgeContainer.WIDE_WIDTH : GameEdgeContainer.NARROW_WIDTH;
			
			removeChildren();
			
			if(m_endPt.x != 0 && m_endPt.y !=0)
			{
				var startPt:Point = new Point(0,0);
				m_quad = drawDiagonalLine(startPt, m_endPt, lineSize, color);
				m_quad.x = -lineSize/2;
				m_quad.y = 0;
			}
			else if(m_endPt.x != 0)
			{
				if(isHover)
				{
					m_quad = new Quad(m_endPt.x, lineSize+1, 0xeeeeee);
					m_quad.y = -lineSize/2 - 0.5;
					m_quad.x = 0;
					addChild(m_quad);
				}
				m_quad = new Quad(m_endPt.x, lineSize, color);
				m_quad.y = -lineSize/2;
				m_quad.x = 0;
			}
			else
			{
				if(isHover)
				{
					m_quad = new Quad(lineSize+1, m_endPt.y, 0xeeeeee);
					m_quad.y = -lineSize/2;
					m_quad.x =  -1;
					addChild(m_quad);
				}
				m_quad = new Quad(lineSize, m_endPt.y, color);
				m_quad.x = -lineSize/2;
				m_quad.y = 0;
			}
			
			addChild(m_quad);
			
			// Create/add arrows
			var numArr:int = Math.floor(m_endPt.length / ARROW_SPACING);
			if (numArr > 0) {
				var currX:Number, currY:Number, dX:Number, dY:Number, myAng:Number;
				dX = m_endPt.x / m_endPt.length;
				dY = m_endPt.y / m_endPt.length;
				myAng = Math.atan2(dY, dX);
				var arrHeight:Number = GameEdgeContainer.WIDE_WIDTH;
				currX = (dX * ARROW_SPACING) / 2.0 + arrHeight * Math.sin(myAng) / 2.0;
				currY = (dY * ARROW_SPACING) / 2.0 - arrHeight * Math.cos(myAng) / 2.0;
				for (var i:int = 0; i < numArr; i++) {
					var myText:Texture;
					if (m_parentEdge.hasError()) {
						myText = AssetInterface.getTextureColorAll("Game", "ChevronClass", 0xffff0000);
					} else {
						myText  = AssetInterface.getTexture("Game", "ChevronClass");
					}
					var myArr:Image = new Image(myText);
					myArr.touchable = false;
					myArr.width = ARROW_WIDTH;
					myArr.height = arrHeight + 1.0;
					XSprite.setPivotCenter(myArr);
					if (isHover) {
						trace("dX/dY/ang:" + dX + " " + dY + " " + (Math.atan2(dY, dX) * 180 / Math.PI));
						trace("endPt:" + m_endPt.toString());
					}
					myArr.x = currX + this.x;
					myArr.y = currY + this.y;
					myArr.rotation = myAng;
					currX += ARROW_SPACING * dX;
					currY += ARROW_SPACING * dY;
					m_parentEdge.addChild(myArr);
					m_arrows.push(myArr);
				}
			}
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
			if(m_isLastSegment)
				return m_toComponent.getColor();
			else
				return m_fromComponent.getColor();
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