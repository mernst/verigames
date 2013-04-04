package utilities 
{
	import graph.*;
	import graph.LevelNodes;
	import graph.Network;
	
	import system.VerigameServerConstants;
	import Game;
	
	import flash.external.ExternalInterface;
	import flash.geom.Point;
	import flash.utils.Dictionary;

	/**
	 * Class to read XML and create/link node objects and edge objects from them
	*/
	public class LevelLayout 
	{
	
		public static function parseLevelXML(my_level_xml:XML, obfuscater:NameObfuscater = null):LevelNodes {
			var my_levelNodes:LevelNodes = new LevelNodes(my_level_xml.attribute("name").toString(), obfuscater);
			
			if (my_level_xml["boards"].length() == 0) {
				Game.printDebug("NO <boards> found. Level not created...");
				return null;
			}
			
			// Obtain boards
			if (my_level_xml["boards"][0]["board"].length() == 0) {
				Game.printDebug("NO <boards> <board> 's found. Level not created...");
				return null;
			}
			var boards_xml_list:XMLList = my_level_xml["boards"][0]["board"];
			
			// Obtain edges
			if (my_level_xml["boards"][0]["board"]["edge"].attribute("description").length() == 0) {
				Game.printDebug("NO <boards> <edge> 's found. Level not created...");
				return null;
			}
			
			// Obtain linked edge sets
			var edge_set_dictionary:Dictionary = new Dictionary();
			if (my_level_xml["linked-edges"][0]["edge-set"].length() == 0) {
				Game.printDebug("NO <linked-edges> <edge-set> 's found. Level not created...");
				return null;
			}
			var edge_set_index:int = 0;
			for each (var le_set:XML in my_level_xml["linked-edges"][0]["edge-set"]) {
				if (le_set["edgeref"].attribute("id").length() > 0) {
					var my_id:String = String(le_set.attribute("id"));
					if (my_id.length == 0) {
						my_id = edge_set_index.toString();
					}
					var my_edge_set:EdgeSetRef = new EdgeSetRef(my_id, edge_set_dictionary);
					for (var le_id_indx:uint = 0; le_id_indx < le_set["edgeref"].attribute("id").length(); le_id_indx++) {
						edge_set_dictionary[le_set["edgeref"].attribute("id")[le_id_indx].toString()] = my_edge_set;
						my_edge_set.edge_ids.push(le_set["edgeref"].attribute("id")[le_id_indx].toString());
					}
					for (var stamp_id_indx:uint = 0; stamp_id_indx < le_set["stamp"].length(); stamp_id_indx++) {
						var isActive:Boolean = XString.stringToBool(String(le_set["stamp"][stamp_id_indx].attribute("active")));
						my_edge_set.addStamp(String(le_set["stamp"][stamp_id_indx].attribute("id")), isActive);
					}
					edge_set_index++;
				}
			}
			
			var my_board_xml:XML;
			var source_node:Node, dest_node:Node;
			for (var b:uint = 0; b < boards_xml_list.length(); b++) {
				my_board_xml = boards_xml_list[b];
				Game.printDebug("Processing board: " + my_board_xml.attribute("name"));
				
				
				// FORM NODE/EDGE OBJECTS FROM XML
				for each (var n1:XML in my_board_xml["node"]) {
					var md:Metadata = attributesToMetadata(n1);
					var new_node:Node;
					var my_kind:String = n1.attribute("kind");
					switch (my_kind) {
						case NodeTypes.SUBBOARD:
							new_node = new SubnetworkNode(Number(n1.layout.x), Number(n1.layout.y), Number(n1.layout.y), md);
						break;
						case NodeTypes.GET:
							new_node = new MapGetNode(Number(n1.layout.x), Number(n1.layout.y), Number(n1.layout.y), md);
						break;
						default:
							new_node = new Node(Number(n1.layout.x), Number(n1.layout.y), Number(n1.layout.y), my_kind, md);
						break;
					}
					my_levelNodes.addNode(new_node, my_board_xml.attribute("name"));
				}
				
				if (my_board_xml["display"].length() > 0) {
					var boardNode:BoardNodes = my_levelNodes.getDictionary(my_board_xml.attribute("name"));
					if(boardNode)
					{
						var boardDisplayXML:XMLList = my_board_xml["display"];
						boardNode.metadata["display"] = boardDisplayXML[0];
					}
				}
				
				for each (var e1:XML in my_board_xml["edge"]) {
					var md1:Metadata = attributesToMetadata(e1);
					if ( (e1["from"]["noderef"].attribute("id").length() != 1) || (e1["from"]["noderef"].attribute("port").length() != 1) ) {
						Game.printDebug("WARNING: Edge #id = " + e1.attribute("id") + " does not have a source node id/port");
						return null;
					}
					if ( (e1["to"]["noderef"].attribute("id").length() != 1) || (e1["to"]["noderef"].attribute("port").length() != 1) ) {
						Game.printDebug("WARNING: Edge #id = " + e1.attribute("id") + " does not have a destination node id/port");
						return null;
					}
					
					source_node = my_levelNodes.getNode(my_board_xml.attribute("name"), e1["from"]["noderef"].attribute("id").toString());
					dest_node = my_levelNodes.getNode(my_board_xml.attribute("name"), e1["to"]["noderef"].attribute("id").toString());
					
					if ( (source_node == null) || (dest_node == null) ) {
						Game.printDebug("WARNING: Edge #id = " + e1.attribute("id") + " could not find node with getNodeById() method.");
						return null;
					}
					
					var spline_control_points:Vector.<Point> = new Vector.<Point>();
					for each (var pts:XML in e1["edge-layout"]) {
						for each (var pt:XML in pts["point"]) {
							var pt_x:String = pt["x"];
							var pt_y:String = pt["y"];
							if (!isNaN(Number(pt_x)) && !isNaN(Number(pt_y))) {
								spline_control_points.push(new Point(Number(pt_x), Number(pt_y)));
							}
						}
					}
					
					// Add this edge!
					source_node.addOutgoingEdge(e1["from"]["noderef"].attribute("port").toString(), dest_node, e1["to"]["noderef"].attribute("port").toString(), spline_control_points, edge_set_dictionary[e1.attribute("id").toString()], md1);
				}
			} // loop over every node a.k.a. board
			
			if (my_level_xml["display"].length() != 0) {
				var levelDisplayXML:XMLList = my_board_xml["display"];
				my_levelNodes.metadata["display"] = levelDisplayXML;		
			}
			
			if (my_level_xml.attribute("index").length() != 0) {
				my_levelNodes.metadata["index"] = new Number(my_level_xml.attribute("index"));		
			}
			
			Game.printDebug("Level layout LOADED!");
			return my_levelNodes;
		}
		
		/**
		 * Converts all XML attributes for the XML object to metadata to be stored in an edge/node
		 * @param	_xml XML to load attributes from
		 * @return Metadata object created with attributes
		 */
		public static function attributesToMetadata(_xml:XML):Metadata {
			// This function grabs all the attribute key/value pairs and stores them as a Metadata object
			// NOTE: All values are stored as Strings, no type casting is performed unless specifically laid out
			var obj:Object = new Object();
			for each (var attr:XML in _xml.attributes()) {
				//trace("obj['" + attr.name().localName + "'] = " + _xml.attribute(attr.name()).toString());
				if (attr.name() == "id") {
					obj[attr.name().localName] = _xml.attribute(attr.name()).toString();// this could be parse to int, but is not
				} else {
					obj[attr.name().localName] = _xml.attribute(attr.name()).toString();
				}
				if (_xml.attribute(attr.name()).length() == 0)
					Game.printWarning("WARNING! Attribute '"+attr.name()+"' value found for this XML.");
				else if (_xml.attribute(attr.name()).length() > 1)
					Game.printWarning("WARNING! More than one attribute '"+attr.name()+"' value was found for this XML.");
			}
			return new Metadata(obj, _xml);
		}
		
	}

}