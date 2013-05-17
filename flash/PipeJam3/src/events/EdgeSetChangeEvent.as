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
		public var level:Level;
		
		public function EdgeSetChangeEvent(type:String, _edgeSetChanged:GameNodeBase, _level:Level = null) 
		{
			super(type, true);
			edgeSetChanged = _edgeSetChanged;
			level = _level;
		}
		
	}

}