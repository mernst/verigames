package
{
	import audio.AudioManager;
	
	import buildInfo.BuildInfo;
	
	import cgs.Cache.Cache;
	
	import display.MusicButton;
	import display.PipeJamTheme;
	import display.SoundButton;
	
	import feathers.themes.AeonDesktopTheme;
	
	import flash.display.LoaderInfo;
	import flash.events.Event;
	import flash.external.ExternalInterface;
	import flash.system.System;
	import flash.ui.Keyboard;
	
	import scenes.*;
	import scenes.game.*;
	import networking.*;
	import scenes.loadingscreen.LoadingScreenScene;
	import scenes.splashscreen.*;
	import scenes.levelselectscene.LevelSelectScene;
	
	import starling.core.Starling;
	import starling.display.BlendMode;
	import starling.display.Image;
	import starling.display.Sprite;
	import starling.events.Event;
	import starling.events.KeyboardEvent;
	import starling.text.TextField;
	import starling.utils.VAlign;
	
	import utils.XSprite;
	
	public class PipeJamGame extends Game
	{
		/** Set by flashVars */
		public static var DEBUG_MODE:Boolean = false;
		
		/** Set to true to print trace statements identifying the type of objects that are clicked on */
		public static var DEBUG_IDENTIFY_CLICKED_ELEMENTS_MODE:Boolean = false;
		
		/** list of all network connection objects spawned */
		protected static var networkConnections:Vector.<NetworkConnection>;
		
		public static var SEPARATE_FILES:int = 1;
		public static var ALL_IN_ONE:int = 2;
		
		public static var theme:PipeJamTheme;
		public static var theme1:AeonDesktopTheme;
		
		private var m_musicButton:MusicButton;
		private var m_sfxButton:SoundButton;
		
		public function PipeJamGame()
		{
			super();
			
			// load general assets
			prepareAssets();
			
			scenesToCreate["LoadingScene"] = LoadingScreenScene;
			scenesToCreate["SplashScreen"] = SplashScreenScene;
			scenesToCreate["LevelSelectScene"] = LevelSelectScene;
			scenesToCreate["PipeJamGame"] = PipeJamGameScene;
			
			AudioManager.getInstance().audioDriver().reset();
			//AudioManager.getInstance().audioDriver().musicOn = !Boolean(Cache.getSave(Constants.CACHE_MUTE_MUSIC));
			AudioManager.getInstance().audioDriver().sfxOn = AudioManager.getInstance().audioDriver().musicOn = !Boolean(Cache.getSave(Constants.CACHE_MUTE_SFX));
			
			/*
			m_musicButton = new MusicButton();
			XSprite.setupDisplayObject(m_musicButton, 16.5, Constants.GameHeight - 14.5, 12.5);
			AudioManager.getInstance().setMusicButton(m_musicButton, updateMusicState);
			*/
			m_sfxButton = new SoundButton();
			XSprite.setupDisplayObject(m_sfxButton, 15, Constants.GameHeight - 22, 12.5);
			AudioManager.getInstance().setAllAudioButton(m_sfxButton, updateSfxState);
			
			this.addEventListener(starling.events.Event.ADDED_TO_STAGE, addedToStage);
			this.addEventListener(starling.events.Event.REMOVED_FROM_STAGE, removedFromStage);
		}
		
		
		//override to get your scene initialized for viewing
		protected function addedToStage(event:starling.events.Event):void
		{
			theme = new PipeJamTheme( this.stage );
			//	theme1 = new AeonDesktopTheme( this.stage );
			
			// create and show menu screen
			if(PipeJam3.RELEASE_BUILD && !PipeJam3.LOCAL_DEPLOYMENT)
				showScene("LoadingScene");
			else
			{
				PlayerValidation.playerID = PlayerValidation.playerIDForTesting;
				TutorialController.getTutorialController().getTutorialsCompletedByPlayer();
				showScene("SplashScreen");				
			}
			
			addChild(m_sfxButton);
			
			stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
		}
		
		protected function removedFromStage(event:starling.events.Event):void
		{
			stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
		}
		
		private function onKeyDown(event:KeyboardEvent):void
		{
			if (event.ctrlKey && event.altKey && event.shiftKey && event.keyCode == Keyboard.V) {
				var buildId:String = BuildInfo.DATE + "-" + BuildInfo.VERSION;
				trace(buildId);
				System.setClipboard(buildId);
			}
		}
		
		private function updateMusicState(musicOn:Boolean):void
		{
			m_musicButton.musicOn = musicOn;
			var result:Boolean = Cache.setSave(Constants.CACHE_MUTE_MUSIC, !musicOn)
			trace("Cache updateMusicState: " + result);
		}
		
		private function updateSfxState(sfxOn:Boolean):void
		{
			m_sfxButton.sfxOn = sfxOn;
			var result:Boolean = Cache.setSave(Constants.CACHE_MUTE_SFX, !sfxOn)
			trace("Cache updateSfxState: " + result);
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