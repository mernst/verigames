package system
{	
	import maxsat.MaxSatManager;
	
	public class MaxSatSolver
	{
		static private var m_mgr:MaxSatManager = new MaxSatManager();
		static private var unsat_best:int = -1;
		
		public static function test():void
		{
			run_solver([
				[10,  1, 2],
				[10, -1, -2],
				[10, 3, 4],
				[10, -3, -4]
			]);
			
			run_solver([
				[76222, -1, 2],
				[76222, 1, -2],
				[41225, 2, 3],
				[41225, -2, -3],
				[50104, -3, 1],
				[50104, 3, -1],
				[125307, 4, 5],
				[125307, -4, -5],
				[51429, 5, 6],
				[51429, -5, -6]
			]);
			
			run_solver([
				[20, -1, 10, 3, 4, -5],
				[30, -2, 3, 1],
				[50, -1, 9],
				[60, -8, 3],
				[10, -6, 8],
				[10, -1, 10, -7, -8, -9],
				[10, -6, 10],
				[10, -5, 1, 2],
				[10, -6, 9, 3, 4, -1],
				[10, -3, 5]
			]);
		}
		
		public static function run_solver(clause_arrays:Array, callback:Function = null):void
		{
			if(callback == null)
				m_mgr.start(clause_arrays, callbackFunction, function(err_msg:String):void { done_callback(err_msg, unsat_best); });
			else
				m_mgr.start(clause_arrays, callback, function(err_msg:String):void { done_callback(err_msg, unsat_best); });
		}
		
		private static function callbackFunction(vars:Array, unsat_weight:int):int
		{
			trace("Result:");
			for (var ii:int = 0; ii < vars.length; ++ ii) {
				trace(" ", ii + 1, "=", vars[ii]);
			}
			return 1;
		}
		
		private static function done_callback(err_msg:String, unsat_best:int):void
		{
			if (err_msg) {
				trace("ERROR:", err_msg);
			}
			
			trace("Expect: " + unsat_best);
		}
	}
}