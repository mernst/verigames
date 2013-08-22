package events 
{
	import graph.Port;
	import flash.events.Event;
	
	public class PortTroublePointEvent extends Event 
	{
		public static const PORT_TROUBLE_POINT_CHANGE:String = "PORT_TROUBLE_POINT_CHANGE";
		
		public var port:Port;
		
		public function PortTroublePointEvent(type:String, _port:Port) 
		{
			super(type);
			port = _port;
			//trace("dispatching: " + this);
		}
		
		override public function toString():String
		{
			return "[PortTroublePointEvent:" + type + " port:" + port.toString() + "]";
		}
	}
}