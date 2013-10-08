package scenes.game.display
{
	import audio.AudioManager;
	import cgs.server.logging.actions.ClientAction;
	import display.TextBubble;
	import events.EdgeSetChangeEvent;
	import events.UndoEvent;
	import graph.PropDictionary;
	import server.ReplayController;
	import starling.events.Event;
	
	import flash.ui.Keyboard;
	
	import graph.Network;
	
	import starling.events.KeyboardEvent;
	
	import system.VerigameServerConstants;
	
	import utils.XString;
	
	public class ReplayWorld extends World
	{
		
		public function ReplayWorld(_network:Network, _world_xml:XML, _layout:XML, _constraints:XML)
		{
			super(_network, _world_xml, _layout, _constraints);
			//this.touchable = false;// disable user interaction
		}
		
		override protected function onAddedToStage(event:Event):void
		{
			super.onAddedToStage(event);
			AudioManager.getInstance().reset(); // no replay music
		}
		
		override protected function selectLevel(newLevel:Level, restart:Boolean = false):void
		{
			super.selectLevel(newLevel, restart);
			PipeJam3.showReplayText("Replaying Level: " + active_level.original_level_name);
		}
		
		override public function handleKeyUp(event:KeyboardEvent):void
		{
			switch (event.keyCode) {
				case Keyboard.LEFT:
				case Keyboard.A:
				case Keyboard.NUMPAD_4:
					ReplayController.getInstance().backup(this);
					break;
				case Keyboard.RIGHT:
				case Keyboard.D:
				case Keyboard.NUMPAD_6:
					ReplayController.getInstance().advance(this);
					break;
			}
		}
		
		public function performAction(action:ClientAction, isUndo:Boolean = false):void
		{
			if (!action.detailObject) return;
			if (!active_level) return;
			var edgeSetId:String, propChanged:String, newPropValue:Boolean;
			if (action.detailObject[VerigameServerConstants.ACTION_PARAMETER_EDGESET_ID]) {
				edgeSetId = action.detailObject[VerigameServerConstants.ACTION_PARAMETER_EDGESET_ID] as String;
			}
			if (action.detailObject[VerigameServerConstants.ACTION_PARAMETER_PROP_CHANGED]) {
				propChanged = action.detailObject[VerigameServerConstants.ACTION_PARAMETER_PROP_CHANGED] as String;
			}
			if (action.detailObject[VerigameServerConstants.ACTION_PARAMETER_PROP_VALUE]) {
				newPropValue = XString.stringToBool(action.detailObject[VerigameServerConstants.ACTION_PARAMETER_PROP_VALUE] as String);
			}
			if (edgeSetId && propChanged) {
				var gameNode:GameNode = active_level.getNode(edgeSetId);
				if (!gameNode) {
					PipeJam3.showReplayText("Replay action failed: Game node not found: " + edgeSetId);
					return;
				}
				var eventToPerform:EdgeSetChangeEvent = new EdgeSetChangeEvent(EdgeSetChangeEvent.EDGE_SET_CHANGED, gameNode, propChanged, newPropValue);
				gameNode.handleUndoEvent(eventToPerform, isUndo);
				PipeJam3.showReplayText("performed: " + edgeSetId + " " + propChanged + " -> " + newPropValue + (isUndo ? " (undo)" : ""));
			} else {
				PipeJam3.showReplayText("Replay action failed, edgeSetId: " + edgeSetId + " propChanged: " + propChanged);
			}
		}
		
		public function previewAction(action:ClientAction, isUndo:Boolean = false):void
		{
			if (!action.detailObject) return;
			if (!active_level) return;
			if (!edgeSetGraphViewPanel) return;
			var edgeSetId:String, propChanged:String, newPropValue:Boolean;
			if (action.detailObject[VerigameServerConstants.ACTION_PARAMETER_EDGESET_ID]) {
				edgeSetId = action.detailObject[VerigameServerConstants.ACTION_PARAMETER_EDGESET_ID] as String;
			}
			if (action.detailObject[VerigameServerConstants.ACTION_PARAMETER_PROP_CHANGED]) {
				propChanged = action.detailObject[VerigameServerConstants.ACTION_PARAMETER_PROP_CHANGED] as String;
			}
			if (action.detailObject[VerigameServerConstants.ACTION_PARAMETER_PROP_VALUE]) {
				newPropValue = XString.stringToBool(action.detailObject[VerigameServerConstants.ACTION_PARAMETER_PROP_VALUE] as String);
			}
			if (edgeSetId && propChanged) {
				var gameNode:GameNode = active_level.getNode(edgeSetId);
				if (!gameNode) {
					PipeJam3.showReplayText("Replay action preview failed: Game node not found: " + edgeSetId);
					return;
				}
				edgeSetGraphViewPanel.centerOnComponent(gameNode);
				PipeJam3.showReplayText("Preview: " + edgeSetId + " " + propChanged + " -> " + newPropValue + (isUndo ? " (undo)" : "")));
			} else {
				PipeJam3.showReplayText("Replay action preview failed, edgeSetId: " + edgeSetId + " propChanged: " + propChanged);
			}
		}
	}
}