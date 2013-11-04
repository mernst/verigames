package tasks 
{
	import graph.LevelNodes;
	import graph.Network;
	import utils.LevelLayout;
	
	public class ParseLevelXMLTask extends Task 
	{
		
		private var level_xml:XML;
		private var worldNodes:Network;
		
		public function ParseLevelXMLTask(_level_xml:XML, _worldNodes:Network, _id:String = "", _dependentTaskIds:Vector.<String> = null) 
		{
			level_xml = _level_xml;
			worldNodes = _worldNodes
			if (_id.length == 0) {
				_id = level_xml.attribute("name").toString();
			}
			super(_id, _dependentTaskIds);
		}
		
		public override function perform():void {
			super.perform();
			LevelLayout.parseLevelXML(level_xml, worldNodes, worldNodes.obfuscator);
			complete = true;
		}
		
	}

}