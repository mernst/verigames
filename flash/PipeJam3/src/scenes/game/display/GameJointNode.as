package scenes.game.display 
{
	import flash.events.Event;
	import flash.geom.Rectangle;
	import scenes.BaseComponent;
	import starling.display.Quad;
	import starling.events.TouchEvent;
	
	public class GameJointNode extends GameNodeBase
	{	
		private var m_quad:Quad;
		
		public function GameJointNode( _layoutXML:XML) 
		{
			super(_layoutXML);
			
			draw();
		}
		
		override public function draw():void
		{
			if (!m_quad) {
				m_quad = new Quad(m_boundingBox.width, m_boundingBox.height, getColor());
			}
			addChild(m_quad);
		}
		
		override public function isWide():Boolean
		{
			// Joint's output is wide is any inputs are wide
			var wide:Boolean = false;
			for each (var oedge:GameEdgeContainer in m_incomingEdges) {
				wide = (wide || oedge.isWide());
			}
			m_isWide = wide;
			return wide;
		}
		
		override public function getColor():int
		{
			return 0xAAAAAA;
		}
	}

}