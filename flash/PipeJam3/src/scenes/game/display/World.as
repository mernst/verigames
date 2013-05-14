package scenes.game.display
{
	import assets.AssetInterface;
	import flash.external.ExternalInterface;
	import flash.utils.Dictionary;
	import flash.events.Event;
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
	import scenes.game.components.InGameMenuBox;
	
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
		
		public static var SHOW_GAME_MENU:String = "show_game_menu";
		public static var SWITCH_TO_NEXT_LEVEL:String = "switch_to_next_level";
		
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

			addEventListener(starling.events.Event.ADDED_TO_STAGE, onAddedToStage);
			addEventListener(starling.events.Event.REMOVED_FROM_STAGE, onRemovedFromStage);			
		}
		
		protected function onAddedToStage(event:starling.events.Event):void
		{
			edgeSetGraphViewPanel = new GridViewPanel;
			addChild(edgeSetGraphViewPanel);
			
			gameControlPanel = new GameControlPanel;
			gameControlPanel.x = edgeSetGraphViewPanel.width;
			addChild(gameControlPanel);
			
			selectLevel(firstLevel);
			
			addEventListener(Level.SCORE_CHANGED, onScoreChange);
			addEventListener(Level.CENTER_ON_COMPONENT, onCenterOnNodeEvent);
			addEventListener(World.SHOW_GAME_MENU, onShowGameMenuEvent);
			addEventListener(World.SWITCH_TO_NEXT_LEVEL, onNextLevel);
			
			addEventListener(Level.SAVE_LAYOUT, onSaveLayoutFile);
			addEventListener(Level.SUBMIT_SCORE, onSubmitScore);
			addEventListener(Level.SAVE_LOCALLY, onSaveLocally);
		}
		
		private function onShowGameMenuEvent():void
		{
			var inGameMenuBox:InGameMenuBox = new InGameMenuBox();
			addChild(inGameMenuBox);
			inGameMenuBox.x = 150;
			inGameMenuBox.y = 20;
		}
		
		public function onSaveLayoutFile(event:starling.events.Event):void
		{
			if(active_level != null)
				active_level.onSaveLayoutFile(event);
		}
		
		public function onSubmitScore(event:starling.events.Event):void
		{
			if(active_level != null)
				active_level.onSubmitScore(event);
		}
		
		public function onSaveLocally(event:starling.events.Event):void
		{
			if(active_level != null)
				active_level.onSaveLocally(event);
		}
		
		private function onScoreChange(e:starling.events.Event):void
		{
			var level:Level = e.data as Level;
			gameControlPanel.updateScore(level);
		}
		
		private function onCenterOnNodeEvent(e:starling.events.Event):void
		{
			var component:GameComponent = e.data as GameComponent;
			if(component)
			{
				edgeSetGraphViewPanel.centerOnComponent(component);
			}
		}
		
		private function onNextLevel(e:starling.events.Event):void
		{
			currentLevelNumber = (currentLevelNumber + 1) % levels.length;
			selectLevel(levels[currentLevelNumber]);
		}
		
		
		private function selectLevel(newLevel:Level):void
		{
			if (newLevel == active_level) {
				return;
			}

			active_level = newLevel;
			
			edgeSetGraphViewPanel.loadLevel(newLevel);
			gameControlPanel.updateScore(newLevel);
			
			trace("gcp: " + gameControlPanel.width + " x " + gameControlPanel.height);
			trace("vp: " + edgeSetGraphViewPanel.width + " x " + edgeSetGraphViewPanel.height);
			dispatchEvent(new starling.events.Event(Game.STOP_BUSY_ANIMATION,true));
		}
		

		
		private function onRemovedFromStage():void
		{
			removeEventListener(Level.CENTER_ON_COMPONENT, onCenterOnNodeEvent);
			if(active_level)
				removeChild(active_level, true);
			m_network = null;
			world_xml = null;
			m_layoutXML = null;
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
			var layoutList:XMLList = m_layoutXML.level;
			for each(var layout:XML in layoutList)
			{
				//contains the name, and it's at the end to avoid matches like level_name1
				var levelName:String = layout.@id;
				var matchIndex:int = levelName.indexOf(name);
				if(matchIndex != -1 && matchIndex+(name).length == levelName.length)
					return layout;
			}
			
			return null;
		}
	}
}