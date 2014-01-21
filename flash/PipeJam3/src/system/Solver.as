package system 
{
	import events.WidgetChangeEvent;
	import flash.utils.Dictionary;
	import graph.ConflictDictionary;
	import graph.Edge;
	import graph.EdgeSetRef;
	import graph.Port;
	import graph.PropDictionary;
	import scenes.game.display.GameNode;
	import scenes.game.display.Level;
	
	public class Solver 
	{
		private static var m_instance:Solver;
		
		public static function getInstance():Solver
		{
			if (m_instance == null) m_instance = new Solver(new SingletonLock());
			return m_instance;
		}
		
		public function Solver(lock:SingletonLock):void { }
		
		public function findTargetScore(level:Level, iter:int = 3):int
		{
			var bestScore:int = level.currentScore;
			var allMovesPerformed:Vector.<WidgetChangeEvent> = new Vector.<WidgetChangeEvent>();
			for (var i:int = 0; i < iter; i++) {
				var suggestedMoves:Vector.<WidgetChangeEvent> = getSuggestedMoves(level);
				if (suggestedMoves.length == 0) break; // no moves to suggest
				var score:int = level.currentScore;
				allMovesPerformed = allMovesPerformed.concat(suggestedMoves);
				if (score < bestScore) break;
				bestScore = score;
				//trace("New Target: " + bestScore);
			}
			// Undo moves to reset level graph
			for (var m:int = 0; m < allMovesPerformed.length; m++) {
				performWidgetChangeEvent(allMovesPerformed[m], true);
			}
			return bestScore;
		}
		
		public function getSuggestedMoves(level:Level):Vector.<WidgetChangeEvent>
		{
			// TODO: Props besides NARROW
			var narrowMovesGroups:Array = new Array();
			var widenMovesGroups:Array = new Array();
			var prop:String, wideEdgeSets:Vector.<EdgeSetRef>, e:int;
			var moveSets:Vector.<MoveSet> = new Vector.<MoveSet>();
			var moveSet:MoveSet, numMoves:int, gameNode:GameNode;
			var conflicts:Array = [];
			// TODO: get from level.levelGraph and adapt for constraints, not simulator/old graph format
			// If no target score, establish one by making simple moves
			//for (var boardName:String in conflicts) {
				//if (!level.boardInLevel(boardName)) continue;
				//var boardConflicts:ConflictDictionary = (simulator.boardToConflicts[boardName] as ConflictDictionary);
				//for (var portKey:String in boardConflicts.iterPorts()) {
					//var port:Port = boardConflicts.getPort(portKey);
					//var portConfl:PropDictionary = boardConflicts.getPortConflicts(portKey);
					//for (prop in portConfl.iterProps()) {
						// TODO: Props besides NARROW
						//if (prop == PropDictionary.PROP_NARROW) {
							//moveSet = new MoveSet();
							//numMoves = 0;
							//wideEdgeSets = port.edge.getOriginatingEdgeSetsMatchingPropValue(prop, false);
							//for (e = 0; e < wideEdgeSets.length; e++) {
								//gameNode = level.getNode(wideEdgeSets[e].id);
								//if (!gameNode) continue;
								//if (gameNode.isEditable()) {
									//numMoves += moveSet.addMoveSafe(gameNode, prop, true) ? 1 : 0;
								//}
							//}
							//if (numMoves > 0) moveSets.push(moveSet);
						//}
					//}
				//}
				//for (var edgeKey:String in boardConflicts.iterEdges()) {
					//var edge:Edge = boardConflicts.getEdge(edgeKey);
					//var edgeConfl:PropDictionary = boardConflicts.getEdgeConflicts(edgeKey);
					//for (prop in edgeConfl.iterProps()) {
						// TODO: Props besides NARROW
						//if (prop == PropDictionary.PROP_NARROW) {
							//var newPropValue:Boolean;
							//if (edge.has_pinch || !edge.editable) {
								// Can't change this width, try making narrow upstream
								//newPropValue = true;
								//wideEdgeSets = edge.getOriginatingEdgeSetsMatchingPropValue(prop, false);
							//} else if (!edge.is_wide && edge.editable) {
								// Try making this wide and widening downstream
								//newPropValue = false;
								//wideEdgeSets = edge.getDownStreamEdgeSetsMatchingPropValue(prop, true, level.original_level_name);
							//}
							//moveSet = new MoveSet();
							//numMoves = 0;
							//for (e = 0; e < wideEdgeSets.length; e++) {
								//gameNode = level.getNode(wideEdgeSets[e].id);
								//if (!gameNode) continue;
								//if (gameNode.isEditable()) {
									//numMoves += moveSet.addMoveSafe(gameNode, prop, newPropValue) ? 1 : 0;
								//}
							//}
							//if (numMoves > 0) moveSets.push(moveSet);
						//}
					//}
				//}
			//}
			//var prevScore:int;
			var suggestedMoves:Vector.<WidgetChangeEvent> = new Vector.<WidgetChangeEvent>();
			//for (var m:int = 0; m < moveSets.length; m++) {
				//var movesToTry:MoveSet = moveSets[m];
				//prevScore = level.currentScore;
				//trace("Checking moves:");
				//var movesToSuggest:Vector.<WidgetChangeEvent> = performMoves(movesToTry);
				//simulator.updateOnBoxSizeChange("", level.level_name);
				//level.updateScore();
				//if (level.currentScore >= prevScore) {
					//trace("Good moves! Net score increase: " + (level.currentScore - prevScore));
					//suggestedMoves = suggestedMoves.concat(movesToSuggest);
				//} else {
					//trace("Bad moves! Net score increase: " + (level.currentScore - prevScore) + " Undoing...");
					//performMoves(movesToTry, true);
					//simulator.updateOnBoxSizeChange("", level.level_name);
					//level.updateScore();
				//}
			//}
			return suggestedMoves;
		}
		
		private function performMoves(movesToPerform:MoveSet, undo:Boolean = false):Vector.<WidgetChangeEvent>
		{
			var movesPerformed:Vector.<WidgetChangeEvent> = new Vector.<WidgetChangeEvent>();
			for (var edgeSetKey:String in movesToPerform.iterEdgeSets()) {
				// TODO: prop besides narrow
				var edgeMoves:Vector.<WidgetChangeEvent> = movesToPerform.getMoves(edgeSetKey, PropDictionary.PROP_NARROW);
				for (var em:int = 0; em < edgeMoves.length; em++) {
					var performed:Boolean = performWidgetChangeEvent(edgeMoves[em], undo);
					if (performed) movesPerformed.push(edgeMoves[em]);
				}
			}
			return movesPerformed;
		}
		
		/**
		 * Perform prop change to associated edgeset, return true if performed
		 * @param	evt
		 * @param	undo
		 * @return
		 */
		private function performWidgetChangeEvent(evt:WidgetChangeEvent, undo:Boolean = false):Boolean
		{
			var gameNode:GameNode = evt.widgetChanged;
			if (!gameNode) return false;
			if (!gameNode.isEditable()) return false;
			if (!gameNode.constraintVar) return false;
			var newValue:Boolean = undo ? !evt.propValue : evt.propValue;
			if (gameNode.constraintVar.getProps().hasProp(evt.prop) == newValue) return false;
			gameNode.constraintVar.setProp(evt.prop, newValue);
			if ((evt.prop == PropDictionary.PROP_NARROW) && (gameNode.m_isWide == newValue)) {
				gameNode.m_isWide = !newValue;
				gameNode.m_isDirty = true;
			}
			/*if (!undo)*/ //trace("--> Make " + gameNode.m_id + (newValue ? " NARROW" : " WIDE"));
			return true;
		}
		
	}
}

