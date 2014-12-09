package constraints 
{
	import constraints.events.VarChangeEvent;
	import utils.PropDictionary;
	import starling.events.EventDispatcher;
	
	public class ConstraintSide extends EventDispatcher
	{
		public var id:String;
		public var formattedId:String;
		public var associatedGroupId:String;
		public var scoringConfig:ConstraintScoringConfig;
		
		public var lhsConstraints:Vector.<Constraint> = new Vector.<Constraint>(); // constraints where this var appears on the left hand side (outgoing edge)
		public var rhsConstraints:Vector.<Constraint> = new Vector.<Constraint>(); // constraints where this var appears on the right hand side (incoming edge)
		
		public function ConstraintSide(_id:String, _scoringConfig:ConstraintScoringConfig)
		{
			id = _id;
			scoringConfig = _scoringConfig;
			var suffixParts:Array = id.split("__");
			var prefixId:String = suffixParts[0];
			var idParts:Array = prefixId.split("_");
			if (idParts.length != 2) trace("Warning! Expected variables of the form var_2, type_0__var_2, found:" + id);
			formattedId = idParts[0] + ":" + idParts[1];
			for (var c:int = 2; c < idParts.length; c++) formattedId += "_" + idParts[c]; // add other parts of id, if any
		}
		
		public function toString():String
		{
			return id;
		}
	}

}