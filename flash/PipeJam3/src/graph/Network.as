package graph 
{
	import utils.NameObfuscater;
	import utils.XString;
	
	import flash.utils.Dictionary;
	
	public class Network 
	{
		/**
		 * Collection of Nodes (and their associated edges contained within) arranged by level. This is what is created by LevelLayout when after XML input is processed.
		 */
		public var world_name:String;
		public var original_world_name:String;
		public var obfuscator:NameObfuscater;
		
		/** Dictionary mapping edge ids to edges */
		//static because edges are created before the network object
		public static var edgeDictionary:Dictionary = new Dictionary();
		
		/** This is a dictionary of LevelNodes, which is a dictionary of BoardNodes, which is a dictionary of Nodes; INDEXED BY LEVEL NAME, BOARD NAME, AND NODE ID, RESPECTIVELY */
		public var LevelNodesDictionary:Dictionary = new Dictionary();
		public var levelNodeNameArray:Array = new Array();
		public var globalBoardNameToBoardNodesDictionary:Dictionary = new Dictionary();
		
		public function Network(_original_world_name:String, _world_index:uint = 1, _obfuscate_names:Boolean = true) 
		{
			original_world_name = _original_world_name;
			if (_obfuscate_names) {
				world_name = "World " + _world_index;
				var my_seed:int = XString.stringToInt(world_name);
				obfuscator = new NameObfuscater(my_seed);
			} else {
				world_name = _original_world_name;
			}
		}
		
		public function addNode(_node:Node, _original_board_name:String, _original_level_name:String):void {
			var new_level_name:String = _original_level_name;
			if (obfuscator) {
				new_level_name = obfuscator.getLevelName(_original_level_name);
			}
			if (LevelNodesDictionary[new_level_name] == null) {
				LevelNodesDictionary[new_level_name] = new LevelNodes(_original_level_name, obfuscator);
				levelNodeNameArray.push(new_level_name);
			}
			
			(LevelNodesDictionary[new_level_name] as LevelNodes).addNode(_node, _original_board_name);
		}
		
		public function addLevel(level:LevelNodes):void
		{
			if (LevelNodesDictionary[level.level_name] == null) {
				LevelNodesDictionary[level.level_name] = level;
				levelNodeNameArray.push(level.level_name);
				for (var obfusBoardName:String in level.boardNodesDictionary) {
					var boardNodes:BoardNodes = level.boardNodesDictionary[obfusBoardName];
					if (globalBoardNameToBoardNodesDictionary.hasOwnProperty(boardNodes.original_board_name)) {
						throw new Error("Duplicate board name found for level: " + level.original_level_name + " board:" + boardNodes.original_board_name);
					}
					globalBoardNameToBoardNodesDictionary[boardNodes.original_board_name] = boardNodes;
				}
			} else {
				throw new Error("Duplicate Level entries found for level: " + level.original_level_name);
			}
		}
		
		public function attachExternalSubboardNodesToBoardNodes():void
		{
			for (var levelName:String in LevelNodesDictionary) {
				var levelNodes:LevelNodes = LevelNodesDictionary[levelName] as LevelNodes;
				for (var boardName:String in levelNodes.boardNodesDictionary) {
					var boardNodes:BoardNodes = levelNodes.boardNodesDictionary[boardName] as BoardNodes;
					for each (var externalSubnetNode:SubnetworkNode in boardNodes.subnetNodesToAssociate) {
						externalSubnetNode.associated_board_is_external = true;
						if (globalBoardNameToBoardNodesDictionary.hasOwnProperty(externalSubnetNode.subboard_name)) {
							externalSubnetNode.associated_board = globalBoardNameToBoardNodesDictionary[externalSubnetNode.subboard_name] as BoardNodes;
						} else {
							// If the board doesn't exist in this world, mark as null
							externalSubnetNode.associated_board = null;
						}
					}
					boardNodes.subnetNodesToAssociate = new Vector.<SubnetworkNode>();
				}
			}
		}
		
		public function getNode(_original_level_name:String, _original_board_name:String, _node_id:String):Node {
			var new_level_name:String = obfuscator.getLevelName(_original_level_name);
			var new_board_name:String = obfuscator.getBoardName(_original_board_name, _original_level_name);
			if (LevelNodesDictionary[new_level_name] != null) {
				if ((LevelNodesDictionary[new_level_name] as LevelNodes).boardNodesDictionary[new_board_name] != null) {
					return ((LevelNodesDictionary[new_level_name] as LevelNodes).boardNodesDictionary[new_board_name] as BoardNodes).nodeDictionary[_node_id];
				}
			}
			return null;
		}
		
		/**
		 * Returns the board in this world of the given name
		 * @param	_name Name of the desired board
		 * @return The board with the name input to this function
		 */
		public function getOriginalBoardName(_name:String):String {
			if (_name == null) {
				return null;
			}
			if (_name.length == 0) {
				return null;
			}
			var new_name:String = _name;
			if (obfuscator) {
				if (obfuscator.boardNameExists(_name)) {
					new_name = obfuscator.getBoardName(_name, "");
				} else {
					return null;
				}
			}
			
			return new_name;
		}
		
		//collect all outgoing edges belonging to nodes that start balls, and then
		//trace downward, marking each edge with a pointer to that topmost edge.
		public function setTopMostEdgeInEdges():void
		{
			//map from edge id to edge
			var topMostEdgeSet:Dictionary = new Dictionary;
			
			for(var edgeID:String in edgeDictionary)
			{
				var edge:Edge = edgeDictionary[edgeID];
				if(edge.from_node.kind == NodeTypes.START_PIPE_DEPENDENT_BALL ||
					edge.from_node.kind == NodeTypes.START_LARGE_BALL ||
					edge.from_node.kind == NodeTypes.START_SMALL_BALL ||
					edge.from_node.kind == NodeTypes.INCOMING)
				{
					topMostEdgeSet[edge.edge_id] = edge;
				}
			}
			
			for(var topEdgeID:String in topMostEdgeSet)
			{
				var topEdge:Edge = topMostEdgeSet[topEdgeID];
				markChildrenWithTopEdges(topEdge, topEdge);
			}
		}
		
		//mark current, and then recursively call on outgoing edges
		public function markChildrenWithTopEdges(topEdge:Edge, currentEdge:Edge):void
		{
			//if we aren't in the dictionary currently, add ourselves
			if(currentEdge.topmostEdgeDictionary[topEdge.edge_id] == null)
			{
				currentEdge.topmostEdgeIDArray[currentEdge.topmostEdgeIDArray.length] = topEdge.edge_id;
				currentEdge.topmostEdgeDictionary[topEdge.edge_id] = topEdge;
				if(currentEdge.topmostEdgeIDArray.length > 1)
					var debugVar:uint = 3;
			}
			var node:Node = currentEdge.to_node;
			for(var outgoingPortID:String in node.outgoing_ports)
			{
				var outgoingPort:Port = node.outgoing_ports[outgoingPortID];
				var outgoingEdge:Edge = outgoingPort.edge;
				
				
				markChildrenWithTopEdges(topEdge, outgoingEdge);
			}
		}
		
		public function updateEdgeSetWidth(edgeSet:EdgeSetRef, isWide:Boolean):void
		{
			for each (var edgeID:String in edgeSet.edge_ids)
			{
				var edge:Edge = edgeDictionary[edgeID];
				edge.updateEdgeWidth(isWide);
			}
		}
		
		
		
	}

}