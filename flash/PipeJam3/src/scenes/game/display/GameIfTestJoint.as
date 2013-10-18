package scenes.game.display 
{
	import assets.AssetInterface;
	import events.ToolTipEvent;
	import starling.textures.Texture;
	import starling.textures.TextureAtlas;
	
	import display.NineSliceBatch;
	
	import events.EdgePropChangeEvent;
	import events.PropertyModeChangeEvent;
	
	import flash.events.Event;
	import flash.geom.Point;
	
	import graph.Edge;
	import graph.MapGetNode;
	import graph.Node;
	import graph.NodeTypes;
	import graph.Port;
	import graph.PropDictionary;
	
	import starling.display.Image;
	import starling.display.Quad;
	import starling.display.Sprite;
	
	public class GameIfTestJoint extends GameJointNode 
	{
		private static const LEFT_EDGE_X_LOC:Number = 0.23;// center of left passage is @ x = 23% of the width
		private static const RIGHT_EDGE_X_LOC:Number = 0.64;//center of right passage is @ x = 64% of the width
		
		private var m_inputEdge:GameEdgeContainer;
		private var m_wideEdge:GameEdgeContainer;
		private var m_narrowEdge:GameEdgeContainer;
		private var m_connectionLayer:Sprite;
		
		public function GameIfTestJoint(_layoutXML:XML, _draggable:Boolean, _node:Node, _port:Port=null) 
		{
			super(_layoutXML, _draggable, _node, _port);
		}
		
		override public function setIncomingEdge(edge:GameEdgeContainer):void
		{
			super.setIncomingEdge(edge);
			m_inputEdge = edge;
			var newEnd:Point = new Point(m_boundingBox.x + RIGHT_EDGE_X_LOC * m_boundingBox.width - edge.x, edge.m_endPoint.y + m_boundingBox.height / 2.0);
			edge.setEndPosition(newEnd);
			edge.increaseOutputHeight(m_boundingBox.height / 2.0);
		}
		
		// TODO: update when input edge changes width
		private function update(evt:Event):void
		{
			m_isDirty = true;
		}
		
		override public function setOutgoingEdge(edge:GameEdgeContainer):void
		{
			super.setOutgoingEdge(edge);
			var newStart:Point;
			if (edge.graphEdge) {
				if (edge.graphEdge.is_wide) {
					m_wideEdge = edge;
					newStart = new Point(m_boundingBox.x + RIGHT_EDGE_X_LOC * m_boundingBox.width - edge.x, edge.m_startPoint.y - m_boundingBox.height / 2.0 - 0.2);
				} else {
					m_narrowEdge = edge;
					newStart = new Point(m_boundingBox.x + LEFT_EDGE_X_LOC * m_boundingBox.width - edge.x, edge.m_startPoint.y - m_boundingBox.height / 2.0 - 0.2);
				}
				edge.setStartPosition(newStart);
				edge.increaseInputHeight(m_boundingBox.height / 2.0);
			}
		}
		
		override public function draw():void
		{
			if (m_costume)
				m_costume.removeFromParent(true);
			
			var assetName:String;
			if (m_propertyMode == PropDictionary.PROP_NARROW) {
				assetName = AssetInterface.PipeJamSubTexture_BallSizeTestSimple;
			} else if (m_inputEdge && m_inputEdge.isWide()) {
				assetName = AssetInterface.PipeJamSubTexture_BallSizeTestMapWide;
			} else {
				assetName = AssetInterface.PipeJamSubTexture_BallSizeTestMapNarrow;
			}
			var atlas:TextureAtlas = AssetInterface.getTextureAtlas("Game", "PipeJamSpriteSheetPNG", "PipeJamSpriteSheetXML");
			var texture:Texture = atlas.getTexture(assetName);
			m_costume = new Image(texture);
			var scaleFactor:Number = m_boundingBox.width / m_costume.width;
			m_costume.width *= scaleFactor;
			m_costume.height *= scaleFactor;
			m_costume.y = (m_boundingBox.height - m_costume.height) / 2.0;
			addChild(m_costume);
			/*
			if (m_connectionLayer) m_connectionLayer.removeFromParent(true);
			m_connectionLayer = new Sprite();
			if (m_valueEdge && m_argumentEdge && m_outputEdge) {
				var valWidth:Number = m_valueEdge.isWide() ? GameEdgeContainer.WIDE_WIDTH : GameEdgeContainer.NARROW_WIDTH;
				var seg1:Image, seg2:Image, seg3:Image, j1:Sprite, j2:Sprite, connectColor:uint;
				if (getNode.argumentHasMapStamp()) {
					seg1 = GameEdgeSegment.createEdgeSegment(new Point(0, m_boundingBox.height / 2.0), m_valueEdge.isWide(), m_valueEdge.isEditable());
					seg1.x = m_valueEdge.m_endPoint.x - seg1.width / 2.0 + m_valueEdge.x - this.x;
					seg1.y = m_valueEdge.m_endPoint.y + m_valueEdge.y - this.y;
					m_connectionLayer.addChild(seg1);
					j1 = GameEdgeJoint.createJoint(false, m_valueEdge.isEditable(), m_valueEdge.isWide());
					j1.width = j1.height = valWidth;
					j1.x = seg1.x;
					j1.y = seg1.y + seg1.height - j1.height / 2.0;
					m_connectionLayer.addChildAt(j1, 0);
					seg3 = GameEdgeSegment.createEdgeSegment(new Point(0, m_boundingBox.height / 2.0), m_valueEdge.isWide(), m_valueEdge.isEditable());
					seg3.x = m_outputEdge.m_startPoint.x - seg3.width / 2.0 + m_outputEdge.x - this.x;
					seg3.y = m_outputEdge.m_startPoint.y + m_outputEdge.y - this.y - seg3.height;
					m_connectionLayer.addChild(seg3);
					j2 = GameEdgeJoint.createJoint(false, m_valueEdge.isEditable(), m_valueEdge.isWide());
					j2.width = j2.height = valWidth;
					j2.x = seg3.x;
					j2.y = seg3.y - j2.height / 2.0;
					m_connectionLayer.addChildAt(j2, 0);
					seg2 = GameEdgeSegment.createEdgeSegment(new Point(Math.abs(seg3.x - seg1.x), 0), m_valueEdge.isWide(), m_valueEdge.isEditable());
					seg2.x = Math.min(seg3.x, seg1.x) + valWidth / 2.0;
					seg2.y = m_boundingBox.height / 2.0 - valWidth / 2.0;
					addChild(seg2);
					connectColor = KEYFOR_COLOR;
				} else {
					seg1 = GameEdgeSegment.createEdgeSegment(new Point(0, m_boundingBox.height / 4.0), m_valueEdge.isWide(), m_valueEdge.isEditable());
					seg1.x = m_valueEdge.m_endPoint.x - seg1.width / 2.0 + m_valueEdge.x - this.x;
					seg1.y = m_valueEdge.m_endPoint.y + m_valueEdge.y - this.y;
					m_connectionLayer.addChild(seg1);
					j1 = GameEdgeJoint.createJoint(false, m_valueEdge.isEditable(), m_valueEdge.isWide());
					j1.width = j1.height = valWidth;
					j1.x = seg1.x;
					j1.y = seg1.y + seg1.height - j1.height / 2.0;
					m_connectionLayer.addChildAt(j1, 0);
					seg3 = GameEdgeSegment.createEdgeSegment(new Point(0, m_boundingBox.height / 4.0), true, false);
					seg3.x = m_outputEdge.m_startPoint.x - seg3.width / 2.0 + m_outputEdge.x - this.x;
					seg3.y = m_outputEdge.m_startPoint.y + m_outputEdge.y - this.y - seg3.height;
					seg3.color = 0x0;
					m_connectionLayer.addChild(seg3);
					j2 = GameEdgeJoint.createJoint(false, false, true, null, null, 0x0);
					j2.width = j2.height = GameEdgeContainer.WIDE_WIDTH;
					j2.x = seg3.x;
					j2.y = seg3.y - j2.height / 2.0;
					m_connectionLayer.addChildAt(j2, 0);
					connectColor = 0x0;
				}
				// Connect argument to intersection 
				var outPt:Point = new Point(j2.x + j2.width / 2.0, m_boundingBox.height / 2.0);
				var q1:Quad = new Quad(GameEdgeContainer.NARROW_WIDTH / 2.0, outPt.y, connectColor);
				q1.x = m_argumentEdge.m_endPoint.x - q1.width / 2.0 + m_argumentEdge.x - this.x;
				q1.y = q1.width / 2.0;
				m_connectionLayer.addChild(q1);
				var q2:Quad = new Quad(Math.abs(q1.x - outPt.x), GameEdgeContainer.NARROW_WIDTH / 2.0, connectColor);
				q2.x = (q1.x < outPt.x) ? (q1.x - q1.width / 2.0) : (outPt.x + q1.width / 2.0);
				q2.y = outPt.y - q2.height / 2.0;
				m_connectionLayer.addChild(q2);
			}
			addChild(m_connectionLayer);
			*/
		}
		
		override protected function getToolTipEvent():ToolTipEvent
		{
			var label:String = "Split Test"; // TODO: name this
			return new ToolTipEvent(ToolTipEvent.ADD_TOOL_TIP, this, label, 8);
		}
	}

}