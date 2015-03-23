package hints 
{
	import scenes.game.display.ClauseNode;
	import scenes.game.display.Edge;
	import scenes.game.display.Level;
	import scenes.game.display.Node;
	import scenes.game.display.VariableNode;
	import starling.display.Sprite;
	
	public class HintController extends Sprite 
	{
		
		private static var m_instance:HintController;
		
		public static function getInstance():HintController
		{
			if (m_instance == null) {
				m_instance = new HintController(new SingletonLock());
			}
			return m_instance;
		}
		
		public function HintController(lock:SingletonLock):void
		{
		}
		
		public function checkForConflictsInAutosolve(level:Level):Boolean
		{
			for each(var selectedNode:Node in level.selectedNodes)
			{
				if (selectedNode is ClauseNode)
				{
					var clauseNode:ClauseNode = selectedNode as ClauseNode;
					if (clauseNode.hasError()) return true;
				}
				else
				{
					for each(var gameEdgeId:String in selectedNode.connectedEdgeIds)
					{
						var edge:Edge = level.edgeLayoutObjs[gameEdgeId] as Edge;
						if (edge != null)
						{
							var clause:ClauseNode;
							if (edge.fromNode is ClauseNode)
							{
								clause = edge.fromNode as ClauseNode;
								if (clause.hasError()) return true;
							}
							if (edge.toNode is ClauseNode)
							{
								clause = edge.toNode as ClauseNode;
								if (clause.hasError()) return true;
							}
						}
					}
				}
			}
			return false;
		}
		
	}

}

internal class SingletonLock {} // to prevent outside construction of singleton