package scenes.game.display
{
	import assets.AssetInterface;
	
	import display.NineSliceBatch;
	
	import flash.geom.Point;
	
	import scenes.BaseComponent;
	
	import starling.display.DisplayObject;
	import starling.display.Image;
	import starling.display.Quad;
	import starling.events.Event;
	import starling.events.Touch;
	import starling.events.TouchEvent;
	import starling.events.TouchPhase;
	import starling.text.TextField;
	import starling.textures.Texture;
	import starling.textures.TextureAtlas;
	
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
		private var m_quad:Quad;
		
		static public var STANDARD_JOINT:int = 0;
		static public var MARKER_JOINT:int = 1;
		static public var END_JOINT:int = 2;
		static public var INNER_CIRCLE_JOINT:int = 3;
		
		public function GameEdgeJoint(jointType:int = 0, _isWide:Boolean = false, _isEditable:Boolean = false, _draggable:Boolean = true)
		{
			super("");
			draggable = _draggable;
			m_isWide = _isWide;
			m_jointType = jointType;
			m_originalPoint = new Point;
			m_isDirty = true;
			
			m_isEditable = _isEditable;
			
			addEventListener(Event.ENTER_FRAME, onEnterFrame);
			if (jointType == INNER_CIRCLE_JOINT) {
				touchable = false;
			} else {
				addEventListener(TouchEvent.TOUCH, onTouch);
			}
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
				m_quad = null;
			}
			super.dispose();
		}
		
		private function onTouch(event:TouchEvent):void
		{
			if (!draggable) return;
			
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
			
			if (m_jointType == INNER_CIRCLE_JOINT) {
				lineSize *= 1.5;
			}
			
			if (m_quad) {
				m_quad.removeFromParent(true);
				m_quad = null;
			}
			
			var isRound:Boolean = (m_jointType == INNER_CIRCLE_JOINT);

			var assetName:String;
			
			if (isRound) {
				if(m_isEditable == true)
				{
					if (m_isWide == true)
						assetName = AssetInterface.PipeJamSubTexture_BlueDarkStart;
					else
						assetName = AssetInterface.PipeJamSubTexture_BlueLightStart;
				}
				else //not adjustable
				{
					if(m_isWide == true)
						assetName = AssetInterface.PipeJamSubTexture_GrayDarkStart;
					else
						assetName = AssetInterface.PipeJamSubTexture_GrayLightStart;
				}
			} else {
				if(m_isEditable == true)
				{
					if (m_isWide == true)
						assetName = AssetInterface.PipeJamSubTexture_BlueDarkJoint;
					else
						assetName = AssetInterface.PipeJamSubTexture_BlueLightJoint;
				}
				else //not adjustable
				{
					if(m_isWide == true)
						assetName = AssetInterface.PipeJamSubTexture_GrayDarkJoint;
					else
						assetName = AssetInterface.PipeJamSubTexture_GrayLightJoint;
				}
			}
			
			var atlas:TextureAtlas = AssetInterface.getTextureAtlas("Game", "PipeJamSpriteSheetPNG", "PipeJamSpriteSheetXML");
			var startTexture:Texture = atlas.getTexture(assetName);
			m_quad = new Image(startTexture);
			m_quad.width = m_quad.height = lineSize;
			
			if(isHoverOn)
			{
				m_quad.color = 0xeeeeee;
			}
			else
			{
				m_quad.color = 0xcccccc;
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