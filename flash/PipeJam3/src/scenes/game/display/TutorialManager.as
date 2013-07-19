package scenes.game.display 
{
	import display.NineSliceBatch;
	import starling.events.Event;
	
	import events.EdgeSetChangeEvent;
	import events.TutorialEvent;
	
	import flash.geom.Point;
	
	import starling.core.Starling;
	import starling.display.DisplayObject;
	import starling.events.EventDispatcher;
	
	public class TutorialManager extends EventDispatcher
	{
		// This is the order the tutorials appers in:
		public static const WIDGET_TUTORIAL:String = "widget";
		public static const LOCKED_TUTORIAL:String = "locked";
		public static const LINKS_TUTORIAL:String = "links";
		public static const CLASH_TUTORIAL:String = "clash";
		public static const WIDEN_TUTORIAL:String = "widen";
		public static const PASSAGE_TUTORIAL:String = "passage";
		public static const PINCH_TUTORIAL:String = "pinch";
		public static const SPLIT_TUTORIAL:String = "split";
		public static const MERGE_TUTORIAL:String = "merge";
		public static const OPTIMIZE_TUTORIAL:String = "optimize";
		public static const ZOOM_PAN_TUTORIAL:String = "zoompan";
		public static const LAYOUT_TUTORIAL:String = "layout";
		public static const SKILLS_A_TUTORIAL:String = "skillsa";
		public static const SKILLS_B_TUTORIAL:String = "skillsb";
		// Not currently used:
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
				case SPLIT_TUTORIAL:
				case MERGE_TUTORIAL:
				case OPTIMIZE_TUTORIAL:
				case LAYOUT_TUTORIAL:
				case ZOOM_PAN_TUTORIAL:
				case SKILLS_A_TUTORIAL:
				case SKILLS_B_TUTORIAL:
				case END_TUTORIAL:
					break;
				default:
					throw new Error("Unknown Tutorial encountered: " + m_tutorialTag);
			}
		}
		
		override public function dispatchEvent(event:Event):void
        {
			// Don't allow events to dispatch if stopped playing level
			if (m_levelStarted) super.dispatchEvent(event);
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
				case SPLIT_TUTORIAL:
				case MERGE_TUTORIAL:
				case OPTIMIZE_TUTORIAL:
				case ZOOM_PAN_TUTORIAL:
				case END_TUTORIAL:
					break;
			}
			m_levelStarted = true;
		}
		
		public function endLevel():void
		{
			m_levelStarted = false;
		}
		
		public function onEdgeSetChange(evt:EdgeSetChangeEvent):void
		{
			if (!m_levelStarted) return;
			// No longer used
		}
		
		public function onGameNodeMoved(updatedGameNodes:Vector.<GameNode>):void
		{
			// No longer used
			/*
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
			*/
		}
		
		public function getPanZoomAllowed():Boolean
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
				case SPLIT_TUTORIAL:
				case MERGE_TUTORIAL:
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
				case SPLIT_TUTORIAL:
				case MERGE_TUTORIAL:
				case OPTIMIZE_TUTORIAL:
				case ZOOM_PAN_TUTORIAL:
					return true;
				case LAYOUT_TUTORIAL:
				case END_TUTORIAL:
					return false;
			}
			return false;
		}
		
		public function getStartScaleFactor():Number
		{
			switch (m_tutorialTag) {
				case WIDGET_TUTORIAL:
				case LOCKED_TUTORIAL:
					return 0.8;
				case ZOOM_PAN_TUTORIAL:
					return 3.0;
				case LAYOUT_TUTORIAL:
					return 0.5;
				case PASSAGE_TUTORIAL:
					return 1.2;
				case LINKS_TUTORIAL:
				case CLASH_TUTORIAL:
				case PINCH_TUTORIAL:
				case WIDEN_TUTORIAL:
				case NARROW_TUTORIAL:
				case COLOR_TUTORIAL:
				case SPLIT_TUTORIAL:
				case MERGE_TUTORIAL:
				case OPTIMIZE_TUTORIAL:
				case END_TUTORIAL:
					return 1.0;
			}
			return 1.0;
		}
		
		public function getStartPanOffset():Point
		{
			switch (m_tutorialTag) {
				case WIDGET_TUTORIAL:
				case LOCKED_TUTORIAL:
				case WIDEN_TUTORIAL:
				case LAYOUT_TUTORIAL:
					return new Point(0, 5);// move down by 5px (pan up)
				case LINKS_TUTORIAL:
				case PASSAGE_TUTORIAL:
					return new Point(15, 0);//move right 15px (pan left)
				case PINCH_TUTORIAL:
					return new Point(0, -15);// move up by 15px
				case MERGE_TUTORIAL:
					return new Point(-15, 0);//move left 15px
				case ZOOM_PAN_TUTORIAL:
					return new Point(40, -10);// move right 40px, up by 10px
				case CLASH_TUTORIAL:
				case NARROW_TUTORIAL:
				case COLOR_TUTORIAL:
				case SPLIT_TUTORIAL:
				case OPTIMIZE_TUTORIAL:
				case END_TUTORIAL:
					return new Point();
			}
			return new Point();
		}
		
		private function pointToNode(name:String):Function
		{
			return function(currentLevel:Level):DisplayObject { return currentLevel.getNode(name); };
		}
		
		private function pointToJoint(name:String):Function
		{
			return function(currentLevel:Level):DisplayObject { return currentLevel.getJoint(name); };
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
						"These are WIDGETS.\n" +
						"Click on widgets to change their color.\n" +
						"Make them a solid color to get points!",
						null,
						pointToNode("IntroWidget2"),
						NineSliceBatch.TOP, null);
				case LOCKED_TUTORIAL:
					return new TutorialManagerTextInfo(
						"Gray widgets are locked.\n" +
						"Their colors can't be changed.",
						null,
						pointToNode("LockedWidget2"),
						NineSliceBatch.TOP, null);
				case LINKS_TUTORIAL:
					return new TutorialManagerTextInfo(
						"Widgets are connected\n" +
						"by LINKS. Dark widgets\n" +
						"create wide links, light\n" +
						"widgets create narrow\n" +
						"links.",
						null,
						pointToEdge("e1__OUT__"),
						NineSliceBatch.LEFT, null);
				case CLASH_TUTORIAL:
					return new TutorialManagerTextInfo(
						"This is a CLASH. Clashes happen when\n" +
						"wide links try to enter narrow\n" +
						"passages. Each clash penalizes your\n" +
						"score by " + Constants.ERROR_POINTS.toString() + " points.",
						null,
						pointToClash("e2__IN__"),
						NineSliceBatch.TOP_RIGHT, NineSliceBatch.TOP);
				case WIDEN_TUTORIAL:
					return new TutorialManagerTextInfo(
						"Click the widgets to widen their passages\n" +
						"and fix the clashes.",
						null,
						null,
						null, null);
				case PASSAGE_TUTORIAL:
					return new TutorialManagerTextInfo(
						"This is a PASSAGE. Links can begin\n" +
						"in, end in or go through passages.\n" +
						"Change the color of the widget to\n" +
						"change the width of its passages.",
						null,
						pointToPassage("e32__IN__"),
						NineSliceBatch.LEFT, NineSliceBatch.BOTTOM_LEFT);
				case PINCH_TUTORIAL:
					return new TutorialManagerTextInfo(
						"Some passages are gray. These passages\n" +
						"won't change width even if their widget\n" +
						"is changed.",
						null,
						pointToPassage("e20__IN__"),
						NineSliceBatch.BOTTOM_LEFT, NineSliceBatch.LEFT);
				case SPLIT_TUTORIAL:
					return new TutorialManagerTextInfo(
						"This is a SPLIT. When a link is split\n" +
						"the outgoing links will match the\n" +
						"incoming link.",
						null,
						pointToJoint("n10__IN__0"),
						NineSliceBatch.TOP_RIGHT, null);
				case MERGE_TUTORIAL:
					return new TutorialManagerTextInfo(
						"This is a MERGE. When two links merge\n" +
						"the outgoing link will be wide if\n" +
						"either incoming link is wide.",
						null,
						pointToJoint("n123"),
						NineSliceBatch.RIGHT, null);
				case OPTIMIZE_TUTORIAL:
					return new TutorialManagerTextInfo(
						"Try different configurations to improve your score!",
						null,
						null,
						null, null);
				case ZOOM_PAN_TUTORIAL:
					return new TutorialManagerTextInfo(
						"Larger levels require navigation. Drag the background\n" +
						"to move around the level. Use the +/- keys to\n" +
						"zoom in and out.",
						null,
						null,
						null, null);
				case LAYOUT_TUTORIAL:
					return new TutorialManagerTextInfo(
						"Widgets and links can be dragged to help organize\n" +
						"the layout. Separate the widgets.",
						null,
						pointToNode("Layout1"),
						null, null);
				case SKILLS_A_TUTORIAL:
					return new TutorialManagerTextInfo(
						"Use the skills you've learned to solve a bigger challenge!",
						null,
						null,
						null, null);
				case SKILLS_B_TUTORIAL:
					return new TutorialManagerTextInfo(
						"Good work! Now try this one!",
						null,
						null,
						null, null);
				// The following are not currently in use:
				case END_TUTORIAL:
					return new TutorialManagerTextInfo(
						"Optimize your first real level!",
						null,
						null,
						null, null);
				case NARROW_TUTORIAL:
					return new TutorialManagerTextInfo(
						"Click the upper widgets to narrow their links\n" +
						"and fix the clashes.",
						null,
						null,
						null, null);
				case COLOR_TUTORIAL:
					return new TutorialManagerTextInfo(
						"Some widgets want to be a certain color. Match\n" +
						"the widgets to the color squares to collect\n" +
						"bonus points.",
						null,
						null,
						null, null);
			}
			return null;
		}
	}
}
