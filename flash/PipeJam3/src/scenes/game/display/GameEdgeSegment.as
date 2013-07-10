 package scenes.game.display
{
	import assets.AssetInterface;
	import starling.display.BlendMode;
	import starling.display.Sprite;
	
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
		private var m_quad:Quad;
		
		public var m_endPt:Point;
		public var m_currentRect:Rectangle;
		public var updatePoint:Point;
		
		public var index:int;
		
		public var m_isInnerBoxSegment:Boolean;
		public var m_isLastSegment:Boolean;
		public var m_dir:String;
		
		public var currentTouch:Touch;
		public var currentDragSegment:Boolean = false;
		
		public var plug:Sprite;
		public var socket:Sprite;
		
		public function GameEdgeSegment(_dir:String, _isInnerBoxSegment:Boolean = false, _isLastSegment:Boolean = false, _isWide:Boolean = false, _isEditable:Boolean = false)
		{
			super("");
			m_isWide = _isWide;
			m_dir = _dir;
			m_isInnerBoxSegment = _isInnerBoxSegment;
			m_isLastSegment = _isLastSegment;
			
			m_isDirty = false;
			m_endPt = new Point(0,0);
			
			m_isEditable = _isEditable;
			
			addEventListener(Event.ENTER_FRAME, onEnterFrame);
			addEventListener(TouchEvent.TOUCH, onTouch);
			addEventListener(Event.ADDED_TO_STAGE, onAddedToStage);	
		}
		
		protected function onAddedToStage(event:starling.events.Event):void
		{
			this.blendMode = BlendMode.NONE;
			m_isDirty = true;
		}
		
		override public function dispose():void
		{
			//if we are the currentDragSegment we will be re-added, so keep original values
			if (m_disposed || currentDragSegment) {
				return;
			}
			
			if (hasEventListener(Event.ENTER_FRAME)) {
				removeEventListener(Event.ENTER_FRAME, onEnterFrame);
			}
			if (hasEventListener(TouchEvent.TOUCH)) {
				removeEventListener(TouchEvent.TOUCH, onTouch);
			}
			disposeChildren();
			super.dispose();
		}
		
		public var returnLocation:Point;
		private var isMoving:Boolean = false;
		private var hasMovedOutsideClickDist:Boolean = false;
		private var startingPoint:Point;
		private static const CLICK_DIST:Number = 0.2; //for extensions, register distance dragged
		public function onTouch(event:TouchEvent):void
		{
			var touches:Vector.<Touch> = event.touches;
			if (touches.length == 0) {
				return;
			}
			var touch:Touch = touches[0];
			if(event.getTouches(this, TouchPhase.MOVED).length)
			{
				if (touches.length == 1)
				{
					var touchXY:Point = new Point(touch.globalX, touch.globalY);
					touchXY = this.globalToLocal(touchXY);
					if(!isMoving) {
						startingPoint = touchXY;
						dispatchEvent(new Event(GameEdgeContainer.SAVE_CURRENT_LOCATION, true));
						isMoving = true;
						hasMovedOutsideClickDist = false;
						return;
					} else if (!hasMovedOutsideClickDist) {
						if (XMath.getDist(startingPoint, touchXY) > CLICK_DIST * Constants.GAME_SCALE) {
							hasMovedOutsideClickDist = true;
						} else {
							// Don't move if haven't moved outside CLICK_DIST
							return;
						}
					}
					
					var currentMoveLocation:Point = touch.getLocation(this);
					var previousLocation:Point = touch.getPreviousLocation(this);
					updatePoint = currentMoveLocation.subtract(previousLocation);	
					currentDragSegment = true;
					dispatchEvent(new Event(GameEdgeContainer.RUBBER_BAND_SEGMENT, true, this));
					currentDragSegment = false;
				}
			}
			else if(event.getTouches(this, TouchPhase.ENDED).length)
			{
				if (touches.length == 1)
				{
					m_isDirty = true;
					
					if(isMoving)
					{
						isMoving = false;
						if (m_isInnerBoxSegment) {
							if (!hasMovedOutsideClickDist) {
								// If haven't moved, register this as a click on the node itself
								dispatchEvent(new Event(GameEdgeContainer.INNER_SEGMENT_CLICKED, true));
							}
							dispatchEvent(new Event(GameEdgeContainer.RESTORE_CURRENT_LOCATION, true));
							dispatchEvent(new Event(GameEdgeContainer.HOVER_EVENT_OUT, true));
						}
					}
					else if (m_isInnerBoxSegment)
					{
						// If haven't moved, register this as a click on the node itself
						dispatchEvent(new Event(GameEdgeContainer.INNER_SEGMENT_CLICKED, true));
					}
				}
				
				if(touch.tapCount == 2)
				{
					this.currentTouch = touch;
					if(!m_isInnerBoxSegment)
						dispatchEvent(new Event(GameEdgeContainer.CREATE_JOINT, true, this));
				}
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
				isMoving = false;
				dispatchEvent(new Event(GameEdgeContainer.HOVER_EVENT_OUT, true));
			}
		}
		
		public function updateSegment(startPt:Point, endPt:Point):void
		{
			m_endPt = endPt.subtract(startPt);
			m_isDirty = true;
		}

		public function draw():void
		{
			var lineSize:Number = isWide() ? GameEdgeContainer.WIDE_WIDTH : GameEdgeContainer.NARROW_WIDTH;
			var color:int = getColor();
			
			if (m_quad) {
				m_quad.removeFromParent(true);
				m_quad = null;
			}
			
			var pctTextWidth:Number;
			var pctTextHeight:Number;
			if(m_endPt.x != 0 && m_endPt.y !=0)
			{
				throw new Error("Diagonal lines deprecated.");
			}
			else if(m_endPt.x != 0)
			{
				m_quad = new Quad(Math.abs(m_endPt.x), lineSize, color);
				if(isHoverOn)
				{
					m_quad.setVertexColor(0, color + 0x333333);
					m_quad.setVertexColor(1, color + 0x333333);
					m_quad.setVertexColor(2, color + 0x333333);
					m_quad.setVertexColor(3, color + 0x333333);
				}
				m_quad.rotation = (m_endPt.x > 0) ? 0 : Math.PI;
				m_quad.y = (m_endPt.x > 0) ? -lineSize/2.0 : lineSize/2.0;
				m_quad.x = 0;
			}
			else
			{
				m_quad = new Quad(lineSize, Math.abs(m_endPt.y), color);
				if(isHoverOn)
				{
					m_quad.setVertexColor(0, color + 0x333333);
					m_quad.setVertexColor(1, color + 0x333333);
					m_quad.setVertexColor(2, color + 0x333333);
					m_quad.setVertexColor(3, color + 0x333333);
				}
				m_quad.rotation = (m_endPt.y > 0) ? 0 : Math.PI;
				m_quad.x = (m_endPt.y > 0) ? -lineSize/2.0 : lineSize/2.0;
				m_quad.y = 0;
			}
			
			addChild(m_quad);
			if (socket) {
				addChild(socket);
			}
			if (plug) {
				addChild(plug);
			}
			if (plug || socket) {
				this.blendMode = BlendMode.NORMAL;
			} else {
				// Don't flatten with plug since it has transparent areas
				this.blendMode = BlendMode.NONE;
				flatten();
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
		
		// Make lines slightly darker to be more visible
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