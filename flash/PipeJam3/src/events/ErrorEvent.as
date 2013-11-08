package events 
{
	import particle.ErrorParticleSystem;
	import starling.events.Event;
	
	public class ErrorEvent extends Event 
	{
		public static const ERROR_ADDED:String = "error_added";
		public static const ERROR_REMOVED:String = "error_removed";
		
		public var errorParticleSystem:ErrorParticleSystem;
		
		public function ErrorEvent(type:String, _errorParticleSystem:ErrorParticleSystem) 
		{
			super(type, true);
			errorParticleSystem = _errorParticleSystem;
		}
		
	}

}