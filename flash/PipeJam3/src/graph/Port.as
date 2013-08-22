package graph
{
	import events.PortTroublePointEvent;
	import flash.events.EventDispatcher;
	import system.VerigameServerConstants;
	import flash.geom.Point;

	/** This object connects a Node to an edge. It is useful as a separate object because
	 *  trouble points will often occur at ports, so associated them with Nodes is not useful
	 *  because it could refer to any number of ports (say the 2nd outgoing edge). */
	public class Port extends EventDispatcher
	{
		/** Associated Node that this port is coming out of/into */
		public var node:Node;
		
		/** Edge that leads into/out of the associated node */
		public var edge:Edge;
		
		/** Id assigned to the port from input XML */
		public var port_id:String;
		
		/** Type - incoming or outgoing, assigned in child class */
		public var type:uint = 0;
		
		/** Types are defined here */
		public static const INCOMING_PORT_TYPE:uint = 0;
		public static const OUTGOING_PORT_TYPE:uint = 1;
		
		private var m_has_error:Boolean = false;
		
		public function Port(_node:Node, _edge:Edge, _id:String, _type:uint = INCOMING_PORT_TYPE) {
			node = _node;
			edge = _edge;
			port_id = _id;
			type = _type;
		}
		
		public function get has_error():Boolean
		{
			return m_has_error;
		}
		
		public function set has_error(b:Boolean):void
		{
			if (m_has_error && !b) {
				dispatchEvent(new PortTroublePointEvent(PortTroublePointEvent.PORT_TROUBLE_POINT_REMOVED, this));
			} else if (!m_has_error && b) {
				dispatchEvent(new PortTroublePointEvent(PortTroublePointEvent.PORT_TROUBLE_POINT_ADDED, this));
			}
			m_has_error = b;
		}
		
		override public function toString():String
		{
			return node.node_id + ((type == INCOMING_PORT_TYPE) ? "_I" : "_O") + port_id;
		}
		
	}
}