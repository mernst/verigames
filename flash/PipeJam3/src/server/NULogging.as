package server 
{
	import flash.events.Event;
	import flash.events.HTTPStatusEvent;
	import flash.events.IEventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.events.SecurityErrorEvent;
	import org.osmf.utils.Version;
	
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
	import mx.utils.UIDUtil;
	
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
		
		static public var trial_id:String;
		static public var session_id:String;
		static public var run_id:String;
		static public var player_id:String;
		static public var version:uint = 1;
		
		static public var run_count:uint;
		static public var run_seqno:uint;
		static public var action_count:uint;
		static public var action_seqno:uint;
		
		static public const ACTION_TYPE_NEXT_LEVEL_CLICKED:uint = 1;
		static public const ACTION_TYPE_SKIP_LEVEL_CLICKED:uint = 2;
		static public const ACTION_TYPE_SKIP_TO_SURVEY_CLICKED:uint = 3;
		static public const ACTION_TYPE_TARGET_SCORE_REACHED:uint = 4;
		static public const ACTION_TYPE_PARADOX_SOLVED:uint = 5;
		static public const ACTION_TYPE_BRUSH_SELECTION_CHANGED:uint = 6;
		static public const ACTION_TYPE_WINDOW_RESIZED:uint = 7;
		static public const ACTION_TYPE_NEW_LEVEL_LOADED:uint = 8;
		static public const ACTION_TYPE_MOUSE_CLICKED:uint = 9;
		static public const ACTION_TYPE_KEY_INPUT:uint = 10;
		static public const ACTION_TYPE_HELP_BUTTON_CLICKED:uint = 11;

		public function NULogging()
		{
			// Nothing so far..
		}
		
		public static function sessionBegin(o:Object):void {
			// At the begining of a new session, always renew the session Id.
			NULogging.session_id = UIDUtil.createUID();
			
			// Reset run count for every session to 0. Reset seqno to 0 for every session.
			NULogging.run_seqno = 0;
			NULogging.run_count = 0;
			
			// Assign player id and hit id in ever session
			NULogging.player_id = World.playerID;
			NULogging.trial_id = World.hitId;
			
			// Finally, log the new object.
			var data:Object = new Object();
			data["session_id"] = NULogging.session_id;
			data["game_id"] = "Paradox";
			data["build_id"] = World.hitId;
			data["condition"] = uint(1);
			data["browser"] = "Unknown";
			data["os"] = "Unknown";
			data["hardware"] = "Unknown";
			data["details"] = o;
			
			logData("session_begin", data);
		}
		
		public static function sessionEnd():void {
			var o:Object = new Object();
			
			// Add the ession id that's about to end and the count of runs in this session.
			o["session_id"] = NULogging.session_id;
			o["run_count"] = NULogging.run_count;
			o["details"] = "";
			
			// Finally log it.
			logData("session_end", o);
		}
		
		public static function runBegin(o:Object):void {
			
			// imcrease the value of run count for every run begin.
			NULogging.run_count++;
			
			// inncrement the value of seqno for every run begin.
			NULogging.run_seqno++;
			
			// Generate a new Run Id.
			NULogging.run_id = UIDUtil.createUID();
			
			// Reset action_seqno, action_count to 0
			NULogging.action_seqno = 0;
			NULogging.action_count = 0;
			
			var data:Object = new Object();
			
			data["session_id"] = NULogging.session_id;
			data["run_id"] = NULogging.run_id;
			data["run_seqno"] = NULogging.run_seqno;
			data["definition"] = "New Level Started";
			data["details"] = o;
			
			
			logData("run_begin", data);
		}
		
		public static function runEnd(o:Object):void {			
			// assuming o has some kind of score information in it..
			var data:Object = new Object();
			
			data["details"] = o;
			data["session_id"] = NULogging.session_id;
			data["run_id"] = NULogging.run_id;
			data["action_count"] = NULogging.action_count;
			data["score"] = Number(0.0);
			
			logData("run_end", data);
		}
		
		public static function action(o:Object, type:uint): void {
			
			// Increase action_count to note how many actions took place.
			NULogging.action_count++;
			
			// increment action_seqno to note which sequence number this action currently is in.
			NULogging.action_seqno++;
			var data:Object = new Object();
			data["details"] = o;
			
			data["run_id"] = NULogging.run_id;
			data["action_seqno"] = NULogging.action_seqno;		
			data["type"] = type;
			data["frame"] = uint(0);
			
			logData("action", data);
		}
		
		private static function logData(type:String, data:Object):void {
			// Add the timestamp
			var date:Date = new Date();
			data["client_time"] = date;
			data["unix_timestamp"] = date.valueOf().toString();	 //Unix timestamp needed to generate level ratings using playback_driver
			
			// Add all constants
			data["trial_id"] = NULogging.trial_id;
			data["player_id"] = NULogging.player_id;
			data["version"] = NULogging.version;
			
			var dataToLog:Object = new Object();
			dataToLog["type"] = type;
			dataToLog.data = data;
			
			
			// Finally log the data
			trace("LOG__________________________________________________________________", LoggingServerInterface.obj2str(dataToLog));
			
			if (loggingOn)
			{
				var jsonHeader:URLRequestHeader = new URLRequestHeader("Content-type", "application/json");
				//request.requestHeaders.push(jsonHeader);
				
				
				request.data = com.adobe.serialization.json.JSON.encode(dataToLog);
				request.method = URLRequestMethod.POST;	
				var urlLoader:URLLoader = new URLLoader();
				urlLoader.dataFormat = URLLoaderDataFormat.TEXT;
				configureListeners(urlLoader);

				
				try {
					urlLoader.load(request);					
				} catch (e:Error) {
					trace("Error logging sequence number: " + seqNumber + ", for log data: " + dataToLog);
					trace(e);
				}
			}
				
		}
		
		public static function log(logData:Object):void {
			
			if (loggingOn){
				var date:Date = new Date();
				logData["timestamp"] = date;
				var unixTimestamp:String = date.valueOf().toString();
				logData["unix_timestamp"] = unixTimestamp;
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
