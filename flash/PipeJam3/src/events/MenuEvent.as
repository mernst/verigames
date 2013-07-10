package events 
{
	import starling.events.Event;
	
	public class MenuEvent extends Event 
	{
		public static var SAVE_LAYOUT:String = "save_layout";
		public static var SET_NEW_LAYOUT:String = "set_new_layout";
		public static var SUBMIT_SCORE:String = "submit_score";
		public static var SAVE_LOCALLY:String = "save_locally";
		
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