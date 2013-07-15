package scenes.game.display 
{
	
	public class TutorialManager 
	{
		public static const ERROR_TUTORIAL:String = "error";
		public static const WIDEN_TUTORIAL:String = "widen";
		public static const NARROW_TUTORIAL:String = "narrow";
		public static const COLOR_TUTORIAL:String = "color";
		public static const OPTIMIZE_TUTORIAL:String = "optimize";
		public static const LAYOUT_TUTORIAL:String = "layout";
		public static const END_TUTORIAL:String = "end";
		
		private var m_tutorialTag:String;
		
		public function TutorialManager(_tutorialTag:String) 
		{
			m_tutorialTag = _tutorialTag;
			switch (m_tutorialTag) {
				case ERROR_TUTORIAL:
				case WIDEN_TUTORIAL:
				case NARROW_TUTORIAL:
				case COLOR_TUTORIAL:
				case OPTIMIZE_TUTORIAL:
				case LAYOUT_TUTORIAL:
				case END_TUTORIAL:
					break;
				default:
					throw new Error("Unknown Tutorial encountered: " + m_tutorialTag);
			}
		}
		
		public function getLayoutFixed():Boolean
		{
			switch (m_tutorialTag) {
				case ERROR_TUTORIAL:
				case WIDEN_TUTORIAL:
				case NARROW_TUTORIAL:
				case COLOR_TUTORIAL:
				case OPTIMIZE_TUTORIAL:
					return true;
				default:
					return false;
			}
		}
		
		public function getText():String
		{
			switch (m_tutorialTag) {
				case ERROR_TUTORIAL:
					return "";
				case WIDEN_TUTORIAL:
					return "Click the blue widgets.\n\nWiden the inputs.\n\nFix the errors.";
				case NARROW_TUTORIAL:
					return "Some inputs can't be changed.\n\nNarrow the upper widgets.\n\nFix the errors.";
				case COLOR_TUTORIAL:
					return "Some widgets want to be a certain color.\n\nMatch the widgets to the color squares.\n\nCollect bonus points.";
				case OPTIMIZE_TUTORIAL:
					return "Try different configurations.\n\nOptimize the level.\n\nGet the high score.";
				case LAYOUT_TUTORIAL:
					return "";
				case END_TUTORIAL:
					return "Tutorial Complete.\n\nOptimize your first real level.";
			}
			return "";
		}
	}

}