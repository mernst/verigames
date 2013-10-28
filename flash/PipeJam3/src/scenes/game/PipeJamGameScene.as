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
	import scenes.game.display.ReplayWorld;
	
	import starling.core.Starling;
	import starling.display.*;
	import starling.events.Event;
	
	import state.ParseXMLState;
	
	public class PipeJamGameScene extends Scene
	{		
		protected var nextParseState:ParseXMLState;
		
		//takes a partial path to the files, using the base file name. -.xml, -Layout.xml and -Constraints.xml will be assumed
		//we could obviously change it back, but this is the standard use case
		static public var demoArray:Array = new Array(
	//		"../../../../../../../save/outputz/AbandonedCanyon",
//			"../../../../../../../save/outputz/AbandonedClay",
//			"../../../../../../../save/outputz/AbandonedDunes",
//			"../../../../../../../save/outputz/AbandonedFalls",
//			"../../../../../../../save/outputz/AbandonedForest",
////			"../../../../../../../save/outputz/BrightCanyon",
////			"../../../../../../../save/outputz/BrightClay",
//			"../../../../../../../save/outputz/BrightDunes",
////			"../../../../../../../save/outputz/BrightFalls",
////			"../../../../../../../save/outputz/BrightForest",
////			"../../../../../../../save/outputz/BusyCanyon",
////			"../../../../../../../save/outputz/BusyClay",
////			"../../../../../../../save/outputz/BusyDunes",
////			"../../../../../../../save/outputz/BusyFalls",
//			"../../../../../../../save/outputz/BusyForest",
////			"../../../../../../../save/outputz/CalmCanyon",
//			"../../../../../../../save/outputz/CalmClay",
//			"../../../../../../../save/outputz/CalmDunes",
////			"../../../../../../../save/outputz/CalmFalls",
//			"../../../../../../../save/outputz/CalmForest",
////			"../../../../../../../save/outputz/ClearCanyon",
////			"../../../../../../../save/outputz/ClearClay",
////			"../../../../../../../save/outputz/ClearDunes",
////			"../../../../../../../save/outputz/ClearFalls",
//			"../../../../../../../save/outputz/ClearForest",
////			"../../../../../../../save/outputz/CoolCanyon",
////			"../../../../../../../save/outputz/CoolClay",
//			"../../../../../../../save/outputz/CoolDesert",
////			"../../../../../../../save/outputz/CoolDunes",
////			"../../../../../../../save/outputz/CoolFalls",
////			"../../../../../../../save/outputz/CoolForest",
////			"../../../../../../../save/outputz/CuriousCanyon",
//			"../../../../../../../save/outputz/CuriousClay",
////			"../../../../../../../save/outputz/CuriousDesert",
//			"../../../../../../../save/outputz/CuriousDunes",
////			"../../../../../../../save/outputz/CuriousFalls",
////			"../../../../../../../save/outputz/CuriousForest",
////			"../../../../../../../save/outputz/CynicalCanyon",
//			"../../../../../../../save/outputz/CynicalClay",
//			"../../../../../../../save/outputz/CynicalDesert",
//			"../../../../../../../save/outputz/CynicalDunes",
//			"../../../../../../../save/outputz/CynicalFalls",
//			"../../../../../../../save/outputz/CynicalForest",
//			"../../../../../../../save/outputz/DarkCanyon",
			"../../../../../../../save/outputz/DarkClay",
			"../../../../../../../save/outputz/DarkDesert",
//			"../../../../../../../save/outputz/DarkDunes",
			"../../../../../../../save/outputz/DarkFalls",
//			"../../../../../../../save/outputz/DarkForest",
//			"../../../../../../../save/outputz/DashingCanyon",
//			"../../../../../../../save/outputz/DashingClay",
//			"../../../../../../../save/outputz/DashingDesert",
//			"../../../../../../../save/outputz/DashingDunes",
			"../../../../../../../save/outputz/DashingFalls",
//			"../../../../../../../save/outputz/DashingForest",
			"../../../../../../../save/outputz/DazzlingCanyon",
//			"../../../../../../../save/outputz/DazzlingClay",
			"../../../../../../../save/outputz/DazzlingDesert",
//			"../../../../../../../save/outputz/DazzlingDunes",
//			"../../../../../../../save/outputz/DazzlingFalls",
			"../../../../../../../save/outputz/DeadCanyon",
//			"../../../../../../../save/outputz/DeadClay",
//			"../../../../../../../save/outputz/DeadDesert",
//			"../../../../../../../save/outputz/DeadDunes",
			"../../../../../../../save/outputz/DeadFalls",
//			"../../../../../../../save/outputz/DeepCanyon",
//			"../../../../../../../save/outputz/DeepClay",
			"../../../../../../../save/outputz/DeepDesert",
//			"../../../../../../../save/outputz/DeepDunes",
//			"../../../../../../../save/outputz/DeepFalls",
//			"../../../../../../../save/outputz/DefiantCanyon",
//			"../../../../../../../save/outputz/DefiantClay",
//			"../../../../../../../save/outputz/DefiantDesert",
//			"../../../../../../../save/outputz/DefiantDunes",
			"../../../../../../../save/outputz/DefiantFalls",
//			"../../../../../../../save/outputz/DizzyCanyon",
//			"../../../../../../../save/outputz/DizzyClay",
//			"../../../../../../../save/outputz/DizzyDesert",
			"../../../../../../../save/outputz/DizzyDunes"
//			"../../../../../../../save/outputz/DizzyFalls",
//			"../../../../../../../save/outputz/DryCanyon",
//			"../../../../../../../save/outputz/DryClay",
//			"../../../../../../../save/outputz/DryDesert",
//			"../../../../../../../save/outputz/DryDunes",
//			"../../../../../../../save/outputz/DryFalls",
//			"../../../../../../../save/outputz/DustyCanyon",
//			"../../../../../../../save/outputz/DustyClay",
//			"../../../../../../../save/outputz/DustyDesert",
//			"../../../../../../../save/outputz/DustyDunes",
//			"../../../../../../../save/outputz/DustyFalls",
//			"../../../../../../../save/outputz/DynamicCanyon",
//			"../../../../../../../save/outputz/DynamicClay",
//			"../../../../../../../save/outputz/DynamicDesert",
//			"../../../../../../../save/outputz/DynamicDunes",
//			"../../../../../../../save/outputz/DynamicFalls",
//			"../../../../../../../save/outputz/EarlyCanyon",
//			"../../../../../../../save/outputz/EarlyClay",
//			"../../../../../../../save/outputz/EarlyDesert",
//			"../../../../../../../save/outputz/EarlyDunes",
//			"../../../../../../../save/outputz/EarlyFalls",
//			"../../../../../../../save/outputz/ElectricCanyon",
//			"../../../../../../../save/outputz/ElectricClay",
//			"../../../../../../../save/outputz/ElectricDesert",
//			"../../../../../../../save/outputz/ElectricDunes",
//			"../../../../../../../save/outputz/ElectricFalls",
//			"../../../../../../../save/outputz/EliteCanyon",
//			"../../../../../../../save/outputz/EliteClay",
//			"../../../../../../../save/outputz/EliteDesert",
//			"../../../../../../../save/outputz/EliteDunes",
//			"../../../../../../../save/outputz/EliteFalls",
//			"../../../../../../../save/outputz/EmptyCanyon",
//			"../../../../../../../save/outputz/EmptyClay",
//			"../../../../../../../save/outputz/EmptyDesert",
//			"../../../../../../../save/outputz/EmptyDunes",
//			"../../../../../../../save/outputz/EmptyFalls",
//			"../../../../../../../save/outputz/FalseCanyon",
//			"../../../../../../../save/outputz/FalseClay",
//			"../../../../../../../save/outputz/FalseDesert",
//			"../../../../../../../save/outputz/FalseDunes",
//			"../../../../../../../save/outputz/FalseFalls"
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
				var world:World;
				if (PipeJam3.REPLAY_DQID) {
					world = new ReplayWorld(_worldNodes, _world_xml, _layout, _constraints);
				} else {
					world = new World(_worldNodes, _world_xml, _layout, _constraints);
				}
			} catch (error:Error) {
				throw new Error("ERROR: " + error.message + "\n" + (error as Error).getStackTrace());
				var debug:int = 0;
			}
			
			return world;
		}
	}
}