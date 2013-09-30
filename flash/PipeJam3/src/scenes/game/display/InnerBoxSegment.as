package scenes.game.display
{
	import assets.AssetInterface;
	import events.ToolTipEvent;
	import flash.geom.Point;
	import scenes.game.display.GameComponent;
	import scenes.game.display.GameEdgeContainer;
	import scenes.game.display.GameEdgeJoint;
	import scenes.game.display.GameEdgeSegment;
	import starling.display.Image;
	import starling.display.Quad;
	import starling.display.Sprite;
	import starling.events.EnterFrameEvent;
	import starling.events.Event;
	import starling.textures.Texture;
	import starling.textures.TextureAtlas;

	public class InnerBoxSegment extends GameComponent
	{
		public static const PLUG_HEIGHT:Number = 0.44 * Constants.GAME_SCALE;
		public static const SOCKET_HEIGHT:Number = 0.17 * Constants.GAME_SCALE;
		private static const BORDER_SIZE:Number = 0.02 * Constants.GAME_SCALE;
		
		private static var id:int = 0;
		
		public var innerCircleJoint:GameEdgeJoint;
		public var edgeSegment:GameEdgeSegment;
		public var edgeSegmentOutline:Quad;
		public var interiorPt:Point;
		private var m_dir:String;
		private var m_height:Number;
		private var m_borderIsWide:Boolean;
		public var isEnd:Boolean;
		private var m_plugIsWide:Boolean;
		private var m_plugIsEditable:Boolean;
		private var m_socketContainer:Sprite;
		private var m_plugContainer:Sprite;
		private var m_socketAssetName:String = "";
		private var m_plugAssetName:String = "";
		private var m_socket:Image;
		private var m_plug:Image;
		
		public function InnerBoxSegment(_interiorPt:Point, height:Number, dir:String, isWide:Boolean, borderIsWide:Boolean, isEditable:Boolean, createInnerCircle:Boolean, _isEnd:Boolean, plugIsWide:Boolean, plugIsEditable:Boolean, _draggable:Boolean)
		{
			super("IS" + id++);
			draggable = _draggable;
			interiorPt = _interiorPt;
			m_height = height;
			m_dir = dir;
			m_isWide = isWide;
			m_borderIsWide = borderIsWide;
			m_isEditable = isEditable;
			isEnd = _isEnd;
			m_plugIsWide = plugIsWide;
			m_plugIsEditable = plugIsEditable;
			edgeSegmentOutline = new Quad(getBorderWidth(), m_height, getBorderColor());
			edgeSegment = new GameEdgeSegment(m_dir, true, false, false, m_isWide, m_isEditable, draggable);
			edgeSegment.updateSegment(new Point(0, 0), new Point(0, m_height));
			if (createInnerCircle) {
				innerCircleJoint = new GameEdgeJoint(GameEdgeJoint.INNER_CIRCLE_JOINT, m_isWide, m_isEditable, draggable);
			}
			m_socketContainer = new Sprite();
			m_plugContainer = new Sprite();
			
			draw();
			if(edgeSegmentOutline)
				addChild(edgeSegmentOutline);
			addChild(edgeSegment);
			if (innerCircleJoint) {
				addChild(innerCircleJoint);
			}
			edgeSegment.socket = m_socketContainer;
			edgeSegment.plug = m_plugContainer;
			edgeSegment.m_isDirty = true;
			
			m_isDirty = false;
			addEventListener(EnterFrameEvent.ENTER_FRAME, onEnterFrame);
		}
		
		public function getPlugYOffset():Number
		{
			if (hasError()) {
				return PLUG_HEIGHT;
			} else if (isEnd) {
				return (PLUG_HEIGHT - SOCKET_HEIGHT + 0.01 * Constants.GAME_SCALE);
			} else {
				return 0;
			}
		}
		
		public function updatePlug():void
		{
			if (!(isEnd || hasError())) {
				// Only show plugs/sockets for end with no extension or errors (two prong into one prong)
				if (m_plug) {
					m_plug.removeFromParent(true);
				}
				m_plug = null;
				m_plugAssetName = "";
				return;
			}
			var assetName:String;
			if (m_plugIsEditable) {
				if (m_plugIsWide) {
					assetName = AssetInterface.PipeJamSubTexture_BlueDarkPlug;
				} else {
					assetName = AssetInterface.PipeJamSubTexture_BlueLightPlug;
				}
			} else {
				if (m_plugIsWide) {
					assetName = AssetInterface.PipeJamSubTexture_GrayDarkPlug;
				} else {
					assetName = AssetInterface.PipeJamSubTexture_GrayLightPlug;
				}
			}
			if (assetName == m_plugAssetName) {
				// No need to change image
				return;
			}
			if (m_plug) {
				m_plug.removeFromParent(true);
			}
			m_plugAssetName = assetName;
			var atlas:TextureAtlas = AssetInterface.getTextureAtlas("Game", "PipeJamSpriteSheetPNG", "PipeJamSpriteSheetXML");
			var plugTexture:Texture = atlas.getTexture(m_plugAssetName);
			m_plug = new Image(plugTexture);
			var scale:Number = PLUG_HEIGHT / m_plug.height;
			m_plug.width *= scale;
			m_plug.height *= scale;
			m_plugContainer.addChild(m_plug);
		}
		
		public function updateSocket():void
		{
			if (!(isEnd || hasError())) {
				// Only show plugs/sockets for end with no extension or errors (two prong into one prong)
				if (m_socket) {
					m_socket.removeFromParent(true);
				}
				m_socket = null;
				m_socketAssetName = "";
				return;
			}
			var assetName:String;
			if (m_isEditable) {
				if (m_borderIsWide) {
					assetName = AssetInterface.PipeJamSubTexture_BlueDarkEnd;
				} else {
					assetName = AssetInterface.PipeJamSubTexture_BlueLightEnd;
				}
			} else {
				if (m_borderIsWide) {
					assetName = AssetInterface.PipeJamSubTexture_GrayDarkEnd;
				} else {
					assetName = AssetInterface.PipeJamSubTexture_GrayLightEnd;
				}
			}
			if (assetName == m_socketAssetName) {
				// No need to change image
				return;
			}
			if (m_socket) {
				m_socket.removeFromParent(true);
			}
			m_socketAssetName = assetName;
			var atlas:TextureAtlas = AssetInterface.getTextureAtlas("Game", "PipeJamSpriteSheetPNG", "PipeJamSpriteSheetXML");
			var socketTexture:Texture = atlas.getTexture(m_socketAssetName);
			m_socket = new Image(socketTexture);
			m_socket.touchable = false;
			var scale:Number = SOCKET_HEIGHT / m_socket.height;
			m_socket.width *= scale;
			m_socket.height *= scale;
			m_socketContainer.addChild(m_socket);
		}
		
		private static function getWidth(_isWide:Boolean):Number
		{
			return _isWide ? GameEdgeContainer.WIDE_WIDTH : GameEdgeContainer.NARROW_WIDTH;
		}
		
		private function getBorderWidth():Number
		{
			// Make pinch points stand out with thicker border
			if (!m_isEditable && !m_borderIsWide) return 4 * BORDER_SIZE + GameEdgeContainer.NARROW_WIDTH;
			return 2 * BORDER_SIZE + (m_borderIsWide ? GameEdgeContainer.WIDE_WIDTH : GameEdgeContainer.NARROW_WIDTH);
		}
		
		private function getBorderColor():uint
		{
			if (m_isEditable) {
				return m_isWide ? GameComponent.WIDE_COLOR_BORDER : GameComponent.NARROW_COLOR_BORDER;
			} else {
				return m_isWide ? GameComponent.UNADJUSTABLE_WIDE_COLOR_BORDER : GameComponent.UNADJUSTABLE_NARROW_COLOR_BORDER;
			}
		}
		
		private function onEnterFrame(event:Event):void
		{
			if(m_isDirty)
			{
				draw();
				m_isDirty = false;
			}
		}
		
		public function updateBorderWidth(_isWide:Boolean):void
		{
			if (m_borderIsWide == _isWide) {
				return;
			}
			if (!m_isEditable) {
				return;
			}
			m_borderIsWide = _isWide;
			m_isDirty = true;
		}
		
		public function draw():void
		{			
			var singleProngToDoubleOffset:Number = 0.0;
			if (!m_isWide && m_borderIsWide) {
				singleProngToDoubleOffset = 0.075 * Constants.GAME_SCALE;
			}
			
			updatePlug();
			if (m_plug) {
				m_plug.x = - m_plug.width / 2;
				m_plug.y = - getPlugYOffset();
			}
			updateSocket();
			if (m_socket) {
				m_socket.x = - m_socket.width / 2 + singleProngToDoubleOffset;
				m_socket.y = 0;
			}
			
			if (m_dir == GameEdgeContainer.DIR_JOINT_TO_BOX) {
				edgeSegment.x = interiorPt.x;
				edgeSegment.y = interiorPt.y - m_height;
			} else {
				edgeSegment.x = interiorPt.x;
				edgeSegment.y = interiorPt.y;
			}
			edgeSegment.isHoverOn = isHoverOn;
			if(edgeSegmentOutline)
			{
				if (edgeSegmentOutline.width != getBorderWidth()) {
					edgeSegmentOutline.width = getBorderWidth();
				}
				if (edgeSegmentOutline.color != getBorderColor()) {
					edgeSegmentOutline.color = getBorderColor();
				}
				edgeSegmentOutline.x = interiorPt.x - edgeSegmentOutline.width / 2.0 + singleProngToDoubleOffset;
				edgeSegmentOutline.y = edgeSegment.y;
			}
			edgeSegment.setIsWide(m_isWide);
			edgeSegment.draw();
			
			if (innerCircleJoint) {
				innerCircleJoint.x = interiorPt.x;
				innerCircleJoint.y = interiorPt.y;
				innerCircleJoint.setIsWide(m_isWide);
				innerCircleJoint.draw();
			}

			if (m_socket && !m_plugIsWide && m_isWide) {
				const offset:Number = 0.075 * Constants.GAME_SCALE;
				if(edgeSegmentOutline)
					edgeSegmentOutline.x += offset;
				edgeSegment.x += offset;
				if (m_plug) {
					m_plug.x -= offset;
				}
				if (innerCircleJoint) {
					innerCircleJoint.x += offset;
				}
			}
		}
		
		override public function setIsWide(b:Boolean):void
		{
			if (m_isWide == b) {
				return;
			}
			if (!m_isEditable) {
				return;
			}
			m_isWide = b;
			m_isDirty = true;
		}
		
		public function setPlugIsWide(_plugWide:Boolean):void
		{
			if (m_plugIsWide == _plugWide) {
				return;
			}
			m_plugIsWide = _plugWide;
			m_isDirty = true;
		}
		
		override public function dispose():void
		{
			if (edgeSegment) {
				edgeSegment.removeFromParent(true);
			}
			if (innerCircleJoint) {
				innerCircleJoint.removeFromParent(true);
			}
			removeEventListener(Event.ENTER_FRAME, onEnterFrame);
			
			super.dispose();
		}
		
		override protected function getToolTipEvent():ToolTipEvent
		{
			var lockedTxt:String = isEditable() ? "" : "Locked ";
			var widthTxt:String = m_borderIsWide ? "Wide " : "Narrow ";
			var startEndTxt:String = "";
			if (isEnd) {
				startEndTxt = "End ";
			} else if (innerCircleJoint) {
				startEndTxt = "Start ";
			}
			return new ToolTipEvent(ToolTipEvent.ADD_TOOL_TIP, this, lockedTxt + widthTxt + startEndTxt + "Passage", 8);
		}
	}
}