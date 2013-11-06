package state 
{
	import starling.events.Event;
	import utils.LevelLayout;
	
	import graph.Network;
	import tasks.ParseLevelXMLTask;
	
	public class ParseXMLState extends LoadingState
	{
		/** Width of game */
		public static var WORLD_PARSED:String = "World Parsed";

		private var WORLD_VALID_XML_VERSIONS:Array = ["1","2","3"];
		private var world_xml:XML;
		private var world_nodes:Network;		
		
		public function ParseXMLState(_world_xml:XML) 
		{
			super();
			world_xml = _world_xml;
		}
		
		public override function stateLoad():void {
			var world_version:String =  world_xml[0].@version;
			if (WORLD_VALID_XML_VERSIONS.indexOf(world_version) == -1) {
				var allVers:String = "";
				for each (var ver:String in WORLD_VALID_XML_VERSIONS) allVers += ver + ", ";
				throw new Error("World XML version used is not one the game is designed to read. The game is designed to read versions '" + allVers + "'");
				return;
			}
			
			var my_world_name:String = "World 1";
			if (world_xml[0].@name && world_xml[0].@name.toString().length) {
				my_world_name = world_xml[0].@name;
			}
			
			world_nodes = new Network(my_world_name, world_version);
			
			if (world_version == "3") {
				// Need to pre-parse the linked variable id table for version 3 (and presumably later versions)
				LevelLayout.parseLinkedVariableIdXML(world_xml, world_nodes);
			}
			
			for (var level_index:uint = 0; level_index < world_xml["level"].length(); level_index++) {
				var my_level_xml:XML = world_xml["level"][level_index];
				var my_task:ParseLevelXMLTask = new ParseLevelXMLTask(my_level_xml, world_nodes);
				tasksVector.push(my_task);
			}
			
			super.stateLoad();
		}
		
		public override function stateUnload():void {
			super.stateUnload();
			world_xml = null;
			world_nodes = null;
		}
		
		public override function onTasksComplete():void {
			world_nodes.attachExternalSubboardNodesToBoardNodes();
			var event:starling.events.Event = new Event(WORLD_PARSED, true, world_nodes);
			dispatchEvent(event);
			stateUnload();
		}
		
	}

}