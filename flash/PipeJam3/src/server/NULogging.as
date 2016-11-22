package server 
{
	import flash.events.Event;
	import flash.events.HTTPStatusEvent;
	import flash.events.IEventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.events.SecurityErrorEvent;
	
	import server.LoggingServerInterface;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	import flash.net.URLRequestMethod;
	import flash.net.URLVariables;
	import flash.net.URLRequestHeader;
	import com.adobe.serialization.json.JSON;
	import Date;
	
	import scenes.game.display.World;

	import networking.HTTPCookies;
	
	/**
	 * ...
	 * @author ...
	 */
	public class NULogging 
	{
		public static var url:String = "http://viridian.ccs.neu.edu/api/objects/";//"http://crudapi-kdin.rhcloud.com/api/objects/";
		public static var loggingOn:Boolean = true;
		public static var request:URLRequest = new URLRequest(url);
		static public var postAlerts:Boolean = false;
		static public var EVENT_COMPLETE:int = 1;
		static public var EVENT_ERROR:int = 2;
		static private var seqNumber:Number = 0;
		
		

		public function NULogging()
		{

		}
		
		public static function log(logData:Object):void {
			
			if (loggingOn){
				var date:Date = new Date();
				logData["timestamp"] = date;
				var unixTimestamp:String = date.valueOf().toString();
				logData["UnixTimestamp"] = unixTimestamp;
				logData["HitId"] = World.hitId;
				logData["SeqNumber"] = seqNumber;
				trace("LOG__________________________________________________________________", LoggingServerInterface.obj2str(logData));
				
				var jsonHeader:URLRequestHeader = new URLRequestHeader("Content-type", "application/json");
				//request.requestHeaders.push(jsonHeader);
				
				request.data = LoggingServerInterface.obj2str(logData);
				request.method = URLRequestMethod.POST;	
				var urlLoader:URLLoader = new URLLoader();
				urlLoader = new URLLoader();
				urlLoader.dataFormat = URLLoaderDataFormat.TEXT;
				configureListeners(urlLoader);

				
				try {
					urlLoader.load(request);
					
				} catch (e:Error) {
					trace("Error logging sequence number: " + seqNumber + ", for log data: " + logData);
					trace(e);
				}
				
				seqNumber++;
			}
		}
		
		private static function configureListeners(dispatcher:flash.events.IEventDispatcher):void
		{
			dispatcher.addEventListener(flash.events.Event.COMPLETE, completeHandler);
			dispatcher.addEventListener(SecurityErrorEvent.SECURITY_ERROR, securityErrorHandler);
			dispatcher.addEventListener(HTTPStatusEvent.HTTP_STATUS, httpStatusHandler);
			dispatcher.addEventListener(IOErrorEvent.IO_ERROR, ioErrorHandler);
		}
		
		private static function securityErrorHandler(e:flash.events.SecurityErrorEvent):void
		{
			trace(e.text);
			if(postAlerts)
				HTTPCookies.displayAlert(e.text);
		}
		
		private static function httpStatusHandler(e:flash.events.HTTPStatusEvent):void
		{
			trace(e.status);
			if(postAlerts)
				HTTPCookies.displayAlert(String(e.status));
		}
		
		private static function ioErrorHandler(e:flash.events.IOErrorEvent):void
		{
			trace(e.text);
			if(postAlerts)
				HTTPCookies.displayAlert(e.text);
			
		}
		
		private static function completeHandler(e:flash.events.Event):void
		{
			try
			{
				trace("in complete " + e.target.data);
				
			}
			catch(err:Error)
			{
				trace("ERROR: failure in complete handler " + err);
			}
		}
		
	}

}
