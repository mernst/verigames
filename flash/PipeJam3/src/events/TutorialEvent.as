package events 
{
	import starling.events.Event;
	
	public class TutorialEvent extends Event 
	{
		public static const SHOW_CONTINUE:String = "SHOW_CONTINUE";
		public static const HIGHLIGHT_BOX:String = "HIGHLIGHT_BOX";
		
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