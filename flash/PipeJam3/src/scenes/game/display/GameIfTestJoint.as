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