package system 
{
	import graph.LevelNodes;
	import graph.Network;
	import graph.Edge;
	import graph.MapGetNode;
	import graph.Node;
	import graph.NodeTypes;
	import graph.Port;
	import graph.BoardNodes;
	import graph.PropDictionary;
	import graph.ConflictDictionary;
	import graph.SubnetworkNode;
	import graph.SubnetworkPort;
	
	import flash.utils.Dictionary;
	
	/**
	 * The PipeSimulator class calculates and stores where trouble points
	 * can occur in the game, based on the current edge/graph configuration.
	 * 
	 * Trouble points can occur at either Ports or Edges. 
	 * 
	 * A trouble point Port occurs only when an edge with a WIDE ball flows
	 * into a NARROW SUBNETWORK edge stub or when a WIDE ball in the argument
	 * edge of a MAPGET node flows into a MAPGET where the VALUE edge is
	 * NARROW.
	 * 
	 * Trouble point edges occur any time a WIDE ball flows into a NARROW edge
	 * or an edge that has a pinch point. For these edges, the edge.enter_ball_type
	 * would be WIDE while the edge.exit_ball_type would be NARROW or NONE.
	 * 
	 * @author Steph
	 */
	public class PipeSimulator 
	{
		private static const DEBUG:Boolean = false;
		
		/** True to use simulation results from external board calls (outside of the current level) on current board */
		private static const SIMULATE_EXTERNAL_BOARDS:Boolean = false;
		
		/* The world in which the PipeSimulator detects trouble points */
		private var network:Network;
		
		/* A map from boardname ConflictDict associated with that level.*/
		private var boardToTroublePoints:Dictionary;
		private var prevBoardToTroublePoints:Dictionary;
		
		/**
		 * Simulates the ball types for each edge in the given network
		 * @param	_network
		 */
		public function PipeSimulator(_network:Network) 
		{
			network = _network;
			boardToTroublePoints = new Dictionary();
			// TODO: globally mark Edges and Ports has_error = true
			var boards_in_prog:Vector.<BoardNodes> = new Vector.<BoardNodes>();
			for (var levelName:String in network.LevelNodesDictionary) {
				var levelNodes:LevelNodes = network.LevelNodesDictionary[levelName] as LevelNodes;
				for (var boardName:String in levelNodes.boardNodesDictionary) {
					var board:BoardNodes = levelNodes.boardNodesDictionary[boardName] as BoardNodes;
					var conflictDict:ConflictDictionary = simulateBoard(board, boards_in_prog);
					var prop:String;
					for (var portk:String in conflictDict.iterPorts()) {
						var portToMark:Port = conflictDict.getPort(portk);
						for (prop in conflictDict.getPortConflicts(portk).iterProps()) {
							// TODO: merge them all at once instead of adding individually
							portToMark.addConflict(prop);
						}
					}
					for (var edgek:String in conflictDict.iterEdges()) {
						var edgeToMark:Edge = conflictDict.getEdge(edgek);
						for (prop in conflictDict.getEdgeConflicts(edgek).iterProps()) {
							// TODO: merge them all at once instead of adding individually
							edgeToMark.addConflict(prop);
						}
					}
					boardToTroublePoints[board.board_name] = conflictDict;
				}
			}
		}
		
		/**
		 * Call this when a box has been clicked by the user to re-simulate.
		 * @param	edgeSetId Corresponding to box clicked
		 * @param	levelToSimulate To simulate a given level, "" to simulate all in world
		 */
		public function updateOnBoxSizeChange(edgeSetId:String, levelToSimulate:String = ""):void {
			// Copy previous trouble points
			prevBoardToTroublePoints = new Dictionary();
			for (var boardName:String in boardToTroublePoints) {
				prevBoardToTroublePoints[boardName] = (boardToTroublePoints[boardName] as ConflictDictionary).clone();
			}
			
			var boardsToSim:Vector.<BoardNodes> = new Vector.<BoardNodes>();
			for (var levelName:String in network.LevelNodesDictionary) {
				if ((levelToSimulate.length == 0) || (levelName == levelToSimulate)) {
					var levelNodes:LevelNodes = network.LevelNodesDictionary[levelName] as LevelNodes;
					for (var boardName1:String in levelNodes.boardNodesDictionary) {
						var board:BoardNodes = levelNodes.boardNodesDictionary[boardName1] as BoardNodes;
						// TODO: We should not have to simulate everything, just any boards that contain this
						// edge id and boards that refer to those boards
						board.changed_since_last_sim = true;
						boardsToSim.push(board);
					}
				}
			}
			var boards_in_prog:Vector.<BoardNodes> = new Vector.<BoardNodes>();
			var boards_touched:Vector.<BoardNodes> = new Vector.<BoardNodes>();
			for each (var simBoard:BoardNodes in boardsToSim) {
				if (simBoard.changed_since_last_sim) {
					boardToTroublePoints[simBoard.board_name] = simulateBoard(simBoard, boards_in_prog, boards_touched);
				}
			}
			
			var addConflictDict:ConflictDictionary = new ConflictDictionary();
			var removeConflictDict:ConflictDictionary = new ConflictDictionary();
			var portk:String, edgek:String, prop:String;
			for each (var boardTouched:BoardNodes in boards_touched) {
				var newConflictDict:ConflictDictionary = boardToTroublePoints[boardTouched.board_name] as ConflictDictionary;
				var prevConflictDict:ConflictDictionary = prevBoardToTroublePoints[boardTouched.board_name] as ConflictDictionary;
				// check new conflict, if they weren't in prevConflictDict then they are new and need to be added
				for (portk in newConflictDict.iterPorts()) {
					var port:Port = newConflictDict.getPort(portk);
					var newPortConfl:PropDictionary = newConflictDict.getPortConflicts(portk);
					var oldPortConfl:PropDictionary = prevConflictDict.getPortConflicts(portk);
					for (prop in newPortConfl.iterProps()) {
						if (oldPortConfl == null) {
							addConflictDict.addPortConflict(port, prop);
							continue;
						}
						if (oldPortConfl.hasProp(prop)) {
							// If appears in new and old, remove from old so that only removed conflict props are there
							oldPortConfl.setProp(prop, false);
						} else {
							addConflictDict.addPortConflict(port, prop);
						}
					}
				}
				for (edgek in newConflictDict.iterEdges()) {
					var edge:Edge = newConflictDict.getEdge(edgek);
					var newEdgeConfl:PropDictionary = newConflictDict.getEdgeConflicts(edgek);
					var oldEdgeConfl:PropDictionary = prevConflictDict.getEdgeConflicts(edgek);
					for (prop in newEdgeConfl.iterProps()) {
						if (oldEdgeConfl == null) {
							addConflictDict.addEdgeConflict(edge, prop);
							continue;
						}
						if (oldEdgeConfl.hasProp(prop)) {
							// If appears in new and old, remove from old so that only removed conflict props are there
							oldEdgeConfl.setProp(prop, false);
						} else {
							addConflictDict.addEdgeConflict(edge, prop);
						}
					}
				}
				// Now all that's left in prevConflictDict should be conflicts that should be removed
				// Mark added conflicts
				for (portk in addConflictDict.iterPorts()) {
					for (prop in addConflictDict.getPortConflicts(portk).iterProps()) {
						// TODO: merge them all at once instead of adding individually
						//trace("->adding " + portk);
						addConflictDict.getPort(portk).addConflict(prop);
					}
				}
				for (edgek in addConflictDict.iterEdges()) {
					for (prop in addConflictDict.getEdgeConflicts(edgek).iterProps()) {
						// TODO: merge them all at once instead of adding individually
						//trace("->adding " + edgek);
						addConflictDict.getEdge(edgek).addConflict(prop);
					}
				}
				
				// Un-mark removed conflicts
				for (portk in prevConflictDict.iterPorts()) {
					for (prop in prevConflictDict.getPortConflicts(portk).iterProps()) {
						// TODO: merge them all at once instead of removing individually
						//trace("->removing " + portk);
						prevConflictDict.getPort(portk).removeConflict(prop);
					}
				}
				for (edgek in prevConflictDict.iterEdges()) {
					for (prop in prevConflictDict.getEdgeConflicts(edgek).iterProps()) {
						// TODO: merge them all at once instead of removing individually
						//trace("->removing " + edgek);
						prevConflictDict.getEdge(edgek).removeConflict(prop);
					}
				}
			}
		}
		
		/**
		 * Simulates a given level and finds trouble points in the level based on 
		 * width of pipes. It is not flow sensitive.
		 * 
		 * @param	level the level to simulate
		 * @param	boards_in_progress Any boards that are already being simulated, used to avoid infinite recursion loops
		 * @return A two element array (list of Port trouble points, list of Edge trouble points)
		 */
		private function simulateBoard(sim_board:BoardNodes, boards_in_progress:Vector.<BoardNodes> = null, boards_touched:Vector.<BoardNodes> = null, simulate_recursion_boards:Boolean = true):ConflictDictionary
		{
			if (!boards_in_progress) {
				boards_in_progress = new Vector.<BoardNodes>();
			}
			if (boards_in_progress.indexOf(sim_board) == -1) {
				boards_in_progress.push(sim_board);
			}
			if (!boards_touched) {
				boards_touched = new Vector.<BoardNodes>();
			}
			if (boards_touched.indexOf(sim_board) == -1) {
				boards_touched.push(sim_board);
			}
			
			//if (DEBUG) { trace("----Simulating " + sim_board.board_name + "----"); }
			
			// When we transition to an algorithm that only traverses the edges that have changes widths (after a click), we will mark 
			// ONLY those pipes as BALL_TYPE_UNDETERMINED and then only perform collision detection below on BALL_TYPE_UNDETERMINED edges (and below)
			// For now, mark all pipes as BALL_TYPE_UNDETERMINED and recompute all
			for (var startingEdgeSetId:String in sim_board.startingEdgeDictionary) {
				var startingEdgeVec:Vector.<Edge> = sim_board.startingEdgeDictionary[startingEdgeSetId] as Vector.<Edge>;
				for each (var startingEdge:Edge in startingEdgeVec) {
					startingEdge.setUndeterminedAndRecurse();
				}
			}
			
			// This will tell us in the end whether we have an infinite recursision problem
			var initial_ghost_outputs:uint = 0;
			var total_outputs:uint = 0;
			var outgoing_vec:Vector.<Edge>;
			for each (outgoing_vec in sim_board.outgoingEdgeDictionary) {
				for each (var oEdge:Edge in outgoing_vec) {
					total_outputs++;
					if ( (oEdge.exit_ball_type == Edge.BALL_TYPE_UNDETERMINED) || 
						(oEdge.exit_ball_type == Edge.BALL_TYPE_GHOST) ) {
						initial_ghost_outputs++;
					}
				}
			}
			//if (DEBUG) { trace("  ["+sim_board.board_name+"] Ghost outputs/total: " + initial_ghost_outputs + "/" + total_outputs); }
			
			var conflictDict:ConflictDictionary = new ConflictDictionary();
			
			var dict:Dictionary = sim_board.startingEdgeDictionary; 
			if (isEmpty(dict)) { // Nothing to compute on "Start" level. 
				boards_in_progress.splice(boards_in_progress.indexOf(sim_board), 1);
				return conflictDict;				
			}
			
			//shift() = dequeue, push() = enqueue
			var queue:Vector.<Edge> = new Vector.<Edge>();
			
			var recursive_boards:Vector.<BoardNodes> = new Vector.<BoardNodes>();
			//check starting edges to see if they come out of a subnetwork and add them to the queue
			for each (var v:Vector.<Edge> in dict) {
				for each (var e:Edge in v) {
					// check for SUBNETWORK width mismatch - this is the case when a SUBNETWORK edge flows into this edge (e)
					switch (e.from_node.kind) {
						case NodeTypes.INCOMING:
							// For now we've agreed to make this a pipe-dependent ball: wide for wide, small for small
							if (e.is_wide) {
								e.enter_ball_type = Edge.BALL_TYPE_WIDE;
							} else {
								e.enter_ball_type = Edge.BALL_TYPE_NARROW;
							}
							queue.push(e);
							break;
						case NodeTypes.START_LARGE_BALL:
							e.enter_ball_type = Edge.BALL_TYPE_WIDE;
							queue.push(e);
							break;
						case NodeTypes.START_NO_BALL:
							e.enter_ball_type = Edge.BALL_TYPE_NONE;
							queue.push(e);
							break;
						case NodeTypes.START_SMALL_BALL:
							e.enter_ball_type = Edge.BALL_TYPE_NARROW;
							queue.push(e);
							break;
						case NodeTypes.START_PIPE_DEPENDENT_BALL:
							e.enter_ball_type = e.is_wide ? Edge.BALL_TYPE_WIDE : Edge.BALL_TYPE_NARROW;
							queue.push(e);
							break;
						case NodeTypes.SUBBOARD:
							var subnet_node:SubnetworkNode = e.from_node as SubnetworkNode;
							//if (DEBUG) { trace("  ["+sim_board.board_name+"] Found subboard starting edge: " + e.edge_id + " board:" + subnet_node.associated_board.board_name); }
							var changedSinceLastSim:Boolean = false;
							var useDefaultBoardOutputs:Boolean = true;
							if (subnet_node.associated_board && (!subnet_node.associated_board_is_external || SIMULATE_EXTERNAL_BOARDS)) {
								var subnet_board:BoardNodes = subnet_node.associated_board;
								useDefaultBoardOutputs = false;
								if (subnet_board.changed_since_last_sim) {
									changedSinceLastSim = true;
									// If this board hasn't been simulated yet
									if (boards_in_progress.indexOf(subnet_board) > -1) {
										// If we're already simulating this, a recursive case is found. For this, use the "default" result, meaning output ghost balls
										if (recursive_boards.indexOf(subnet_board) == -1) {
											recursive_boards.push(subnet_board);
											//if (DEBUG) { trace("  ["+sim_board.board_name+"] Adding " + subnet_board.board_name + " to recursive_boards list"); }
										}
									} else {
										// If we haven't begun simulating this yet, do so now and store results in dictionary
										//if (DEBUG) { trace("  ["+sim_board.board_name+"] Simulate this subboard: " + subnet_board.board_name); }
										boardToTroublePoints[subnet_board.board_name] = simulateBoard(subnet_board, boards_in_progress, boards_touched, simulate_recursion_boards);
									}
								} else {
									changedSinceLastSim = false;
								}
							}
							// Now we can initialize the ball types for pipes on this board flowing out of the subnet_board
							for each (var my_port:Port in e.from_node.outgoing_ports) {
							var subnet_port:SubnetworkPort = (my_port as SubnetworkPort);
							// Mark the ball types on *this* board based on the outputs of the subnet_board (undetermined get set as ghost balls)
							var out_type:uint;
							if (!useDefaultBoardOutputs && subnet_port.linked_subnetwork_edge) {
								out_type = subnet_port.linked_subnetwork_edge.exit_ball_type;
								subnet_port.default_ball_type = out_type; // update best-known default
							} else {
								out_type = subnet_port.default_ball_type;
							}
							switch (out_type) {
								case Edge.BALL_TYPE_WIDE:
									subnet_port.edge.enter_ball_type = Edge.BALL_TYPE_WIDE;
									break;
								case Edge.BALL_TYPE_NONE:
									subnet_port.edge.enter_ball_type = Edge.BALL_TYPE_NONE;
									break;
								case Edge.BALL_TYPE_WIDE_AND_NARROW:
									subnet_port.edge.enter_ball_type = Edge.BALL_TYPE_WIDE_AND_NARROW;
									break;
								case Edge.BALL_TYPE_NARROW:
									subnet_port.edge.enter_ball_type = Edge.BALL_TYPE_NARROW;
									break;
								case Edge.BALL_TYPE_UNDETERMINED:
								case Edge.BALL_TYPE_GHOST:
									//if (DEBUG) { trace("  ["+sim_board.board_name+"] Ball coming out of subboard is UNDETERMINED or GHOST. changedSinceLastSim=" + changedSinceLastSim); }
									if (!changedSinceLastSim) {
										// Unable to make any progress (mutually recursive boards where no new outputs
										// were simulated. In this case, give up and output no ball
										subnet_port.edge.enter_ball_type = Edge.BALL_TYPE_NONE;
										//if (DEBUG) { trace("  [" + sim_board.board_name + "] Assigning subnet outgoing edge: " + subnet_port.edge.edge_id + " BALL_TYPE_NONE"); }
									} else {
										subnet_port.edge.enter_ball_type = Edge.BALL_TYPE_GHOST;
									}
									break;
								default:
									throw new Error("Flow sensitive PipeSimulator: Ball type not defined - " + out_type);
									break;
							}
						}
							queue.push(e);
							break;
						default:
							//trace("FOUND a " + e.from_node.kind);
							break;
					}
					
				}
			}
			
			// This is used for the case of MERGE where one pipe has been traversed but the other hasn't, in this case push to end of queue and try again later
			var edges_awaiting_others:Vector.<Edge> = new Vector.<Edge>();
			
			while ( queue.length != 0 ) { // traverse all the pipes
				var edge:Edge = queue.shift(); //dequeue
				if (edge.enter_ball_type == Edge.BALL_TYPE_UNDETERMINED) {
					throw new Error("Flow sensitive PipeSimulator: Traversed to edge where we begin with ball_type == BALL_TYPE_UNDETERMINED. Cannot proceed.");
				}
				
				// Move from top of this edges's pipe to the bottom
				// If there's a pinch point, remove any large balls and insert a trouble point
				var outgoing_ball_type:uint = edge.enter_ball_type;
				if (edge.has_buzzsaw) {
					// Top of pipe has a Buzzsaw. That means pass any small balls through, otherwise no balls
					switch (edge.enter_ball_type) {
						case Edge.BALL_TYPE_NONE:
							outgoing_ball_type = Edge.BALL_TYPE_NONE;
							break;
						case Edge.BALL_TYPE_WIDE:
						case Edge.BALL_TYPE_NARROW:
						case Edge.BALL_TYPE_WIDE_AND_NARROW:
							outgoing_ball_type = Edge.BALL_TYPE_NARROW;
							break;
						case Edge.BALL_TYPE_GHOST:
							outgoing_ball_type = Edge.BALL_TYPE_GHOST;
							break;
						default:
							throw new Error("Flow sensitive PipeSimulator: Ball type not defined - " + edge.enter_ball_type);
							break;
					}
				} else {
					// Top of pipe has no buzzsaw, fail any wide balls and pass through any narrow/pinched pipes
					switch (edge.enter_ball_type) {
						case Edge.BALL_TYPE_NONE:
						case Edge.BALL_TYPE_NARROW:
						case Edge.BALL_TYPE_GHOST:
							outgoing_ball_type = edge.enter_ball_type;
							break;
						case Edge.BALL_TYPE_WIDE:
							if (edge.has_pinch || !edge.is_wide) {
								conflictDict.addEdgeConflict(edge, PropDictionary.PROP_NARROW);
								outgoing_ball_type = Edge.BALL_TYPE_NONE;
							} else {
								outgoing_ball_type = Edge.BALL_TYPE_WIDE;
							}
							break;
						case Edge.BALL_TYPE_WIDE_AND_NARROW:
							if (edge.has_pinch || !edge.is_wide) {
								conflictDict.addEdgeConflict(edge, PropDictionary.PROP_NARROW);
								outgoing_ball_type = Edge.BALL_TYPE_NARROW;
							} else {
								outgoing_ball_type = Edge.BALL_TYPE_WIDE_AND_NARROW;
							}
							break;
						default:
							throw new Error("Flow sensitive PipeSimulator: Ball type not defined - " + edge.enter_ball_type);
							break;
					}
				}
				// If already simulated, move on
				if (edge.exit_ball_type == outgoing_ball_type) {
					continue;
				}
				edge.exit_ball_type = outgoing_ball_type;
				
				// At this point we have determined what type of ball should be output of this edge, now process next node
				
				var node:Node = edge.to_node;
				
				switch (node.kind) {
					//possible traversal ends
					case NodeTypes.OUTGOING : { } 	//traversal ends
						break;
					
					case NodeTypes.END: { } 		//traversal ends
						break;
					
					case NodeTypes.SUBBOARD : {
						// This is the case when this edge ("edge") flows into a SUBNETWORK edge
						// Problem only if wide ball flows into narrow pipe
						var subnet_incoming_edge:Edge = (edge.to_port as SubnetworkPort).linked_subnetwork_edge;
						var subnet_is_external:Boolean = (node as SubnetworkNode).associated_board_is_external;
						var subnet_stub_is_wide:Boolean;
						if (subnet_incoming_edge && (!subnet_is_external || SIMULATE_EXTERNAL_BOARDS)) {
							subnet_stub_is_wide = subnet_incoming_edge.is_wide;
						} else {
							subnet_stub_is_wide = (edge.to_port as SubnetworkPort).default_is_wide;
						}
						if (!subnet_stub_is_wide) {
							switch (edge.exit_ball_type) {
								case Edge.BALL_TYPE_WIDE:
								case Edge.BALL_TYPE_WIDE_AND_NARROW:
									conflictDict.addPortConflict(edge.to_port, PropDictionary.PROP_NARROW);
									break;
							}
						}
					}
						break;
					
					case NodeTypes.MERGE : {
						var other_edge:Edge = getOtherMergeEdge(edge);
						if (other_edge.exit_ball_type == Edge.BALL_TYPE_UNDETERMINED) {
							// If the other edge has not made a determination yet, push this edge to the back of the queue and try later
							if (queue.indexOf(edge) == -1) queue.push(edge);
							if (edges_awaiting_others.indexOf(edge) == -1) edges_awaiting_others.push(edge);
						} else if (node.outgoing_ports.length == 1) {
							var outgoingMergeEdge:Edge = node.outgoing_ports[0].edge;
							// Merge the ball types - narrow if either incoming ball is narrow, same with wide
							var narrow_ball_into_next_edge:Boolean = (
								(edge.exit_ball_type == Edge.BALL_TYPE_NARROW) ||
								(edge.exit_ball_type == Edge.BALL_TYPE_WIDE_AND_NARROW) ||
								(other_edge.exit_ball_type == Edge.BALL_TYPE_NARROW) ||
								(other_edge.exit_ball_type == Edge.BALL_TYPE_WIDE_AND_NARROW)
							);
							var wide_ball_into_next_edge:Boolean = (
								(edge.exit_ball_type == Edge.BALL_TYPE_WIDE) ||
								(edge.exit_ball_type == Edge.BALL_TYPE_WIDE_AND_NARROW) ||
								(other_edge.exit_ball_type == Edge.BALL_TYPE_WIDE) ||
								(other_edge.exit_ball_type == Edge.BALL_TYPE_WIDE_AND_NARROW)
							);
							if (wide_ball_into_next_edge && narrow_ball_into_next_edge) {
								outgoingMergeEdge.enter_ball_type = Edge.BALL_TYPE_WIDE_AND_NARROW;
							} else if (wide_ball_into_next_edge) {
								outgoingMergeEdge.enter_ball_type = Edge.BALL_TYPE_WIDE;
							} else if (narrow_ball_into_next_edge) {
								outgoingMergeEdge.enter_ball_type = Edge.BALL_TYPE_NARROW;
							} else if ( (edge.exit_ball_type == Edge.BALL_TYPE_GHOST) 
								|| (other_edge.exit_ball_type == Edge.BALL_TYPE_GHOST) ) {
								// TODO: we don't cover the none + ghost case, what should that output? For now, output ghost
								outgoingMergeEdge.enter_ball_type = Edge.BALL_TYPE_GHOST;
							} else {
								outgoingMergeEdge.enter_ball_type = Edge.BALL_TYPE_NONE;
							}
							// Remove edges from waiting list if they're in there
							if (edges_awaiting_others.indexOf(edge) > -1) {
								edges_awaiting_others.splice(edges_awaiting_others.indexOf(edge), 1);
							}
							if (edges_awaiting_others.indexOf(other_edge) > -1) {
								edges_awaiting_others.splice(edges_awaiting_others.indexOf(other_edge), 1);
							}
							if (queue.indexOf(outgoingMergeEdge) == -1) queue.push(outgoingMergeEdge);//enqueue
						} else {
							//trace("WARNING! Found MERGE node (node_id:" + node.node_id + ") with " + node.outgoing_ports.length + " output ports.");
							// Remove edges from waiting list if they're in there
							if (edges_awaiting_others.indexOf(edge) > -1) {
								edges_awaiting_others.splice(edges_awaiting_others.indexOf(edge), 1);
							}
							if (edges_awaiting_others.indexOf(other_edge) > -1) {
								edges_awaiting_others.splice(edges_awaiting_others.indexOf(other_edge), 1);
							}
						}
					}
						break;
					
					//other nodes
					case NodeTypes.SPLIT : {
						node.outgoing_ports[0].edge.enter_ball_type = edge.exit_ball_type;
						if (queue.indexOf(node.outgoing_ports[0].edge) == -1) queue.push(node.outgoing_ports[0].edge);//enqueue
						node.outgoing_ports[1].edge.enter_ball_type = edge.exit_ball_type;
						if (queue.indexOf(node.outgoing_ports[1].edge) == -1) queue.push(node.outgoing_ports[1].edge);//enqueue
					}
						break;
					
					case NodeTypes.BALL_SIZE_TEST : {
						// new implementation: always output a small ball down the small pipe
						// and a large ball down the wide pipe, rather that "sorting" the balls
						for each (var outgoing_port:Port in node.outgoing_ports) {
							if (outgoing_port.edge.is_wide) {
								outgoing_port.edge.enter_ball_type = Edge.BALL_TYPE_WIDE;
							} else {
								outgoing_port.edge.enter_ball_type = Edge.BALL_TYPE_NARROW;
							}
							if (queue.indexOf(outgoing_port.edge) == -1) queue.push(outgoing_port.edge); //enqueue
						}
					}
						break;
					
					case NodeTypes.GET : {
						// Process the GET node when the "VALUE" edge is reached
						if ((node as MapGetNode).valueEdge == edge) {
							node.outgoing_ports[0].edge.enter_ball_type = (node as MapGetNode).getOutputBallType();
							if (queue.indexOf(node.outgoing_ports[0].edge) == -1) queue.push(node.outgoing_ports[0].edge); //enqueue
						}
					}
						break;
					
					case NodeTypes.CONNECT : {
						// Apparently there is a possibility that the CONNECT node doesn't have an output
						if (node.outgoing_ports.length == 1) {
							node.outgoing_ports[0].edge.enter_ball_type = edge.exit_ball_type;
							if (queue.indexOf(node.outgoing_ports[0].edge) == -1) queue.push(node.outgoing_ports[0].edge); //enqueue
						} else {
							//trace("WARNING! Found CONNECT node (node_id:" + node.node_id + ") with " + node.outgoing_ports.length + " output ports.");
						}
					}
						break;
					
					default : {
						// Totally random observation: When this next statement was output as a trace() it caused a stack underflow error when compiled with FlashDevelop,
						// when changed to an Error, it works fine.
						throw new Error("Flow sensitive PipeSimulator missed a kind of node: " + node.kind);
					}
				}
				
				if ((queue.length > 0) && (queue.length <= edges_awaiting_others.length)) {
					// If we only have edges that are awaiting others, perform any merges with at least one determined ball type
					// exiting. Perform on non-ghost exiting ball edges first (if any), then proceed to ghost ball exiting edges
					var non_ghost_edge:Edge, ghost_edge:Edge;
					for (var i:int = 0; i < edges_awaiting_others.length; i++) {
						if (edges_awaiting_others[i].exit_ball_type != Edge.BALL_TYPE_UNDETERMINED) {
							if (edges_awaiting_others[i].exit_ball_type != Edge.BALL_TYPE_GHOST) {
								non_ghost_edge = edges_awaiting_others[i];
								break;
							} else if (ghost_edge == null) {
								ghost_edge = edges_awaiting_others[i];
							}
						}
					}
					// proceed with non-ghost if any
					var edge_to_proceed:Edge = (non_ghost_edge != null) ? non_ghost_edge : ghost_edge;
					if (edge_to_proceed == null) {
						// If only edges with undetermined ball type, throw Error
						throw new Error("Flow sensitive PipeSimulator: Stuck with only edges that require further traversal to proceed "
							+ "(edges that are entering a MERGE node where the other pipe entering hasn't reached this point yet).");
						queue = new Vector.<Edge>();
					}
					// Mark other edge's output as ghost (or whatever input ball type is if not undetermined)
					var other_merge_edge:Edge = getOtherMergeEdge(edge_to_proceed);
					if (other_merge_edge.enter_ball_type == Edge.BALL_TYPE_UNDETERMINED) {
						other_merge_edge.enter_ball_type = Edge.BALL_TYPE_GHOST;
					}
					// enqueue other edge, move to top of queue (remove if in queue, then add to beginning)
					if (queue.indexOf(other_merge_edge) > -1) {
						queue.splice(queue.indexOf(other_merge_edge), 1);
					}
					queue.unshift(other_merge_edge);
				}
			}
			
			var latest_ghost_outputs:uint = 0;
			// Check for any ghost outputs on *this* board
			for each (outgoing_vec in sim_board.outgoingEdgeDictionary) {
				for each (var oEdge1:Edge in outgoing_vec) {
					if ( (oEdge1.exit_ball_type == Edge.BALL_TYPE_UNDETERMINED) || 
						(oEdge1.exit_ball_type == Edge.BALL_TYPE_GHOST) ) {
						latest_ghost_outputs++;
					}
				}
			}
			//if (DEBUG) { trace("  ["+sim_board.board_name+"] Latest ghost outputs for " + sim_board.board_name + " = " + latest_ghost_outputs); }
			
			/* Here we're looping over any subnetwork board that has pipes that output into this board and was already being simulated (recursive case).
			* We want to:
			* 	1) Check if there are any "ghost" or "undetermined" outputs. If there are none, this board is ready to be used.
			* 		a) If there are any ghost outputs, 
			*/
			var new_ghost_outputs:uint = 0;
			while (simulate_recursion_boards && (latest_ghost_outputs > 0)) {
				for each (var recursive_board:BoardNodes in recursive_boards) {
					// Re-simulate this board, but don't use the current stack of recursive calls, this should allow the top-level
					// board to see the updated output ball types
					//if (DEBUG) { trace("  ["+sim_board.board_name+"] Recursively simulating " + recursive_board.board_name + " within " + sim_board.board_name); }
					boardToTroublePoints[recursive_board.board_name] = simulateBoard(recursive_board, null, null, false);
					new_ghost_outputs = 0;
					// Check for any ghost outputs on *this* board
					for each (outgoing_vec in sim_board.outgoingEdgeDictionary) {
						for each (var oEdge2:Edge in outgoing_vec) {
							if ( (oEdge2.exit_ball_type == Edge.BALL_TYPE_UNDETERMINED) || 
								(oEdge2.exit_ball_type == Edge.BALL_TYPE_GHOST) ) {
								new_ghost_outputs++;
							}
						}
					}
					//if (DEBUG) { trace("  ["+sim_board.board_name+"] New ghost outputs = " + new_ghost_outputs); }
					// If we reach zero ghost outputs, that's good enough for this level - exit the routine
					if (new_ghost_outputs == 0) {
						break; // TODO: Could this be an imcomplete solution? For example, could there be narrow balls flowing down wide pipes that we missed?
					}
				}
				
				if (new_ghost_outputs >= latest_ghost_outputs) {
					// We aren't making progress, infinite loop suspected. Just assign outputs and continue
					for each (outgoing_vec in sim_board.outgoingEdgeDictionary) {
						for each (var oEdge3:Edge in outgoing_vec) {
							if ( (oEdge3.exit_ball_type == Edge.BALL_TYPE_UNDETERMINED) || 
								(oEdge3.exit_ball_type == Edge.BALL_TYPE_GHOST) ) {
								if (oEdge3.is_wide) {
									oEdge3.exit_ball_type == Edge.BALL_TYPE_WIDE;
								} else {
									oEdge3.exit_ball_type == Edge.BALL_TYPE_NARROW;
								}
							}
						}
					}
					new_ghost_outputs = 0;
				}
				
				latest_ghost_outputs = new_ghost_outputs;
			}
			
			// Remove sim_board from boards_in_progress, this board's outgoing exit ball types have been updated at this point
			boards_in_progress.splice(boards_in_progress.indexOf(sim_board), 1);
			sim_board.changed_since_last_sim = false;
			
			//if (DEBUG) { trace("----Finished simulating board: " + sim_board.board_name + "----"); }
			
			return conflictDict;
		}
		
		private static function getOtherMergeEdge(edge:Edge):Edge
		{
			var node:Node = edge.to_node;
			var other_edge:Edge;
			if (node.incoming_ports[0] == edge.to_port) {
				return node.incoming_ports[1].edge;
			} else if (node.incoming_ports[1] == edge.to_port) {
				return node.incoming_ports[0].edge;
			} else {
				throw new Error("MERGE node encountered which didn't link to the edge's port. Edge: " + edge.edge_id);
			}
			return null;
		}
		
		private static function cloneDict(dict:Dictionary):Dictionary
		{
			var newDict:Dictionary = new Dictionary();
			for (var oldKey:Object in dict) {
				newDict[oldKey] = dict[oldKey];
			}
			return newDict;
		}
		
		/* Checks if a given dictionary is empty or not. 
		* 
		* @param: dict, a dictionary.
		* @returns: a boolean, true if the dictionary is empty, false otherwise.
		*/
		public function isEmpty(dict:Dictionary):Boolean {
			var empty:Boolean = true;
			
			for (var key:Object in dict)
			{
				empty = false;
				break;
			}
			return empty;
		}
		
	}
}