package audio
{
	import assets.AssetsAudio;
	import cgs.Audio.Audio;
	
	import flash.events.Event;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.utils.ByteArray;
	
	import starling.display.Button;
	import starling.events.Event;

	public class AudioManager
	{
		/** The cgs common audio class instance for playing all audio */
		private var m_audioDriver:Audio = new Audio();
		
		/** Audio is loading. */
		private var m_audioLoaded:Boolean = false;
		
		/** Button for user to turn music on/off */
		private var m_musicButton:Button;
		private var m_musicCallback:Function;
		
		/** Button for user to turn sound fx on/off */
		private var m_sfxButton:Button;
		private var m_sfxCallback:Function;

		private static var m_instance:AudioManager; // singleton instance

		public static function getInstance():AudioManager
		{
			if (m_instance == null) {
				m_instance = new AudioManager(new SingletonLock());
			}
			return m_instance;
		}
		
		public function AudioManager(lock:SingletonLock)
		{
			beginAudioLoad();
		}
		
		public function beginAudioLoad():void
		{
			if (m_audioLoaded) {
				return;
			}
			loadAudioFromEmbedded();
		}

		public function audioLoaded():Boolean
		{
			return m_audioLoaded;
		}
		
		public function audioDriver():Audio
		{
			return m_audioDriver;
		}

		private function loadAudioFromEmbedded():void
		{
			var audioXML:XML = AssetsAudio.getEmbeddedAudioXML();
			loadFromXML(audioXML);
		}
		
		private function loadFromXML(xml:XML):void
		{
			var xmlVec:Vector.<XML> = new Vector.<XML>();
			xmlVec.push(new XML(xml));
			m_audioDriver.init(xmlVec, new AudioResource());
			m_audioDriver.globalVolume = 0.3;
			m_audioLoaded = true;
		}
		
		public function setMusicButton(musicButton:Button, musicCallback:Function):void
		{
			m_musicButton = musicButton;
			m_musicButton.addEventListener(starling.events.Event.TRIGGERED, onMusicClick);
			
			m_musicCallback = musicCallback;
			updateMusicState();
		}
		
		public function get musicButton():Button
		{
			return m_musicButton;
		}
		
		private function onMusicClick(ev:starling.events.Event):void
		{
			audioDriver().musicOn = !audioDriver().musicOn;
			
			updateMusicState();
		}
		
		private function updateMusicState():void
		{
			if (m_musicCallback != null) {
				m_musicCallback(audioDriver().musicOn);
			}
		}
		
		public function setSfxButton(sfxButton:Button, sfxCallback:Function):void
		{
			m_sfxButton = sfxButton;
			m_sfxButton.addEventListener(starling.events.Event.TRIGGERED, onSfxClick);
			
			m_sfxCallback = sfxCallback;
			updateSfxState();
		}
		
		public function get sfxButton():Button
		{
			return m_sfxButton;
		}
		
		private function onSfxClick(ev:starling.events.Event):void
		{
			audioDriver().sfxOn = !audioDriver().sfxOn;
			
			updateSfxState();
		}
		
		private function updateSfxState():void
		{
			if (m_sfxCallback != null) {
				m_sfxCallback(audioDriver().sfxOn);
			}
		}
	}
}

internal class SingletonLock {} // to prevent outside construction of singleton
