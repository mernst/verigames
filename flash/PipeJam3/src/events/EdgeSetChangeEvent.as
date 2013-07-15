package events 
{
	import scenes.game.display.GameNodeBase;
	import scenes.game.display.Level;
	import starling.events.Event;
	
	public class EdgeSetChangeEvent extends Event 
	{
		public static const EDGE_SET_CHANGED:String = "EDGE_SET_CHANGED";
		public static const LEVEL_EDGE_SET_CHANGED:String = "LEVEL_EDGE_SET_CHANGED";
		
		public var edgeSetChanged:GameNodeBase;
		public var newIsWide:Boolean;
		public var level:Level;
		public var silent:Boolean;
		
		public function EdgeSetChangeEvent(type:String, _edgeSetChanged:GameNodeBase, _newIsWide:Boolean, _level:Level = null, _silent:Boolean = false) 
		{
			super(type, true);
			edgeSetChanged = _edgeSetChanged;
			newIsWide = _newIsWide;
			level = _level;
			silent = _silent;
		}
		
	}

}