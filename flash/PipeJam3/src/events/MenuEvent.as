package events 
{
	import starling.events.Event;
	
	public class MenuEvent extends Event 
	{
		public static var SAVE_LAYOUT:String = "save_layout";
		public static var SET_NEW_LAYOUT:String = "set_new_layout";
		public static var SUBMIT_LEVEL:String = "submit_level";
		public static var SAVE_LEVEL:String = "save_level";
		public static var ZOOM_IN:String = "zoom_in";
		public static var ZOOM_OUT:String = "zoom_out";
		public static var RECENTER:String = "recenter";
		
		public var layoutName:String;
		public var layoutXML:XML;
		
		public function MenuEvent(_type:String, _layoutName:String = "", _layoutXML:XML = null) 
		{
			super(_type, true);
			layoutName = _layoutName;
			layoutXML = _layoutXML;
		}
		
	}

}