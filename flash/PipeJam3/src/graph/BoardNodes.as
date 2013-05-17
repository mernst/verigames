package graph 
{

	import flash.utils.Dictionary;

	public class BoardNodes
	{
		/** Board name (may be obfuscated) */
		public var board_name:String;
		
		/** Original board name from XML (unobfuscated) */
		public var original_board_name:String;
		
		/** This is a dictionary of Nodes; INDEXED BY NODE_ID */
		public var nodeDictionary:Dictionary = new Dictionary();
		public var nodeIDArray:Array = new Array;
		
		/** The names of any boards that appear on this board */
		public var subboardNames:Vector.<String> = new Vector.<String>();
		
		/** Any nodes that represent the beginning of a pipe, either INCOMING OR START_* OR SUBBOARD with no incoming edges */
		public var beginningNodes:Vector.<Node> = new Vector.<Node>();
		
		/** Map from edge set id to all starting edges for that edge set ON THIS BOARD (no other boards) */
		public var startingEdgeDictionary:Dictionary = new Dictionary();
		
		/** Map from edge set id to all OUTGOING edges for that edge set ON THIS BOARD (no other boards) */
		public var outgoingEdgeDictionary:Dictionary = new Dictionary();
		
		/** True if a change in pipe width or buzzsaw was made since the last simulation */
		public var changed_since_last_sim:Boolean = true;
		/** True if a simulation has been run on this board */
		public var simulated:Boolean = false;
		/** True if the board is being checked for trouble points */
		public var simulating:Boolean = false;
		
		public var metadata:Dictionary = new Dictionary();;
		/** After all BoardNodes are created, we want to associate all SubnetNodes with their appropriate BoardNodes */
		public var subnetNodesToAssociate:Vector.<SubnetworkNode> = new Vector.<SubnetworkNode>();
		
		public var incoming_node:Node;
		public var outgoing_node:Node;
		
		public function BoardNodes(_obfuscated_board_name:String, _original_board_name:String) 
		{
			board_name = _obfuscated_board_name;
			original_board_name = _original_board_name;
		}
		
		public function addNode(_node:Node):void {
			if (nodeDictionary[_node.node_id] == null) {
				nodeDictionary[_node.node_id] = _node;
				nodeIDArray.push(_node.node_id);
				var ip:Port, op:Port;
				switch (_node.kind) {
					case NodeTypes.SUBBOARD:
						if ((_node as SubnetworkNode).subboard_name.length > 0) {
							if (subboardNames.indexOf((_node as SubnetworkNode).subboard_name) == -1) {
								subboardNames.push((_node as SubnetworkNode).subboard_name);
							}
						}
						subnetNodesToAssociate.push(_node as SubnetworkNode);
						// If there are no incoming pipes to the subboard, this is a beginning node - fall through to add to beginningNodes list
						if (_node.incoming_ports.length == 0) {
							if (beginningNodes.indexOf(_node) == -1) {
								beginningNodes.push(_node);
							}
						}
						for each (op in _node.outgoing_ports) {
							addStartingEdgeToDictionary(op.edge);
						}
					break;
					case NodeTypes.OUTGOING:
						if (outgoing_node) {
							throw new Error("Board found with multiple outgoing nodes: " + original_board_name + " nodes:" + outgoing_node.node_id + " & " + _node.node_id);
						}
						outgoing_node = _node;
						// It is also (apparently) possible for an outgoing node to have no inputs or outputs, this won't actually get processed but include it anyway
						if (_node.incoming_ports.length == 0) {
							if (beginningNodes.indexOf(_node) == -1) {
								beginningNodes.push(_node);
							}
						}
						for each (ip in _node.incoming_ports) {
							addOutgoingEdgeToDictionary(ip.edge);
						}
					break;
					case NodeTypes.INCOMING:
						if (incoming_node) {
							throw new Error("Board found with multiple incoming nodes: " + original_board_name + " nodes:" + incoming_node.node_id + " & " + _node.node_id);
						}
						incoming_node = _node;
						// intentional fall-thru (no break)
					case NodeTypes.START_LARGE_BALL:
					case NodeTypes.START_NO_BALL:
					case NodeTypes.START_PIPE_DEPENDENT_BALL:
					case NodeTypes.START_SMALL_BALL:
						if (beginningNodes.indexOf(_node) == -1) {
							beginningNodes.push(_node);
						}
						for each (op in _node.outgoing_ports) {
							// Should only be one port
							addStartingEdgeToDictionary(op.edge);
						}
					break;
				}
			} else {
				throw new Error("Duplicate world nodes found for node_id: " + _node.node_id);
			}
		}
		
		/**
		 * Adds the input edge and edge set index id pair to the startingEdgeDictionary
		 * @param	e A starting edge to be added to the dictionary
		 * @param	checkIfExists True if only edges that do not already exist in the dictionary are added
		 */
		public function addStartingEdgeToDictionary(e:Edge, checkIfExists:Boolean = true):void {
			var id:String = e.linked_edge_set.id;
			if (startingEdgeDictionary[id] == null) {
				startingEdgeDictionary[id] = new Vector.<Edge>();
			}
			if ((!checkIfExists) || (startingEdgeDictionary[id].indexOf(e) == -1)) {
				startingEdgeDictionary[id].push(e);
			}
		}
		
		/**
		 * Adds the input edge and edge set index id pair to the outgoingEdgeDictionary
		 * @param	e A starting edge to be added to the dictionary
		 * @param	checkIfExists True if only edges that do not already exist in the dictionary are added
		 */
		public function addOutgoingEdgeToDictionary(e:Edge, checkIfExists:Boolean = true):void {
			var id:String = e.linked_edge_set.id;
			if (outgoingEdgeDictionary[id] == null) {
				outgoingEdgeDictionary[id] = new Vector.<Edge>();
			}
			if ((!checkIfExists) || (outgoingEdgeDictionary[id].indexOf(e) == -1)) {
				outgoingEdgeDictionary[id].push(e);
			}
		}
		
	}
}