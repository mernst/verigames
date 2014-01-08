package constraints 
{
	
	public class Constraint 
	{
		public static const SUBTYPE:String = "subtype";
		public static const EQUALITY:String = "equality";
		public static const MAP_GET:String = "map.get";
		public static const IF_NODE:String = "selection_check";
		public static const GENERICS_NODE:String = "enabled_check";
		
		public var type:String;
		
		public function Constraint(_type:String) 
		{
			type = _type;
		}
		
		public function isSatisfied():Boolean
		{
			/* Implemented by children */
			return false;
		}
		
	}

}