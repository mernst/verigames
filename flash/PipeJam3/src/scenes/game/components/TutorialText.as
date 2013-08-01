package scenes.game.components
{
	import display.TextBubble;
	import scenes.game.display.Level;
	import scenes.game.display.TutorialManagerTextInfo;
	import starling.display.DisplayObject;
	import starling.display.Sprite;
	
	public class TutorialText extends TextBubble
	{
		private static const TUTORIAL_FONT_SIZE:Number = 10;
		private static const ARROW_SZ:Number = 10;
		private static const ARROW_BOUNCE:Number = 2;
		private static const ARROW_BOUNCE_SPEED:Number = 0.5;
		private static const INSET:Number = 3;
		private static const PADDING_SZ:Number = ARROW_SZ + 2 * ARROW_BOUNCE + 4 * INSET;
		
		public function TutorialText(level:Level, info:TutorialManagerTextInfo)
		{
			
			// get pointing setup
			var pointAt:DisplayObject = (info.pointAtFn != null) ? info.pointAtFn(level) : null;
			
			var pointPosAlwaysUpdate:Boolean = true;
			if (level.tutorialManager && !level.tutorialManager.getPanZoomAllowed() && level.tutorialManager.getLayoutFixed()) {
				pointPosAlwaysUpdate = false;
			}
			
			super(info.text, TUTORIAL_FONT_SIZE, 0xEEEEEE, pointAt, info.pointFrom, info.pointTo, info.size, pointPosAlwaysUpdate, ARROW_SZ, ARROW_BOUNCE, ARROW_BOUNCE_SPEED, INSET);
		}
	}
}
