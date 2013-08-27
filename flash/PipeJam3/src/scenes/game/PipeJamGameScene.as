package scenes.game
{
	import deng.fzip.FZip;
	import deng.fzip.FZipFile;
	
	import events.NavigationEvent;
	
	import flash.events.Event;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.utils.ByteArray;
	
	import graph.Network;
	
	import scenes.Scene;
	import scenes.game.display.World;
	import networking.LoginHelper;
	import networking.HTTPCookies;
	
	import starling.core.Starling;
	import starling.display.*;
	import starling.events.Event;
	
	import state.ParseXMLState;
	
	public class PipeJamGameScene extends Scene
	{		
		public var worldFileLoader:URLLoader;
		public var layoutLoader:URLLoader;
		public var constraintsLoader:URLLoader;
		protected var nextParseState:ParseXMLState;
		
		static public var demoButtonWorldFile:String = "../SampleWorlds/net_sf_picard_metrics_VersionHeader.zip";
		static public var demoButtonLayoutFile:String = "../SampleWorlds/net_sf_picard_metrics_VersionHeaderLayout.zip";
		static public var demoButtonConstraintsFile:String = "../SampleWorlds/net_sf_picard_metrics_VersionHeaderConstraints.zip";
		
		static public var dArray:Array = new Array(
			"../SampleWorlds/MapGet.zip",
			"../SampleWorlds/MapGetConstraints.zip",
			"../SampleWorlds/MapGetLayout.zip"
		);
		
		static private const DEBUG_PLAY_WORLD_ZIP:String = "";// "../lib/levels/bonus/bonus.zip";
		
		[Embed(source = "../../../lib/levels/tutorial/tutorial.xml", mimeType = "application/octet-stream")]
		static public const tutorialFileClass:Class;
		static public const tutorialXML:XML = XML(new tutorialFileClass());
		
		[Embed(source = "../../../lib/levels/tutorial/tutorialLayout.xml", mimeType = "application/octet-stream")]
		static public const tutorialLayoutFileClass:Class;
		static public const tutorialLayoutXML:XML = XML(new tutorialLayoutFileClass());
		
		[Embed(source = "../../../lib/levels/tutorial/tutorialConstraints.xml", mimeType = "application/octet-stream")]
		static public const tutorialConstraintsFileClass:Class;
		static public const tutorialConstraintsXML:XML = XML(new tutorialConstraintsFileClass());
		
		static public var numTutorialLevels:int = 0;
		static public var maxTutorialLevelCompleted:int = 0;
		static public var currentTutorialLevel:int = 0;
		static public var inTutorial:Boolean = false;
		
		static public var worldFile:String = demoButtonWorldFile;
		static public var layoutFile:String = demoButtonLayoutFile;
		static public var constraintsFile:String = demoButtonConstraintsFile;
		static public var worldAllInOneFile:String;
		
		public var m_worldXML:XML;
		public var m_layoutXML:XML;
		public var m_constraintsXML:XML;
		public var m_allInOneXML:XML;
		private var fz1:FZip;
		private var fz2:FZip;
		private var fz3:FZip;
		
		protected var m_layoutLoaded:Boolean = false;
		protected var m_constraintsLoaded:Boolean = false;
		protected var m_worldLoaded:Boolean = false;
		
		/** Start button image */
		protected var start_button:Button;
		private var active_world:World;
		private var m_network:Network;
		
		public function PipeJamGameScene(game:PipeJamGame)
		{
			super(game);
		}
		
		protected override function addedToStage(event:starling.events.Event):void
		{
			var loginHelper:LoginHelper = LoginHelper.getLoginHelper();
			var fileName:String;
			
			super.addedToStage(event);
			
			if(loginHelper.levelObject && loginHelper.levelObject.levelId is int && loginHelper.levelObject.levelId < 1000) // in the tutorial if a short level id
			{
				PipeJamGameScene.inTutorial = true;
				fileName = "tutorial";
			}
			if (DEBUG_PLAY_WORLD_ZIP && !PipeJam3.RELEASE_BUILD)
			{
				//load the zip file from it's location
				loadType = LoginHelper.USE_URL;
				fz1 = new FZip();
				fz1.addEventListener(flash.events.Event.COMPLETE, worldZipLoaded);
				fz1.load(new URLRequest(DEBUG_PLAY_WORLD_ZIP));
			}
			else if(PipeJamGameScene.inTutorial)
			{
				//reset these so we wait till we set them all
				m_layoutLoaded = m_worldLoaded = m_constraintsLoaded = false;
				onLayoutLoaded(tutorialLayoutXML);
				onConstraintsLoaded(tutorialConstraintsXML);
				onWorldLoaded(tutorialXML);
			}
			else
			{
				var loadType:int = LoginHelper.USE_LOCAL;
				
				var obj:Object = Starling.current.nativeStage.loaderInfo.parameters;
				if(!PipeJamGameScene.inTutorial)
					fileName = obj["files"];
				if(loginHelper.levelObject != null && !PipeJamGameScene.inTutorial) //load from MongoDB
				{
					loadType = LoginHelper.USE_DATABASE;
					worldAllInOneFile = worldFile = layoutFile = constraintsFile = null;
					//is this an all in one file?
					var version:int = 0;
					if(loginHelper.levelObject.version is String)
						version = parseInt(loginHelper.levelObject.version);
					if(version == PipeJamGame.ALL_IN_ONE)
					{
						worldAllInOneFile = "/file/get/" +loginHelper.levelObject.constraintsID+"/constraints";
					}
					else
					{
						worldFile = "/file/get/" + loginHelper.levelObject.xmlID+"/xml";
						layoutFile = "/file/get/" + loginHelper.levelObject.layoutID+"/layout";
						constraintsFile = "/file/get/" +loginHelper.levelObject.constraintsID+"/constraints";	
					}
				}
				else if(fileName && fileName.length > 0)
				{
					worldFile = "../SampleWorlds/DemoWorld/"+fileName+".zip";
					layoutFile = "../SampleWorlds/DemoWorld/"+fileName+"Layout.zip";
					constraintsFile = "../SampleWorlds/DemoWorld/"+fileName+"Constraints.zip";
				}
				
				m_layoutLoaded = m_worldLoaded = m_constraintsLoaded = false;
				
				if(worldFile) 
				{
					fz1 = new FZip();
					loginHelper.loadFile(loadType, null, worldFile, worldZipLoaded, fz1);
				}
				if(layoutFile)
				{
					fz2 = new FZip();
					loginHelper.loadFile(loadType, null, layoutFile, layoutZipLoaded, fz2);
				}
				if(constraintsFile)
				{
					fz3 = new FZip();
					loginHelper.loadFile(loadType, null, constraintsFile, constraintsZipLoaded, fz3);
				}
				
				if(worldAllInOneFile)
				{
					fz1 = new FZip();
					loginHelper.loadFile(loadType, null, worldAllInOneFile , allInOneZipLoaded, fz1);
				}
			}
		}
		
		protected  override function removedFromStage(event:starling.events.Event):void
		{
			removeChildren(0, -1, true);
			active_world = null;
		}
		
		private function onLayoutLoaded(_layoutXML:XML):void {
			m_layoutXML = _layoutXML; 
			m_layoutLoaded = true;
			//call, but probably wait on xml
			tasksComplete();
		}
		
		private function onConstraintsLoaded(_constraintsXML:XML):void {
			m_constraintsXML = _constraintsXML;
			m_constraintsLoaded = true;
			//call, but probably wait on xml
			tasksComplete();
		}
		
		private function onWorldLoaded(_worldXML:XML):void { 
			var worldXML:XML = _worldXML; 
			m_worldLoaded = true;
			parseXML(worldXML);
		}
		
		private function worldZipLoaded(e:flash.events.Event):void {
			fz1.removeEventListener(flash.events.Event.COMPLETE, worldZipLoaded);
			var zipFile:FZipFile, worldXML:XML;
			if(fz1.getFileCount() == 3)
			{
				var layoutXML:XML, constraintsXML:XML;
				for (var i:int = 0; i < fz1.getFileCount(); i++) {
					zipFile = fz1.getFileAt(i);
					if (zipFile.filename.toLowerCase().indexOf("layout") > -1) {
						layoutXML = new XML(zipFile.content);
					} else if (zipFile.filename.toLowerCase().indexOf("constraints") > -1) {
						constraintsXML = new XML(zipFile.content);
					} else {
						worldXML = new XML(zipFile.content);
					}
				}
				onLayoutLoaded(layoutXML);
				onConstraintsLoaded(constraintsXML);
				onWorldLoaded(worldXML);
			}
			else
			{
		//		trace("zip failed unexpected # of files:" + fz1.getFileCount());
				zipFile = fz1.getFileAt(0);
				trace(zipFile.filename);
				worldXML = new XML(zipFile.content);
				onWorldLoaded(worldXML);
			}
		}
		
		private function allInOneZipLoaded(e:flash.events.Event):void {
			fz1.removeEventListener(flash.events.Event.COMPLETE, allInOneZipLoaded);
			if(fz1.getFileCount() > 0)
			{
				var zipFile:FZipFile = fz1.getFileAt(0);
				var containerXML:XML = new XML(zipFile.content);
				m_worldXML = containerXML.world[0];
				m_layoutXML = containerXML.layout[0];
				m_constraintsXML = containerXML.constraints[0];
			}
			onLayoutLoaded(m_layoutXML);
			onConstraintsLoaded(m_constraintsXML);
			onWorldLoaded(m_worldXML);
			
		}
		
		private function layoutZipLoaded(e:flash.events.Event):void {
			fz2.removeEventListener(flash.events.Event.COMPLETE, layoutZipLoaded);
			if(fz2.getFileCount() > 0)
			{
				var zipFile:FZipFile = fz2.getFileAt(0);
				trace(zipFile.filename);
				var layoutXML:XML = new XML(zipFile.content);
				onLayoutLoaded(layoutXML);
			}
			else
				trace("zip failed");
		}
		
		private function constraintsZipLoaded(e:flash.events.Event):void {
			fz3.removeEventListener(flash.events.Event.COMPLETE, constraintsZipLoaded);
			if(fz3.getFileCount() > 0)
			{
				var zipFile:FZipFile = fz3.getFileAt(0);
				trace(zipFile.filename);
				var constraintsXML:XML = new XML(zipFile.content);
				onConstraintsLoaded(constraintsXML);
			}
			else
				trace("zip failed");
		}
		
		public function parseXML(world_xml:XML):void
		{
			m_worldXML = world_xml;
			if(nextParseState)
				nextParseState.removeFromParent();
			nextParseState = new ParseXMLState(world_xml);
			addChild(nextParseState); //to allow done parsing event to be caught
			this.addEventListener(ParseXMLState.WORLD_PARSED, worldComplete);
			nextParseState.stateLoad();
		}
		
		public function worldComplete(event:starling.events.Event):void
		{
			m_network = event.data as Network;
			m_worldLoaded = true;
			this.removeEventListener(ParseXMLState.WORLD_PARSED, worldComplete);
			tasksComplete();
		}
		
		public function tasksComplete():void
		{
			if(m_layoutLoaded && m_worldLoaded && m_constraintsLoaded)
			{
				trace("everything loaded");
				if(nextParseState)
					nextParseState.removeFromParent();
				
				active_world = createWorldFromNodes(m_network, m_worldXML, m_layoutXML, m_constraintsXML);		
				
				addChild(active_world);
			}
		}
		
		
		/**
		 * This function is called after the graph structure (Nodes, edges) has been read in from XML. It converts nodes/edges to a playable world.
		 * @param	_worldNodes
		 * @param	_world_xml
		 * @return
		 */
		public function createWorldFromNodes(_worldNodes:Network, _world_xml:XML, _layout:XML, _constraints:XML):World {
			try {
				
				m_network = _worldNodes;
				PipeJamGame.printDebug("Creating World...");
				var world:World = new World(_worldNodes, _world_xml, _layout, _constraints);				
			} catch (error:Error) {
				throw new Error("ERROR: " + error.message + "\n" + (error as Error).getStackTrace());
				var debug:int = 0;
			}
			
			return world;
		}
		
		public static var solvedTutorialLevelTags:Vector.<String> = new Vector.<String>();
		public static function solvedTutorialLevel(_tutorialTag:String):void {
			if (!_tutorialTag) return;
			if (solvedTutorialLevelTags.indexOf(_tutorialTag) > -1) return;//already solved
			solvedTutorialLevelTags.push(_tutorialTag);
			maxTutorialLevelCompleted++;
			HTTPCookies.setCookie(HTTPCookies.TUTORIALS_COMPLETED, maxTutorialLevelCompleted);
		}
		
		public static function resetTutorialStatus():void
		{
			solvedTutorialLevelTags = new Vector.<String>();
			maxTutorialLevelCompleted = 0;
		}
	}
}