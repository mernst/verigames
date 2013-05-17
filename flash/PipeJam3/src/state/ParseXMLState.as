package state 
{
	import graph.Network;
	
	import tasks.ParseLevelXMLTask;
	
	import flash.events.Event;
	import starling.events.Event;
	
	public class ParseXMLState extends LoadingState
	{
		/** Width of game */
		public static var WORLD_PARSED:String = "World Parsed";

		private var WORLD_INPUT_XML_VERSION:String = "1";
		private var world_xml:XML;
		private var world_nodes:Network;		
		
		public function ParseXMLState(_world_xml:XML) 
		{
			super();
			world_xml = _world_xml;
		}
		
		public override function stateLoad():void {
			
			var version_failed:Boolean = false;
			
			if ("1" == null) {
				version_failed = true;
			} else if ("1" != WORLD_INPUT_XML_VERSION) {
				version_failed = true;
			}
			if (version_failed) {
				throw new Error("World XML version used does not match the version that this game .SWF is designed to read. The game is designed to read version '" + WORLD_INPUT_XML_VERSION + "'");
				return;
			}
			
			var my_world_name:String = "World 1";
			if (world_xml.attribute("name") != null) {
				if (world_xml.attribute("name").toString().length > 0) {
					my_world_name = world_xml.attribute("name").toString();
				}
			}
			
			world_nodes = new Network(my_world_name);
			
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
			var event:starling.events.Event = new starling.events.Event(WORLD_PARSED, true, world_nodes);
			dispatchEvent(event);
			stateUnload();
		}
		
	}

}