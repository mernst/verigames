package scenes.game.display 
{
	import events.EdgeSetChangeEvent;
	import events.TutorialEvent;
	import starling.core.Starling;
	import starling.events.EventDispatcher;
	
	public class TutorialManager extends EventDispatcher
	{
		public static const WIDGET_TUTORIAL:String = "widget";
		public static const LOCKED_TUTORIAL:String = "locked";
		public static const LINKS_TUTORIAL:String = "links";
		public static const PASSAGE_TUTORIAL:String = "passage";
		public static const PINCH_TUTORIAL:String = "pinch";
		public static const CLASH_TUTORIAL:String = "clash";
		public static const WIDEN_TUTORIAL:String = "widen";
		public static const NARROW_TUTORIAL:String = "narrow";
		public static const COLOR_TUTORIAL:String = "color";
		public static const OPTIMIZE_TUTORIAL:String = "optimize";
		public static const LAYOUT_TUTORIAL:String = "layout";
		public static const ZOOM_PAN_TUTORIAL:String = "zoompan";
		public static const END_TUTORIAL:String = "end";
		
		private var m_tutorialTag:String;
		private var m_levelStarted:Boolean = false;
		
		public function TutorialManager(_tutorialTag:String)
		{
			m_tutorialTag = _tutorialTag;
			switch (m_tutorialTag) {
				case WIDGET_TUTORIAL:
				case LOCKED_TUTORIAL:
				case LINKS_TUTORIAL:
				case PASSAGE_TUTORIAL:
				case PINCH_TUTORIAL:
				case CLASH_TUTORIAL:
				case WIDEN_TUTORIAL:
				case NARROW_TUTORIAL:
				case COLOR_TUTORIAL:
				case OPTIMIZE_TUTORIAL:
				case LAYOUT_TUTORIAL:
				case ZOOM_PAN_TUTORIAL:
				case END_TUTORIAL:
					break;
				default:
					throw new Error("Unknown Tutorial encountered: " + m_tutorialTag);
			}
		}
		
		public function startLevel():void
		{
			switch (m_tutorialTag) {
				case WIDGET_TUTORIAL:
					Starling.juggler.delayCall(function():void { dispatchEvent(new TutorialEvent(TutorialEvent.HIGHLIGHT_BOX, "IntroWidget4", true)); }, 0.2);
					break;
				case LOCKED_TUTORIAL:
					Starling.juggler.delayCall(function():void { dispatchEvent(new TutorialEvent(TutorialEvent.HIGHLIGHT_BOX, "LockedWidget1", true)); }, 0.2);
					Starling.juggler.delayCall(function():void { dispatchEvent(new TutorialEvent(TutorialEvent.SHOW_CONTINUE)); }, 3.0);
					break;
				case LINKS_TUTORIAL:
					Starling.juggler.delayCall(function():void { dispatchEvent(new TutorialEvent(TutorialEvent.HIGHLIGHT_EDGE, "e1__OUT__", true)); }, 0.2);
					Starling.juggler.delayCall(function():void { dispatchEvent(new TutorialEvent(TutorialEvent.SHOW_CONTINUE)); }, 3.0);
					break;
				case PASSAGE_TUTORIAL:
					Starling.juggler.delayCall(function():void { dispatchEvent(new TutorialEvent(TutorialEvent.HIGHLIGHT_PASSAGE, "Links3", true)); }, 0.2);
					break;
				case PINCH_TUTORIAL:	
					break;
				case CLASH_TUTORIAL:
					
					break;
				case WIDEN_TUTORIAL:
				case NARROW_TUTORIAL:
				case COLOR_TUTORIAL:
				case OPTIMIZE_TUTORIAL:
				case LAYOUT_TUTORIAL:
				case ZOOM_PAN_TUTORIAL:
				case END_TUTORIAL:
					break;
			}
			m_levelStarted = true;
		}
		
		public function onEdgeSetChange(evt:EdgeSetChangeEvent):void
		{
			if (!m_levelStarted) return;
			switch (m_tutorialTag) {
				case WIDGET_TUTORIAL:
				case LINKS_TUTORIAL:
					dispatchEvent(new TutorialEvent(TutorialEvent.HIGHLIGHT_BOX, "", false));
					// Allow user to continue after they click a box
					dispatchEvent(new TutorialEvent(TutorialEvent.SHOW_CONTINUE));
					break;
				case PASSAGE_TUTORIAL:
					if (evt.edgeSetChanged.m_id == "Links3") {
						dispatchEvent(new TutorialEvent(TutorialEvent.HIGHLIGHT_BOX, "", false));
						// Allow user to continue after they click a box
						dispatchEvent(new TutorialEvent(TutorialEvent.SHOW_CONTINUE));
					}
					break;
			}
		}
		
		public function getLayoutFixed():Boolean
		{
			switch (m_tutorialTag) {
				case WIDGET_TUTORIAL:
				case LOCKED_TUTORIAL:
				case LINKS_TUTORIAL:
				case PASSAGE_TUTORIAL:
				case PINCH_TUTORIAL:
				case CLASH_TUTORIAL:
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
				case WIDGET_TUTORIAL:
					return "These are widgets. Click the blue widgets to\n\ntoggle their shades between dark and light.";
				case LOCKED_TUTORIAL:
					return "Gray widgets are locked, they cannot be changed.";
				case LINKS_TUTORIAL:
					return "Widgets are connected by links. Dark widgets\n\ncreate wide links, light widgets create narrow links.";
				case PASSAGE_TUTORIAL:
					return "This is a passage. Links can begin, end or pass\n\nthrough widgets through these passages. Changing the size of\n\nthe widget can change the width of the passage.";
				case PINCH_TUTORIAL:
					return "Some passages are gray. These passages are\n\nlocked and will not change, even if the widget\n\nis changed.";
				case CLASH_TUTORIAL:
					return "This is a clash. Clashes happen when wide links\n\ntry to enter narrow passages. Each clash incurs\n\na penalty of -75 points.";
				case WIDEN_TUTORIAL:
					return "Click the blue widgets to widen their passages\n\nand fix the clashes.";
				case NARROW_TUTORIAL:
					return "Click the upper widgets to narrow their links\n\nand fix the clashes.";
				case COLOR_TUTORIAL:
					return "Some widgets want to be a certain color. Match\n\nthe widgets to the color squares to collect bonus\n\npoints.";// Remember, clashes are worth -75 points.";
				case OPTIMIZE_TUTORIAL:
					return "Try different configurations. Optimize the level.\n\nGet the high score.";
				case LAYOUT_TUTORIAL:
					return "Drag the widgets and links around to help\n\norganize the layout. Separate the widgets to continue.";
				case ZOOM_PAN_TUTORIAL:
					return "Larger levels require navigation. Drag the\n\nbackground to move around the level. Use the +/- keys\n\nto zoom in and out.";
				case END_TUTORIAL:
					return "Tutorial Complete. Optimize your first real level.";
			}
			return "";
		}
	}

}