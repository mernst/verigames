package constraints 
{
	import flash.utils.Dictionary;
	import flash.utils.getQualifiedClassName;

	public class ConstraintGraph 
	{
		public static const GAME_DEFAULT_VAR_VALUE:ConstraintValue = new ConstraintValue(0);
		
		private static const VERSION:String = "version";
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
		private static const TYPE_VALUE:String = "type_value";
		private static const KEYFOR_VALUES:String = "keyfor_value";
		// Constraint side types:
		private static const VAR:String = "var";
		private static const TYPE:String = "type";
		
		public var variableDict:Dictionary = new Dictionary();
		public var constraintsList:Vector.<Constraint> = new Vector.<Constraint>();
		public var graphScoringConfig:ConstraintScoringConfig = new ConstraintScoringConfig();
		
		private var m_score:Number;
		
		public function updateScore():void
		{
			m_score = 0;
			for (var varId:String in variableDict) {
				var thisVar:ConstraintVar = variableDict[varId] as ConstraintVar;
				if (thisVar.val != null && thisVar.scoringConfig != null) {
					// If there is a bonus for the current value of thisVar, add to score
					m_score += thisVar.scoringConfig.getScoringValue(thisVar.val.verbose);
				}
			}
			for (var i:int = 0; i < constraintsList.length; i++) {
				var thisConstr:Constraint = constraintsList[i];
				m_score += thisConstr.isSatisfied() ? graphScoringConfig.getScoringValue(ConstraintScoringConfig.CONSTRAINT_VALUE_KEY) : 0;
			}
			trace("Score: " + m_score);
		}
		
		public static function fromJSON(_json:String):ConstraintGraph
		{
			var levelObj:Object = JSON.parse(_json);
			var graph:ConstraintGraph = new ConstraintGraph();
			var ver:String = levelObj[VERSION];
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
							var varParamsObj:Object = variablesObj[varId];
							var typeValStr:String = varParamsObj[TYPE_VALUE];
							var typeVal:ConstraintValue = ConstraintValue.fromVerboseStr(typeValStr);
							if (typeVal == null) throw new Error("Unexpected type value: " + varParamsObj[TYPE_VALUE]);
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
							var newVar:ConstraintVar = new ConstraintVar(varId, typeVal, defaultVal, mergedVarScoring, possibleKeyfors, keyforVals);
							graph.variableDict[varId] = newVar;
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
						graph.constraintsList.push(newConstraint);
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
			
			var lhs:ConstraintSide = parseConstraintSide(lhsType, lhsId, _variableDictionary, _defaultVal);
			var rhs:ConstraintSide = parseConstraintSide(rhsType, rhsId, _variableDictionary, _defaultVal);
			
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
			
			var lhs:ConstraintSide = parseConstraintSide(lhsResult[1] as String, lhsResult[2] as String, _variableDictionary, _defaultVal);
			var rhs:ConstraintSide = parseConstraintSide(rhsResult[1] as String, rhsResult[2] as String, _variableDictionary, _defaultVal);
			
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
		
		private static function parseConstraintSide(_type:String, _id:String, _variableDictionary:Dictionary, _defaultVal:ConstraintValue):ConstraintSide
		{
			var constrSide:ConstraintSide;
			switch (_type) {
				case VAR:
					if (_variableDictionary.hasOwnProperty(_id)) {
						constrSide = _variableDictionary[_id] as ConstraintVar;
					} else {
						constrSide = new ConstraintVar(_id, _defaultVal, _defaultVal);
						_variableDictionary[_id] = constrSide;
					}
					break;
				case TYPE:
					constrSide = ConstraintValue.fromStr(_id);
					break;
				default:
					throw new Error("Invalid constraint var/type found: ('" + _type + "'). Expecting 'var' or 'type'");
					break;
			}
			return constrSide;
		}
		
	}

}