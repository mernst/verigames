package
{
	import flash.external.ExternalInterface;
	
	import scenes.*;
	import scenes.game.*;
	import scenes.login.*;
	
	import server.LoggingServerInterface;
	
	import starling.core.Starling;
	import starling.display.BlendMode;
	import starling.display.Image;
	import starling.display.Sprite;
	import starling.events.Event;
	import starling.text.TextField;
	import starling.utils.VAlign;

	
	public class PipeJamGame extends Game
	{
		/** True to log to the CGS server */
		public static var LOGGING_ON:Boolean = true;
		
		/** Set by flashVars */
		public static var DEBUG_MODE:Boolean = false;
		
		/** Set to true to print trace statements identifying the type of objects that are clicked on */
		public static var DEBUG_IDENTIFY_CLICKED_ELEMENTS_MODE:Boolean = false;
		
		/** True to not output any trace statements. */
		public static var SUPPRESS_TRACE_STATEMENTS:Boolean = true;
		
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
			scenesToCreate["LoginTestScene"] = LoginTestScene;
			
			this.addEventListener(starling.events.Event.ADDED_TO_STAGE, addedToStage);
			this.addEventListener(starling.events.Event.REMOVED_FROM_STAGE, removedFromStage);

		}
		
		
		//override to get your scene initialized for viewing
		protected function addedToStage(event:starling.events.Event):void
		{
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

	}
}