import events.WidgetChangeEvent;
import flash.utils.Dictionary;
import scenes.game.display.GameNode;

internal class SingletonLock {} // to prevent outside construction of singleton

internal class MoveSet {
	
	private var m_edgeSetIdPropToMoves:Dictionary = new Dictionary();
	
	public function MoveSet() { }
	
	/**
	 * Add property value change to moveSet iff property/edgeSet combo has not been added as a move yet
	 * @param	gameNode
	 * @param	prop
	 * @param	value
	 * @return True is move added, false if move already existed for gameNode edgeSet and property combination
	 */
	public function addMoveSafe(gameNode:GameNode, prop:String, value:Boolean):Boolean
	{
		if (!gameNode.constraintVar) return false;
		if (!gameNode.isEditable()) return false;
		var propToMovesDict:Dictionary;
		if (m_edgeSetIdPropToMoves.hasOwnProperty(gameNode.constraintVar.id)) {
			propToMovesDict = m_edgeSetIdPropToMoves[gameNode.constraintVar.id] as Dictionary;
			if (propToMovesDict.hasOwnProperty(prop)) {
				return false;
			}
		} else {
			propToMovesDict = new Dictionary();
		}
		propToMovesDict[prop] = new WidgetChangeEvent(WidgetChangeEvent.WIDGET_CHANGED, gameNode, prop, value);
		m_edgeSetIdPropToMoves[gameNode.constraintVar.id] = propToMovesDict;
		return true;
	}
	
	public function iterEdgeSets():Dictionary
	{
		return m_edgeSetIdPropToMoves;
	}
	
	public function getMoves(edgeSetId:String, prop:String):Vector.<WidgetChangeEvent>
	{
		var moves:Vector.<WidgetChangeEvent> = new Vector.<WidgetChangeEvent>();
		if (m_edgeSetIdPropToMoves.hasOwnProperty(edgeSetId)) {
			var propToMovesDict:Dictionary = m_edgeSetIdPropToMoves[edgeSetId] as Dictionary;
			if (propToMovesDict.hasOwnProperty(prop)) {
				var move:WidgetChangeEvent = propToMovesDict[prop] as WidgetChangeEvent;
				moves.push(move);
			}
		}
		return moves;
	}
}