package scenes.game.display
{
	import assets.AssetInterface;
	import flash.external.ExternalInterface;
	import flash.utils.Dictionary;
	import graph.LevelNodes;
	import graph.Network;
	import graph.Node;
	import scenes.BaseComponent;
	import scenes.game.components.GameControlPanel;
	import scenes.game.components.GridViewPanel;
	import starling.display.Button;
	import starling.display.Image;
	import starling.events.Event;
	import starling.textures.Texture;
	import system.Simulator;
	
	/**
	 * World that contains levels that each contain boards that each contain pipes
	 */
	public class World extends BaseComponent
	{
		protected var edgeSetGraphViewPanel:GridViewPanel;
		public var gameControlPanel:GameControlPanel;
	
		
		/** All the levels in this world */
		public var levels:Vector.<Level> = new Vector.<Level>();
		protected var currentLevelNumber:Number = 0;
		
		/** Images used for boards of a given level (different colors, same texture) */
		public var level_background_images:Vector.<Image>;
		
		/** Map from edge set index to Vector of Pipe instances */
		public var pipeEdgeSetDictionary:Dictionary = new Dictionary();
		
		/** Map from edge_id to Pipe instance */
		public var pipeIdDictionary:Dictionary = new Dictionary();
		
		/** Current level being played by the user */
		public var active_level:Level = null;
		
		//shim to make it start with a level until we get servers up
		protected var firstLevel:Level = null;
		
		/** Network for this world */
		public var m_network:Network;
		
		/** simulator for the network */
		public var m_simulator:Simulator;

		/** Original XML used for this world */
		public var world_xml:XML;

		/** True if at least one level on this board has not succeeded */
		public var failed:Boolean = false;
		
		/** True if all levels on this board have succeeded */
		public var succeeded:Boolean = false;
		
		/** If we are in process of selecting a level. */
		protected static var selecting_level:Boolean;
		
		/** True if this World has been solves and fireworks displayed, setting this will prevent euphoria from being displayed more than once */
		public var world_has_been_solved_before:Boolean = false;
		
		/** Set to true to only include pipes on normal boards in pipeIdDictionary, not pipes that appear on subboard clones */
		public static const ONLY_INCLUDE_ORIGINAL_PIPES_IN_PIPE_ID_DICTIONARY:Boolean = true;
		
		/** Map from board name to board */
		public var worldBoardNameDictionary:Dictionary = new Dictionary();
		private var m_layoutXML:XML;
		
		protected var right_arrow_button:Button;
		protected var left_arrow_button:Button;
		
		/**
		 * World that contains levels that each contain boards that each contain pipes
		 * @param	_x X coordinate, this is currently unused
		 * @param	_y Y coordinate, this is currently unused
		 * @param	_width Width, this is currently unused
		 * @param	_height Height, this is currently unused
		 * @param	_name Name of the level
		 * @param	_system The parent VerigameSystem instance
		 */
		public function World(_network:Network, _world_xml:XML, _layout:XML = null)
		{
//			super(_x, _y, _width, _height);
			m_network = _network;
			world_xml = _world_xml;
			m_layoutXML = _layout;
			
			createWorld(m_network.LevelNodesDictionary);
			m_simulator = new Simulator(m_network);

			addEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
			addEventListener(Event.REMOVED_FROM_STAGE, onRemovedFromStage);			
		}
		
		protected function onAddedToStage(event:starling.events.Event):void
		{
			edgeSetGraphViewPanel = new GridViewPanel;
			addChild(edgeSetGraphViewPanel);
			
			gameControlPanel = new GameControlPanel;
			gameControlPanel.x = edgeSetGraphViewPanel.width;
			addChild(gameControlPanel);
			
			var arrowRightUp:Texture = AssetInterface.getTexture("GameControlPanel", "ArrowRightUpClass");
			var arrowRightClick:Texture = AssetInterface.getTexture("GameControlPanel", "ArrowRightClickClass");
			
			right_arrow_button = new Button(arrowRightUp, "", arrowRightClick);
			right_arrow_button.addEventListener(Event.TRIGGERED, onArrowRightButtonTriggered);
			right_arrow_button.x = gameControlPanel.x + gameControlPanel.width/2 - 4;
			right_arrow_button.y = 280 - 5;
			addChild(right_arrow_button);
			
			var arrowLeftUp:Texture = AssetInterface.getTexture("GameControlPanel", "ArrowLeftUpClass");
			var arrowLeftClick:Texture = AssetInterface.getTexture("GameControlPanel", "ArrowLeftClickClass");
			
			left_arrow_button = new Button(arrowLeftUp, "", arrowLeftClick);
			left_arrow_button.addEventListener(Event.TRIGGERED, onArrowLeftButtonTriggered);
			left_arrow_button.x = gameControlPanel.x + gameControlPanel.width/2 - left_arrow_button.width - 8;
			left_arrow_button.y = right_arrow_button.y;
			addChild(left_arrow_button);
			
			selectLevel(firstLevel);
			
			addEventListener(Level.SCORE_CHANGED, onScoreChange);
			addEventListener(Level.CENTER_ON_NODE, onCenterOnNodeEvent);
		}
		
		private function onArrowRightButtonTriggered():void
		{
			currentLevelNumber = (currentLevelNumber + 1) % levels.length;
			selectLevel(levels[currentLevelNumber]);
		}
		
		private function onArrowLeftButtonTriggered():void
		{
			currentLevelNumber--;
			if (currentLevelNumber<0)
				currentLevelNumber = levels.length -1
			selectLevel(levels[currentLevelNumber]);
		}
		
		private function onScoreChange(e:Event):void
		{
			var level:Level = e.data as Level;
			gameControlPanel.updateScore(level);
		}
		
		private function onCenterOnNodeEvent(e:starling.events.Event):void
		{
			var component:GameNode = e.data as GameNode;
			if(component)
			{
				edgeSetGraphViewPanel.centerOnNode(component);
			}
		}
		
		
		private function selectLevel(newLevel:Level):void
		{
			var _level:Level = newLevel;
			if (selecting_level || _level == active_level) {
				return;
			}
			selecting_level = true;
			var old_level:Level = active_level;
			if (old_level)
				removeChild(old_level);
			
			active_level = _level;
						
			selecting_level = false;
						
			active_level.initialize();
			edgeSetGraphViewPanel.loadLevel(active_level);
			gameControlPanel.updateScore(active_level);
		}
		

		
		private function onRemovedFromStage():void
		{
			removeEventListener(Level.CENTER_ON_NODE, onCenterOnNodeEvent);
		}
		
		public function createWorld(worldNodesDictionary:Dictionary):void
		{
			var original_subboard_nodes:Vector.<Node> = new Vector.<Node>();

			for (var my_level_name:String in worldNodesDictionary) {
				if (worldNodesDictionary[my_level_name] == null) {
					// This is true if there are no edges in the level, skip this level
					PipeJamGame.printDebug("No edges found on level " + my_level_name + " skipping this level and not creating...");
					continue;
				}
				var my_levelNodes:LevelNodes = (worldNodesDictionary[my_level_name] as LevelNodes);
				PipeJamGame.printDebug("Creating level: " + my_level_name);
				
				var levelLayoutXML:XML = findLevelLayout(my_levelNodes.original_level_name);
				var my_level:Level = new Level(my_level_name, my_levelNodes, levelLayoutXML);
				levels.push(my_level);
									
		//		if(my_levelNodes.original_level_name == "Application2") //KhakiDunes
					firstLevel = my_level; //grab last one..
			}
		}
		
		public function findLevel(index:uint):Level
		{
			for (var my_level_index:uint = 0; my_level_index < levels.length; my_level_index++) {
				var level:Level = levels[my_level_index];
				if(level.levelNodes.metadata["index"] == index)
					return level;
			}	
			
			return null;
		}
		
		public function findLevelLayout(name:String):XML
		{
			var layoutList:XMLList = m_layoutXML.graph.node;
			for each(var layout:XML in layoutList)
			{
				//contains the name, and it's at the end to avoid matches like level_name1
				var levelName:String = layout.@id;
				var matchIndex:int = levelName.indexOf("level_"+name);
				if(matchIndex != -1 && matchIndex+("level_"+name).length == levelName.length)
					return layout;
			}
			
			return null;
		}
		
		
		/**
		 * To be used if a graphical representation of the Level is implemented
		 */
		public function draw():void {
			
		}
		
		/**
		 * If all the levels in this world have succeeded then lots of fireworks are displayed
		 * @param	_simulation True if this was called from a simulation, false if from dropping balls
		 */
		public function checkWorldForSuccess(_simulation:Boolean):void {
			var at_least_one_level_not_succeeded:Boolean = false;
			for each (var my_level:Level in levels) {
				if (my_level.failed) {
					at_least_one_level_not_succeeded = true;
				}
			}
			if (!at_least_one_level_not_succeeded) {
				if (_simulation && Level.DROP_WHEN_SUCCEEDED) {
					return;
				} else {
					succeeded = true;
					outputXmlToJavascript();
					if (!world_has_been_solved_before) {
						var event:Event = new Event("PIPEJAM.WORLD_COMPLETE", true);
						dispatchEvent(event);
					}
					world_has_been_solved_before = true;
				}
			} else {
				succeeded = false;
			}
			//system.draw();
		}
		
		public function outputXmlToJavascript(_quit:Boolean = false):void {
			var output_xml:String = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<!DOCTYPE world SYSTEM \"world.dtd\">\n" + String(getUpdatedXML());
			if (ExternalInterface.available) {
				var reply:String = ExternalInterface.call("receiveUpdatedXML", output_xml, _quit);
			}
		}
		
		public function getUpdatedXML():XML {
			// TODO: Save level_index in each Level class instance to avoid unnecessary loops that this code uses
			var output_xml:XML = new XML(world_xml);
//			for each (var my_level:Level in levels) {
//				// Find this level in XML
//				if (my_level.levelNodes == null) {
//					continue;
//				}
//				var my_level_xml_indx:int = -1;
//				for (var level_indx:uint = 0; level_indx < output_xml["level"].length(); level_indx++) {
//					if (output_xml["level"][level_indx].attribute("name").toString() == my_level.levelNodes.original_level_name) {
//						my_level_xml_indx = level_indx;
//						break;
//					}
//				}
//				if (my_level_xml_indx > -1) {
//					//for each (var my_board:Board in my_level.boards) {
//						// Loop over boards, edges
//						for (var board_index:uint = 0; board_index < output_xml["level"][my_level_xml_indx]["boards"][0]["board"].length(); board_index++) {
//							for (var edge_index:uint = 0; edge_index < output_xml["level"][my_level_xml_indx]["boards"][0]["board"][board_index]["edge"].length(); edge_index++) {
//								var my_edge_id:String = output_xml["level"][my_level_xml_indx]["boards"][0]["board"][board_index]["edge"][edge_index].attribute("id").toString();
//								var my_pipe:Pipe = pipeIdDictionary[my_edge_id];
//								if (my_pipe) {
//									var my_width:String = "narrow";
//									if (my_pipe.associated_edge.is_wide) {
//										my_width = "wide";
//									}
//
//									output_xml["level"][my_level_xml_indx]["boards"][0]["board"][board_index]["edge"][edge_index].@width = my_width;
//									output_xml["level"][my_level_xml_indx]["boards"][0]["board"][board_index]["edge"][edge_index].@buzzsaw = my_pipe.associated_edge.has_buzzsaw.toString();
//									
//								} else {
//									throw new Error("World.getUpdatedXML(): Edge pipe not found for edge id: " + my_edge_id);
//								}
//							}
//						}
//				} else {
//					throw new Error("World.getUpdatedXML(): Level not found: " + my_level.level_name);
//				}
//				//Update the xml with the stamp state information. Currently updating all stamp states, changed or not.
//				var numEdgeSets:uint = output_xml["level"][my_level_xml_indx]["linked-edges"][0]["edge-set"].length(); 
//				for(var edgeSetIndex:uint = 0; edgeSetIndex<numEdgeSets; edgeSetIndex++) {
//					
//					var edgeID:String = output_xml["level"][my_level_xml_indx]["linked-edges"][0]["edge-set"][edgeSetIndex].attribute("id").toString();
//					var pipeVector:Vector.<Pipe> = pipeEdgeSetDictionary[edgeID];
//					for each (var currentPipe:Pipe in pipeVector) {
//					var linkedEdgeSet:EdgeSetRef =  currentPipe.associated_edge.linked_edge_set;
//						var stampLength:uint = linkedEdgeSet.num_stamps;
//						for(var stampIndex:uint = 0; stampIndex < stampLength; stampIndex++) {
//							var stampID:String = output_xml["level"][my_level_xml_indx]["linked-edges"][0]["edge-set"][edgeSetIndex]["stamp"][stampIndex].@id;
//							output_xml["level"][my_level_xml_indx]["linked-edges"][0]["edge-set"][edgeSetIndex]["stamp"][stampIndex].@active
//																	= linkedEdgeSet.hasActiveStampOfEdgeSetId(stampID).toString();
//						}
//					}
//				}
//
//			}	
			return output_xml;
		}

		
//		public function simulatorUpdateTroublePointsFS(simulator:Simulator, nodes_to_traverse:Vector.<BoardNodes> = null):void {
//			if (simulator == null) {
//				return;
//			}
//			
//			var boards_to_redraw:Vector.<Board> = new Vector.<Board>;
//			var levels_to_redraw:Vector.<Level> = new Vector.<Level>;
//			
//			//Gather all interesting boards
//			var boards_to_traverse:Vector.<Board> = new Vector.<Board>;
//			// Defaults to traversing all levels
//			if (nodes_to_traverse == null) {
//				boards_to_traverse = new Vector.<BoardNodes>();
//				for each (var lev:Level in levels) {
//					for each (var my_board:Board in lev.boards) {
//						boards_to_traverse.push(my_board.m_boardNodes);
//					}
//				}
//			}
//			else
//			{
//				for each(var boardNode:BoardNodes in nodes_to_traverse)
//				{
//					boards_to_traverse.push(worldBoardNameDictionary[boardNode.board_name]);
//				}
//			}
//			
//			var tpCount:uint = updateTroublePoints(simulator, boards_to_traverse);
//					
//			var boards_to_check_for_success:Vector.<Board> = new Vector.<Board>();
//			for each (var sim_board1:Board in boards_to_traverse) {
//				sim_board1.level.failed = false;
//			}
//			for each (var sim_board:Board in boards_to_traverse) {
//					if (tpCount > 0) {
//						// If we haven't already failed this board, fail it and any other boards that it appears on
//						if (sim_board.trouble_points.length != 0) {
//							// If not already failed, fail this board's level
//							if (!sim_board.level.failed) {
//								sim_board.level.failed = true;
//								if(levels_to_redraw.indexOf(sim_board.level) != -1)
//									levels_to_redraw.push(sim_board.level); 
//							}
//							// Queue up any un-failed boards that this board appears on to be failed
//							var queue:Vector.<Board> = new Vector.<Board>();
//							for each (var my_board1:Board in sim_board.clone_children) {
//								if (my_board1.trouble_points == null || my_board1.trouble_points.length == 0) {
//									if (my_board1.sub_board_parent) {
//										if (my_board1.sub_board_parent.clone_level == 0) {
//											if (queue.indexOf(my_board1.sub_board_parent) == -1) {
//												queue.push(my_board1.sub_board_parent);
//											}
//										}
//									}
//								}
//							}
//							//var boards_checked:Vector.<Board> = new Vector.<Board>();
//							while (queue.length > 0) {
//								var board_to_fail:Board = queue.shift();
//								//boards_checked.push(board_to_fail);
//								if(boards_to_redraw.indexOf(board_to_fail) == -1)
//									boards_to_redraw.push(board_to_fail);
//								board_to_fail.updateCloneChildrenToMatch();
//								if (!board_to_fail.level.failed) {
//									board_to_fail.level.failed = true;
//									if(levels_to_redraw.indexOf(board_to_fail.level) == -1)
//										levels_to_redraw.push(board_to_fail.level); 
//								}
//								// Queue up any boards that THIS board appears on (this shouldn't be subject to infinite loops)
//								for each (var new_fail_board:Board in board_to_fail.clone_children) {
//									if (new_fail_board.sub_board_parent) {
//										if (new_fail_board.sub_board_parent.clone_level == 0) {
//											if (new_fail_board.sub_board_parent.trouble_points.length == 0) {
//												if ((new_fail_board != board_to_fail) && queue.indexOf(new_fail_board.sub_board_parent) == -1) {
//													queue.push(new_fail_board.sub_board_parent);
//												}
//											}
//										}
//									}
//								}
//							}
//							if(boards_to_redraw.indexOf(sim_board) == -1)
//								boards_to_redraw.push(sim_board); 
//							sim_board.updateCloneChildrenToMatch();
//						}
//					} else {
//						// If no trouble points and hasn't been marked by failed by previous board, mark as succeeded for now and check any sub boards in the next loop
//						if (boards_to_check_for_success.indexOf(sim_board) == -1) {
//							boards_to_check_for_success.push(sim_board);
//						}
//					}
//				if (sim_board.trouble_points.length == 0) {
//					// If no trouble points and hasn't been marked by failed by previous board, mark as succeeded for now and check any sub boards in the next loop
//					if (boards_to_check_for_success.indexOf(sim_board) == -1) {
//						boards_to_check_for_success.push(sim_board);
//					}
//				}
//			}
//			
//			// Now traverse updated boards to see if they were subsequently failed, if not mark as succeeded and check levels
//			var levels_to_check_for_success:Vector.<Level> = new Vector.<Level>();
//			for each (var my_success_board:Board in boards_to_check_for_success) {
//				if (my_success_board.trouble_points.length == 0) {
//					my_success_board.updateCloneChildrenToMatch();
//					if (levels_to_check_for_success.indexOf(my_success_board.level) == -1) {
//						levels_to_check_for_success.push(my_success_board.level);
//						if(boards_to_redraw.indexOf(my_success_board) == -1)
//							boards_to_redraw.push(my_success_board); 
//					}
//				}
//			}
//			// Now traverse levels with at least one newly succeeded board to check for success
//			for each (var my_success_level:Level in levels_to_check_for_success) {
//				my_success_level.checkLevelForSuccess(true);
//			}
//			m_gameSystem.checkForCelebration();
//	//		m_gameSystem.draw(); just drew in checkLevelForSuccess above
//			for each(var level:Level in levels_to_redraw)
//				level.draw();
//			for each(var board:Board in boards_to_redraw)
//			{
//				board.draw();
//				m_gameSystem.navigation_control_panel.updateBoard(board);
//			}
//			m_gameSystem.navigation_control_panel.initializeBoardNavigationBar();
//		}
		
//		public function updateTroublePoints(simulator:Simulator, boards_to_traverse:Vector.<Board> = null):uint
//		{	
//			var tpCount:uint = 0;
//			for each (var sim_board:Board in boards_to_traverse) 
//			{
//				//clean the board
//				sim_board.removeAllTroublePoints();
//				
//				// Get new trouble points from simulator
//				var trouble_pointsContainers:Dictionary = simulator.getAllTroublePointsByBoardName(sim_board.board_name);
//				
//				if (trouble_pointsContainers) {
//					for each (var port:Port in trouble_pointsContainers["port"]) {
//						tpCount++;
//						sim_board.insertCircularTroublePoint(port.edge.associated_pipe);
//						// Mark failed = succeeded = false to force pipe to recompute this during the draw() call
//						port.edge.associated_pipe.failed = false;
//						port.edge.associated_pipe.draw();
//						// Mark the board failed = succeeded = false to force pipe to recompute this after all trouble points dealt with
//					}
//					for each (var edge:Edge in trouble_pointsContainers["edge"]) {
//						tpCount++;
//						sim_board.insertCircularTroublePoint(edge.associated_pipe);
//						// Mark failed = succeeded = false to force pipe to recompute this during the draw() call
//						edge.associated_pipe.failed = false;
//						edge.associated_pipe.draw();
//						// Mark the board failed = succeeded = false to force pipe to recompute this after all trouble points dealt with
//					}
//					
//				}
//			}
//			return tpCount;
//		}
	}
}