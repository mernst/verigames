package scenes.game
{
	import deng.fzip.FZip;
	import deng.fzip.FZipFile;
	
	import events.NavigationEvent;
	
	import flash.events.Event;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	
	import graph.Network;
	
	import scenes.Scene;
	import scenes.game.display.World;
	
	import starling.display.*;
	import starling.events.Event;
	
	import state.ParseXMLState;
	
	public class PipeJamGameScene extends Scene
	{		
		public var worldFileLoader:URLLoader;
		public var layoutLoader:URLLoader;
		protected var nextParseState:ParseXMLState;
				
		public var worldFile:String = "../SampleWorlds/DemoWorld/DemoWorld.xml";
		public var layoutFile:String = "../SampleWorlds/DemoWorld/DemoWorld.gxl";
		private var world_zip_file_to_be_played:String;// = "..\\SampleWorlds\\DemoWorld.zip";
		public var m_worldXML:XML;
		public var m_worldLayout:XML;
		private var fz:FZip;
		
		protected var loadType:int;
		
		public static var USE_LOCAL:int = 1;
		public static var USE_DATABASE:int = 2;
		public static var USE_URL:int = 3;
		
		public static const HOST_URL:String = "";

		protected var m_layoutLoaded:Boolean = false;
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
			super.addedToStage(event);
			if(levelNumberString != null) //load from MongoDB
			{
				loadType = USE_DATABASE;
				worldFileLoader = new URLLoader();
				loadFile(worldFileLoader, levelNumberString+"/xml", onWorldLoaded);
				layoutLoader = new URLLoader();
				loadFile(layoutLoader, levelNumberString+"/gxl", onLayoutLoaded);
			}
			else if (!world_zip_file_to_be_played)
			{
				loadType = USE_LOCAL;
			
				worldFileLoader = new URLLoader();
				loadFile(worldFileLoader, worldFile, onWorldLoaded);
				layoutLoader = new URLLoader();
				loadFile(layoutLoader, layoutFile, onLayoutLoaded);
			}
			else
			 {
				//load the zip file from it's location
				loadType = USE_URL;
				fz = new FZip();
				fz.addEventListener(flash.events.Event.COMPLETE, onZipLoaded);
				fz.load(new URLRequest(world_zip_file_to_be_played));
			}
			initGame();

		}
		
		protected  override function removedFromStage(event:starling.events.Event):void
		{
		}
		
		
		/**
		 * Run once to initialize the game
		 */
		public function initGame():void 
		{

		}
		
		public function loadFile(loader:URLLoader, fileName:String, callback:Function):void
		{
			switch(loadType)
			{
				case USE_DATABASE:
				{
					loader.addEventListener(flash.events.Event.COMPLETE, callback);
					loader.load(new URLRequest(PROXY_URL +"/" +fileName+ "&method=DATABASE"));
					break;
				}
				case USE_LOCAL:
				{
					loader.addEventListener(flash.events.Event.COMPLETE, callback);
					loader.load(new URLRequest(fileName));
					break;
				}
				case USE_URL:
				{
					loader.addEventListener(flash.events.Event.COMPLETE, callback);
					loader.load(new URLRequest(HOST_URL +fileName + "?version=" + Math.round(1000000*Math.random())));
					break;
				}
			}
		}
		
		public function onLayoutLoaded(e:flash.events.Event):void {
			layoutLoader.removeEventListener(flash.events.Event.COMPLETE, onLayoutLoaded);
			m_worldLayout = new XML(e.target.data); 
			m_layoutLoaded = true;
			//call, but probably wait on xml
			tasksComplete();
		}
		
		public function onWorldLoaded(e:flash.events.Event):void { 
			worldFileLoader.removeEventListener(flash.events.Event.COMPLETE, onWorldLoaded);
			var worldXML:XML = new XML(e.target.data);  
			
			parseXML(worldXML);
		}
		
		private function onZipLoaded(e:flash.events.Event):void {
			fz.removeEventListener(flash.events.Event.COMPLETE, onZipLoaded);
			var fzip_files:Vector.<FZipFile> = new Vector.<FZipFile>();
			for (var f:int = 0; f < fz.getFileCount(); f++) {
				var zipFile:FZipFile = fz.getFileAt(f);
				if(zipFile.filename.indexOf(".xml") != -1)
				{
					var worldXML:XML = XML(zipFile.content);
					parseXML(worldXML);
				}
				else
				{
					m_worldLayout = XML(zipFile.content);
					m_layoutLoaded = true;
				}
			}
			
			//call, but probably wait on xml
			tasksComplete();

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
			if(m_layoutLoaded && m_worldLoaded)
			{
				trace("everything loaded");
				if(nextParseState)
					nextParseState.removeFromParent();
				
				//			var levelName:String = world_nodes.worldNodeNameArray[0];
				//			edgeSetGraphViewPanel.loadLevel(world_nodes.worldNodesDictionary[levelName]);
				
				active_world = createWorldFromNodes(m_network, m_worldXML, m_worldLayout);		
				
				addChild(active_world);
			}
		}
		
		
		/**
		 * This function is called after the graph structure (Nodes, edges) has been read in from XML. It converts nodes/edges to a playable world.
		 * @param	_worldNodes
		 * @param	_world_xml
		 * @return
		 */
		public function createWorldFromNodes(_worldNodes:Network, _world_xml:XML, _layout:XML):World {
			try {
				
				m_network = _worldNodes;
				PipeJamGame.printDebug("Creating World...");
				var world:World = new World(_worldNodes, _world_xml, _layout);				
			} catch (error:Error) {
				throw new Error("ERROR: " + error.message + "\n" + (error as Error).getStackTrace());
				var debug:int = 0;
			}
			
			return world;
		}
	}
}