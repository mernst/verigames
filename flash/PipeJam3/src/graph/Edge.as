package graph
{
	import flash.events.EventDispatcher;
	import flash.utils.Dictionary;
	
	import events.BallTypeChangeEvent;
	import events.EdgeTroublePointEvent;
	import graph.Node;
	import utils.Metadata;
	
	/**
	 * Directed Edge created when a graph structure is read in from XML.
	 */
	public class Edge extends EventDispatcher
	{
		// ### BALL_TYPES ### \\
		//renumbered so you can now BIT AND these together, as needed.
		//Now you can & STARRED with the other types
		//Left wide_and_narrow combination so I don't have to rework code
		public static const BALL_TYPE_NONE:uint 			= 0;
		public static const BALL_TYPE_NARROW:uint 			= 1;
		public static const BALL_TYPE_WIDE:uint 			= 2;
		public static const BALL_TYPE_WIDE_AND_NARROW:uint 	= 3;
		public static const BALL_TYPE_STARRED:uint 			= 4;
		public static const BALL_TYPE_UNDETERMINED:uint 	= 8;
		public static const BALL_TYPE_GHOST:uint 			= 16; // used for recursion
		// ### END BALL_TYPES ### \\

		/* Network connections */
		/** Port on source node */
		public var from_port:Port;
		
		/** Port on destination node */
		public var to_port:Port;
		
		/** Any extra information contained in the orginal XML for this edge */
		public var metadata:Object;
		
		/** The numerical index (starting at 0 = first) corresponding to the linked edge set (by level) that this edge belongs to */
		public var linked_edge_set:EdgeSetRef;
		
		/* Edge identifiers */
		/** Name of the variable provided in XML */
		public var description:String = "";
		
		/** The unique id given as input from XML (unique within a given world) */
		public var edge_id:String;		
		
		/** Id of the variable identified in XML */
		public var variableID:int;
		
		/** pointers back up to all starting edges that can reach this edge. */
		public var topmostEdgeDictionary:Dictionary = new Dictionary;
		public var topmostEdgeIDArray:Array = new Array;
		
		/* Starting state of the pipe */
		/** True if edge has attribute width="wide" in XML, false otherwise */
		public var starting_is_wide:Boolean = false;
		
		/** True if edge has attribute buzzsaw="true" in XML, false otherwise */
		public var starting_has_buzzsaw:Boolean = false;
		
		/** True if this edge's width can be changed by the user, if false pipe is gray and cannot be changed */
		public var editable:Boolean = false;
		
		/* current state of the pipe */
		/** True if edge has attribute width="wide" in XML, false otherwise */
		public var is_wide:Boolean = false;
		
		/** True if edge has attribute buzzsaw="true" in XML, false otherwise */
		public var has_buzzsaw:Boolean = false;
		
		/** True if this edge contains a pinch point, false otherwise */
		public var has_pinch:Boolean = false;
		
		/** used to mark nodes that think they are starting nodes, and we check later if they actually are. 
		 I think this is only a situation that arises on mismade boards (like some I hand created) but I'll handle the case anyway as it helps with debugging
		*/
		public var isStartingNode:Boolean;		
		
		// The following five vars are used to plug in the PipeSimulator and detecting ball type changes:
		private var m_enter_ball_type:uint = BALL_TYPE_UNDETERMINED;
		private var m_exit_ball_type:uint = BALL_TYPE_UNDETERMINED;
		private var m_prev_enter_ball_type:uint = BALL_TYPE_UNDETERMINED;
		private var m_prev_exit_ball_type:uint = BALL_TYPE_UNDETERMINED;
		private var m_has_error:Boolean = false;
		
		/**
		 * Directed Edge created when a graph structure is read in from XML.
		 * @param	_from_node Source node
		 * @param	_from_port Port on source node
		 * @param	_to_node Destination node
		 * @param	_to_port Port on destination node
		 * @param	_metadata Extra information about this edge (for example: any attributes in the original XML object)
		 */
		public function Edge(_from_node:Node, _from_port_id:String, _to_node:Node, _to_port_id:String, _linked_edge_set:EdgeSetRef = null, _metadata:Object = null)
		{
			if (_from_node is SubnetworkNode) {
				from_port = new SubnetworkPort((_from_node as SubnetworkNode), this, _from_port_id, Port.OUTGOING_PORT_TYPE);
			} else {
				from_port = new Port(_from_node, this, _from_port_id, Port.OUTGOING_PORT_TYPE);
			}
			
			if (_to_node is SubnetworkNode) {
				to_port = new SubnetworkPort((_to_node as SubnetworkNode), this, _to_port_id, Port.INCOMING_PORT_TYPE);
			} else {
				to_port = new Port(_to_node, this, _to_port_id, Port.INCOMING_PORT_TYPE);
			}
			
			metadata = _metadata;
			linked_edge_set = _linked_edge_set;
			if (_metadata == null) {
				metadata = new Metadata(null);
			} else if (_metadata.data != null) {
				//Example: <edge description="chute1" variableID="-1" pinch="false" width="wide" id="e1" buzzsaw="false">
				if (metadata.data.description) {
					if (String(metadata.data.description).length > 0) {
						description = String(metadata.data.description);
					}
				}
				if (metadata.data.variableID) {
					if (!isNaN(int(metadata.data.variableID))) {
						variableID = int(metadata.data.variableID);
					}
				}
				if (String(metadata.data.pinch).toLowerCase() == "true") {
					has_pinch = true;
				}
				if (String(metadata.data.editable).toLowerCase() == "true") {
					editable = true;
				}
				if (String(metadata.data.width).toLowerCase() == "wide") {
					starting_is_wide = true;
					is_wide = true;
				}
				if (String(metadata.data.buzzsaw).toLowerCase() == "true") {
					starting_has_buzzsaw = true;
					has_buzzsaw = true;
				}
				if (String(_metadata.data.id).length > 0) {
					edge_id = String(_metadata.data.id);
				}
			}
			
			metadata = null;
			
			Network.edgeDictionary[edge_id] = this;
		}
		
		public function updateEdgeWidth(isWide:Boolean):void
		{
			if(editable)
				is_wide = isWide;
		}
		
		public function isStartingEdge():Boolean
		{
			switch (from_node.kind) {
				case NodeTypes.START_LARGE_BALL:
				case NodeTypes.START_NO_BALL:
				case NodeTypes.START_SMALL_BALL:
				case NodeTypes.START_PIPE_DEPENDENT_BALL:
				case NodeTypes.INCOMING:
			//	case NodeTypes.SUBBOARD:
					return true;
					break;
			}
			
			return false;
		}
		
		//returns the active stamps associated with this edge
		protected function getActiveStampVector():Vector.<StampRef> {
			var activeStampVector:Vector.<StampRef> = new Vector.<StampRef>;
			
			var numActiveStamps:uint = linked_edge_set.num_active_stamps;
			for(var i:uint = 0; i < numActiveStamps; i++)
			{
				var activeStamp:StampRef = linked_edge_set.getActiveStampAt(i);
				activeStampVector[activeStampVector.length] = activeStamp;				
			}
			
			return activeStampVector;
		}
		
		public function get from_node():Node {
			return from_port.node;
		}
		
		public function get to_node():Node {
			return to_port.node;
		}
		
		public function get from_port_id():String {
			return from_port.port_id;
		}
		
		public function get to_port_id():String {
			return to_port.port_id;
		}
		
		public function get enter_ball_type():uint
		{
			return m_enter_ball_type;
		}
		
		public function get exit_ball_type():uint
		{
			return m_exit_ball_type;
		}
		
		public function set enter_ball_type(typ:uint):void
		{
			if (ballUnknown(typ) && !ballUnknown(m_enter_ball_type)) {
				// If setting a ball to be UNDETERMINED/GHOST to begin sim, keep previous type to compare after sim
				m_prev_enter_ball_type = m_enter_ball_type;
				m_enter_ball_type = typ;
			} else if (!ballUnknown(typ)) {
				// If setting a type to a KNOWN ball type (done simulating, for example) record change
				m_enter_ball_type = typ;
				if (m_prev_enter_ball_type != m_enter_ball_type) {
					dispatchEvent(new BallTypeChangeEvent(BallTypeChangeEvent.ENTER_BALL_TYPE_CHANGED, m_prev_enter_ball_type, m_enter_ball_type, this));
				}
				m_prev_enter_ball_type = m_enter_ball_type;
			} else {
				// Was unknown, still unknown - simply make the change
				m_enter_ball_type = typ;
			}
		}
		
		public function set exit_ball_type(typ:uint):void
		{
			if (ballUnknown(typ) && !ballUnknown(m_exit_ball_type)) {
				// If setting a ball to be UNDETERMINED/GHOST to begin sim, keep previous type to compare after sim
				m_prev_exit_ball_type = m_exit_ball_type;
				m_exit_ball_type = typ;
			} else if (!ballUnknown(typ)) {
				// If setting a type to a KNOWN ball type (done simulating, for example) record change
				m_exit_ball_type = typ;
				if (m_prev_exit_ball_type != m_exit_ball_type) {
					dispatchEvent(new BallTypeChangeEvent(BallTypeChangeEvent.EXIT_BALL_TYPE_CHANGED, m_prev_exit_ball_type, m_exit_ball_type, this));
				}
				m_prev_exit_ball_type = m_exit_ball_type;
			} else {
				// Was unknown, still unknown - simply make the change
				m_exit_ball_type = typ;
			}
		}
		
		// Set this edge to UNDETERMINED and outgoing Edge's
		public function setUndeterminedAndRecurse():void
		{
			if ((m_enter_ball_type == BALL_TYPE_UNDETERMINED) && (m_exit_ball_type == BALL_TYPE_UNDETERMINED)) {
				return;
			}
			m_enter_ball_type = BALL_TYPE_UNDETERMINED;
			m_exit_ball_type = BALL_TYPE_UNDETERMINED;
			for each (var outport:Port in to_port.node.outgoing_ports) {
				outport.edge.setUndeterminedAndRecurse();
			}
		}
		
		public function get has_error():Boolean
		{
			return m_has_error;
		}
		
		public function set has_error(b:Boolean):void
		{
			if (m_has_error && !b) {
				dispatchEvent(new EdgeTroublePointEvent(EdgeTroublePointEvent.EDGE_TROUBLE_POINT_REMOVED, this));
			} else if (!m_has_error && b) {
				dispatchEvent(new EdgeTroublePointEvent(EdgeTroublePointEvent.EDGE_TROUBLE_POINT_ADDED, this));
			}
			m_has_error = b;
		}
		
		private function ballUnknown(typ:uint):Boolean
		{
			switch (typ) {
				case BALL_TYPE_UNDETERMINED:
				case BALL_TYPE_GHOST:
					return true;
			}
			return false;
		}
		
	}
}