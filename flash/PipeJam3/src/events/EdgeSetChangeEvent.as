package events 
{
	import flash.geom.Point;
	import scenes.game.display.GameNode;
	import scenes.game.display.Level;
	
	import starling.events.Event;
	
	public class EdgeSetChangeEvent extends Event 
	{
		public static const EDGE_SET_CHANGED:String = "EDGE_SET_CHANGED";
		public static const LEVEL_EDGE_SET_CHANGED:String = "LEVEL_EDGE_SET_CHANGED";
		
		public var edgeSetChanged:GameNode;
		public var prop:String;
		public var propValue:Boolean;
		public var level:Level;
		public var silent:Boolean;
		public var point:Point;
		
		public function EdgeSetChangeEvent(type:String, _edgeSetChanged:GameNode, _prop:String, _propValue:Boolean, _level:Level = null, _silent:Boolean = false, _point:Point = null) 
		{
			super(type, true);
			edgeSetChanged = _edgeSetChanged;
			prop = _prop;
			propValue = _propValue;
			level = _level;
			silent = _silent;
			point = _point;
		}
		
	}

}