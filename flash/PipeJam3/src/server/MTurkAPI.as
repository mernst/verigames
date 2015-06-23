package server 
{
	import flash.events.Event;
	import flash.external.ExternalInterface;
	import flash.net.URLRequestMethod;
	
	import networking.NetworkConnection;
	
	public class MTurkAPI 
	{
		private static var m_instance:MTurkAPI;
		
		public var workerToken:String;
		public var taskId:String = "101";
		
		public static function getInstance():MTurkAPI
		{
			if (m_instance == null) {
				m_instance = new MTurkAPI(new SingletonLock());
			}
			return m_instance;
		}
		
		
		
		public function MTurkAPI(lock:SingletonLock) 
		{
			// TODO: get time?
		}
		
		public function onTaskComplete(callback:Function):void
		{
			var url:String = NetworkConnection.productionInterop + "?function=mTurkTaskComplete&data_id='test'";
			var method:String = URLRequestMethod.POST;
			function thisCallback(result:int, e:Event):void
			{
				if (e == null)
				{
					if (ExternalInterface.available) ExternalInterface.call("console.log", "interop.php mTurkTaskComplete bad response");
					callback(null);
				}
				var code:String = e.target.data as String;
				if (ExternalInterface.available) ExternalInterface.call("console.log", "interop.php mTurkTaskComplete code:" + code + " result:" + result);
				callback(code);
			}
			if (ExternalInterface.available) ExternalInterface.call("console.log", "calling " + url);
			var data:String = JSON.stringify( { "test":1 } );
			NetworkConnection.sendMessage(thisCallback, data, url, method);
		}
		
	}

}

internal class SingletonLock {} // to prevent outside construction of singleton