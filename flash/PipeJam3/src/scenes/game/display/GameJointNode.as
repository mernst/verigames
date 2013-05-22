package scenes.game.display 
{
	import flash.events.Event;
	import flash.geom.Rectangle;
	import graph.Node;
	import graph.Port;
	import scenes.BaseComponent;
	import starling.display.Quad;
	import starling.events.TouchEvent;
	
	public class GameJointNode extends GameNodeBase
	{	
		private var m_quad:Quad;
		private var m_node:Node;
		private var m_port:Port;
		
		public function GameJointNode( _layoutXML:XML, _node:Node = null, _port:Port = null) 
		{
			super(_layoutXML);
			m_node = _node;
			m_port = _port;
			updateSize();
			draw();
		}
		
		override public function draw():void
		{
			if (!m_quad) {
				m_quad = new Quad(m_boundingBox.width, m_boundingBox.height, getColor());
			}
			addChild(m_quad);
		}
		
		override public function updateSize():void
		{
			if (m_outgoingEdges.length == 0) {
				m_isWide = true;// Case where no outputs, don't put a constraint on input lines
			}
			// Any outputs narrow, create a narrow constraint
			var anyNarrowOutputs:Boolean = false;
			for each (var oedge:GameEdgeContainer in m_outgoingEdges) {
				if (!oedge.isWide()) {
					anyNarrowOutputs = true;
					break;
				}
			}
			
			var wide:Boolean = !anyNarrowOutputs;
			if (m_isWide != wide) {
				m_isWide = wide;
				m_isDirty = true; // if we end up drawing based on width, re-draw at this point
				for each (var iedge:GameEdgeContainer in m_incomingEdges) {
					if (!m_isWide || iedge.isWide()) {
						iedge.setOutgoingWidth(m_isWide);
					}
				}
			}
		}
		
		override public function isWide():Boolean
		{
			return m_isWide;
		}
		
		override public function getColor():int
		{
			return 0xAAAAAA;
		}
	}

}