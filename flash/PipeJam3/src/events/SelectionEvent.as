package events 
{
	import starling.events.Event;
	
	public class SelectionEvent extends Event 
	{
		public static var GROUP_SELECTED:String = "group_selected";
		public static var GROUP_UNSELECTED:String = "group_unselected";
		public static var COMPONENT_SELECTED:String = "component_selected";
		public static var COMPONENT_UNSELECTED:String = "component_unselected";
		
		public static var NUM_SELECTED_NODES_CHANGED:String = "num_sel_nodes_changed";
		
		public var selection:Vector.<Object>;
		public var component:Object;
		
		public function SelectionEvent(_type:String, _component:Object, _selection:Vector.<Object> = null) 
		{
			super(_type, true);
			component = _component;
			if (_selection == null) {
				_selection = new Vector.<Object>();
			}
			selection = _selection;
		}
		
	}

}