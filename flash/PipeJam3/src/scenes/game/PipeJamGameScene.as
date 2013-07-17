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
	import scenes.login.HTTPCookies;
	import scenes.login.LoginHelper;
	
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
			"../SampleWorlds/test/Intervals.zip",
			"../SampleWorlds/test/IntervalsConstraints.zip",
			"../SampleWorlds/test/IntervalsLayout.zip"

		);
		
		static public var tutorialButtonWorldFile:String = "../SampleWorlds/DemoWorld/tutorial.zip";
		static public var tutorialButtonLayoutFile:String = "../SampleWorlds/DemoWorld/tutorialLayout.zip";
		static public var tutorialButtonConstraintsFile:String = "../SampleWorlds/DemoWorld/tutorialConstraints.zip";
		static public var numTutorialLevels:int = 0;
		static public var numTutorialLevelsCompleted:int = 0;
		static public var inTutorial:Boolean = false;
		
		static public var worldFile:String = demoButtonWorldFile;
		static public var layoutFile:String = demoButtonLayoutFile;
		static public var constraintsFile:String = demoButtonConstraintsFile;
		private var world_zip_file_to_be_played:String;// = "../SampleWorlds/DemoWorld.zip";
		public var m_worldXML:XML;
		public var m_worldLayout:XML;
		public var m_worldConstraints:XML;
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
			dispatchEvent(new starling.events.Event(Game.START_BUSY_ANIMATION,true));
			
			if( LoginHelper.levelObject is int) // in the tutorial
			{
				PipeJamGameScene.inTutorial = true;
				fileName = "tutorial";
			}
			
			if(PipeJamGameScene.inTutorial && LoginHelper.tutorialFile) //previously loaded?
			{
				//mark extra files as loaded, and then parse world file
				m_layoutLoaded = m_constraintsLoaded = true;
				parseXML(m_worldXML);
			}
			
			if (!world_zip_file_to_be_played)
			{
				var loadType:int = LoginHelper.USE_LOCAL;
				
				var obj:Object = Starling.current.nativeStage.loaderInfo.parameters;
				if(!PipeJamGameScene.inTutorial)
					fileName = obj["files"];
				if(LoginHelper.levelObject != null && !PipeJamGameScene.inTutorial) //load from MongoDB
				{
					loadType = LoginHelper.USE_DATABASE;
					worldFile = "/level/get/" + LoginHelper.levelObject.xmlID+"/xml";
					layoutFile = "/level/get/" + LoginHelper.levelObject.layoutID+"/layout";
					constraintsFile = "/level/get/" + LoginHelper.levelObject.constraintsID+"/constraints";		
				}
				else if(fileName && fileName.length > 0)
				{
					worldFile = "../SampleWorlds/DemoWorld/"+fileName+".zip";
					layoutFile = "../SampleWorlds/DemoWorld/"+fileName+"Layout.zip";
					constraintsFile = "../SampleWorlds/DemoWorld/"+fileName+"Constraints.zip";
				}
				
				m_layoutLoaded = m_worldLoaded = m_constraintsLoaded = false;
				
				fz1 = new FZip();
				loginHelper.loadFile(loadType, null, worldFile, worldZipLoaded, fz1);
				fz2 = new FZip();
				loginHelper.loadFile(loadType, null, layoutFile, layoutZipLoaded, fz2);
				fz3 = new FZip();
				loginHelper.loadFile(loadType, null, constraintsFile, constraintsZipLoaded, fz3);
			}
			else
			{
				//load the zip file from it's location
				loadType = LoginHelper.USE_URL;
				fz1 = new FZip();
				fz1.addEventListener(flash.events.Event.COMPLETE, worldZipLoaded);
				fz1.load(new URLRequest(world_zip_file_to_be_played));
			}
			initGame();
			
		}
		
		protected  override function removedFromStage(event:starling.events.Event):void
		{
			removeChildren(0, -1, true);
			active_world = null;
		}
		
		
		/**
		 * Run once to initialize the game
		 */
		public function initGame():void 
		{
			
		}
		
		public function onLayoutLoaded(byteArray:ByteArray):void {
			m_worldLayout = new XML(byteArray); 
			m_layoutLoaded = true;
			//call, but probably wait on xml
			tasksComplete();
		}
		
		public function onConstraintsLoaded(byteArray:ByteArray):void {
			m_worldConstraints = new XML(byteArray); 
			m_constraintsLoaded = true;
			//call, but probably wait on xml
			tasksComplete();
		}
		
		public function onWorldLoaded(byteArray:ByteArray):void { 
			var worldXML:XML  = new XML(byteArray); 
			m_worldLoaded = true;
			parseXML(worldXML);
		}
		
		
		private function worldZipLoaded(e:flash.events.Event):void {
			fz1.removeEventListener(flash.events.Event.COMPLETE, worldZipLoaded);
			if(fz1.getFileCount() > 0)
			{
				var zipFile:FZipFile = fz1.getFileAt(0);
				trace(zipFile.filename);
				onWorldLoaded(zipFile.content);
			}
			else
				trace("zip failed");
		}
		
		private function layoutZipLoaded(e:flash.events.Event):void {
			fz2.removeEventListener(flash.events.Event.COMPLETE, layoutZipLoaded);
			if(fz2.getFileCount() > 0)
			{
				var zipFile:FZipFile = fz2.getFileAt(0);
				trace(zipFile.filename);
				onLayoutLoaded(zipFile.content);
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
				onConstraintsLoaded(zipFile.content);
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
				if(PipeJamGameScene.inTutorial)
				{
					LoginHelper.tutorialFile = m_worldXML;
					LoginHelper.tutorialLayoutFile = m_worldLayout;
					LoginHelper.tutorialConstraintsFile = m_worldConstraints;
				}
				trace("everything loaded");
				if(nextParseState)
					nextParseState.removeFromParent();
				
				active_world = createWorldFromNodes(m_network, m_worldXML, m_worldLayout, m_worldConstraints);		
				
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
			numTutorialLevelsCompleted++;
			HTTPCookies.setCookie(HTTPCookies.TUTORIALS_COMPLETED, numTutorialLevelsCompleted);
		}
		
		public static function resetTutorialStatus():void
		{
			solvedTutorialLevelTags = new Vector.<String>();
			numTutorialLevelsCompleted = 0;
		}
	}
}