package constraints 
{
	import constraints.events.VarChangeEvent;
	import utils.PropDictionary;
	import starling.events.EventDispatcher;
	
	public class ConstraintVar extends EventDispatcher
	{
		
		public var id:String;
		public var formattedId:String;
		public var defaultVal:ConstraintValue;
		public var constant:Boolean;
		public var scoringConfig:ConstraintScoringConfig;
		public var associatedGroupId:String;
		
		private var m_props:PropDictionary;
		private var m_value:ConstraintValue;
		public var lhsConstraints:Vector.<Constraint> = new Vector.<Constraint>(); // constraints where this var appears on the left hand side (outgoing edge)
		public var rhsConstraints:Vector.<Constraint> = new Vector.<Constraint>(); // constraints where this var appears on the right hand side (incoming edge)
		
		public function ConstraintVar(_id:String, _val:ConstraintValue, _defaultVal:ConstraintValue, _constant:Boolean, _scoringConfig:ConstraintScoringConfig)
		{
			id = _id;
			m_value = _val;
			defaultVal = _defaultVal;
			constant = _constant;
			scoringConfig = _scoringConfig;
			m_props = new PropDictionary();
			if (m_value.intVal == 0) m_props.setProp(PropDictionary.PROP_NARROW, true);
			var suffixParts:Array = id.split("__");
			var prefixId:String = suffixParts[0];
			var idParts:Array = prefixId.split("_");
			if (idParts.length != 2) trace("Warning! Expected variables of the form var_2, type_0__var_2, found:" + id);
			formattedId = idParts[0] + ":" + idParts[1];
			for (var c:int = 2; c < idParts.length; c++) formattedId += "_" + idParts[c]; // add other parts of id, if any
		}
		
		public function getValue():ConstraintValue { return m_value; }
		public function getProps():PropDictionary { return m_props; }
		
		public function setProp(prop:String, value:Boolean):void
		{
			if (prop == PropDictionary.PROP_NARROW) {
				m_value = ConstraintValue.fromStr(value ? ConstraintValue.TYPE_0 : ConstraintValue.TYPE_1);
			} else {
				throw new Error("Unsupported property: " + prop);
			}
			if (m_props.hasProp(prop) != value) {
				trace(id, value ? " -> narrow" : " -> wide");
				m_props.setProp(prop, value);
				dispatchEvent(new VarChangeEvent(VarChangeEvent.VAR_CHANGED_IN_GRAPH, this, prop, value));
			}
		}
		
		public function toString():String
		{
			return id + "(=" + m_value.verboseStrVal + ")";
		}
	}

}