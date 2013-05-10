package scenes.game.display 
{
	import flash.events.Event;
	import flash.geom.Rectangle;
	import scenes.BaseComponent;
	import starling.display.Quad;
	import starling.events.TouchEvent;
	
	public class GameJointNode extends GameComponent
	{	
		public var id:String;
		public var boundingBox:Rectangle;
		private var m_layoutXML:XML;
		public var m_outgoingEdges:Vector.<GameEdgeContainer>;
		public var m_incomingEdges:Vector.<GameEdgeContainer>;
		private var m_quad:Quad;
		
		public function GameJointNode(_id:String, _layoutXML:XML) 
		{
			super();
			id = _id;
			m_layoutXML = _layoutXML;
			boundingBox = findBoundingBox(m_layoutXML);
			draw();
			addEventListener(Event.ENTER_FRAME, onEnterFrame);
			addEventListener(TouchEvent.TOUCH, onTouch);
		}
		
		public function draw():void
		{
			if (!m_quad) {
				m_quad = new Quad(boundingBox.width, boundingBox.height, getColor());
			}
			addChild(m_quad);
		}
		
		//adds edge to incoming edge method (unless currently in vector), then sorts
		public function setIncomingEdge(edge:GameEdgeContainer):void
		{
			if(m_incomingEdges.indexOf(edge) == -1)
				m_incomingEdges.push(edge);
			edge.incomingEdgePosition = m_incomingEdges.length-1;
			//I want the edges to be in ascending order according to x position, so do that here
			m_incomingEdges.sort(GameEdgeContainer.sortIncomingXPositions);
		}
		
		//adds edge to outgoing edge method (unless currently in vector), then sorts
		public function setOutgoingEdge(edge:GameEdgeContainer):void
		{
			if(m_outgoingEdges.indexOf(edge) == -1)
				m_outgoingEdges.push(edge);
			edge.outgoingEdgePosition = m_outgoingEdges.length-1;
			//I want the edges to be in ascending order according to x position, so do that here
			m_outgoingEdges.sort(GameEdgeContainer.sortOutgoingXPositions);
		}
		
		public function onEnterFrame(event:Event):void
		{
			if(m_isDirty)
			{
				removeChildren();
				draw();
				m_isDirty = false;
			}
		}
		
		private function onTouch(event:TouchEvent):void
		{
			
		}
		
		override public function isWide():Boolean
		{
			// Joint's output is wide is any inputs are wide
			var wide:Boolean = false;
			for each (var oedge:GameEdgeContainer in m_incomingEdges) {
				wide = (wide || oedge.isWide());
			}
			return wide;
		}
		
		override public function getColor():int
		{
			return 0xAAAAAA;
		}
	}

}