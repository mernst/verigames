package scenes.game.display
{
	import cgs.server.logging.actions.ClientAction;
	
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
		
		public function performAction(action:ClientAction):void
		{
			if (!action.detailObject) return;
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
				trace("perform: " + edgeSetId + " " + propChanged + " -> " + newPropValue);
				// TODO: perform onEdgeSetChange
			}
		}
		
		public function previewAction(action:ClientAction):void
		{
			if (!action.detailObject) return;
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
				trace("preview: " + edgeSetId + " " + propChanged + " -> " + newPropValue);
				// TODO: center on component
			}
		}
	}
}