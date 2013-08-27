package graph 
{
	import events.StampChangeEvent;
	import flash.events.EventDispatcher;
	import flash.utils.Dictionary;
	import graph.StampRef;
	
	public class EdgeSetRef extends EventDispatcher
	{
		public var stamp_dictionary:Dictionary = new Dictionary();
		public var edge_set_dictionary:Dictionary;
		public var id:String;
		public var edge_ids:Vector.<String> = new Vector.<String>();
		private var m_props:PropDictionary = new PropDictionary();
		
		public function EdgeSetRef(_id:String, _edge_set_dictionary:Dictionary) 
		{
			id = _id;
			edge_set_dictionary = _edge_set_dictionary;
		}
		
		public function addStamp(_edge_set_id:String, _active:Boolean):void {
			if (stamp_dictionary[_edge_set_id] == null) {
				stamp_dictionary[_edge_set_id] = new StampRef(_edge_set_id, _active, this);
			} else if ((stamp_dictionary[_edge_set_id] as StampRef).active != _active) {
				(stamp_dictionary[_edge_set_id] as StampRef).active = _active;
			}
			m_props.setProp(PropDictionary.PROP_KEYFOR_PREFIX + _edge_set_id, _active);
		}
		
		public function removeStamp(_edge_set_id:String):void {
			delete stamp_dictionary[_edge_set_id];
			m_props.setProp(PropDictionary.PROP_KEYFOR_PREFIX + _edge_set_id, false);
		}
		
		public function activateStamp(_edge_set_id:String):void {
			if (stamp_dictionary[_edge_set_id]) {
				(stamp_dictionary[_edge_set_id] as StampRef).active = true;
			}
			var change:Boolean = m_props.setPropCheck(PropDictionary.PROP_KEYFOR_PREFIX + _edge_set_id, true);
			if (change) onActivationChange();
		}
		
		public function deactivateStamp(_edge_set_id:String):void {
			if (stamp_dictionary[_edge_set_id]) {
				(stamp_dictionary[_edge_set_id] as StampRef).active = false;
			}
			var change:Boolean = m_props.setPropCheck(PropDictionary.PROP_KEYFOR_PREFIX + _edge_set_id, false);
			if (change) onActivationChange();
		}
		
		public function hasActiveStampOfEdgeSetId(_edge_set_id:String):Boolean {
			if (stamp_dictionary[_edge_set_id] == null) {
				return false;
			}
			return (stamp_dictionary[_edge_set_id] as StampRef).active;
		}
		
		public function get num_stamps():uint {
			var i:int = 0;
			for (var edge_set_id:String in stamp_dictionary) {
				i++;
			}
			return i;
		}
		
		public function get num_active_stamps():uint {
			var i:int = 0;
			for (var edge_set_id:String in stamp_dictionary) {
				if ((stamp_dictionary[edge_set_id] as StampRef).active) {
					i++;
				}
			}
			return i;
		}
		
		public function onActivationChange():void {
			var ev:StampChangeEvent = new StampChangeEvent(StampChangeEvent.STAMP_ACTIVATION, this);
			dispatchEvent(ev);
		}
		
		// Testbed
		public function getProps():PropDictionary
		{
			return m_props;
		}
	}

	
	
}