package server 
{
	
	import server.LoggingServerInterface;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	import flash.net.URLRequestMethod;
	import flash.net.URLVariables;
	
	/**
	 * ...
	 * @author ...
	 */
	public class NULogging 
	{
		public static var url:String = "http://crudapi-kdin.rhcloud.com/api/objects/";
		public static var request:URLRequest = new URLRequest(url);
		
		public function NULogging()
		{

		}
		
		public static function log(logData:Object):void{
				
			request.data = LoggingServerInterface.obj2str(logData);
			request.method = URLRequestMethod.POST;	
			var urlLoader:URLLoader = new URLLoader();
			urlLoader = new URLLoader();
			urlLoader.dataFormat = URLLoaderDataFormat.TEXT;
			
			try {
				urlLoader.load(request);
			} catch (e:Error) {
				trace(e);
			}
			
		}
		
	}

}