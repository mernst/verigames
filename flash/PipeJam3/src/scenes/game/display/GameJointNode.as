package scenes.game.display 
{
	import flash.events.Event;
	import flash.geom.Rectangle;
	import graph.Node;
	import graph.Port;
	import scenes.BaseComponent;
	import starling.display.Quad;
	import starling.events.TouchEvent;
	import utils.XSprite;
	
	public class GameJointNode extends GameNodeBase
	{	
		private var m_node:Node;
		private var m_port:Port;
		
		public function GameJointNode( _layoutXML:XML, _node:Node = null, _port:Port = null) 
		{
			super(_layoutXML);
			m_node = _node;
			m_port = _port;
			draw();
		}
		
		override public function draw():void
		{
			if (m_quad)
				removeChildren(0,-1,true);
			
			m_quad = new Quad(m_boundingBox.width, m_boundingBox.height, getColor());
			
			addChild(m_quad);
			this.flatten();
		}
		
		override public function updateSize():void
		{
			// no concept of size for joints
		}
		
		override public function isWide():Boolean
		{
			return m_isWide;
		}
		
		override public function getColor():int
		{
			if(m_isSelected)
				return 0x888888;
			else
				return 0xAAAAAA;
		}
	}

}