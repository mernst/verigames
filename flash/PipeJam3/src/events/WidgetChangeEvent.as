package events 
{
	import flash.geom.Point;
	import scenes.game.display.GameNode;
	import scenes.game.display.Level;
	
	import starling.events.Event;
	
	public class WidgetChangeEvent extends Event 
	{
		public static const WIDGET_CHANGED:String = "WIDGET_CHANGED";
		public static const LEVEL_WIDGET_CHANGED:String = "LEVEL_WIDGET_CHANGED";
		
		public var widgetChanged:GameNode;
		public var prop:String;
		public var propValue:Boolean;
		public var level:Level;
		public var silent:Boolean;
		public var point:Point;
		public var record:Boolean;
		
		public function WidgetChangeEvent(type:String, _widgetChanged:GameNode, _prop:String, _propValue:Boolean, _level:Level = null, _silent:Boolean = false, _point:Point = null, _record:Boolean = true) 
		{
			super(type, true);
			widgetChanged = _widgetChanged;
			prop = _prop;
			propValue = _propValue;
			level = _level;
			silent = _silent;
			point = _point;
			record = _record;
		}
		
	}

}