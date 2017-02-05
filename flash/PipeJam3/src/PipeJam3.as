package  
{
	import assets.StringTablePowerPlant;
	import assets.StringTable;
	import assets.StringTableBase;
	import assets.StringTableMTurk;
	import com.spikything.utils.MouseWheelTrap;
	import flash.events.MouseEvent;
	import server.MTurkAPI;
	
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	import flash.external.ExternalInterface;
	import flash.geom.Rectangle;
	import flash.text.TextField;
	import flash.text.TextFormat;
	import scenes.game.display.World;
	import assets.AssetsFont;
	
	import cgs.server.logging.data.QuestData;
	
	import dialogs.SimpleAlertDialog;
	
	import events.MenuEvent;
	import events.NavigationEvent;
	
	import net.hires.debug.Stats;
	
	import networking.Achievements;
	import networking.GameFileHandler;
	import networking.HTTPCookies;
	import networking.NetworkConnection;


	
	import server.LoggingServerInterface;
	import server.ReplayController;
	
	import starling.core.Starling;
	
	import system.VerigameServerConstants;
	
	

	[SWF(width = "960", height = "640", frameRate = "30", backgroundColor = "#ffffff")]
	[Frame(factoryClass='Preloader')]
	public class PipeJam3 extends flash.display.Sprite 
	{
		static public var GAME_ID:int = 1;
		
		private var mStarling:Starling;
		
		/** At most one of these two should be true. They can both be false. */
		public static const RELEASE_BUILD:Boolean = false;
		public static const TUTORIAL_DEMO:Boolean = false;
		public static var ASSET_SUFFIX:String = ""; // specify "Turk" to change atlases to turk
		
		//if release build is true, true if using production machine db/info, false if using staging
		public static const PRODUCTION_BUILD:Boolean = true;
		
		/** turn on logging of game play. */
		public static var LOGGING_ON:Boolean = true;
		
		/** to be hosted on the installer dvd. Changes location of scripts on server */
		public static var INSTALL_DVD:Boolean = false;
		
		/** show frames per second, and memory usage. */
		public static var SHOW_PERFORMANCE_STATS:Boolean = false;
		
		public static var REPLAY_DQID:String;// = "dqid_5252fd7aa741e8.90134465";
		private static const REPLAY_TEXT_FORMAT:TextFormat = new TextFormat(AssetsFont.FONT_UBUNTU, 6, 0xFFFF00);
		
		public static const DISABLE_FILTERS:Boolean = true;

		public static const SELECTION_STYLE_CLASSIC:uint                = 0;
		public static const SELECTION_STYLE_VAR_BY_VAR:uint             = 1;
		public static const SELECTION_STYLE_VAR_BY_VAR_AND_CNSTR:uint   = 2;
		public static var SELECTION_STYLE:uint = SELECTION_STYLE_VAR_BY_VAR_AND_CNSTR;

		public static var logging:LoggingServerInterface;
		public static const loggingKey:String = (ASSET_SUFFIX == "Turk") ? LoggingServerInterface.SETUP_KEY_TURK : LoggingServerInterface.SETUP_KEY_FRIENDS_AND_FAMILY_BETA;
		protected var hasBeenAddedToStage:Boolean = false;
		protected var isFullScreen:Boolean = false;

		static public var pipeJam3:PipeJam3;
		
		private static var m_replayText:TextField = new TextField();
		
		public function PipeJam3()
		{
			pipeJam3 = this;
		
			addEventListener(flash.events.Event.ADDED_TO_STAGE, onAddedToStage);			
			
			if (REPLAY_DQID || PipeJam3.LOGGING_ON) 
			{
				logging = new LoggingServerInterface(loggingKey, stage, "", REPLAY_DQID != null);
				if (REPLAY_DQID) {
					ReplayController.getInstance().loadQuestData(REPLAY_DQID, logging.cgsServer, onReplayQuestDataLoaded);
				}
			}	
		}
		
		public function onAddedToStage(evt:flash.events.Event):void {
			trace("In stage function");
			if(hasBeenAddedToStage == false)
			{
				trace("Inside the predicate");
				removeEventListener(flash.events.Event.ADDED_TO_STAGE, onAddedToStage);

				initialize();
			}
		}
		
		public function initialize(result:int = 0, e:flash.events.Event = null):void
		{
			// for now, initialize string table here
			if (GameConfig.IS_MTURK) {
				if (GameConfig.GAME_METAPHOR == GameConfig.ORIGINAL_METAPHOR) {
					StringTable.setInstance(new StringTableMTurk);
					ASSET_SUFFIX = "";
				} else {
					StringTable.setInstance(new StringTablePowerPlant);
					ASSET_SUFFIX = "PowerPlant";
				}
			} else {
				StringTable.setInstance(new StringTableBase);
			}
			
			World.initPlayerVars();
			MouseWheelTrap.setup(stage);
			
			//set up the main controller
			stage.scaleMode = StageScaleMode.NO_SCALE;
			stage.align = StageAlign.TOP_LEFT;
			
			Starling.multitouchEnabled = false; // useful on mobile devices
			Starling.handleLostContext = true; // deactivate on mobile devices (to save memory)
			
			if (SHOW_PERFORMANCE_STATS) {
				var stats:Stats = new Stats;
				stage.addChild(stats);
			}
			
			//	mStarling = new Starling(PipeJamGame, stage, null, null,Context3DRenderMode.SOFTWARE);
			mStarling = new Starling(PipeJamGame, stage);
			trace("Initialized Starling in initialize() function");
			//mostly just an annoyance in desktop mode, so turn off...
			mStarling.simulateMultitouch = false;
			mStarling.enableErrorChecking = false;
			trace("Before starling.start()");
			mStarling.start();
			trace("After starling.start()");
			
			if (REPLAY_DQID) {
				m_replayText.text = "Loading replay...";
				m_replayText.width = Constants.GameWidth;
				m_replayText.height = 30;
				m_replayText.setTextFormat(REPLAY_TEXT_FORMAT);
				mStarling.nativeOverlay.addChild(m_replayText);
			}
			
			// this event is dispatched when stage3D is set up
			mStarling.stage3D.addEventListener(flash.events.Event.CONTEXT3D_CREATE, onContextCreated);
			
			stage.addEventListener(flash.events.Event.RESIZE, updateSize);
			stage.dispatchEvent(new flash.events.Event(flash.events.Event.RESIZE));
			
			trace("Before checking for a predicate to load a level");
			if (ExternalInterface.available) {
				trace("Inside the predicate: So ExternalInterface.available = true")
				ExternalInterface.addCallback("loadLevelFromObjectID", loadLevelFromObjectID);
			}
			
			//initialize JS to ActionScript link
			HTTPCookies.initialize();
			
			var fullURL:String = this.loaderInfo.url;

			var protocolEndIndex:int = fullURL.indexOf('//');
			var baseURLEndIndex:int = fullURL.indexOf('/', protocolEndIndex + 2);
			NetworkConnection.baseURL = fullURL.substring(0, baseURLEndIndex);
			if(NetworkConnection.baseURL.indexOf("http") != -1)
			{			
				if(PipeJam3.INSTALL_DVD == true)
					NetworkConnection.productionInterop = NetworkConnection.baseURL + "/flowjam/scripts/interop.php";
				else
					NetworkConnection.productionInterop = NetworkConnection.baseURL + "/cgi-bin/interop.php";
			}
			else
			{
				if (ASSET_SUFFIX == "Turk")
				{
					NetworkConnection.productionInterop = "http://ec2-184-73-33-59.compute-1.amazonaws.com/cgi-bin/interop.php";
					NetworkConnection.baseURL = "http://ec2-184-73-33-59.compute-1.amazonaws.com/";
				}
				else if(PRODUCTION_BUILD)
				{
					NetworkConnection.productionInterop = "http://paradox.verigames.com/cgi-bin/interop.php";
					NetworkConnection.baseURL = "http://paradox.verigames.com";
				}
				else
				{
					NetworkConnection.productionInterop = "http://paradox.verigames.org/cgi-bin/interop.php";
					NetworkConnection.baseURL = "http://paradox.verigames.org";
				}
			}
			
			if (ASSET_SUFFIX == "Turk")
			{
				MTurkAPI.getInstance(); // initialize
			}
			GameFileHandler.retrieveLevelMetadata();
			
			Starling.current.nativeStage.addEventListener(flash.events.Event.FULLSCREEN, changeFullScreen);
			
			addEventListener(NavigationEvent.LOAD_LEVEL, onLoadLevel);
		}
				
		protected function changeFullScreen(event:flash.events.Event):void
		{
			//adjust sizes and stuff
			isFullScreen = !isFullScreen;
			
			var newWidth:int = Starling.current.nativeStage.fullScreenWidth;
			var newHeight:int = Starling.current.nativeStage.fullScreenHeight;

			stage.stageWidth = newWidth;
			stage.stageHeight = newHeight;
			Starling.current.viewPort = new Rectangle(0,0,stage.stageWidth,stage.stageHeight);
			PipeJamGame.m_pipeJamGame.changeFullScreen(newWidth, newHeight);
		}
		
		private function onContextCreated(event:flash.events.Event):void
		{
			// set framerate to 30 in software mode
			
			if (Starling.context.driverInfo.toLowerCase().indexOf("software") != -1)
				Starling.current.nativeStage.frameRate = 30;
		}
		
		public function updateSize(e:flash.events.Event):void {
			// Compute max view port size
			var fullViewPort:Rectangle = new Rectangle(0, 0, stage.stageWidth, stage.stageHeight);
			const DES_WIDTH:Number = Constants.GameWidth;
			const DES_HEIGHT:Number = Constants.GameHeight;
			var scaleFactor:Number = Math.min(stage.stageWidth / DES_WIDTH, stage.stageHeight / DES_HEIGHT);
			
			// Compute ideal view port
			var viewPort:Rectangle = new Rectangle();
			viewPort.width = scaleFactor * DES_WIDTH;
			viewPort.height = scaleFactor * DES_HEIGHT;
			viewPort.x = 0.5 * (stage.stageWidth - viewPort.width);
			viewPort.y = 0.5 * (stage.stageHeight - viewPort.height);
			
			// Ensure the ideal view port is not larger than the max view port (could cause a crash otherwise)
			viewPort = viewPort.intersection(fullViewPort);
			
			// Set the updated view port
			Starling.current.viewPort = viewPort;
		}
		
		public function onLoadLevel(event:NavigationEvent = null):void
		{
			loadLevelFromObjectID(event.info);
		}
		
		//call from JavaScript to load specific level
		public function loadLevelFromObjectID(levelID:String):void
		{
			GameFileHandler.loadLevelInfoFromObjectID(levelID, loadLevel);
		}
		
		protected function loadLevel(result:int, objVector:Vector.<Object>):void
		{
			PipeJamGame.levelInfo = new objVector[0];		
			PipeJamGame.m_pipeJamGame.dispatchEvent(new NavigationEvent(NavigationEvent.CHANGE_SCREEN, "PipeJamGame"));
		}
		
		private function onReplayQuestDataLoaded(questData:QuestData, err:String = null):void
		{
			trace("Found " + (questData.actions ? questData.actions.length : 0) + " actions");
			if (err) trace("Error: " + err);
			if (questData && questData.startData && questData.startData.details &&
				questData.startData.details.hasOwnProperty(VerigameServerConstants.QUEST_PARAMETER_LEVEL_INFO) &&
				questData.startData.details[VerigameServerConstants.QUEST_PARAMETER_LEVEL_INFO] &&
				questData.startData.details[VerigameServerConstants.QUEST_PARAMETER_LEVEL_INFO].m_id) {
				var levelId:String = questData.startData.details[VerigameServerConstants.QUEST_PARAMETER_LEVEL_INFO].m_id as String;
				trace("Replaying levelId: " + levelId);
				loadLevelFromObjectID(levelId);
				return;
			}
			trace("Error: Couldn't find levelId for replay.");
		}
		
		public static function showReplayText(text:String):void
		{
			if (!m_replayText) return;
			m_replayText.text = text;
			m_replayText.setTextFormat(REPLAY_TEXT_FORMAT);
		}
	}	
}
