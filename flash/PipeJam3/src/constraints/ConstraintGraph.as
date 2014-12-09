package constraints 
{
	import flash.utils.Dictionary;
	import flash.utils.getQualifiedClassName;
	import starling.events.EventDispatcher;
	
	import constraints.events.ErrorEvent;	
	import utils.XString;

	public class ConstraintGraph extends EventDispatcher
	{
		public static const GAME_DEFAULT_VAR_VALUE:ConstraintValue = new ConstraintValue(1);
		
		private static const VERSION:String = "version";
		private static const DEFAULT_VAR:String = "default";
		private static const QID:String = "qid";
		// Sections:
		private static const SCORING:String = "scoring";
		private static const VARIABLES:String = "variables";
		private static const CONSTRAINTS:String = "constraints";
		// Variable fields:
		private static const DEFAULT:String = "default";
		private static const SCORE:String = "score";
		private static const POSSIBLE_KEYFORS:String = "possible_keyfor";
		public static const TYPE_VALUE:String = "type_value";
		public static const KEYFOR_VALUES:String = "keyfor_value";
		private static const CONSTANT:String = "constant";
		// Constraint side types:
		private static const VAR:String = "var";
		private static const C:String = "c";
		
		private static const NULL_SCORING:ConstraintScoringConfig = new ConstraintScoringConfig();
		
		public var variableDict:Dictionary = new Dictionary();
		public var constraintsDict:Dictionary = new Dictionary();
		public var clauseDict:Dictionary = new Dictionary();
		public var unsatisfiedConstraintDict:Dictionary = new Dictionary();
		public var graphScoringConfig:ConstraintScoringConfig = new ConstraintScoringConfig();
		
		public var startingScore:int = NaN;
		public var currentScore:int = 0;
		public var prevScore:int = 0;
		public var oldScore:int = 0;
		
		public var qid:int = -1;
		
		static protected var updateCount:int = 0;
		
		public function updateScore(varIdChanged:String = null, propChanged:String = null, newPropValue:Boolean = false):void
		{
			var clauseID:String;
			var constraint:ConstraintEdge;
			
			oldScore = prevScore;
			prevScore = currentScore;
//			if(updateCount++ % 200 == 0)
//				trace("updateScore currentScore ", currentScore, " varIdChanged:",varIdChanged);
			var constraintId:String;
			var lhsConstraint:Constraint, rhsConstraint:Constraint;
			var newUnsatisfiedConstraints:Dictionary = new Dictionary();
			var currentConstraints:Dictionary = new Dictionary();
			var newSatisfiedConstraints:Dictionary = new Dictionary();
			if (varIdChanged != null && propChanged != null) {
				var varChanged:ConstraintVar = variableDict[varIdChanged] as ConstraintVar;

				var prevBonus:int = varChanged.scoringConfig.getScoringValue(varChanged.getValue().verboseStrVal);
				var prevConstraintPoints:int = 0;
				// Recalc incoming/outgoing constraints
				var i:int;
				for (i = 0; i < varChanged.lhsConstraints.length; i++) {
					lhsConstraint = varChanged.lhsConstraints[i];
					if(lhsConstraint is ConstraintEdge && currentConstraints[lhsConstraint.id] == null)
					{
						constraint = lhsConstraint as ConstraintEdge;
						currentConstraints[constraint.id] = lhsConstraint;
						if (constraint.isClauseSatisfied(varIdChanged, !newPropValue)) prevConstraintPoints += lhsConstraint.scoring.getScoringValue(ConstraintScoringConfig.CONSTRAINT_VALUE_KEY);
					}
				}
				for (i = 0; i < varChanged.rhsConstraints.length; i++) {
					rhsConstraint = varChanged.rhsConstraints[i];
					if(rhsConstraint is ConstraintEdge && currentConstraints[rhsConstraint.id] == null)
					{
						constraint = rhsConstraint as ConstraintEdge;
						currentConstraints[rhsConstraint.id] = rhsConstraint;
						if (constraint.isClauseSatisfied(varIdChanged, !newPropValue)) prevConstraintPoints += rhsConstraint.scoring.getScoringValue(ConstraintScoringConfig.CONSTRAINT_VALUE_KEY);
					}
				}
				// Recalc incoming/outgoing constraints
				varChanged.setProp(propChanged, newPropValue);
				var newBonus:int = varChanged.scoringConfig.getScoringValue(varChanged.getValue().verboseStrVal);
				var newConstraintPoints:int = 0;
				for each(constraint in currentConstraints) {
					if(constraint.lhs.id.indexOf('c') != -1)
						clauseID = constraint.lhs.id;
					else
						clauseID = constraint.rhs.id;
					if (constraint.isClauseSatisfied(varIdChanged, newPropValue)) {
						newConstraintPoints += constraint.scoring.getScoringValue(ConstraintScoringConfig.CONSTRAINT_VALUE_KEY);
						newSatisfiedConstraints[clauseID] = constraint;
					} else {
						newUnsatisfiedConstraints[clauseID] = constraint;
					}
				}
				// Offset score by change in bonus and new constraints satisfied/not
//				trace("newBonus ", newBonus, " prevBonus ", prevBonus, " newConstraintPoints ", newConstraintPoints, " prevConstraintPoints ", prevConstraintPoints);
				currentScore += newConstraintPoints - prevConstraintPoints;
				trace("new currentScore ", currentScore);
			}
			 else {
				currentScore = 0;
//				for (var varId:String in variableDict) {
//					var thisVar:ConstraintVar = variableDict[varId] as ConstraintVar;
//					if (thisVar.getValue() != null && thisVar.scoringConfig != null) {
//						// If there is a bonus for the current value of thisVar, add to score
//						currentScore += thisVar.scoringConfig.getScoringValue(thisVar.getValue().verboseStrVal);
//					}
//				}
				for (constraintId in constraintsDict) { // TODO: we are recalculating each clause for every edge, need only traverse clauses once
					//old style - scoring per constraint
					//new style - scoring per satisfied clause (might be multiple unsatisfied constraints per clause, but one satisfied one is enough)
					var thisConstr:Constraint = constraintsDict[constraintId] as Constraint;
					if(thisConstr is ConstraintEdge)
					{
						constraint = thisConstr as ConstraintEdge;
						if(thisConstr.lhs.id.indexOf('c') != -1)
							clauseID = thisConstr.lhs.id;
						else
							clauseID = thisConstr.rhs.id;
						if (constraint.isClauseSatisfied(null, false)) {
							//get clauseID
							if(newSatisfiedConstraints[clauseID] == null)
							{
								currentScore += thisConstr.scoring.getScoringValue(ConstraintScoringConfig.CONSTRAINT_VALUE_KEY);
								newSatisfiedConstraints[clauseID] = thisConstr;
							}
						} else {
							newUnsatisfiedConstraints[clauseID] = thisConstr;
						}
					} 
				}
			}
			for (clauseID in newSatisfiedConstraints) {
				if (unsatisfiedConstraintDict.hasOwnProperty(clauseID)) {
					delete unsatisfiedConstraintDict[clauseID];
					dispatchEvent(new ErrorEvent(ErrorEvent.ERROR_REMOVED, newSatisfiedConstraints[clauseID]));
				}
			}
			for (clauseID in newUnsatisfiedConstraints) {
				if (!unsatisfiedConstraintDict.hasOwnProperty(clauseID)) {
					unsatisfiedConstraintDict[clauseID] = newUnsatisfiedConstraints[clauseID];
					dispatchEvent(new ErrorEvent(ErrorEvent.ERROR_ADDED, newUnsatisfiedConstraints[clauseID]));
				}
			}
			if (isNaN(startingScore)) startingScore = currentScore;
		}
		
		public function resetScoring():void
		{
			updateScore();
			oldScore = prevScore = currentScore;
		}
		
		public static function fromString(_json:String):ConstraintGraph
		{
			var levelObj:Object = JSON.parse(_json);
			return fromJSON(levelObj);
		}
		
		public static function fromJSON(levelObj:Object):ConstraintGraph
		{
			//with the inclusion of the import graph.PropDictionary, FlashBuilder confuses the graph package with this var when 
			//just named 'graph'. Add the one so things compile.
			var graph1:ConstraintGraph = new ConstraintGraph();
			var ver:String = levelObj[VERSION];
			var defaultValue:String = levelObj[DEFAULT_VAR];
			graph1.qid = parseInt(levelObj[QID]);
			switch (ver) {
				case "1": // Version 1
				case "2": // Version 2
					// No "default" specified in json, use game default
					var graphDefaultVal:ConstraintValue;
					if (defaultValue == ConstraintScoringConfig.TYPE_0_VALUE_KEY) {
						graphDefaultVal = new ConstraintValue(0);
					} else if (defaultValue == ConstraintScoringConfig.TYPE_1_VALUE_KEY) {
						graphDefaultVal = new ConstraintValue(1);
					} else {
						graphDefaultVal = GAME_DEFAULT_VAR_VALUE;
					}
					// Build Scoring
					var scoringObj:Object = levelObj[SCORING];
					var constraintScore:int = scoringObj ? scoringObj[ConstraintScoringConfig.CONSTRAINT_VALUE_KEY] : 100;
					var variableScoreObj:Object = scoringObj ? scoringObj[VARIABLES] : {"type:0": 0, "type:1": 1};
					var type0Score:int = variableScoreObj[ConstraintScoringConfig.TYPE_0_VALUE_KEY];
					var type1Score:int = variableScoreObj[ConstraintScoringConfig.TYPE_1_VALUE_KEY];
					graph1.graphScoringConfig.updateScoringValue(ConstraintScoringConfig.CONSTRAINT_VALUE_KEY, constraintScore);
					graph1.graphScoringConfig.updateScoringValue(ConstraintScoringConfig.TYPE_0_VALUE_KEY, type0Score);
					graph1.graphScoringConfig.updateScoringValue(ConstraintScoringConfig.TYPE_1_VALUE_KEY, type1Score);
					
					// Build variables (if any specified, this section is optional)
					var variablesObj:Object = levelObj[VARIABLES];
					if (variablesObj) {
						for (var varId:String in variablesObj) {
							var idParts:Array = varId.split(":");
							var formattedId:String = idParts[0] + "_" + idParts[1];
							var varParamsObj:Object = variablesObj[varId];
							var isConstant:Boolean = false;
							if (varParamsObj.hasOwnProperty(CONSTANT)) isConstant = XString.stringToBool(varParamsObj[CONSTANT] as String);
							var typeValStr:String = varParamsObj[TYPE_VALUE];
							var varScoring:ConstraintScoringConfig = new ConstraintScoringConfig();
							var scoreObj:Object = varParamsObj[SCORE];
							if (scoreObj) {
								var type0VarScore:int = scoreObj[ConstraintScoringConfig.TYPE_0_VALUE_KEY];
								var type1VarScore:int = scoreObj[ConstraintScoringConfig.TYPE_1_VALUE_KEY];
								varScoring.updateScoringValue(ConstraintScoringConfig.TYPE_0_VALUE_KEY, type0VarScore);
								varScoring.updateScoringValue(ConstraintScoringConfig.TYPE_1_VALUE_KEY, type1VarScore);
							}
							var mergedVarScoring:ConstraintScoringConfig = ConstraintScoringConfig.merge(graph1.graphScoringConfig, varScoring);
							var defaultValStr:String = varParamsObj[DEFAULT];
							var defaultVal:ConstraintValue;
							if (defaultValStr) defaultVal = ConstraintValue.fromVerboseStr(defaultValStr);
							var typeVal:ConstraintValue;
							if (typeValStr) {
								typeVal = ConstraintValue.fromVerboseStr(typeValStr);
							} else if (defaultVal) {
								typeVal = defaultVal.clone();
							} else {
								typeVal = graphDefaultVal.clone();
							}
							var newVar:ConstraintVar = new ConstraintVar(formattedId, typeVal, defaultVal, isConstant, isConstant ? NULL_SCORING : mergedVarScoring);
							graph1.variableDict[formattedId] = newVar;
						}
					}
					// Build constraints (and add any uninitialized variables to graph.variableDict)
					var constraintsArr:Array = levelObj[CONSTRAINTS];
					for (var c:int = 0; c < constraintsArr.length; c++) {
						var newConstraint:Constraint;
						if (getQualifiedClassName(constraintsArr[c]) == "String") {
							// process as String, i.e. "var:1 <= c:2"
							newConstraint = parseConstraintString(constraintsArr[c] as String, graph1.variableDict, graph1.clauseDict, graphDefaultVal, graph1.graphScoringConfig);
						} else {
							throw new Error("Unknown constraint format: " + constraintsArr[c]);
						}
						if (newConstraint is ConstraintEdge) {
							graph1.constraintsDict[newConstraint.id] = newConstraint;
						} else {
							throw new Error("Unknown constraint type:" + newConstraint);
						}
					}
					break;
				default:
					throw new Error("ConstraintGraph.fromJSON:: Unknown version encountered: " + ver);
					break;
			}
			return graph1;
		}
		
		private static function parseConstraintString(_str:String, _variableDictionary:Dictionary, _clauseDictionary:Dictionary, _defaultVal:ConstraintValue, _defaultScoring:ConstraintScoringConfig):Constraint
		{
			var pattern:RegExp = /(var|c):(.*) (<|=)= (var|c):(.*)/i;
			var result:Object = pattern.exec(_str);
			if (result == null) throw new Error("Invalid constraint string found: " + _str);
			if (result.length != 6) throw new Error("Invalid constraint string found: " + _str);
			var lhsType:String = result[1];
			var lhsId:String = result[2];
			var constType:String = result[3];
			var rhsType:String = result[4];
			var rhsId:String = result[5];
			var typeNumArray:Array;
 			
			var lsuffix:String = "";
			var rsuffix:String = "";
			if (rhsType == VAR && lhsType == C) {
				typeNumArray = lhsId.split("_");
			} else if (rhsType == C && lhsType == VAR) {
				typeNumArray = rhsId.split("_");
			} else {
				trace("WARNING! Constraint found between two types (no var): " + JSON.stringify(_str));
			}
			
			var lhs:ConstraintSide = parseConstraintSide(lhsType, lhsId, lsuffix, _variableDictionary, _clauseDictionary, _defaultVal, _defaultScoring.clone());
			var rhs:ConstraintSide = parseConstraintSide(rhsType, rhsId, rsuffix, _variableDictionary, _clauseDictionary, _defaultVal, _defaultScoring.clone());
			
			var newConstraint:Constraint;
			if(rhsType == 'c' || lhsType == 'c')
			{
				newConstraint = new ConstraintEdge(lhs, rhs, _defaultScoring);
			}
			else
			{
				throw new Error("Invalid constraint type found ('"+constType+"') in string: " + _str);
			}
 			return newConstraint;
 		}
		
		private static function parseConstraintSide(_type:String, _type_num:String, _typeSuffix:String, _variableDictionary:Dictionary, _clauseDictionary:Dictionary, _defaultVal:ConstraintValue, _defaultScoring:ConstraintScoringConfig):ConstraintSide
		{
			var fullId:String = _type + "_" + _type_num + _typeSuffix;
			var constrSide:ConstraintSide;
			if (_type == VAR) {
				if (_variableDictionary.hasOwnProperty(fullId)) {
					constrSide = _variableDictionary[fullId] as ConstraintVar;
				} else {
					constrSide = new ConstraintVar(fullId, _defaultVal, _defaultVal, false, _defaultScoring);
					_variableDictionary[fullId] = constrSide;
				}
			} else if (_type == C) {
				fullId = _type + "_" + _type_num;
				if (_clauseDictionary.hasOwnProperty(fullId)) {
					constrSide = _clauseDictionary[fullId] as ConstraintClause;
				} else {
					constrSide = new ConstraintClause(fullId, _defaultScoring);
					_clauseDictionary[fullId] = constrSide;
				}
			} else {
				throw new Error("Invalid constraint element found: ('" + _type + "'). Expecting 'var' or 'c'");
			}
			return constrSide;
		}
		
	}
}