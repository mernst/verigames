package server
{
	public class ReplayController
	{
		
	}
}

/*	import cgs.server.logging.actions.ClientAction;
	import cgs.server.logging.CGSServer;
	import cgs.server.logging.CGSServerProps;
	import cgs.server.logging.GameServerData;
	import cgs.server.logging.data.QuestData;		
	import flash.display.Sprite;
		
	public class ReplayController extends Sprite
	{	
		private static const SKEY:String = ""; // TODO: fill in
		private static const GAME_NAME:String = "PipeJam"; // TODO: fill in
		private static const GAME_ID:int = 1234; // TODO: fill in
		private static const VERSION:int = 1; // TODO: fill in whatever the current version of the game is, replays probably won't work for older versions being loaded from server
		private static const CATEGORY:int = 1; // this actually doesn't matter for replays, it will grab the data regardless
		private static const CGS_SERVER_TAG:String = CGSServerProps.PRODUCTION_SERVER; //or CGSServerProps.DEVELOPMENT_SERVER
		
		private var m_replayActionObjects:Vector.<ClientAction>;
		private var m_replayActionIndex:int = -1;
		
		public function ReplayController(new_dqid:String = null)
		{
			var dqidToReplay:String;
			if (root && root.loaderInfo && root.loaderInfo.parameters["dqid"])
			{
				dqidToReplay = root.loaderInfo.parameters["dqid"];
			} else {
				dqidToReplay = new_dqid;
			}
			trace ("dqid = " + dqidToReplay);
			loadReplay(dqidToReplay);
		}
		
		private function loadReplay(dqid:String):void {
			var props:CGSServerProps = new CGSServerProps(
				SKEY,
				GameServerData.NO_SKEY_HASH,
				GAME_NAME,
				GAME_ID,
				VERSION,
				CATEGORY,
				CGS_SERVER_TAG
			);
			CGSServer.instance.setup(props);
			CGSServer.instance.requestQuestData(dqid, onLoadQuestData);
		}
		
//		private function onLoadQuestData(questData:QuestData, failed:Boolean):void
//		{
//			if (failed) {
//				trace("Quest data not loaded.");
//				return;
//			}
//			
//			if (questData == null) {
//				trace("Quest data empty.");
//				return;
//			}
//			
//			if (questData.startData == null) {
//				trace("Quest startData empty.");
//				return;
//			}
//			
//			if (questData.actions == null || questData.actions.length == 0) {
//				trace("No actions for this quest.");
//				return;
//			}
//			
//			if (VERSION != questData.versionId) {
//				trace("Version mismatch: expected " + VERSION + " got " + questData.versionId);
//				return;
//			}
//			
//			m_replayActionObjects = Vector.<ClientAction>(questData.actions.concat());
//			// TODO: make sure these are sorted by qaction_seqid if possible
//			
//			
//			var timeline:ReplayTimeline = new ReplayTimeline(m_replayActionObjects, skipAction, stepToIndex, 600, 300);
//			addChild(timeline);
//		}
		
		private function skipAction(obj:Object):Boolean
		{
			// TODO: If any actions can be skipped in replay, define the logic here and return true
			return false;
		}
		
		private function stepToIndex(index:int):void
		{
			index = clampInt(index, -1, m_replayActionObjects.length - 1);
			
			if (index == m_replayActionIndex) {
				return;
			}
			
			// For previous actions, replay all from beginning (TODO: may need to reset the level first)
			if (index < m_replayActionIndex) {
				m_replayActionIndex = -1;
			}
			
			// Replay all actions from the current action to the index = action to be replayed up to
			while (index > m_replayActionIndex) {
				++ m_replayActionIndex;
				
				var obj:ClientAction = m_replayActionObjects[m_replayActionIndex];
				// TODO: replay this ClientAction
			}
		}
		
		
		
		public static function clampInt(x:int, lo:int, hi:int):int
		{
			return (x < lo ? lo : (x > hi ? hi : x));
		}

/*		public function replayAction(obj:ClientAction):void
{
if(obj.actionId == VerigameServerConstants.VERIGAME_ACTION_START)
{
openReplayPanel(obj);
}
else if(obj.actionId == VerigameServerConstants.VERIGAME_ACTION_SWITCH_BOARDS)
{
var boardName:String = obj.actionObject.detail[VerigameServerConstants.ACTION_PARAMETER_BOARD_NAME];
var levelName:String = obj.actionObject.detail[VerigameServerConstants.ACTION_PARAMETER_LEVEL_NAME];
var displayedBoardName:String = replayNetwork.obfuscator.getBoardName(boardName, levelName);
var displayedLevelName:String = replayNetwork.obfuscator.getLevelName(levelName);
for each(var level:Level in replay_game_panel.replayWorld.levels)
{
if(level.level_name == displayedLevelName)
for each(var board:Board in level.boards)
{
if(board.board_name == displayedBoardName)
{
replay_game_panel.update(board, false);
return;
}
}
}

}
else if(obj.actionId == VerigameServerConstants.VERIGAME_ACTION_CHANGE_PIPE_WIDTH)
{
var edgeID:String = obj.actionObject.detail[VerigameServerConstants.ACTION_PARAMETER_PIPE_EDGE_ID];
for each(var pipe:Pipe in replay_game_panel.m_currentBoard.pipes)
{
if(pipe.associated_edge.edge_id == edgeID)
{
pipe.pipeClick(null, false);
return;
}
}
}
else if(obj.actionId == VerigameServerConstants.VERIGAME_ACTION_ADD_PIPE_BUZZSAW)
{
var edgeID1:String = obj.actionObject.detail[VerigameServerConstants.ACTION_PARAMETER_PIPE_EDGE_ID];
for each(var pipe1:Pipe in replay_game_panel.m_currentBoard.pipes)
{
if(pipe1.associated_edge.edge_id == edgeID1)
{
buzzing = true;
pipe1.pipeClick(null, false);
buzzing = false;
draw();
return;
} 
}
}
}

protected var replayXML:XML;
protected var replayNetwork:Network;
//		public function openReplayPanel(obj:ClientAction):void
//		{
//			if(obj.actionId == VerigameServerConstants.VERIGAME_ACTION_START)
//			{
//				var startInfo:Object = obj.actionObject.detail[VerigameServerConstants.ACTION_PARAMETER_START_INFO];
//				var worldXML:String = startInfo["world_xml_url"];
//				replayXML = new XML(worldXML);
//				var nextParseState:ParseReplayState = new ParseReplayState(replayXML, this);
//				nextParseState.stateLoad();
//				replayNetwork = nextParseState.world_nodes;
//			}
//		}

public function loadReplay(world_nodes:Network):void
{
	if(replay_game_panel == null)
	{
		//				replay_game_panel = new PipeViewPanel(50, 50, width - 100, height - 100, this);
		//				replay_game_panel.init();
		//				replay_game_panel.next_button.visible = false;
		//				replay_game_panel.exit_button.removeEventListener(TouchEvent.CLICK, onBackToMainMenuButtonClick);
		//				replay_game_panel.exit_button.addEventListener(TouchEvent.CLICK, closeReplayPanel);
		//				replay_game_panel.exit_button.y = replay_game_panel.height - 75;
		//				replay_game_panel.exit_button.x = replay_game_panel.width - 100;
	}
	else
		replay_game_panel.visible = true;
	
	if(replayGameOverlay == null)
	{
		//				var contentRect:Sprite = replay_game_panel.getContentRectangle();
		//				replayGameOverlay = new Sprite(contentRect.x, contentRect.y, contentRect.width, contentRect.height);
		//				replayGameOverlay.graphics.beginFill(0x000000, 0.0);
		//				replayGameOverlay.graphics.drawRect(0,0,replayGameOverlay.width, replayGameOverlay.height);
		//				replayGameOverlay.graphics.endFill();
	}
	
	//			if(replayTimeline == null)
	//			{
	//				replayTimeline = localServer.replayActions(replay_game_panel);
	//				replay_game_panel.addChild(replayTimeline);
	//			}
	
	var world:World = new World(0, 0, GAME_WIDTH, GAME_HEIGHT, world_nodes.world_name, this, replayXML);
	//			world.createWorld(world_nodes.worldNodesDictionary, replay_game_panel.getContentRectangle());
	//			replay_game_panel.replayWorld = world;
	//			replay_game_panel.graphics.beginFill(0x111111);
	//			replay_game_panel.graphics.drawRect(0,0,replay_game_panel.width, replay_game_panel.height);
	//			replay_game_panel.graphics.endFill();
	//			
	//			var boards_to_update:Vector.<BoardNodes> = world.simulateAllLevels();
	//			world.simulatorUpdateTroublePointsFS(PipeJamController.mainController.simulator, boards_to_update);
	//			replay_game_panel.update(world.levels[0].boards[0], false);
	//			replay_game_panel.m_currentBoard.title = null;
	//			replay_game_panel.addChild(replayGameOverlay);			
	//			addChild(replay_game_panel);
}

protected function closeReplayPanel(event:TouchEvent):void
{
	replay_game_panel.visible = false;
}
		
	}
}*/