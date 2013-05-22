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
	import graph.SubnetworkNode;
	import graph.SubnetworkPort;
	
	import flash.external.ExternalInterface;
	import flash.utils.Dictionary;
	
	/**
	 * The PipeSimulator class calculates and stores where trouble points
	 * can occur in the game, based on the current pipe configuration.
	 * 
	 * Trouble points can be either Nodes or Edges. 
	 * 
	 * A trouble point Node can be, for example, a MERGE node where a wide
	 * pipe flows into a narrow pipe.
	 * 
	 * A trouble edge can be, for example, an edge on a wide chute with a 
	 * pinch point. Other trouble edges can happen flowing into and flowing
	 * out of subnetworks. 
	 * 
	 * @author Steph
	 */
	public class PipeSimulator 
	{
		/** True to use simulation results from external board calls (outside of the current level) on current board */
		private static const SIMULATE_EXTERNAL_BOARDS:Boolean = false;
		
		/** True to mark both the incoming wide ball port AND outgoing narrow port, False to only mark incoming port */
		private static const MARK_OUTGOING_PORT_TROUBLE_POINTS:Boolean = false;
		
		/* The world in which the PipeSimulator detects trouble points */
		private var network:Network;
		
		/* A map from boardname to an Array that contains the trouble points 
		 * associated with that level. 
		 * 
		 * The Array has exactly two elements. The first element is a Dictionary 
		 * of Port trouble points. The second is a Dictionary of Edge trouble points.
		 */
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
					var tpArr:Array = simulateBoard(board, boards_in_prog);
					var portTpDict:Dictionary = tpArr[0] as Dictionary;
					var edgeTpDict:Dictionary = tpArr[1] as Dictionary;
					for (var portId:String in portTpDict) {
						var portToMark:Port = portTpDict[portId] as Port;
						portToMark.has_error = true;
					}
					for (var edgeId:String in edgeTpDict) {
						var edgeToMark:Edge = edgeTpDict[edgeId] as Edge;
						edgeToMark.has_error = true;
					}
					boardToTroublePoints[board.board_name] = tpArr;
				}
			}
		}
		
		public function getAllTroublePointsByBoard(board:BoardNodes):Array {
			return boardToTroublePoints[board.board_name];
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
				var tpArr:Array = boardToTroublePoints[boardName] as Array;
				var portTpDict:Dictionary = tpArr[0] as Dictionary;
				var edgeTpDict:Dictionary = tpArr[1] as Dictionary;
				var portTpDictCopy:Dictionary = cloneDict(portTpDict);
				var edgeTpDictCopy:Dictionary = cloneDict(edgeTpDict);
				var tpArrCopy:Array = new Array(portTpDictCopy, edgeTpDictCopy);
				prevBoardToTroublePoints[boardName] = tpArrCopy;
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
			
			var newEdgeTp:Vector.<Edge> = new Vector.<Edge>();
			var newPortTp:Vector.<Port> = new Vector.<Port>();
			var removeEdgeTp:Vector.<Edge> = new Vector.<Edge>();
			var removePortTp:Vector.<Port> = new Vector.<Port>();
			for each (var boardTouched:BoardNodes in boards_touched) {
				var prevPortTpDict:Dictionary = (prevBoardToTroublePoints[boardTouched.board_name] as Array)[0]
				var prevEdgeTpDict:Dictionary = (prevBoardToTroublePoints[boardTouched.board_name] as Array)[1]
				var newPortTpDict:Dictionary = (boardToTroublePoints[boardTouched.board_name] as Array)[0]
				var newEdgeTpDict:Dictionary = (boardToTroublePoints[boardTouched.board_name] as Array)[1]
				// check new tp, if they weren't in old Dict then they are new
				for (var portId:String in newPortTpDict) {
					if (!prevPortTpDict.hasOwnProperty(portId)) {
						newPortTp.push(newPortTpDict[portId] as Port);
					} else {
						// get rid of this entry, since it appears in both we don't care about it
						delete prevPortTpDict[portId];
					}
				}
				for (var edgeId:String in newEdgeTpDict) {
					if (!prevEdgeTpDict.hasOwnProperty(edgeId)) {
						newEdgeTp.push(newEdgeTpDict[edgeId] as Edge);
					} else {
						// get rid of this entry, since it appears in both we don't care about it
						delete prevEdgeTpDict[edgeId];
					}
				}
				// Now all that's left in prevPortTpDict and prevEdgeTpDict should be TP that should be removed
				for (var portId1:String in prevPortTpDict) {
					if (newPortTpDict.hasOwnProperty(portId1)) {
						throw new Error("Shouldn't happen!");
					}
					removePortTp.push(prevPortTpDict[portId1] as Port);
				}
				for (var edgeId1:String in prevEdgeTpDict) {
					if (newEdgeTpDict.hasOwnProperty(edgeId1)) {
						throw new Error("Shouldn't happen!");
					}
					removeEdgeTp.push(prevEdgeTpDict[edgeId1] as Edge);
				}
			}
			
			// Un-mark removed tps
			for each (var unmarkEdge:Edge in removeEdgeTp) {
				unmarkEdge.has_error = false;
			}
			for each (var unmarkPort:Port in removePortTp) {
				unmarkPort.has_error = false;
			}
			// Mark added tps
			for each (var markEdge:Edge in newEdgeTp) {
				markEdge.has_error = true;
			}
			for each (var markPort:Port in newPortTp) {
				markPort.has_error = true;
			}
		}
		
		private static function cloneDict(dict:Dictionary):Dictionary
		{
			var newDict:Dictionary = new Dictionary();
			for (var oldKey:Object in dict) {
				newDict[oldKey] = dict[oldKey];
			}
			return newDict;
		}
		
		/**
		 * Simulates a given level and finds trouble points in the level based on 
		 * width of pipes. It is not flow sensitive.
		 * 
		 * @param	level the level to simulate
		 * @param	boards_in_progress Any boards that are already being simulated, used to avoid infinite recursion loops
		 * @return A two element array (list of Port trouble points, list of Edge trouble points)
		 */
		private function simulateBoard(sim_board:BoardNodes, boards_in_progress:Vector.<BoardNodes> = null, boards_touched:Vector.<BoardNodes> = null, simulate_recursion_boards:Boolean = true):Array
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
			
			var listPortTroublePoints:Dictionary = new Dictionary();
			var listEdgeTroublePoints:Dictionary = new Dictionary();
			
			var dict:Dictionary = sim_board.startingEdgeDictionary; 
			if (isEmpty(dict)) { // Nothing to compute on "Start" level. 
				boards_in_progress.splice(boards_in_progress.indexOf(sim_board), 1);
				
				var result:Array = new Array(2);
				result[0] = listPortTroublePoints;
				result[1] = listEdgeTroublePoints;
				return result;				
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
										}
									} else {
										// If we haven't begun simulating this yet, do so now and store results in dictionary
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
								} else {
									out_type = subnet_port.default_ball_type;
								}
								switch (out_type) {
									case Edge.BALL_TYPE_WIDE:
										if (!subnet_port.edge.is_wide) {
											addTpPort(listPortTroublePoints, subnet_port);
											subnet_port.edge.enter_ball_type = Edge.BALL_TYPE_NONE;
										} else {
											subnet_port.edge.enter_ball_type = Edge.BALL_TYPE_WIDE;
										}
									break;
									case Edge.BALL_TYPE_NONE:
										subnet_port.edge.enter_ball_type = Edge.BALL_TYPE_NONE;
									break;
									case Edge.BALL_TYPE_WIDE_AND_NARROW:
										if (!subnet_port.edge.is_wide) {
											addTpPort(listPortTroublePoints, subnet_port);
											subnet_port.edge.enter_ball_type = Edge.BALL_TYPE_NARROW;
										} else {
											subnet_port.edge.enter_ball_type = Edge.BALL_TYPE_WIDE_AND_NARROW;
										}
									break;
									case Edge.BALL_TYPE_NARROW:
										subnet_port.edge.enter_ball_type = Edge.BALL_TYPE_NARROW;
									break;
									case Edge.BALL_TYPE_UNDETERMINED:
									case Edge.BALL_TYPE_GHOST:
										if (!changedSinceLastSim) {
											throw new Error("Flow sensitive PipeSimulator: BALL_TYPE_UNDETERMINED/GHOST found for supposedly simulated board. This should not be the case");
										}
										subnet_port.edge.enter_ball_type = Edge.BALL_TYPE_GHOST;
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
					// Top of pipe has no buzzsaw, fail any wide ball pipes and pass through any narrow balls
					switch (edge.enter_ball_type) {
						case Edge.BALL_TYPE_NONE:
							outgoing_ball_type = Edge.BALL_TYPE_NONE;
						break;
						case Edge.BALL_TYPE_NARROW:
							outgoing_ball_type = Edge.BALL_TYPE_NARROW;
						break;
						case Edge.BALL_TYPE_WIDE:
							if (edge.has_pinch) {
								addTpEdge(listEdgeTroublePoints, edge);
								outgoing_ball_type = Edge.BALL_TYPE_NONE;
							} else {
								outgoing_ball_type = Edge.BALL_TYPE_WIDE;
							}
						break;
						case Edge.BALL_TYPE_WIDE_AND_NARROW:
							if (edge.has_pinch) {
								addTpEdge(listEdgeTroublePoints, edge);
								outgoing_ball_type = Edge.BALL_TYPE_NARROW;
							} else {
								outgoing_ball_type = Edge.BALL_TYPE_WIDE_AND_NARROW;
							}
						break;
						case Edge.BALL_TYPE_GHOST:
							outgoing_ball_type = Edge.BALL_TYPE_GHOST;
						break;
						default:
							throw new Error("Flow sensitive PipeSimulator: Ball type not defined - " + edge.enter_ball_type);
						break;
					}
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
						// Problem only if wide pipe flows into narrow
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
									addTpPort(listPortTroublePoints, edge.to_port);
									break;
							}
						}
					}
					break;
					
					case NodeTypes.MERGE : {
						var other_edge:Edge;
						if (node.incoming_ports[0] == edge.to_port) {
							other_edge = node.incoming_ports[1].edge;
						} else if (node.incoming_ports[1] == edge.to_port) {
							other_edge = node.incoming_ports[0].edge;
						} else {
							throw new Error("Flow sensitive PipeSimulator: MERGE node encountered which didn't link to the edge's port. Edge: " + edge.edge_id);
						}
						if (other_edge.exit_ball_type == Edge.BALL_TYPE_UNDETERMINED) {
							// If the other edge has not made a determination yet, push this edge to the back of the queue and try later
							queue.push(edge);
							if (edges_awaiting_others.indexOf(edge) == -1) {
								edges_awaiting_others.push(edge);
							}
						} else {
							var outgoingMergeEdge:Edge = node.outgoing_ports[0].edge;
							// The other edge has already been reached, proceed with collision detection
							// There is only a problem if the outgoing pipe is narrow and we have a wide ball in either incoming pipe
							var narrow_ball_into_next_edge:Boolean = ( 
								(edge.exit_ball_type == Edge.BALL_TYPE_NARROW) ||
								(edge.exit_ball_type == Edge.BALL_TYPE_WIDE_AND_NARROW) ||
								(other_edge.exit_ball_type == Edge.BALL_TYPE_NARROW) ||
								(other_edge.exit_ball_type == Edge.BALL_TYPE_WIDE_AND_NARROW)
								);
							var wide_ball_into_next_edge:Boolean = false;
							switch (edge.exit_ball_type) {
								case Edge.BALL_TYPE_WIDE:
								case Edge.BALL_TYPE_WIDE_AND_NARROW:
									if (!outgoingMergeEdge.is_wide && !outgoingMergeEdge.has_buzzsaw) {
										addTpPort(listPortTroublePoints, edge.to_port);
										if (MARK_OUTGOING_PORT_TROUBLE_POINTS) {
											addTpPort(listPortTroublePoints, outgoingMergeEdge.from_port);
										}
									} else {
										wide_ball_into_next_edge = true;
									}
								break;
							}
							switch (other_edge.exit_ball_type) {
								case Edge.BALL_TYPE_WIDE:
								case Edge.BALL_TYPE_WIDE_AND_NARROW:
									if (!outgoingMergeEdge.is_wide && !outgoingMergeEdge.has_buzzsaw) {
										addTpPort(listPortTroublePoints, other_edge.to_port);
										if (MARK_OUTGOING_PORT_TROUBLE_POINTS) {
											addTpPort(listPortTroublePoints, outgoingMergeEdge.from_port);
										}
									} else {
										wide_ball_into_next_edge = true;
									}
								break;
							}
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
							queue.push(outgoingMergeEdge); //enqueue
						}
					}
					break;
					
					//other nodes
					case NodeTypes.SPLIT : {
						// Check for wide into small condition, although I imagine the two pipes would be linked (same color, same width)
						if ( !node.outgoing_ports[0].edge.is_wide ) {
							switch (edge.exit_ball_type) {
								case Edge.BALL_TYPE_WIDE:
									addTpPort(listPortTroublePoints, edge.to_port);
									if (MARK_OUTGOING_PORT_TROUBLE_POINTS) {
										addTpPort(listPortTroublePoints, node.outgoing_ports[0]);
									}
									node.outgoing_ports[0].edge.enter_ball_type = Edge.BALL_TYPE_NONE;
								break;
								case Edge.BALL_TYPE_WIDE_AND_NARROW:
									addTpPort(listPortTroublePoints, edge.to_port);
									if (MARK_OUTGOING_PORT_TROUBLE_POINTS) {
										addTpPort(listPortTroublePoints, node.outgoing_ports[0]);
									}
									node.outgoing_ports[0].edge.enter_ball_type = Edge.BALL_TYPE_NARROW;
								break;
								default:
									node.outgoing_ports[0].edge.enter_ball_type = edge.exit_ball_type;
								break;
							}
						} else {
							node.outgoing_ports[0].edge.enter_ball_type = edge.exit_ball_type;
						}
						queue.push(node.outgoing_ports[0].edge); //enqueue
						// Check for wide into small condition, although I imagine the two pipes would be linked (same color, same width)
						if ( !node.outgoing_ports[1].edge.is_wide ) {
							switch (edge.exit_ball_type) {
								case Edge.BALL_TYPE_WIDE:
									addTpPort(listPortTroublePoints, edge.to_port);
									if (MARK_OUTGOING_PORT_TROUBLE_POINTS) {
										addTpPort(listPortTroublePoints, node.outgoing_ports[1]);
									}
									node.outgoing_ports[1].edge.enter_ball_type = Edge.BALL_TYPE_NONE;
								break;
								case Edge.BALL_TYPE_WIDE_AND_NARROW:
									addTpPort(listPortTroublePoints, edge.to_port);
									if (MARK_OUTGOING_PORT_TROUBLE_POINTS) {
										addTpPort(listPortTroublePoints, node.outgoing_ports[1]);
									}
									node.outgoing_ports[1].edge.enter_ball_type = Edge.BALL_TYPE_NARROW;
								break;
								default:
									node.outgoing_ports[1].edge.enter_ball_type = edge.exit_ball_type;
								break;
							}
						} else {
							node.outgoing_ports[1].edge.enter_ball_type = edge.exit_ball_type;
						}
						queue.push(node.outgoing_ports[1].edge); //enqueue
					}
					break;
					
					case NodeTypes.BALL_SIZE_TEST : {
						for each (var outgoing_port:Port in node.outgoing_ports) {
							if (outgoing_port.edge.is_wide) {
								// If there was a wide ball, send it down this pipe
								switch (edge.exit_ball_type) {
									case Edge.BALL_TYPE_WIDE:
									case Edge.BALL_TYPE_WIDE_AND_NARROW:
										outgoing_port.edge.enter_ball_type = Edge.BALL_TYPE_WIDE;
									break;
									default:
										outgoing_port.edge.enter_ball_type = Edge.BALL_TYPE_NONE;
									break;
								}
							} else {
								// If there was a narrow ball, send it down this pipe
								switch (edge.exit_ball_type) {
									case Edge.BALL_TYPE_NARROW:
									case Edge.BALL_TYPE_WIDE_AND_NARROW:
										outgoing_port.edge.enter_ball_type = Edge.BALL_TYPE_NARROW;
									break;
									default:
										outgoing_port.edge.enter_ball_type = Edge.BALL_TYPE_NONE;
									break;
								}
							}
							queue.push(outgoing_port.edge); //enqueue
						}
					}
					break;
					
					case NodeTypes.GET : {
						// Process the GET node when the "VALUE" edge is reached
						if ((node as MapGetNode).valueEdge == edge) {
							// Check for wide into small condition
							if ( !node.outgoing_ports[0].edge.is_wide ) {
								switch (edge.exit_ball_type) {
									case Edge.BALL_TYPE_WIDE:
									case Edge.BALL_TYPE_WIDE_AND_NARROW:
										addTpPort(listPortTroublePoints, edge.to_port);
										break;
								}
							}
							var my_exit_ball:uint = node.outgoing_ports[0].edge.enter_ball_type = (node as MapGetNode).getOutputBallType();
							if (!node.outgoing_ports[0].edge.is_wide && ((my_exit_ball == Edge.BALL_TYPE_WIDE) || (my_exit_ball == Edge.BALL_TYPE_WIDE_AND_NARROW))) {
								node.outgoing_ports[0].edge.enter_ball_type == Edge.BALL_TYPE_NONE;
								addTpPort(listPortTroublePoints, node.outgoing_ports[0]);
							} else {
								node.outgoing_ports[0].edge.enter_ball_type = my_exit_ball;
							}
							queue.push(node.outgoing_ports[0].edge); //enqueue
						}
					}
					break;
					
					case NodeTypes.CONNECT : {
						// Check for wide into small condition, although I imagine the two pipes would be linked (same color, same width)
						if ( !node.outgoing_ports[0].edge.is_wide ) {
							switch (edge.exit_ball_type) {
								case Edge.BALL_TYPE_WIDE:
									addTpPort(listPortTroublePoints, edge.to_port);
									if (MARK_OUTGOING_PORT_TROUBLE_POINTS) {
										addTpPort(listPortTroublePoints, node.outgoing_ports[0]);
									}
									node.outgoing_ports[0].edge.enter_ball_type = Edge.BALL_TYPE_NONE;
								break;
								case Edge.BALL_TYPE_WIDE_AND_NARROW:
									addTpPort(listPortTroublePoints, edge.to_port);
									if (MARK_OUTGOING_PORT_TROUBLE_POINTS) {
										addTpPort(listPortTroublePoints, node.outgoing_ports[0]);
									}
									node.outgoing_ports[0].edge.enter_ball_type = Edge.BALL_TYPE_NARROW;
								break;
								default:
									node.outgoing_ports[0].edge.enter_ball_type = edge.exit_ball_type;
								break;
							}
						} else {
							node.outgoing_ports[0].edge.enter_ball_type = edge.exit_ball_type;
						}
						queue.push(node.outgoing_ports[0].edge); //enqueue
					}
					break;
					
					default : {
						// Totally random observation: When this next statement was output as a trace() it caused a stack underflow error when compiled with FlashDevelop,
						// when changed to an Error, it works fine.
						throw new Error("Flow sensitive PipeSimulator missed a kind of node: " + node.kind);
					}
				}
				
				if ((queue.length > 0) && (queue.length <= edges_awaiting_others.length)) {
					// If we only have edges that are awaiting others, this doesn't seem right. Throw error.
					throw new Error("Flow sensitive PipeSimulator: Stuck with only edges that require further traversal to proceed "
						+ "(edges that are entering a MERGE node where the other pipe entering hasn't reached this point yet).");
					queue = new Vector.<Edge>();
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
					//trace("Recursively simulating " + recursive_board.board_name + " within " + sim_board.board_name);
					var arr:Array = simulateBoard(recursive_board, null, null, false);
					boardToTroublePoints[recursive_board.board_name] = arr;
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
			
			var result1:Array = new Array(2);
			result1[0] = listPortTroublePoints;
			result1[1] = listEdgeTroublePoints;
			return result1;
		}
		
		private static function addTpPort(tpDictionary:Dictionary, port:Port):void
		{
			tpDictionary[port.toString()] = port;
		}
		
		private static function addTpEdge(tpDictionary:Dictionary, edge:Edge):void
		{
			tpDictionary[edge.edge_id] = edge;
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