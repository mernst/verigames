package
{
	import flash.external.ExternalInterface;
	import flash.net.URLVariables;
	import flash.system.System;
	import flash.ui.Keyboard;
	import flash.utils.Dictionary;
	
	import assets.AssetsAudio;
	
	import audio.AudioManager;
	
	import buildInfo.BuildInfo;
	
	import cgs.Cache.Cache;
	
	import display.GameObjectBatch;
	import display.MusicButton;
	import display.NineSliceBatch;
	import display.PipeJamTheme;
	import display.SoundButton;
	
	import events.MenuEvent;
	import events.NavigationEvent;
	
	import feathers.themes.AeonDesktopTheme;
	
	import networking.GameFileHandler;
	import networking.LevelInformation;
	import networking.PlayerValidation;
	import networking.TutorialController;
	
	import scenes.game.PipeJamGameScene;
	import scenes.levelselectscene.LevelSelectScene;
	import scenes.loadingscreen.LoadingScreenScene;
	import scenes.splashscreen.SplashScreenScene;
	
	import starling.core.Starling;
	import starling.events.Event;
	import starling.events.KeyboardEvent;
	
	import utils.XSprite;
	
	public class PipeJamGame extends Game
	{
		/** Set by flashVars */
		public static var DEBUG_MODE:Boolean = false;
		
		/** Set to true to print trace statements identifying the type of objects that are clicked on */
		public static var DEBUG_IDENTIFY_CLICKED_ELEMENTS_MODE:Boolean = false;
				
		public static var SEPARATE_FILES:int = 1;
		public static var ALL_IN_ONE:int = 2;
		
		public static var theme:PipeJamTheme;
		public static var theme1:AeonDesktopTheme;
		
		private var m_musicButton:MusicButton;
		private var m_sfxButton:SoundButton;
		
		private var m_gameObjectBatch:GameObjectBatch;
		
		/** this is the main holder of information about the level. */
		public static var levelInfo:LevelInformation;

		public static var m_pipeJamGame:PipeJamGame;
		
		public var m_fileName:String;

		
		public function PipeJamGame()
		{
			super();
			m_pipeJamGame = this;
			
			// load general assets
			prepareAssets();
			
			scenesToCreate["LoadingScene"] = LoadingScreenScene;
			scenesToCreate["SplashScreen"] = SplashScreenScene;
			scenesToCreate["LevelSelectScene"] = LevelSelectScene;
			scenesToCreate["PipeJamGame"] = PipeJamGameScene;
			
			AudioManager.getInstance().reset();
			//AudioManager.getInstance().audioDriver().musicOn = !Boolean(Cache.getSave(Constants.CACHE_MUTE_MUSIC));
			AudioManager.getInstance().audioDriver().sfxOn = AudioManager.getInstance().audioDriver().musicOn = !Boolean(Cache.getSave(Constants.CACHE_MUTE_SFX));
			
			/*
			m_musicButton = new MusicButton();
			XSprite.setupDisplayObject(m_musicButton, 16.5, Constants.GameHeight - 14.5, 12.5);
			AudioManager.getInstance().setMusicButton(m_musicButton, updateMusicState);
			*/
			m_sfxButton = new SoundButton();
			XSprite.setupDisplayObject(m_sfxButton, 20, Constants.GameHeight - 20, 12.5);
			AudioManager.getInstance().setAllAudioButton(m_sfxButton, updateSfxState);
			
			this.addEventListener(starling.events.Event.ADDED_TO_STAGE, addedToStage);
			this.addEventListener(starling.events.Event.REMOVED_FROM_STAGE, removedFromStage);
			
			this.addEventListener(MenuEvent.TOGGLE_SOUND_CONTROL, toggleSoundControl);
			addEventListener(NavigationEvent.GET_RANDOM_LEVEL, onGetRandomLevel);
			addEventListener(NavigationEvent.GET_SAVED_LEVEL, onGetSavedLevel);

		}	
		
		//override to get your scene initialized for viewing
		protected function addedToStage(event:starling.events.Event):void
		{			
			theme = new PipeJamTheme( this.stage );
			//	theme1 = new AeonDesktopTheme( this.stage );
			
			m_gameObjectBatch = new GameObjectBatch;
			NineSliceBatch.gameObjectBatch = m_gameObjectBatch;
			
			var obj:Object = Starling.current.nativeStage.loaderInfo.parameters;
			if(obj.hasOwnProperty("file"))
			{
				m_fileName = obj["file"];
			}
			else if (ExternalInterface.available) {
				var url:String = ExternalInterface.call("window.location.href.toString");
				var paramsStart:int = url.indexOf('?');
				if(paramsStart != -1)
				{
					var params:String = url.substring(paramsStart+1);
					var vars:URLVariables = new URLVariables(params);
					m_fileName = vars.file;
				}
			}
			
			// use file if set in url, else create and show menu screen
			if(m_fileName)
			{ 
				showScene("PipeJamGame");
			}
			else if(PipeJam3.RELEASE_BUILD && !PipeJam3.LOCAL_DEPLOYMENT)
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
			removeEventListener(NavigationEvent.GET_RANDOM_LEVEL, onGetRandomLevel);
		}
		
		private function onGetSavedLevel(event:NavigationEvent):void
		{
			PipeJamGameScene.inTutorial = false;
			PipeJamGame.levelInfo = GameFileHandler.findLevelObject(PipeJam3.m_saveLevelInfo.data.levelInfoID);
			//update assignmentsID if needed
			PipeJamGame.levelInfo.m_assignmentsID = PipeJam3.m_saveLevelInfo.data.assignmentsID;
			dispatchEvent(new NavigationEvent(NavigationEvent.CHANGE_SCREEN, "PipeJamGame"));
			
		}	
		
		protected function onGetRandomLevel(event:NavigationEvent):void
		{
			PipeJamGameScene.inTutorial = false;
			PipeJamGame.levelInfo = GameFileHandler.getRandomLevelObject();
			//save info locally so we can retrieve next run
			PipeJam3.m_saveLevelInfo.data.levelInfoID = PipeJamGame.levelInfo.m_id;
			PipeJam3.m_saveLevelInfo.data.levelID = PipeJamGame.levelInfo.m_levelID;
			PipeJam3.m_saveLevelInfo.data.assignmentsID = PipeJamGame.levelInfo.m_assignmentsID;
			PipeJam3.m_saveLevelInfo.data.layoutID = PipeJamGame.levelInfo.m_layoutID;
			PipeJam3.m_saveLevelInfo.data.assignmentUpdates = new Object();
			dispatchEvent(new NavigationEvent(NavigationEvent.CHANGE_SCREEN, "PipeJamGame"));
		}
		
		protected function toggleSoundControl(event:starling.events.Event):void
		{
			m_sfxButton.visible = event.data;
			if(m_sfxButton.visible)
			{
				AudioManager.getInstance().reset();
				AudioManager.getInstance().playMusic(AssetsAudio.MUSIC_FIELD_SONG);
			}
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
	}
}