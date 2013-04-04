package events
{
	import flash.geom.Point;
	
	import starling.events.Event;
	import scenes.game.display.GameComponent;
	
	public class MoveEvent extends Event
	{
		public var m_startPoint:Point;
		
		public function MoveEvent(type:String, component:GameComponent, startPoint:Point)
		{
			super(type, true, data);
			m_startPoint = startPoint;
		}
	}
}