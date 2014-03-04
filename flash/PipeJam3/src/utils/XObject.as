package utils
{
	
	/**
	 * My own extended Object class
	 * @author pavlik
	 */	
	public final class XObject
	{
		/**
		 * Take an input JSON compatible object and return clone of it
		 * @param	obj: Object to clone
		 * @return Cloned obj
		 */
		public static function clone(obj:Object):Object
		{
			var cloneStr:String = JSON.stringify(obj);
			var clone:Object = JSON.parse(cloneStr);
			return clone;
		}
	}
}
