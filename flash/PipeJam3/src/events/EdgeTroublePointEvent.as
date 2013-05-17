package events 
{
	import graph.Edge;
	import flash.events.Event;
	
	public class EdgeTroublePointEvent extends Event 
	{
		public static const EDGE_TROUBLE_POINT_REMOVED:String = "EDGE_TROUBLE_POINT_REMOVED";
		public static const EDGE_TROUBLE_POINT_ADDED:String = "EDGE_TROUBLE_POINT_ADDED";
		
		public var edge:Edge;
		
		public function EdgeTroublePointEvent(type:String, _edge:Edge) 
		{
			super(type);
			edge = _edge;
			trace("dispatching: " + this);
		}
		
		override public function toString():String
		{
			return "[EdgeTroublePointEvent:" + type + " edgeId:" + edge.edge_id + "]";
		}
	}
}