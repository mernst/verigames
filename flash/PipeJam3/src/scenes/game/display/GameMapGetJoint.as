package scenes.game.display 
{
	import assets.AssetInterface;
	import display.NineSliceBatch;
	import flash.geom.Point;
	import graph.Edge;
	import graph.MapGetNode;
	import graph.Node;
	import graph.Port;
	import starling.display.Quad;
	import starling.display.Sprite;
	
	public class GameMapGetJoint extends GameJointNode 
	{
		private var m_valueEdge:GameEdgeContainer;
		private var m_argumentEdge:GameEdgeContainer;
		private var m_outputEdge:GameEdgeContainer;
		
		public function GameMapGetJoint(_layoutXML:XML, _draggable:Boolean, _node:Node, _port:Port=null) 
		{
			super(_layoutXML, _draggable, _node, _port);
			if (!(_node is MapGetNode)) {
				throw new Error("MapGetJoint created for node where node is not type MapGetNode.");
			}
		}
		
		override public function setIncomingEdge(edge:GameEdgeContainer):void
		{
			super.setIncomingEdge(edge);
			if (edge.graphEdge == getNode.valueEdge) {
				m_valueEdge = edge;
			} else if (edge.graphEdge == getNode.argumentEdge) {
				m_argumentEdge = edge;
			}
		}
		
		override public function setOutgoingEdge(edge:GameEdgeContainer):void
		{
			super.setOutgoingEdge(edge);
			m_outputEdge = edge;
		}
		
		private function get getNode():MapGetNode
		{
			return m_node as MapGetNode;
		}
		
		private var m_connectionLayer:Sprite;
		override public function draw():void
		{
			if (m_box9slice)
				m_box9slice.removeFromParent(true);
			
			var assetName:String = m_isSelected ? AssetInterface.PipeJamSubTexture_GrayDarkBoxSelectPrefix : AssetInterface.PipeJamSubTexture_GrayDarkBoxPrefix;
			m_box9slice = new NineSliceBatch(m_boundingBox.width, m_boundingBox.height, m_boundingBox.height / 3.0, m_boundingBox.height / 3.0, "Game", "PipeJamSpriteSheetPNG", "PipeJamSpriteSheetXML", assetName);
			addChild(m_box9slice);
			
			if (m_connectionLayer) m_connectionLayer.removeFromParent(true);
			m_connectionLayer = new Sprite();
			if (m_valueEdge && m_argumentEdge && m_outputEdge) {
				var valWidth:Number = m_valueEdge.isWide() ? GameEdgeContainer.WIDE_WIDTH : GameEdgeContainer.NARROW_WIDTH;
				var outWidth:Number, outColor:int;
				if (getNode.argumentHasMapStamp()) {
					
					outWidth = valWidth;
					outColor = m_valueEdge.getColor();
				} else {
					outWidth = GameEdgeContainer.WIDE_WIDTH;
					outColor = UNADJUSTABLE_WIDE_COLOR;
				}
			}
			addChild(m_connectionLayer);
			
			this.flatten();
		}
		
		override public function onClicked(pt:Point):void
		{
			
		}
	}

}