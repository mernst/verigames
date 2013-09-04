package events
{
	import scenes.game.display.GameComponent;
	
	import starling.events.Event;
	
	public class ToolTipEvent extends Event
	{
		public static const ADD_TOOL_TIP:String = "ADD_TOOL_TIP";
		public static const CLEAR_TOOL_TIP:String = "CLEAR_TOOL_TIP";
		public var component:GameComponent;
		public var text:String;
		public var fontSize:Number;
		public var persistent:Boolean;
		
		public function ToolTipEvent(type:String, _component:GameComponent, _text:String = "", _fontSize:Number = 8, _persistent:Boolean = false)
		{
			super(type, true);
			component = _component;
			text = _text;
			fontSize = _fontSize;
			persistent = _persistent;
		}
	}
}