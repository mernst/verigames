package scenes.game.display 
{
	import display.NineSliceBatch;
	import events.EdgeContainerEvent;
	import events.TutorialEvent;
	import starling.core.Starling;
	
	import events.EdgeSetChangeEvent;
	
	import flash.geom.Point;
	
	import starling.display.DisplayObject;
	import starling.events.Event;
	import starling.events.EventDispatcher;
	
	public class TutorialManager extends EventDispatcher
	{
		// This is the order the tutorials appers in:
		public static const WIDGET_TUTORIAL:String = "widget";
		public static const WIDGET_PRACTICE_TUTORIAL:String = "widgetpractice";
		public static const LOCKED_TUTORIAL:String = "locked";
		public static const LINKS_TUTORIAL:String = "links";
		public static const PASSAGE_TUTORIAL:String = "passage";
		public static const CLASH_TUTORIAL:String = "clash";
		public static const WIDEN_TUTORIAL:String = "widen";
		public static const PINCH_TUTORIAL:String = "pinch";
		public static const OPTIMIZE_TUTORIAL:String = "optimize";
		public static const SPLIT_TUTORIAL:String = "split";
		public static const MERGE_TUTORIAL:String = "merge";
		public static const SPLIT_MERGE_PRACTICE_TUTORIAL:String = "splitmergepractice";
		public static const ZOOM_PAN_TUTORIAL:String = "zoompan";
		public static const LAYOUT_TUTORIAL:String = "layout";
		public static const GROUP_SELECT_TUTORIAL:String = "groupselect";
		public static const CREATE_JOINT_TUTORIAL:String = "createjoint";
		public static const SKILLS_A_TUTORIAL:String = "skillsa";
		public static const SKILLS_B_TUTORIAL:String = "skillsb";
		// Not currently used:
		public static const END_TUTORIAL:String = "end";
		public static const NARROW_TUTORIAL:String = "narrow";
		public static const COLOR_TUTORIAL:String = "color";
		
		private var m_tutorialTag:String;
		private var m_levelStarted:Boolean = false;
		private var m_levelFinished:Boolean = false;
		// If default text is ovewridden, store here (otherwise if null, use default text)
		private var m_currentTutorialText:TutorialManagerTextInfo;
		
		public function TutorialManager(_tutorialTag:String)
		{
			m_tutorialTag = _tutorialTag;
			switch (m_tutorialTag) {
				case WIDGET_TUTORIAL:
				case WIDGET_PRACTICE_TUTORIAL:
				case LOCKED_TUTORIAL:
				case LINKS_TUTORIAL:
				case PASSAGE_TUTORIAL:
				case CLASH_TUTORIAL:
				case WIDEN_TUTORIAL:
				case PINCH_TUTORIAL:
				case OPTIMIZE_TUTORIAL:
				case SPLIT_TUTORIAL:
				case MERGE_TUTORIAL:
				case SPLIT_MERGE_PRACTICE_TUTORIAL:
				case ZOOM_PAN_TUTORIAL:
				case LAYOUT_TUTORIAL:
				case GROUP_SELECT_TUTORIAL:
				case CREATE_JOINT_TUTORIAL:
				case SKILLS_A_TUTORIAL:
				case SKILLS_B_TUTORIAL:
				// Not used:
				case END_TUTORIAL:
				case NARROW_TUTORIAL:
				case COLOR_TUTORIAL:
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
			m_currentTutorialText = null;
			m_levelFinished = false;
			m_levelStarted = true;
		}
		
		public function endLevel():void
		{
			m_currentTutorialText = null;
			m_levelFinished = true;
			m_levelStarted = false;
		}
		
		public function onSegmentMoved(event:EdgeContainerEvent, textPointingAtSegment:Boolean = false):void
		{
			switch (m_tutorialTag) {
				case CREATE_JOINT_TUTORIAL:
					if (!m_levelFinished && textPointingAtSegment) {
						m_levelFinished = true;
						Starling.juggler.delayCall(function():void {
							dispatchEvent(new TutorialEvent(TutorialEvent.SHOW_CONTINUE));
						}, 0.5);
					}
				break;
			}
		}
		
		public function onJointCreated(event:EdgeContainerEvent):void
		{
			switch (m_tutorialTag) {
				case CREATE_JOINT_TUTORIAL:
					var toPos:String = (event.segment.m_endPt.y != 0) ? NineSliceBatch.LEFT : NineSliceBatch.TOP;
					m_currentTutorialText = new TutorialManagerTextInfo(
						"Drag the new link segment",
						null,
						pointToEdgeSegment(event.container.m_id, event.segmentIndex),
						toPos, NineSliceBatch.CENTER);
					dispatchEvent(new TutorialEvent(TutorialEvent.NEW_TUTORIAL_TEXT, "", true, m_currentTutorialText));
					break;
			}
		}
		
		public function onEdgeSetChange(evt:EdgeSetChangeEvent):void
		{
		}
		
		public function onGameNodeMoved(updatedGameNodes:Vector.<GameNode>):void
		{
			switch (m_tutorialTag) {
				case GROUP_SELECT_TUTORIAL:
					if (!m_levelFinished && (updatedGameNodes.length > 0)) {
						m_levelFinished = true;
						Starling.juggler.delayCall(function():void {
							dispatchEvent(new TutorialEvent(TutorialEvent.SHOW_CONTINUE));
						}, 2.0);
					}
					break;
			}
		}
		
		public function getPanZoomAllowed():Boolean
		{
			switch (m_tutorialTag) {
				case WIDGET_TUTORIAL:
				case WIDGET_PRACTICE_TUTORIAL:
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
				case SPLIT_MERGE_PRACTICE_TUTORIAL:
				case OPTIMIZE_TUTORIAL:
					return false;
				case ZOOM_PAN_TUTORIAL:
				case LAYOUT_TUTORIAL:
				case GROUP_SELECT_TUTORIAL:
				case CREATE_JOINT_TUTORIAL:
				case END_TUTORIAL:
					return true;
			}
			return true;
		}
		
		public function getLayoutFixed():Boolean
		{
			switch (m_tutorialTag) {
				case WIDGET_TUTORIAL:
				case WIDGET_PRACTICE_TUTORIAL:
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
				case SPLIT_MERGE_PRACTICE_TUTORIAL:
				case OPTIMIZE_TUTORIAL:
				case ZOOM_PAN_TUTORIAL:
					return true;
				case GROUP_SELECT_TUTORIAL:
				case CREATE_JOINT_TUTORIAL:
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
				case WIDGET_PRACTICE_TUTORIAL:
				case LOCKED_TUTORIAL:
					return 0.8;
				case ZOOM_PAN_TUTORIAL:
					return 3.0;
				case LAYOUT_TUTORIAL:
					return 0.5;
				case PASSAGE_TUTORIAL:
					return 1.2;
				case CLASH_TUTORIAL:
				case MERGE_TUTORIAL:
				case OPTIMIZE_TUTORIAL:
					return 1.5;
				case LINKS_TUTORIAL:
				case PINCH_TUTORIAL:
				case WIDEN_TUTORIAL:
				case NARROW_TUTORIAL:
				case COLOR_TUTORIAL:
				case SPLIT_TUTORIAL:
				case SPLIT_MERGE_PRACTICE_TUTORIAL:
				case GROUP_SELECT_TUTORIAL:
				case CREATE_JOINT_TUTORIAL:
				case END_TUTORIAL:
					return 1.0;
			}
			return 1.0;
		}
		
		public function getStartPanOffset():Point
		{
			switch (m_tutorialTag) {
				case WIDGET_TUTORIAL:
				case WIDGET_PRACTICE_TUTORIAL:
				case LOCKED_TUTORIAL:
				case WIDEN_TUTORIAL:
				case LAYOUT_TUTORIAL:
					return new Point(0, 5);// move down by 5px (pan up)
				case LINKS_TUTORIAL:
				case PASSAGE_TUTORIAL:
					return new Point(15, 0);//move right 15px (pan left)
				case PINCH_TUTORIAL:
				case CLASH_TUTORIAL:
					return new Point(0, -10);// move up by 10px
				case OPTIMIZE_TUTORIAL:
					return new Point(0, -20);// move up by 20px
				case MERGE_TUTORIAL:
					return new Point(-15, -5);//move left 15px, up 5px
				case ZOOM_PAN_TUTORIAL:
					return new Point(40, -10);// move right 40px, up by 10px
				case SPLIT_MERGE_PRACTICE_TUTORIAL:
				case NARROW_TUTORIAL:
				case COLOR_TUTORIAL:
				case SPLIT_TUTORIAL:
				case GROUP_SELECT_TUTORIAL:
				case CREATE_JOINT_TUTORIAL:
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
		
		private function pointToEdgeSegment(edgeName:String, segmentIndex:int):Function
		{
			return function(currentLevel:Level):DisplayObject {
				var container:GameEdgeContainer = currentLevel.getEdgeContainer(edgeName);
				if (container != null) return container.getSegment(segmentIndex);
				return null;
			};
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
				if (edge && edge.errorContainer) {
					return edge.errorContainer;
				} else {
					return null;
				}
			};
		}
		
		public function getTextInfo():TutorialManagerTextInfo
		{
			if (m_currentTutorialText != null) return m_currentTutorialText;
			switch (m_tutorialTag) {
				case WIDGET_TUTORIAL:
					return new TutorialManagerTextInfo(
						"Click on WIDGETS to change their color.\n" +
						"Make them a solid color to get points!",
						null,
						pointToNode("IntroWidget2"),
						NineSliceBatch.TOP, null);
				case WIDGET_PRACTICE_TUTORIAL:
					return new TutorialManagerTextInfo(
						"Practice clicking on widgets and matching colors.\n",
						null,
						null,
						null, null);
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
						"by LINKS. Light widgets\n" +
						"create narrow links, dark\n" +
						"widgets create wide\n" +
						"links.",
						null,
						pointToEdge("e1__OUT__"),
						NineSliceBatch.LEFT, null);
				case PASSAGE_TUTORIAL:
					return new TutorialManagerTextInfo(
						"Links can begin in, end in, or go\n" +
						"through PASSAGES. Change a widget's\n" +
						"color to change its passages.",
						null,
						pointToPassage("e32__IN__"),
						NineSliceBatch.LEFT, NineSliceBatch.BOTTOM_LEFT);
				case CLASH_TUTORIAL:
					return new TutorialManagerTextInfo(
						"CLASHES happen when wide links enter\n" +
						"narrow passages. Each clash penalizes\n" +
						"your score by " + Constants.ERROR_POINTS.toString() + " points.",
						null,
						pointToClash("e2__IN__"),
						NineSliceBatch.TOP_RIGHT, NineSliceBatch.TOP);
				case WIDEN_TUTORIAL:
					return null;/* new TutorialManagerTextInfo(
						"Click the widgets to widen their passages\n" +
						"and fix the clashes.",
						null,
						null,
						null, null);*/
				case PINCH_TUTORIAL:
					return new TutorialManagerTextInfo(
						"Gray passages won't change width\n" +
						"even if their widget is changed.",
						null,
						pointToPassage("e20__IN__"),
						NineSliceBatch.BOTTOM_LEFT, NineSliceBatch.LEFT);
				case OPTIMIZE_TUTORIAL:
					return new TutorialManagerTextInfo(
						"Sometimes the best score still has clashes.\n" +
						"Try different configurations to improve your score!",
						null,
						null,
						null, null);
				case SPLIT_TUTORIAL:
					return new TutorialManagerTextInfo(
						"When a link is SPLIT the outgoing\n" +
						"links will match the incoming link.",
						null,
						pointToJoint("n10__IN__0"),
						NineSliceBatch.TOP_RIGHT, null);
				case MERGE_TUTORIAL:
					return new TutorialManagerTextInfo(
						"When links MERGE the outgoing\n" +
						"link will be wide if any\n" +
						"incoming link is wide.",
						null,
						pointToJoint("n123"),
						NineSliceBatch.RIGHT, null);
				case SPLIT_MERGE_PRACTICE_TUTORIAL:
					return new TutorialManagerTextInfo(
						"Practice splits and merges.",
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
						"Widgets can be dragged to help organize\n" +
						"the layout. Separate the widgets.",
						null,
						pointToNode("Layout1"),
						null, null);
				case GROUP_SELECT_TUTORIAL:
					return new TutorialManagerTextInfo(
						"SELECT groups of widgets by holding <SHIFT>\n" +
						"and click-dragging the mouse. SELECT and\n" +
						"move a group of widgets to continue...",
						null,
						null,
						null, null);
				case CREATE_JOINT_TUTORIAL:
					return new TutorialManagerTextInfo(
						"Create a joint on any link by\n" +
						"double-clicking a spot on the link.",
						null,
						null,
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
