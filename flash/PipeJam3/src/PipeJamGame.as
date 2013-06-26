package
{
	import flash.external.ExternalInterface;
	
	import scenes.*;
	import scenes.game.*;
	import scenes.splashscreen.*;
	import scenes.login.*;
	import flash.display.LoaderInfo;
	
	import server.LoggingServerInterface;
	
	import starling.core.Starling;
	import starling.display.BlendMode;
	import starling.display.Image;
	import starling.display.Sprite;
	import starling.events.Event;
	import flash.events.Event;
	import starling.text.TextField;
	import starling.utils.VAlign;
	
	import display.PipeJamTheme;
	import feathers.themes.AeonDesktopTheme;
	
	public class PipeJamGame extends Game
	{
		/** True to log to the CGS server */
		public static var LOGGING_ON:Boolean = true;
		
		/** Set by flashVars */
		public static var DEBUG_MODE:Boolean = false;
		
		/** Set to true to print trace statements identifying the type of objects that are clicked on */
		public static var DEBUG_IDENTIFY_CLICKED_ELEMENTS_MODE:Boolean = false;
		
		/** Set to true if player logged into website (there's an express.sid cookie, and it's validated by server) */
		public static var PLAYER_LOGGED_IN:Boolean = false;
				
		/** list of all network connection objects spawned */
		protected static var networkConnections:Vector.<NetworkConnection>;

		public static var theme:PipeJamTheme;
		public static var theme1:AeonDesktopTheme;
		
		public function PipeJamGame()
		{
			super();
						
			if(!LoggingServerInterface.m_serverInitialized)
				LoggingServerInterface.initializeServer();
			
			// load general assets
			prepareAssets();
			
			scenesToCreate["SplashScreen"] = SplashScreenScene;
			scenesToCreate["PipeJamGame"] = PipeJamGameScene;
			scenesToCreate["LoginScene"] = LoginScene;
			
			
			this.addEventListener(starling.events.Event.ADDED_TO_STAGE, addedToStage);
			this.addEventListener(starling.events.Event.REMOVED_FROM_STAGE, removedFromStage);
		}
		
		
		//override to get your scene initialized for viewing
		protected function addedToStage(event:starling.events.Event):void
		{
			theme = new PipeJamTheme( this.stage );
		//	theme1 = new AeonDesktopTheme( this.stage );
			// create and show menu screen
			showScene("SplashScreen");
			
			
		}
		
		protected function removedFromStage(event:starling.events.Event):void
		{
			
		}
		
		
		/**
		 * This prints any debug messages to Javascript if embedded in a webpage with a script "printDebug(msg)"
		 * @param	_msg Text to print
		 */
		public static function printDebug(_msg:String):void {
			//			if (!SUPPRESS_TRACE_STATEMENTS) {
			//				trace(_msg);
			//				if (ExternalInterface.available) {
			//					//var reply:String = ExternalInterface.call("navTo", URLBASE + "browsing/card.php?id=" + quiz_card_asked + "&topic=" + TOPIC_NUM);
			//					var reply:String = ExternalInterface.call("printDebug", _msg);
			//				}
			//			}
		}
		
		/**
		 * This prints any debug messages to Javascript if embedded in a webpage with a script "printDebug(msg)" - Specifically warnings that may be wanted even if other debug messages are not
		 * @param	_msg Warning text to print
		 */
		public static function printWarning(_msg:String):void {
			if (!SUPPRESS_TRACE_STATEMENTS) {
				trace(_msg);
				if (ExternalInterface.available) {
					//var reply:String = ExternalInterface.call("navTo", URLBASE + "browsing/card.php?id=" + quiz_card_asked + "&topic=" + TOPIC_NUM);
					var reply:String = ExternalInterface.call("printDebug", _msg);
				}
			}
		}
		
		public static function addNetworkConnection(connection:NetworkConnection):void
		{
			if(networkConnections == null)
				networkConnections = new Vector.<NetworkConnection>;
			
			networkConnections.push(connection);
			
			//clean up list some, if any of the earliest connections done
			var frontNC:NetworkConnection = networkConnections[0];
			while(frontNC && frontNC.done == true)
			{
				networkConnections.pop();
				frontNC.dispose();
				frontNC = networkConnections[0];
			}
		}

	}
}