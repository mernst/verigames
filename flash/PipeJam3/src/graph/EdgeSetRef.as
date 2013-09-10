package graph 
{
	import events.StampChangeEvent;
	import flash.events.EventDispatcher;
	import flash.utils.Dictionary;
	import graph.StampRef;
	
	public class EdgeSetRef extends EventDispatcher
	{
		public var id:String;
		public var edge_ids:Vector.<String> = new Vector.<String>();
		public var edges:Vector.<Edge> = new Vector.<Edge>();
		private var m_props:PropDictionary = new PropDictionary();
		// Possible stamps that the edge set can have, can only activate possible props
		private var m_possibleProps:PropDictionary;
		public var editable:Boolean = false;
		
		public function EdgeSetRef(_id:String) 
		{
			id = _id;
			m_possibleProps = new PropDictionary();
			// TODO: if edge set not editable, set to false
			m_possibleProps.setProp(PropDictionary.PROP_NARROW, true);
		}
		
		public function addStamp(_edge_set_id:String, _active:Boolean):void {
			m_possibleProps.setProp(PropDictionary.PROP_KEYFOR_PREFIX + _edge_set_id, true);
			m_props.setProp(PropDictionary.PROP_KEYFOR_PREFIX + _edge_set_id, _active);
		}
		
		public function removeStamp(_edge_set_id:String):void {
			m_possibleProps.setProp(PropDictionary.PROP_KEYFOR_PREFIX + _edge_set_id, false);
			m_props.setProp(PropDictionary.PROP_KEYFOR_PREFIX + _edge_set_id, false);
		}
		
		public function activateStamp(_edge_set_id:String):void {
			if (!canSetProp(PropDictionary.PROP_KEYFOR_PREFIX + _edge_set_id)) return;
			var change:Boolean = m_props.setPropCheck(PropDictionary.PROP_KEYFOR_PREFIX + _edge_set_id, true);
			if (change) onActivationChange();
		}
		
		public function deactivateStamp(_edge_set_id:String):void {
			if (!canSetProp(PropDictionary.PROP_KEYFOR_PREFIX + _edge_set_id)) return;
			var change:Boolean = m_props.setPropCheck(PropDictionary.PROP_KEYFOR_PREFIX + _edge_set_id, false);
			if (change) onActivationChange();
		}
		
		public function hasActiveStampOfEdgeSetId(_edge_set_id:String):Boolean {
			return m_props.hasProp(PropDictionary.PROP_KEYFOR_PREFIX + _edge_set_id);
		}
		
		public function onActivationChange():void {
			var ev:StampChangeEvent = new StampChangeEvent(StampChangeEvent.STAMP_ACTIVATION, this);
			dispatchEvent(ev);
		}
		
		public function canSetProp(prop:String):Boolean
		{
			return m_possibleProps.hasProp(prop);
		}
		
		public function setProp(prop:String, val:Boolean):void
		{
			if (!canSetProp(prop)) return;
			var change:Boolean = m_props.setPropCheck(prop, val);
			if (change && (prop.indexOf(PropDictionary.PROP_KEYFOR_PREFIX) == 0)) onActivationChange();
		}
		
		// Testbed
		public function getProps():PropDictionary
		{
			return m_props;
		}
	}

	
	
}