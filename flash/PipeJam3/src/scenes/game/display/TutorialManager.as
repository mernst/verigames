package scenes.game.display 
{
	import display.NineSliceBatch;
	
	import events.EdgeSetChangeEvent;
	import events.TutorialEvent;
	
	import flash.geom.Point;
	
	import starling.core.Starling;
	import starling.display.DisplayObject;
	import starling.events.EventDispatcher;
	
	public class TutorialManager extends EventDispatcher
	{
		public static const WIDGET_TUTORIAL:String = "widget";
		public static const LOCKED_TUTORIAL:String = "locked";
		public static const LINKS_TUTORIAL:String = "links";
		public static const CLASH_TUTORIAL:String = "clash";
		public static const WIDEN_TUTORIAL:String = "widen";
		public static const PASSAGE_TUTORIAL:String = "passage";
		public static const PINCH_TUTORIAL:String = "pinch";
		public static const OPTIMIZE_TUTORIAL:String = "optimize";
		public static const ZOOM_PAN_TUTORIAL:String = "zoompan";
		public static const LAYOUT_TUTORIAL:String = "layout";
		public static const END_TUTORIAL:String = "end";
		
		public static const NARROW_TUTORIAL:String = "narrow";
		public static const COLOR_TUTORIAL:String = "color";
		
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
					//Starling.juggler.delayCall(function():void { dispatchEvent(new TutorialEvent(TutorialEvent.HIGHLIGHT_BOX, "IntroWidget4", true)); }, 0.2);
					break;
				case LOCKED_TUTORIAL:
					//Starling.juggler.delayCall(function():void { dispatchEvent(new TutorialEvent(TutorialEvent.HIGHLIGHT_BOX, "LockedWidget1", true)); }, 0.2);
					break;
				case LINKS_TUTORIAL:
					//Starling.juggler.delayCall(function():void { dispatchEvent(new TutorialEvent(TutorialEvent.HIGHLIGHT_EDGE, "e1__OUT__", true)); }, 0.2);
					break;
				case PASSAGE_TUTORIAL:
					//Starling.juggler.delayCall(function():void { dispatchEvent(new TutorialEvent(TutorialEvent.HIGHLIGHT_PASSAGE, "e32__IN__", true)); }, 0.2);
					break;
				case PINCH_TUTORIAL:	
					break;
				case CLASH_TUTORIAL:
					//Starling.juggler.delayCall(function():void { dispatchEvent(new TutorialEvent(TutorialEvent.HIGHLIGHT_CLASH, "e2__IN__", true)); }, 0.2);
					break;
				case WIDEN_TUTORIAL:
				case NARROW_TUTORIAL:
				case COLOR_TUTORIAL:
				case OPTIMIZE_TUTORIAL:
				case ZOOM_PAN_TUTORIAL:
				case END_TUTORIAL:
					break;
			}
			m_levelStarted = true;
		}
		
		public function onEdgeSetChange(evt:EdgeSetChangeEvent):void
		{
			if (!m_levelStarted) return;
			// No longer used
		}
		
		public function onGameNodeMoved(updatedGameNodes:Vector.<GameNode>):void
		{
			switch (m_tutorialTag) {
				case LAYOUT_TUTORIAL:
					if (updatedGameNodes.length == 2) {
						const SEPARATED_DIST_SQUARED_CHECK:Number = 25*25;
						var dx:Number = updatedGameNodes[0].x - updatedGameNodes[1].x;
						var dy:Number = updatedGameNodes[0].y - updatedGameNodes[1].y;
						if (dx * dx + dy * dy > SEPARATED_DIST_SQUARED_CHECK) {
							dispatchEvent(new TutorialEvent(TutorialEvent.SHOW_CONTINUE));
						}
					}
					break;
			}
		}
		
		public function getZoomAllowed():Boolean
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
				case LAYOUT_TUTORIAL:
					return false;
				case ZOOM_PAN_TUTORIAL:
				case END_TUTORIAL:
					return true;
			}
			return true;
		}
		
		public function getPanAllowed():Boolean
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
				case LAYOUT_TUTORIAL:
					return false;
				case ZOOM_PAN_TUTORIAL:
				case END_TUTORIAL:
					return true;
			}
			return true;
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
				case LAYOUT_TUTORIAL:
				case ZOOM_PAN_TUTORIAL:
				case END_TUTORIAL:
					return false;
			}
			return false;
		}
		
		public function getAutoZoomAtStart():Boolean
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
				case LAYOUT_TUTORIAL:
				case ZOOM_PAN_TUTORIAL:
				case END_TUTORIAL:
					return false;
			}
			return false;
		}
		
		private function pointToNode(name:String):Function
		{
			return function(currentLevel:Level):DisplayObject { return currentLevel.getNode(name); };
		}
		
		private function pointToEdge(name:String):Function
		{
			return function(currentLevel:Level):DisplayObject { return currentLevel.getEdgeContainer(name); };
		}
		
		private function pointToPassage(name:String):Function
		{
			return function(currentLevel:Level):DisplayObject {
				var edge:GameEdgeContainer = currentLevel.getEdgeContainer(name);
				if (edge && edge.m_innerBoxSegment) {
					return edge.m_innerBoxSegment;
				} else {
					return null;
				}
			};
		}
		
		private function pointToClash(name:String):Function
		{
			return function(currentLevel:Level):DisplayObject {
				var edge:GameEdgeContainer = currentLevel.getEdgeContainer(name);
				if (edge && edge.m_errorParticleSystem) {
					return edge.m_errorParticleSystem;
				} else {
					return null;
				}
			};
		}
		
		public function getTextInfo():TutorialManagerTextInfo
		{
			switch (m_tutorialTag) {
				case WIDGET_TUTORIAL:
					return new TutorialManagerTextInfo(
						"These are widgets. Click the blue widgets to\n" +
						"toggle their shades between dark and light.",
						null,
						pointToNode("IntroWidget2"),
						NineSliceBatch.TOP);
				case LOCKED_TUTORIAL:
					return new TutorialManagerTextInfo(
						"Gray widgets are locked, they cannot be changed.",
						null,
						pointToNode("LockedWidget2"),
						NineSliceBatch.TOP);
				case LINKS_TUTORIAL:
					return new TutorialManagerTextInfo(
						"Widgets are connected by\n" +
						"links. Dark widgets create wide\n" +
						"links, light widgets\n" +
						"create narrow links.",
						null,
						pointToEdge("e1__OUT__"),
						NineSliceBatch.LEFT);
				case PASSAGE_TUTORIAL:
					return new TutorialManagerTextInfo(
						"This is a passage. Links can begin,\n" +
						"end or pass through these passages.\n" +
						"Change the size of the widget to\n" +
						"change the width its passages.",
						null,
						pointToPassage("e32__IN__"),
						NineSliceBatch.TOP_RIGHT);
				case PINCH_TUTORIAL:
					return new TutorialManagerTextInfo(
						"Some passages are gray. These passages are\n" +
						"locked and will not change, even if the widget\n" +
						"is changed.",
						null,
						null,
						null);
				case CLASH_TUTORIAL:
					return new TutorialManagerTextInfo(
						"This is a clash. Clashes happen when\n" +
						"wide links try to enter narrow\n" +
						"passages. Each clash incurs a penalty\n" +
						"of " + Constants.ERROR_POINTS.toString() + " points.",
						null,
						pointToClash("e2__IN__"),
						NineSliceBatch.TOP_RIGHT);
				case WIDEN_TUTORIAL:
					return new TutorialManagerTextInfo(
						"Click the blue widgets to widen their passages\n" +
						"and fix the clashes.",
						null,
						null,
						null);
				case NARROW_TUTORIAL:
					return new TutorialManagerTextInfo(
						"Click the upper widgets to narrow their links\n" +
						"and fix the clashes.",
						null,
						null,
						null);
				case COLOR_TUTORIAL:
					return new TutorialManagerTextInfo(
						"Some widgets want to be a certain color. Match\n" +
						"the widgets to the color squares to collect\n" +
						"bonus points.",
						null,
						null,
						null);
				case OPTIMIZE_TUTORIAL:
					return new TutorialManagerTextInfo(
						"Try different configurations to improve your score!",
						null,
						null,
						null);
				case LAYOUT_TUTORIAL:
					return new TutorialManagerTextInfo(
						"Drag the widgets and links around to help organize\n" +
						"the layout. Separate the widgets to continue.",
						null,
						null,
						null);
				case ZOOM_PAN_TUTORIAL:
					return new TutorialManagerTextInfo(
						"Larger levels require navigation. Drag the background\n" +
						"to move around the level. Use the +/- keys to\n" +
						"zoom in and out.",
						null,
						null,
						null);
				case END_TUTORIAL:
					return new TutorialManagerTextInfo(
						"Optimize your first real level!",
						null,
						null,
						null);
			}
			return null;
		}
	}
}
