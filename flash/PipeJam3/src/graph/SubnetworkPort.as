package graph 
{
	/**
	 * Special case of a port on a board connecting to a subnetwork node. The 
	 * @author Tim Pavlik
	 */
	public class SubnetworkPort extends Port 
	{
		
		/** The edge (inside of the Subnetwork board) that this port points to. */
		public var linked_subnetwork_edge:Edge;
		
		public var default_ball_type:uint;
		public var default_is_wide:Boolean;
		
		public function SubnetworkPort(_node:SubnetworkNode, _edge:Edge, _id:String, _type:uint = INCOMING_PORT_TYPE) {
			super(_node, _edge, _id, _type);
			if (type == INCOMING_PORT_TYPE) {
				default_ball_type = Edge.BALL_TYPE_NONE;
				default_is_wide = true;
			} else {
				default_ball_type = Edge.BALL_TYPE_NARROW;
				default_is_wide = false;
			}
		}
		
	}

}