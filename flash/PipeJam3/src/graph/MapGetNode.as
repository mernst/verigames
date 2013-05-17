package graph 
{
	import system.VerigameServerConstants;

	/**
	 * Special type of node - subnetwork. This does not contain any graphics/drawing information, but it does 
	 * contain a reference to the associated_board object that has all of that.
	 * 
	 * @author Tim Pavlik
	 */
	public class MapGetNode extends Node 
	{
		public static const MAP_PORT_IDENTIFIER:String = 		"0";
		public static const KEY_PORT_IDENTIFIER:String = 		"1";
		public static const VALUE_PORT_IDENTIFIER:String = 		"2";
		public static const ARGUMENT_PORT_IDENTIFIER:String = 	"3";
		
		public function MapGetNode(_x:Number, _y:Number, _t:Number, _metadata:Object = null) {
			super(_x, _y, _t, NodeTypes.GET, _metadata);
		}
		
		public function getOutputBallType():uint {
			if (argumentHasMapStamp()) {
				// Argument pinstriping matches key, ball travels from value to output
				if (valueEdge.is_wide) {
					return valueEdge.exit_ball_type;
				} else {
					switch (valueEdge.exit_ball_type) {
						case VerigameServerConstants.BALL_TYPE_WIDE:
							// WIDE ball through narrow pipe? This shouldn't be possible, but process it anyway
							return VerigameServerConstants.BALL_TYPE_NONE;
						break;
						case VerigameServerConstants.BALL_TYPE_WIDE_AND_NARROW:
							return VerigameServerConstants.BALL_TYPE_NARROW;
						break;
					}
					return valueEdge.exit_ball_type;
				}
			}
			// Argument pinstriping doesn't match key, null literal (WIDE ball) thrown)
			return VerigameServerConstants.BALL_TYPE_WIDE;
		}
		
		public function argumentHasMapStamp():Boolean
		{
			var mapEdgeSet:EdgeSetRef = mapEdge.linked_edge_set;
			return argumentEdge.linked_edge_set.hasActiveStampOfEdgeSetId(mapEdgeSet.id);
		}
		
		public function get mapEdge():Edge {
			for each (var my_port:Port in incoming_ports) {
				if (my_port.port_id == MAP_PORT_IDENTIFIER) {
					return my_port.edge;
				}
			}
			return null;
		}
		
		public function get keyEdge():Edge {
			for each (var my_port:Port in incoming_ports) {
				if (my_port.port_id == KEY_PORT_IDENTIFIER) {
					return my_port.edge;
				}
			}
			return null;
		}
		
		public function get valueEdge():Edge {
			for each (var my_port:Port in incoming_ports) {
				if (my_port.port_id == VALUE_PORT_IDENTIFIER) {
					return my_port.edge;
				}
			}
			return null;
		}
		
		public function get argumentEdge():Edge {
			for each (var my_port:Port in incoming_ports) {
				if (my_port.port_id == ARGUMENT_PORT_IDENTIFIER) {
					return my_port.edge;
				}
			}
			return null;
		}
		
		public function get outputEdge():Edge {
			return outgoing_ports[0].edge;
		}
		
	}

}