package system 
{
	import events.EdgeSetChangeEvent;
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
		
		public function findTargetScore(level:Level, simulator:PipeSimulator, iter:int = 3):int
		{
			var bestScore:int = level.currentScore;
			var allMovesPerformed:Vector.<EdgeSetChangeEvent> = new Vector.<EdgeSetChangeEvent>();
			for (var i:int = 0; i < iter; i++) {
				var suggestedMoves:Vector.<EdgeSetChangeEvent> = getSuggestedMoves(level, simulator);
				if (suggestedMoves.length == 0) break; // no moves to suggest
				var score:int = level.currentScore;
				allMovesPerformed = allMovesPerformed.concat(suggestedMoves);
				if (score < bestScore) break;
				bestScore = score;
				trace("New Target: " + bestScore);
			}
			// Undo moves to reset level graph
			for (var m:int = 0; m < allMovesPerformed.length; m++) {
				performEdgeSetChangeEvent(allMovesPerformed[m], true);
			}
			return bestScore;
		}
		
		public function getSuggestedMoves(level:Level, simulator:PipeSimulator):Vector.<EdgeSetChangeEvent>
		{
			// TODO: Props besides NARROW
			var narrowMovesGroups:Array = new Array();
			var widenMovesGroups:Array = new Array();
			var prop:String, wideEdgeSets:Vector.<EdgeSetRef>, e:int;
			var moveSets:Vector.<MoveSet> = new Vector.<MoveSet>();
			var moveSet:MoveSet, numMoves:int, gameNode:GameNode;
			// If no target score, establish one by making simple moves
			for (var boardName:String in simulator.boardToConflicts) {
				if (!level.boardInLevel(boardName)) continue;
				var boardConflicts:ConflictDictionary = (simulator.boardToConflicts[boardName] as ConflictDictionary);
				for (var portKey:String in boardConflicts.iterPorts()) {
					var port:Port = boardConflicts.getPort(portKey);
					var portConfl:PropDictionary = boardConflicts.getPortConflicts(portKey);
					for (prop in portConfl.iterProps()) {
						// TODO: Props besides NARROW
						if (prop == PropDictionary.PROP_NARROW) {
							moveSet = new MoveSet();
							numMoves = 0;
							wideEdgeSets = port.edge.getOriginatingEdgeSetsMatchingPropValue(prop, false);
							for (e = 0; e < wideEdgeSets.length; e++) {
								gameNode = level.getNode(wideEdgeSets[e].id);
								if (!gameNode) continue;
								if (gameNode.isEditable()) {
									numMoves += moveSet.addMoveSafe(gameNode, prop, true) ? 1 : 0;
								}
							}
							if (numMoves > 0) moveSets.push(moveSet);
						}
					}
				}
				for (var edgeKey:String in boardConflicts.iterEdges()) {
					var edge:Edge = boardConflicts.getEdge(edgeKey);
					var edgeConfl:PropDictionary = boardConflicts.getEdgeConflicts(edgeKey);
					for (prop in edgeConfl.iterProps()) {
						// TODO: Props besides NARROW
						if (prop == PropDictionary.PROP_NARROW) {
							var newPropValue:Boolean;
							if (edge.has_pinch || !edge.editable) {
								// Can't change this width, try making narrow upstream
								newPropValue = true;
								wideEdgeSets = edge.getOriginatingEdgeSetsMatchingPropValue(prop, false);
							} else if (!edge.is_wide && edge.editable) {
								// Try making this wide and widening downstream
								newPropValue = false;
								wideEdgeSets = edge.getDownStreamEdgeSetsMatchingPropValue(prop, true);
							}
							moveSet = new MoveSet();
							numMoves = 0;
							for (e = 0; e < wideEdgeSets.length; e++) {
								gameNode = level.getNode(wideEdgeSets[e].id);
								if (!gameNode) continue;
								numMoves += moveSet.addMoveSafe(gameNode, prop, newPropValue) ? 1 : 0;
							}
							if (numMoves > 0) moveSets.push(moveSet);
						}
					}
				}
			}
			var prevScore:int;
			var suggestedMoves:Vector.<EdgeSetChangeEvent> = new Vector.<EdgeSetChangeEvent>();
			for (var m:int = 0; m < moveSets.length; m++) {
				var movesToTry:MoveSet = moveSets[m];
				prevScore = level.currentScore;
				trace("Checking moves:");
				var movesToSuggest:Vector.<EdgeSetChangeEvent> = performMoves(movesToTry);
				simulator.updateOnBoxSizeChange("", level.level_name);
				level.updateScore();
				if (level.currentScore >= prevScore) {
					trace("Good moves! Net score increase: " + (level.currentScore - prevScore));
					suggestedMoves = suggestedMoves.concat(movesToSuggest);
				} else {
					trace("Bad moves! Net score increase: " + (level.currentScore - prevScore) + " Undoing...");
					performMoves(movesToTry, true);
					simulator.updateOnBoxSizeChange("", level.level_name);
					level.updateScore();
				}
			}
			return suggestedMoves;
		}
		
		private function performMoves(movesToPerform:MoveSet, undo:Boolean = false):Vector.<EdgeSetChangeEvent>
		{
			var movesPerformed:Vector.<EdgeSetChangeEvent> = new Vector.<EdgeSetChangeEvent>();
			for (var edgeSetKey:String in movesToPerform.iterEdgeSets()) {
				// TODO: prop besides narrow
				var edgeMoves:Vector.<EdgeSetChangeEvent> = movesToPerform.getMoves(edgeSetKey, PropDictionary.PROP_NARROW);
				for (var em:int = 0; em < edgeMoves.length; em++) {
					var performed:Boolean = performEdgeSetChangeEvent(edgeMoves[em], undo);
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
		private function performEdgeSetChangeEvent(evt:EdgeSetChangeEvent, undo:Boolean = false):Boolean
		{
			var gameNode:GameNode = evt.edgeSetChanged;
			if (!gameNode) return false;
			if (!gameNode.isEditable()) return false;
			if (!gameNode.m_edgeSet) return false;
			var newValue:Boolean = undo ? !evt.propValue : evt.propValue;
			if (gameNode.m_edgeSet.getProps().hasProp(evt.prop) == newValue) return false;
			gameNode.m_edgeSet.setProp(evt.prop, newValue);
			/*if (!undo)*/ trace("--> Make " + gameNode.m_id + (newValue ? " NARROW" : " WIDE"));
			return true;
		}
		
	}
}

import events.EdgeSetChangeEvent;
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
		if (!gameNode.m_edgeSet) return false;
		var propToMovesDict:Dictionary;
		if (m_edgeSetIdPropToMoves.hasOwnProperty(gameNode.m_edgeSet.id)) {
			propToMovesDict = m_edgeSetIdPropToMoves[gameNode.m_edgeSet.id] as Dictionary;
			if (propToMovesDict.hasOwnProperty(prop)) {
				return false;
			}
		} else {
			propToMovesDict = new Dictionary();
		}
		propToMovesDict[prop] = new EdgeSetChangeEvent(EdgeSetChangeEvent.EDGE_SET_CHANGED, gameNode, prop, value);
		m_edgeSetIdPropToMoves[gameNode.m_edgeSet.id] = propToMovesDict;
		return true;
	}
	
	public function iterEdgeSets():Dictionary
	{
		return m_edgeSetIdPropToMoves;
	}
	
	public function getMoves(edgeSetId:String, prop:String):Vector.<EdgeSetChangeEvent>
	{
		var moves:Vector.<EdgeSetChangeEvent> = new Vector.<EdgeSetChangeEvent>();
		if (m_edgeSetIdPropToMoves.hasOwnProperty(edgeSetId)) {
			var propToMovesDict:Dictionary = m_edgeSetIdPropToMoves[edgeSetId] as Dictionary;
			if (propToMovesDict.hasOwnProperty(prop)) {
				var move:EdgeSetChangeEvent = propToMovesDict[prop] as EdgeSetChangeEvent;
				moves.push(move);
			}
		}
		return moves;
	}
}