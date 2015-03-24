package hints 
{
	import display.TextBubble;
	import scenes.game.display.ClauseNode;
	import scenes.game.display.Edge;
	import scenes.game.display.Level;
	import scenes.game.display.Node;
	import starling.core.Starling;
	import starling.display.Sprite;
	
	public class HintController extends Sprite 
	{
		private static const FADE_SEC:Number = 0.3;
		
		private static var m_instance:HintController;
		
		private var hintBubble:TextBubble;
		public var hintLayer:Sprite;
		
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
			popHint("Paint at least one\nconflict before optimizing", level);
			return false;
		}
		
		public function popHint(text:String, level:Level, secToShow:Number = 3.0):void
		{
			if (hintBubble != null) Starling.juggler.removeTweens(hintBubble);
			removeHint(); // any existing hints
			hintBubble = new TextBubble("Hint: " + text, 10, Constants.NARROW_BLUE, null, level, Constants.HINT_LOC, null, null, false);
			fadeInHint();
			Starling.juggler.delayCall(fadeOutHint, secToShow + FADE_SEC);
		}
		
		public function fadeInHint():void
		{
			if (hintBubble != null)
			{
				hintBubble.alpha = 0;
				hintLayer.addChild(hintBubble);
				Starling.juggler.tween(hintBubble, FADE_SEC, { alpha:1.0 } );
			}
		}
		
		public function fadeOutHint():void
		{
			if (hintBubble != null)
			{
				Starling.juggler.tween(hintBubble, FADE_SEC, { alpha:0, onComplete:removeHint } );
			}
		}
		
		public function removeHint():void
		{
			if (hintBubble != null) hintBubble.removeFromParent(true);
		}
	}

}

internal class SingletonLock {} // to prevent outside construction of singleton