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
		
		public function addLevel(level:LevelNodes):void
		{
			//if (LevelNodesDictionary[level.level_name] == null) {
				LevelNodesDictionary[level.level_name] = level;
				levelNodeNameArray.push(level.level_name);
				for (var obfusBoardName:String in level.boardNodesDictionary) {
					var boardNodes:BoardNodes = level.boardNodesDictionary[obfusBoardName];
					if (globalBoardNameToBoardNodesDictionary.hasOwnProperty(boardNodes.original_board_name)) {
						throw new Error("Duplicate board name found for level: " + level.original_level_name + " board:" + boardNodes.original_board_name);
					}
					globalBoardNameToBoardNodesDictionary[boardNodes.original_board_name] = boardNodes;
				}
//			} else {
//				throw new Error("Duplicate Level entries found for level: " + level.original_level_name);
//			}
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
	}

}