package graph 
{
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
						case Edge.BALL_TYPE_WIDE:
							// WIDE ball through narrow pipe? This shouldn't be possible, but process it anyway
							return Edge.BALL_TYPE_NONE;
						break;
						case Edge.BALL_TYPE_WIDE_AND_NARROW:
							return Edge.BALL_TYPE_NARROW;
						break;
					}
					return valueEdge.exit_ball_type;
				}
			}
			// Argument pinstriping doesn't match key, null literal (WIDE ball) thrown)
			return Edge.BALL_TYPE_WIDE;
		}
		
		public function argumentHasMapStamp():Boolean
		{
			var mapEdgeSet:EdgeSetRef = mapEdge.linked_edge_set;
			// TODO: HARDCODE TO BE TRUE FOR NOW, change back when UI has been added
			return true;
			//return argumentEdge.linked_edge_set.hasActiveStampOfEdgeSetId(mapEdgeSet.id);
		}
		
		public function get mapEdge():Edge {
			var my_port:Port = getIncomingPort(MAP_PORT_IDENTIFIER);
			if (my_port) {
				return my_port.edge;
			}
			return null;
		}
		
		public function get keyEdge():Edge {
			var my_port:Port = getIncomingPort(KEY_PORT_IDENTIFIER);
			if (my_port) {
				return my_port.edge;
			}
			return null;
		}
		
		public function get valueEdge():Edge {
			var my_port:Port = getIncomingPort(VALUE_PORT_IDENTIFIER);
			if (my_port) {
				return my_port.edge;
			}
			return null;
		}
		
		public function get argumentEdge():Edge {
			var my_port:Port = getIncomingPort(ARGUMENT_PORT_IDENTIFIER);
			if (my_port) {
				return my_port.edge;
			}
			return null;
		}
		
		public function get outputEdge():Edge {
			return outgoing_ports[0].edge;
		}
		
	}

}