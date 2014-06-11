package scenes.game.components
{
	import starling.events.Event;
	
	public class GameControlPanel2 extends GameControlPanel
	{
		public function GameControlPanel2()
		{
			super();
		}
		
		override public function addedToStage(event:Event):void
		{
			super.addedToStage(event);
			y += 100;
		}
	}
}