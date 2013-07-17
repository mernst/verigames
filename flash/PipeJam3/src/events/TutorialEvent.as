package events 
{
	import starling.events.Event;
	
	public class TutorialEvent extends Event 
	{
		public static const SHOW_CONTINUE:String = "SHOW_CONTINUE";
		public static const HIGHLIGHT_BOX:String = "HIGHLIGHT_BOX";
		public static const HIGHLIGHT_EDGE:String = "HIGHLIGHT_EDGE";
		public static const HIGHLIGHT_PASSAGE:String = "HIGHLIGHT_PASSAGE";
		public static const HIGHLIGHT_CLASH:String = "HIGHLIGHT_CLASH";
		public static const HIGHLIGHT_SCOREBLOCK:String = "HIGHLIGHT_SCOREBLOCK";
		
		public var componentId:String;
		public var highlightOn:Boolean;
		
		public function TutorialEvent(_type:String, _componentId:String = "", _highlightOn:Boolean = true) 
		{
			super(_type, true);
			componentId = _componentId;
			highlightOn = _highlightOn;
		}
	}

}