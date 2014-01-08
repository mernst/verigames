package constraints 
{
	
	public class ConstraintValue extends ConstraintSide
	{
		public static const TYPE_0:String = "0";
		public static const TYPE_1:String = "1";
		
		public static const VERBOSE_TYPE_0:String = "type:0";
		public static const VERBOSE_TYPE_1:String = "type:1";
		
		public var val:uint;
		public var str:String;
		public var verbose:String;
		
		public function ConstraintValue(_val:uint) 
		{
			val = _val;
			switch (val) {
				case 0:
					str = TYPE_0;
					verbose = VERBOSE_TYPE_0;
					break;
				case 1:
					str = TYPE_1;
					verbose = VERBOSE_TYPE_1;
					break;
				default:
					throw new Error("Unexpected Constraint Value: " + val);
					break;
			}
		}
		
		public override function getValue():ConstraintValue
		{
			return this;
		}
		
		public function toString():String
		{
			return verbose;
		}
		
		public static function fromStr(str:String):ConstraintValue
		{
			switch (str) {
				case TYPE_0:
					return new ConstraintValue(0);
				case TYPE_1:
					return new ConstraintValue(1);
			}
			return null;
		}
		
		public static function fromVerboseStr(verboseStr:String):ConstraintValue
		{
			switch (verboseStr) {
				case VERBOSE_TYPE_0:
					return new ConstraintValue(0);
				case VERBOSE_TYPE_1:
					return new ConstraintValue(1);
			}
			return null;
		}
		
	}

}