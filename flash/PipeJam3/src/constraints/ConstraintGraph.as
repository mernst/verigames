package constraints 
{
	import flash.utils.Dictionary;
	import flash.utils.getQualifiedClassName;
	import utils.XString;

	public class ConstraintGraph 
	{
		public static const GAME_DEFAULT_VAR_VALUE:ConstraintValue = new ConstraintValue(0);
		
		private static const VERSION:String = "version";
		private static const QID:String = "qid";
		// Sections:
		private static const SCORING:String = "scoring";
		private static const VARIABLES:String = "variables";
		private static const CONSTRAINTS:String = "constraints";
		// Constraint fields:
		private static const CONSTRAINT:String = "constraint";
		private static const LHS:String = "lhs";
		private static const RHS:String = "rhs";
		// Variable fields:
		private static const DEFAULT:String = "default";
		private static const SCORE:String = "score";
		private static const POSSIBLE_KEYFORS:String = "possible_keyfor";
		public static const TYPE_VALUE:String = "type_value";
		public static const KEYFOR_VALUES:String = "keyfor_value";
		private static const CONSTANT:String = "constant";
		// Constraint side types:
		private static const VAR:String = "var";
		private static const TYPE:String = "type";
		
		public var variableDict:Dictionary = new Dictionary();
		public var constraintsDict:Dictionary = new Dictionary();
		public var graphScoringConfig:ConstraintScoringConfig = new ConstraintScoringConfig();
		
		public var score:Number;
		public var qid:int = -1;
		
		public function updateScore():void
		{
			score = 0;
			for (var varId:String in variableDict) {
				var thisVar:ConstraintVar = variableDict[varId] as ConstraintVar;
				if (thisVar.getValue() != null && thisVar.scoringConfig != null) {
					// If there is a bonus for the current value of thisVar, add to score
					score += thisVar.scoringConfig.getScoringValue(thisVar.getValue().verboseStrVal);
				}
			}
			for (var constraintId:String in constraintsDict) {
				var thisConstr:Constraint = constraintsDict[constraintId] as Constraint;
				score += thisConstr.isSatisfied() ? graphScoringConfig.getScoringValue(ConstraintScoringConfig.CONSTRAINT_VALUE_KEY) : 0;
			}
			trace("Score: " + score);
		}
		
		public static function fromString(_json:String):ConstraintGraph
		{
			var levelObj:Object = JSON.parse(_json);
			return fromJSON(levelObj);
		}
		
		public static function fromJSON(levelObj:Object):ConstraintGraph
		{
			var graph:ConstraintGraph = new ConstraintGraph();
			var ver:String = levelObj[VERSION];
			graph.qid = parseInt(levelObj[QID]);
			switch (ver) {
				case "1": // Version 1
					// No "default" specified in json, use game default
					var graphDefaultVal:ConstraintValue = GAME_DEFAULT_VAR_VALUE;
					
					// Build Scoring
					var scoringObj:Object = levelObj[SCORING];
					var constraintScore:int = scoringObj[ConstraintScoringConfig.CONSTRAINT_VALUE_KEY];
					var variableScoreObj:Object = scoringObj[VARIABLES];
					var type0Score:int = variableScoreObj[ConstraintScoringConfig.TYPE_0_VALUE_KEY];
					var type1Score:int = variableScoreObj[ConstraintScoringConfig.TYPE_1_VALUE_KEY];
					graph.graphScoringConfig.updateScoringValue(ConstraintScoringConfig.CONSTRAINT_VALUE_KEY, constraintScore);
					graph.graphScoringConfig.updateScoringValue(ConstraintScoringConfig.TYPE_0_VALUE_KEY, type0Score);
					graph.graphScoringConfig.updateScoringValue(ConstraintScoringConfig.TYPE_1_VALUE_KEY, type1Score);
					
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
							var typeVal:ConstraintValue = ConstraintValue.fromVerboseStr(typeValStr) || graphDefaultVal.clone();
							var varScoring:ConstraintScoringConfig = new ConstraintScoringConfig();
							var scoreObj:Object = varParamsObj[SCORE];
							if (scoreObj) {
								var type0VarScore:int = scoreObj[ConstraintScoringConfig.TYPE_0_VALUE_KEY];
								var type1VarScore:int = scoreObj[ConstraintScoringConfig.TYPE_1_VALUE_KEY];
								varScoring.updateScoringValue(ConstraintScoringConfig.TYPE_0_VALUE_KEY, type0VarScore);
								varScoring.updateScoringValue(ConstraintScoringConfig.TYPE_1_VALUE_KEY, type1VarScore);
							}
							var mergedVarScoring:ConstraintScoringConfig = ConstraintScoringConfig.merge(graph.graphScoringConfig, varScoring);
							var defaultValStr:String = varParamsObj[DEFAULT];
							var defaultVal:ConstraintValue;
							if (defaultValStr) defaultVal = ConstraintValue.fromVerboseStr(defaultValStr);
							var possibleKeyfors:Vector.<String> = new Vector.<String>();
							var possibleKeyforsArr:Array = varParamsObj[POSSIBLE_KEYFORS];
							if (possibleKeyforsArr) {
								for (var i:int = 0; i < possibleKeyforsArr.length; i++) possibleKeyfors.push(possibleKeyforsArr[i]);
							}
							var keyforVals:Vector.<String> = new Vector.<String>();
							var keyforValsArr:Array = varParamsObj[KEYFOR_VALUES];
							if (keyforValsArr) {
								for (var j:int = 0; j < keyforValsArr.length; j++) keyforVals.push(keyforValsArr[j]);
							}
							var newVar:ConstraintVar = new ConstraintVar(formattedId, typeVal, defaultVal, isConstant, mergedVarScoring, possibleKeyfors, keyforVals);
							graph.variableDict[formattedId] = newVar;
						}
					}
					
					// Build constraints (and add any uninitialized variables to graph.variableDict)
					var constraintsArr:Array = levelObj[CONSTRAINTS];
					for (var c:int = 0; c < constraintsArr.length; c++) {
						var newConstraint:Constraint;
						if (getQualifiedClassName(constraintsArr[c]) == "String") {
							// process as String, i.e. "var:1 <= var:2"
							newConstraint = parseConstraintString(constraintsArr[c] as String, graph.variableDict, graphDefaultVal);
						} else {
							// process as json object i.e. {"rhs": "type:1", "constraint": "subtype", "lhs": "var:9"}
							newConstraint = parseConstraintJson(constraintsArr[c] as Object, graph.variableDict, graphDefaultVal);
						}
						if (newConstraint is EqualityConstraint) {
							// For equality, convert to two separate equality constaints (one for each edge) and put in constraintsDict
							// Scoring: take same scoring for now, any conflict on EITHER subtype constraint will cause -100 (or whatever conflict penalty is for the equality constrtaint)
							var constr1:SubtypeConstraint = new SubtypeConstraint(newConstraint.lhs, newConstraint.rhs, newConstraint.customScoring);
							var constr2:SubtypeConstraint = new SubtypeConstraint(newConstraint.rhs, newConstraint.lhs, newConstraint.customScoring);
							graph.constraintsDict[constr1.lhs.id + " -> " + constr1.rhs.id] = constr1;
							graph.constraintsDict[constr2.lhs.id + " -> " + constr2.rhs.id] = constr2;
						} else if (newConstraint is SubtypeConstraint) {
							graph.constraintsDict[newConstraint.lhs.id + " -> " + newConstraint.rhs.id] = newConstraint;
						}
					}
					
					break;
				default:
					throw new Error("ConstraintGraph.fromJSON:: Unknown version encountered: " + ver);
					break;
			}
			graph.updateScore();
			return graph;
		}
		
		private static function parseConstraintString(_str:String, _variableDictionary:Dictionary, _defaultVal:ConstraintValue):Constraint
		{
			var pattern:RegExp = /(var|type):(.*) ?(<|=)= ?(var|type):(.*)/i;
			var result:Object = pattern.exec(_str);
			if (result == null) throw new Error("Invalid constraint string found: " + _str);
			if (result.length != 6) throw new Error("Invalid constraint string found: " + _str);
			var lhsType:String = result[1];
			var lhsId:String = result[2];
			var constType:String = result[3];
			var rhsType:String = result[4];
			var rhsId:String = result[5];
			
			var lsuffix:String = "";
			var rsuffix:String = "";
			if (lhsType == VAR && rhsType == TYPE) {
				rsuffix = "__" + VAR + "_" + lhsType;
			} else if (rhsType == VAR && lhsType == TYPE) {
				lsuffix = "__" + VAR + "_" + rhsType;
			} else if (rhsType == TYPE && lhsType == TYPE) {
				trace("WARNING! Constraint found between two types (no var): " + JSON.stringify(_str));
			}
			
			var lhs:ConstraintVar = parseConstraintSide(lhsType, lhsId, lsuffix, _variableDictionary, _defaultVal);
			var rhs:ConstraintVar = parseConstraintSide(rhsType, rhsId, rsuffix, _variableDictionary, _defaultVal);
			
			var newConstraint:Constraint;
			switch (constType) {
				case "<":
					newConstraint = new SubtypeConstraint(lhs, rhs);
					break;
				case "=":
					newConstraint = new EqualityConstraint(lhs, rhs);
					break;
				default:
					throw new Error("Invalid constraint type found ('"+constType+"') in string: " + _str);
					break;
			}
			return newConstraint;
		}
		
		private static function parseConstraintJson(_constraintJson:Object, _variableDictionary:Dictionary, _defaultVal:ConstraintValue):Constraint
		{
			var type:String = _constraintJson[CONSTRAINT];
			var lhsStr:String = _constraintJson[LHS];
			var rhsStr:String = _constraintJson[RHS];
			var pattern:RegExp = /(var|type):(.*)/i;
			var lhsResult:Object = pattern.exec(lhsStr);
			var rhsResult:Object = pattern.exec(rhsStr);
			if (!lhsResult || !rhsResult) throw new Error("Error parsing constraint json for lhs:'" + lhsStr + "' rhs:'" + rhsStr + "'");
			if (lhsResult.length != 3 || rhsResult.length != 3) throw new Error("Error parsing constraint json for lhs:'" + lhsStr + "' rhs:'" + rhsStr + "'");
			
			var lsuffix:String = "";
			var rsuffix:String = "";
			if ((lhsResult[1] as String) == VAR && (rhsResult[1] as String) == TYPE) {
				rsuffix = "__" + VAR + "_" + (lhsResult[2] as String);
			} else if ((rhsResult[1] as String) == VAR && (lhsResult[1] as String) == TYPE) {
				lsuffix = "__" + VAR + "_" + (rhsResult[2] as String);
			} else if ((lhsResult[1] as String) == TYPE && (rhsResult[1] as String) == TYPE) {
				trace("WARNING! Constraint found between two types (no var): " + JSON.stringify(_constraintJson));
			}
			
			var lhs:ConstraintVar = parseConstraintSide(lhsResult[1] as String, lhsResult[2] as String, lsuffix, _variableDictionary, _defaultVal);
			var rhs:ConstraintVar = parseConstraintSide(rhsResult[1] as String, rhsResult[2] as String, rsuffix, _variableDictionary, _defaultVal);
			
			var newConstraint:Constraint;
			switch (type) {
				case Constraint.SUBTYPE:
					newConstraint = new SubtypeConstraint(lhs, rhs);
					break;
				case Constraint.EQUALITY:
					newConstraint = new EqualityConstraint(lhs, rhs);
					break;
				default:
					throw new Error("Invalid constraint type found ('"+type+"') in parseConstraintJson()");
					break;
			}
			return newConstraint;
		}
		
		private static function parseConstraintSide(_type:String, _type_num:String, _typeSuffix:String, _variableDictionary:Dictionary, _defaultVal:ConstraintValue):ConstraintVar
		{
			var constrVar:ConstraintVar;
			var fullId:String = _type + "_" + _type_num + _typeSuffix;
			if (_variableDictionary.hasOwnProperty(fullId)) {
				constrVar = _variableDictionary[fullId] as ConstraintVar;
			} else {
				if (_type == VAR) {
					constrVar = new ConstraintVar(fullId, _defaultVal, _defaultVal);
				} else if (_type == TYPE) {
					var constrVal:ConstraintValue = ConstraintValue.fromStr(_type_num);
					constrVar = new ConstraintVar(fullId, constrVal, constrVal, true);
				} else {
					throw new Error("Invalid constraint var/type found: ('" + _type + "'). Expecting 'var' or 'type'");
				}
				_variableDictionary[fullId] = constrVar;
			}
			return constrVar;
		}
		
	}

}