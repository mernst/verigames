package scenes.game.display
{
	import flash.ui.Keyboard;
	import flash.utils.Dictionary;
	import starling.events.Event;
	import starling.events.KeyboardEvent;
	
	import audio.AudioManager;
	import cgs.server.logging.actions.ClientAction;
	import events.WidgetChangeEvent;
	import server.ReplayController;
	import system.VerigameServerConstants;
	import utils.XString;
	
	// TODO: reconfigure for json
	public class ReplayWorld extends World
	{
		
		public function ReplayWorld(_worldGraphDict:Dictionary, _worldObj:Object, _layout:Object, _assignments:Object)
		{
			super(_worldGraphDict, _worldObj, _layout, _assignments);
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
			var varId:String, propChanged:String, newPropValue:Boolean;
			if (action.detailObject[VerigameServerConstants.ACTION_PARAMETER_VAR_ID]) {
				varId = action.detailObject[VerigameServerConstants.ACTION_PARAMETER_VAR_ID] as String;
			}
			if (action.detailObject[VerigameServerConstants.ACTION_PARAMETER_PROP_CHANGED]) {
				propChanged = action.detailObject[VerigameServerConstants.ACTION_PARAMETER_PROP_CHANGED] as String;
			}
			if (action.detailObject[VerigameServerConstants.ACTION_PARAMETER_PROP_VALUE]) {
				newPropValue = XString.stringToBool(action.detailObject[VerigameServerConstants.ACTION_PARAMETER_PROP_VALUE] as String);
			}
			if (varId && propChanged) {
				var gameNode:GameNode = active_level.getNode(varId);
				if (!gameNode) {
					PipeJam3.showReplayText("Replay action failed: Game node not found: " + varId);
					return;
				}
				var eventToPerform:WidgetChangeEvent = new WidgetChangeEvent(WidgetChangeEvent.WIDGET_CHANGED, gameNode, propChanged, newPropValue);
				gameNode.handleUndoEvent(eventToPerform, isUndo);
				PipeJam3.showReplayText("performed: " + varId + " " + propChanged + " -> " + newPropValue + (isUndo ? " (undo)" : ""));
			} else {
				PipeJam3.showReplayText("Replay action failed, varId: " + varId + " propChanged: " + propChanged);
			}
		}
		
		public function previewAction(action:ClientAction, isUndo:Boolean = false):void
		{
			if (!action.detailObject) return;
			if (!active_level) return;
			if (!edgeSetGraphViewPanel) return;
			var edgeSetId:String, propChanged:String, newPropValue:Boolean;
			if (action.detailObject[VerigameServerConstants.ACTION_PARAMETER_VAR_ID]) {
				edgeSetId = action.detailObject[VerigameServerConstants.ACTION_PARAMETER_VAR_ID] as String;
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
				PipeJam3.showReplayText("Preview: " + edgeSetId + " " + propChanged + " -> " + newPropValue + (isUndo ? " (undo)" : ""));
			} else {
				PipeJam3.showReplayText("Replay action preview failed, edgeSetId: " + edgeSetId + " propChanged: " + propChanged);
			}
		}
	}
}