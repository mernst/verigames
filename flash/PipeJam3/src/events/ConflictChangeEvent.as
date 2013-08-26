package events 
{
	import flash.events.Event;
	
	public class ConflictChangeEvent extends Event 
	{
		public static const CONFLICT_CHANGE:String = "CONFLICT_CHANGE";
		
		public function ConflictChangeEvent() 
		{
			super(CONFLICT_CHANGE, true);
			
		}
		
	}

}