package events 
{
	import graph.Edge;
	import scenes.game.display.GameNodeBase;
	import scenes.game.display.Level;
	import starling.events.Event;
	
	public class BallTypeChangeEvent extends Event 
	{
		public static const ENTER_BALL_TYPE_CHANGED:String = "ENTER_BALL_TYPE_CHANGED";
		public static const EXIT_BALL_TYPE_CHANGED:String = "EXIT_BALL_TYPE_CHANGED";
		
		/** True if enter_ball_type, False if exit_ball_type */
		public var oldType:uint;
		public var newType:uint;
		public var edge:Edge;
		
		public function BallTypeChangeEvent(eventType:String, _oldType:uint, _newType:uint, _edge:Edge) 
		{
			super(type, true);
			oldType = _oldType;
			newType = _newType;
			edge = _edge;
		}
		
	}

}