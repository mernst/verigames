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
	
	import networking.*;
	
	import scenes.Scene;
	import scenes.game.display.World;
	
	import starling.core.Starling;
	import starling.display.*;
	import starling.events.Event;
	
	import state.ParseXMLState;
	
	public class PipeJamGameScene extends Scene
	{		
		protected var nextParseState:ParseXMLState;
		
		static public var demoButtonWorldFile:String = "../SampleWorlds/net_sf_picard_metrics_VersionHeader";
		
		static public var demoArray:Array = new Array(
			"../../../../SampleWorlds/5220c523e4b06c4c132c6705"
		);
		
		static public const DEBUG_PLAY_WORLD_ZIP:String = "";// "../lib/levels/bonus/bonus.zip";
				
		static public var inTutorial:Boolean = false;
		static public var inDemo:Boolean = false;
		
		public var m_worldXML:XML;
		public var m_layoutXML:XML;
		public var m_constraintsXML:XML;
		public var m_allInOneXML:XML;
		
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
			var fileName:String;
						
			super.addedToStage(event);
			m_layoutLoaded = m_worldLoaded = m_constraintsLoaded = false;
			GameFileHandler.loadGameFiles(onWorldLoaded, onLayoutLoaded, onConstraintsLoaded);
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
		
		//might be a single xml file, or maybe an array of three xml files
		private function onWorldLoaded(obj:Object):void { 
			if(obj is XML)
				m_worldXML = obj as XML;
			else if(obj is Array)
			{
				m_worldXML = (obj as Array)[0];
				m_constraintsXML = (obj as Array)[1];
				m_layoutXML = (obj as Array)[2];
				m_constraintsLoaded = true;
				m_layoutLoaded = true;
			}
			m_worldLoaded = true;
			tasksComplete();
		}
		
		public function parseXML():void
		{
			if(nextParseState)
				nextParseState.removeFromParent();
			nextParseState = new ParseXMLState(m_worldXML);
			addChild(nextParseState); //to allow done parsing event to be caught
			this.addEventListener(ParseXMLState.WORLD_PARSED, worldComplete);
			nextParseState.stateLoad();
		}
		
		public function worldComplete(event:starling.events.Event):void
		{
			m_network = event.data as Network;
			m_worldLoaded = true;
			this.removeEventListener(ParseXMLState.WORLD_PARSED, worldComplete);
			worldXMLParsed();
		}
		
		public function tasksComplete():void
		{
			if(m_layoutLoaded && m_worldLoaded && m_constraintsLoaded)
			{
				trace("everything loaded");
				parseXML();
			}
		}
		
		protected function worldXMLParsed():void
		{
			if(nextParseState)
				nextParseState.removeFromParent();
				
			active_world = createWorldFromNodes(m_network, m_worldXML, m_layoutXML, m_constraintsXML);		
				
			addChild(active_world);
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
	}
}