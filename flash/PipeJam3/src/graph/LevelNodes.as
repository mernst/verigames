package graph 
{

	import flash.utils.Dictionary;
	import utils.NameObfuscater;
	
	public class LevelNodes
	{
		
		public var level_name:String;
		public var original_level_name:String;
		private var m_obfuscator:NameObfuscater;
		
		public var metadata:Dictionary = new Dictionary();
		
		/** This is a dictionary of BoardNodes, which is a dictionary of Nodes; INDEXED BY BOARD NAME AND NODE ID, RESPECTIVELY */
		public var boardNodesDictionary:Dictionary = new Dictionary();
		public var boardNodeNameArray:Array = new Array;
		
		public function LevelNodes(_original_level_name:String, _obfuscater:NameObfuscater = null) 
		{
			original_level_name = _original_level_name;
			m_obfuscator = _obfuscater;
			if (m_obfuscator) {
				level_name = m_obfuscator.getLevelName(_original_level_name);
			} else {
				level_name = _original_level_name;
			}
		}
		
		public function addNode(_node:Node, _original_board_name:String):void {
			var new_board_name:String = _original_board_name;
			if (m_obfuscator) {
				new_board_name = m_obfuscator.getBoardName(_original_board_name, original_level_name);
			}
			if (boardNodesDictionary[new_board_name] == null) {
				boardNodesDictionary[new_board_name] = new BoardNodes(new_board_name, _original_board_name);
			}
			(boardNodesDictionary[new_board_name] as BoardNodes).addNode(_node);
			boardNodeNameArray.push(new_board_name);
		}
		
		public function getBoardNodes(_original_board_name:String):BoardNodes {
			var new_board_name:String = _original_board_name;
			if (m_obfuscator) {
				new_board_name = m_obfuscator.getBoardName(_original_board_name, original_level_name);
			}
			return boardNodesDictionary[new_board_name];
		}
		
		public function getNode(_original_board_name:String, _node_id:String):Node {
			var new_board_name:String = _original_board_name;
			if (m_obfuscator) {
				new_board_name = m_obfuscator.getBoardName(_original_board_name, original_level_name);
			}
			if (boardNodesDictionary[new_board_name] != null) {
				return (boardNodesDictionary[new_board_name] as BoardNodes).nodeDictionary[_node_id];
			}
			return null;
		}
		
		public function associateSubnetNodesToBoardNodes():void
		{
			for (var boardName:String in boardNodesDictionary) {
				var boardNodes:BoardNodes = boardNodesDictionary[boardName];
				var remainingNodes:Vector.<SubnetworkNode> = new Vector.<SubnetworkNode>();
				for each (var subnetNodeToFinish:SubnetworkNode in boardNodes.subnetNodesToAssociate) {
					var obsName:String = m_obfuscator.getBoardName(subnetNodeToFinish.subboard_name, original_level_name);
					if (obsName && boardNodesDictionary.hasOwnProperty(obsName)) {
						var foundBoardNodes:BoardNodes = boardNodesDictionary[obsName] as BoardNodes;
						subnetNodeToFinish.associated_board = foundBoardNodes;
						subnetNodeToFinish.associated_board_is_external = false;
					} else {
						// Must be external, keep as unassociated
						remainingNodes.push(subnetNodeToFinish);
					}
				}
				boardNodes.subnetNodesToAssociate = remainingNodes;
			}
		}
		
		public function clone():LevelNodes
		{
			return this;
		}
		
	}

}