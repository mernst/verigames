package VisualWorld
{
	import flash.geom.PerspectiveProjection;
	import flash.geom.Point;
	import VisualWorld.*;
	import UserInterface.*;
	import System.*;
	
	import UserInterface.Components.LevelIcon;
	import UserInterface.Components.RectangularObject;
	
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.text.TextField;
	import flash.utils.Dictionary;
	
	import NetworkGraph.*;
	
	/**
	 * Level contains multiple boards that each contain multiple pipes
	 */
	public class Level extends RectangularObject
	{
		
		/** True to allow user to navigate to any level regardless of whether levels below it are solved for debugging */
		public static var UNLOCK_ALL_LEVELS_FOR_DEBUG:Boolean = false;
		
		/** True if the balls should be dropped when the level has been solved, rather than displaying fireworks right away */
		public static const DROP_WHEN_SUCCEEDED:Boolean = false;
		
		/** All the boards contained within this level (not including any subboards) */
		public var boards:Vector.<Board>;
		
		/** Name of this level */
		public var level_name:String;
		
		/** World that this level appears in */
		public var world:World;
		
		/** True if not all boards on this level have succeeded */
		public var failed:Boolean = true;
		
		/** The array that describes which color corresponds to a given edge set index */
		private var set_index_colors:Dictionary = new Dictionary();// set_index_colors[id] = 0xXXXXX (i.e. 0xFFFF00)
		
		/** Index indicating the next color to be used when assigning to an edge set index */
		public var color_index:uint = 0;
		
		/** True if this level has been solves and fireworks displayed, setting this will prevent euphoria from being displayed more than once */
		public var level_has_been_solved_before:Boolean = false;
		
		/** All levels that contain a copy of a board from this level as a subboard on a board on that level */
		public var levels_that_depend_on_this_level:Vector.<Level>;
		
		/** All levels containing boards that appear as subboards on any boards in this level */
		public var levels_that_this_level_depends_on:Vector.<Level>;
		
		/** True if the levels that this level depends on have been solved, and the user can visit this level */
		public var unlocked:Boolean = true;
		
		/** Rank refers to have many levels of dependency this level has. If no dependencies: rank = 0, if this level 
		 * depends one level (contains a subboard from another level) that also depends on a level (contains a 
		 * subboard from another level) then rank = 2, etc. 
		 * This will correspond to how high up the level should be on the world map (0 = low, towards Start) */
		public var rank:uint = 0;
		
		/** Index of this level within the overall rank, i.e. the 2nd level of rank = 5 has rank_index = 1, this may equate to 
		 * an X coordinate on the world map */
		public var rank_index:uint = 0;
		
		/** The last board on this level (if any) that the user played */
		public var last_board_visited:Board;
		
		/** The icon associated with this level on the world map */
		public var level_icon:LevelIcon;
		
		/** Map from edge set index to Vector of Pipe instances */
		public var pipeEdgeSetDictionary:Dictionary = new Dictionary();
		
		/** Map from edge_id to Pipe instance */
		public var pipeIdDictionary:Dictionary = new Dictionary();
				
		/** Node collection used to create this level, including name obfuscater */
		public var levelNodes:LevelNodes;
		
		public var m_gameSystem:VerigameSystem;
		
		public var boardContainerPanel:RectangularObject;
		/**
		 * Level contains multiple boards that each contain multiple pipes
		 * @param	_x X coordinate, this is currently unused
		 * @param	_y Y coordinate, this is currently unused
		 * @param	_width Width, this is currently unused
		 * @param	_height Height, this is currently unused
		 * @param	_name Name of the level
		 * @param	_world The parent world that contains this level
		 * @param  _levelNodes The node objects used to create this level (including name obfuscater)
		 */
		public function Level(_x:int, _y:int, _width:uint, _height:uint, _name:String, _system:VerigameSystem, _world:World, _levelNodes:LevelNodes)
		{
			super(_x, _y, _width, _height);
			UNLOCK_ALL_LEVELS_FOR_DEBUG = VerigameSystem.DEBUG_MODE;
			level_name = _name;
			name = "Level:" + level_name;
			m_gameSystem = _system;
			world = _world;
			levelNodes = _levelNodes;
			boards = new Vector.<Board>();
			color_index = 0;
			levels_that_depend_on_this_level = new Vector.<Level>();
			levels_that_this_level_depends_on = new Vector.<Level>();
						
			setDisplayData();
			
			draw();
		}
		
		protected function setDisplayData():void
		{
		//	var displayNode
		}
		
		public function createLevel(original_subboard_nodes:Vector.<Node>, gameArea:RectangularObject):void
		{			
			var my_board_index:uint = 0;
				
			for each(var my_boardNode:BoardNodes in levelNodes.boardNodesDictionary) {

				var my_board:Board;
				//make the board bigger so that pipes shrink down to reasonable size
				my_board = new Board(0, 0, gameArea.width*2, gameArea.height*2, my_boardNode.board_name, 0.0, this, m_gameSystem, m_gameSystem.selectBoard);
				my_board.m_boardNodes = my_boardNode;
				boards.push(my_board);
				
				var min_y:Number, max_y:Number;
				min_y = Number.MAX_VALUE;
				max_y = Number.NEGATIVE_INFINITY;
				my_board.unallocated_node_ids = new Vector.<String>();
				
				for (var nodeID:String in my_boardNode.nodeDictionary) {
					var test_min_max_node:Node = (my_boardNode.nodeDictionary[nodeID] as Node);
					if (test_min_max_node.y < min_y) {
						min_y = test_min_max_node.y;
					}
					if (test_min_max_node.y > max_y) {
						max_y = test_min_max_node.y;
					}
					my_board.unallocated_node_ids.push(test_min_max_node.node_id);
				}
				
				// adjust nodes to start at y = 0.0
				for (var my_node_id1:String in my_boardNode.nodeDictionary) {
					var adjust_min_max_node:Node = (my_boardNode.nodeDictionary[my_node_id1] as Node);
					adjust_min_max_node.y = adjust_min_max_node.y - min_y;
				}
				min_y = 0.0;
				
				my_board.createBoard(original_subboard_nodes );
				
				// Perform topological sort, order pipes from top to bottom
				var pipes_to_allocate:Vector.<Pipe> = my_board.pipes.splice(0, my_board.pipes.length);
				var dict:Dictionary = my_board.m_boardNodes.startingEdgeDictionary; 
				var queue:Vector.<Edge> = new Vector.<Edge>();
				for each (var v:Vector.<Edge> in dict) {
					for each (var e:Edge in v) {
						if (e.from_node.kind != NodeTypes.MERGE) {
							queue.push(e);
						}
					}
				}
				while ( queue.length != 0 ) { // traverse all the pipes
					var next_edge:Edge = queue.shift(); //dequeue
					switch (next_edge.from_node.kind) {
						case NodeTypes.CONNECT:
							// If the previous pipe hasn't been added yet, don't proceed forward yet and put this pipe back in the queue
							// (this can happen if pipes joined with CONNECT node have different edge_set_ids (the outgoing pipe is then added
							// to the starting_edge_dictionary)
							if (my_board.pipes.indexOf(next_edge.from_node.incoming_ports[0].edge.associated_pipe) == -1) {
								queue.push(next_edge); // push this back on the queue
								continue;
							}
							break;
					}
					if (pipes_to_allocate.indexOf(next_edge.associated_pipe) > -1) {
						var pipe_sorted:Vector.<Pipe> = pipes_to_allocate.splice(pipes_to_allocate.indexOf(next_edge.associated_pipe), 1);
						my_board.addPipe(pipe_sorted[0]);
					} else {
						VerigameSystem.printWarning("WARNING! Pipe found during topological sort that is not contained on this board: pipe edge id = " + next_edge.edge_id);
					}
					var add_outgoing_edges:Boolean = true;
					var to_node:Node = next_edge.to_node;
					switch (to_node.kind) {
						case NodeTypes.MERGE:
							// Check if the other merging edge's pipe has already been added, if so we can continue - otherwise wait
							var other_indx:int;
							if (to_node.incoming_ports[0].edge == next_edge) {
								other_indx = my_board.pipes.indexOf(to_node.incoming_ports[1].edge.associated_pipe);
								if (other_indx == -1) {
									// Wait for other edge to arrive before proceeding
									add_outgoing_edges = false;
								}
							} else {
								other_indx = my_board.pipes.indexOf(to_node.incoming_ports[0].edge.associated_pipe);
								if (other_indx == -1) {
									// Wait for other edge to arrive before proceeding
									add_outgoing_edges = false;
								}
							}
							break;
					}
					if (add_outgoing_edges) {
						for each (var outgoing_port:Port in to_node.outgoing_ports) {
							// Queue if we haven't dealt with this edge yet (which we may have for, say, an earlier traversal of the other merging edge)
							if ( (queue.indexOf(outgoing_port.edge) == -1) && (my_board.pipes.indexOf(outgoing_port.edge.associated_pipe) == -1) ) {
								queue.push(outgoing_port.edge); //enqueue
							}
						}
					}
				}
				// There ought to be no pipes left unallocated, but if so do it here
				while (pipes_to_allocate.length > 0) {
					my_board.addPipe(pipes_to_allocate.shift());
				}
				my_board_index++;
			}
		}
		
		public function finishLevel():void
		{
			for each (var board_to_finish:Board in boards) {
				board_to_finish.finishBoard();
				board_to_finish.deactivate();
			}
		}
		

		/**
		 * To be used if a graphical representation of the Level is implemented
		 */
		public function draw():void {
			if (level_icon) {
				level_icon.draw();
			}
		}
		
		/**
		 * This function will be called when this level's icon is clicked on in the world map
		 */
		public function selectMe(e:Event):void {
			if ((world.m_gameSystem.current_world == world) && (world.levels.indexOf(this) > -1) && (unlocked || UNLOCK_ALL_LEVELS_FOR_DEBUG)) {
				m_gameSystem.selecting_level = false; //haven't started yet...
				world.m_gameSystem.selectLevel(this, true);
			}
		}
		
		/**
		 * Adds the input edge set index and pipe object instance pair to the pipeEdgeSetDictionary and pipe id pipe instance pair to the pipeIdDictionary
		 * @param	p Pipe object instance to be associated
		 * @param	checkIfExists True if only pipes that do not already exist in the dictionary are added
		 */
		public function addPipeToDictionaries(p:Pipe, checkIfExists:Boolean = true):void {
			var id:String = p.associated_edge.edge_id;
			var edge_set_id:String = p.edge_set_id;
			if (pipeEdgeSetDictionary[edge_set_id] == null) {
				pipeEdgeSetDictionary[edge_set_id] = new Vector.<Pipe>();
			}
			if ((!checkIfExists) || (pipeEdgeSetDictionary[edge_set_id].indexOf(p) == -1)) {
				pipeEdgeSetDictionary[edge_set_id].push(p);
			}
			if (pipeIdDictionary[id] != null) {
				VerigameSystem.printDebug("WARNING! Collision of edge ids detected at " + id);
			} else {
				pipeIdDictionary[id] = p;
			}
		}
		
		/**
		 * Checks if all boards on this level have succeeded and marks the level as succeeded if so, if this was
		 * a simulation and the DROP_WHEN_SUCCEEDED flag is true then the balls are subsequently dropped.
		 * Fireworks are displayed if the level has not been solved before.
		 * @param	_simulation True if this was called after a simulation (as opposed to the user pressing the drop button)
		 */
		public function checkLevelForSuccess(_simulation:Boolean):void {
			failed = true;
			var at_least_one_board_not_succeeded:Boolean = false;
			for each (var my_board:Board in boards) {
				for each (var my_sub:Board in my_board.subnet_boards) {
					if (my_sub.clone_parent.trouble_points.length != 0) {
						at_least_one_board_not_succeeded = true;
						my_board.draw();
						break;
					}
				}

				if (my_board.trouble_points.length != 0) {
					at_least_one_board_not_succeeded = true;
				}
			}
			if (!at_least_one_board_not_succeeded) {
				if (!(_simulation && DROP_WHEN_SUCCEEDED)) {
					failed = false;
					world.m_gameSystem.draw();
				}
				if (world.m_gameSystem.m_shouldCelebrate)
					world.checkWorldForSuccess(_simulation);
				if (!world.succeeded) {
					if (_simulation && DROP_WHEN_SUCCEEDED) {
						return;
					} else {
						failed = false;
						if (!level_has_been_solved_before && !world.m_gameSystem.loading_world && (world.m_gameSystem.current_level == this)) {
							if(world.m_gameSystem.m_shouldCelebrate)
								world.m_gameSystem.levelCompleteEuphoria();
							
							world.m_gameSystem.m_gameScene.levelCompleted();
						} else {
							world.m_gameSystem.draw();
						}
						level_has_been_solved_before = true;
					}
				} else {
					level_has_been_solved_before = true;
				}
				for each (var level_to_unlock:Level in levels_that_depend_on_this_level) {
					if (!level_to_unlock.unlocked) {
						level_to_unlock.unlocked = true;
						level_to_unlock.draw();
						level_to_unlock.level_icon.draw();
					}
				}
			} else {
				failed = true;
			}
			//update world map, in all cases
			draw();
		}
		
		/**
		 * Returns the existing color pipe for this edge set index, if none exists than a color is associated with it
		 * @param	_set_id Edge set id to use to retrieve the associated color
		 * @return The color associated with this edge set index
		 */
		public function getColorByEdgeSetId(_set_id:String):Number {
			if (set_index_colors[_set_id] != null) {
				return Number(set_index_colors[_set_id]);
			} else {
				set_index_colors[_set_id] = getNextColor();
				return Number(set_index_colors[_set_id]);
			}
		}
		
		/**
		 * Old color scheme with fewer colors, preserved if old levels are needed to be recreated color-for-color
		 * @return Next color, cycles back to first color if all have been used already
		 */
		public function getNextColorOld():Number {
			var arr:Array = new Array(0x0000FF, 0xFFFF00, 0xFFAAAA, 0x009900, 0x00FFFF, 0xFFCC33, 0x9933FF, 0x993300, 0x009999, 0xFF33CC);
			color_index++;
			return arr[color_index % arr.length];
		}
		
		/**
		 * Gets the next color in the list of available pipe colors
		 * @return Next color, cycles back to first color if all have been used already
		 */
		public function getNextColor():Number {
			var arr:Array = new Array(0x006600, 0x00FFFF, 0xFFFF00, 0x669999, 0x000099, 0x0000FF,  0xAA99FF, 0xFFAAAA, 0x009900, 0xFFCC33, 0xFF6600, 0x9933FF, 0x993300, 0x009999, 0xFF33CC, 0x880066, 0xCCFF33, 0xCCCC00, 0x993333);
			color_index++;
			return arr[color_index % arr.length];
		}
		
		/**
		 * Removes all trouble points from all boards in the level
		 */
		public function clearAllTroublePoints():void {
			for each (var my_board:Board in boards) {
				if (my_board.trouble_points.length > 0) {
						my_board.removeAllTroublePoints();
				}
			}
		}
		
		public function updateBallSizes():void {
			for each (var board:Board in boards) {
				for each (var ball:Ball in board.all_balls) {
					ball.updateSize();
				}
			}
		}
		
		public function updateLinkedPipes(p:Pipe, isWide:Boolean):void
		{
			var pipeVector:Vector.<Pipe> = pipeEdgeSetDictionary[p.edge_set_id];
			for each (var pipe:Pipe in pipeVector)
			{
				pipe.forceWidth(isWide);
				pipe.draw();
				pipe.associated_edge.updatePriorEdges();
			}
			
		}
	}
}