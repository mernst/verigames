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
		private var m_currentToolTipsText:Vector.<TutorialManagerTextInfo>;
		
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
			m_currentToolTipsText = null;
			m_levelFinished = false;
			m_levelStarted = true;
		}
		
		public function endLevel():void
		{
			m_currentTutorialText = null;
			m_currentToolTipsText = null;
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
						"Drag the new Link segment",
						null,
						pointToEdgeSegment(event.container.m_id, event.segmentIndex),
						toPos, NineSliceBatch.CENTER);
					var txtVec:Vector.<TutorialManagerTextInfo> = new Vector.<TutorialManagerTextInfo>();
					txtVec.push(m_currentTutorialText);
					dispatchEvent(new TutorialEvent(TutorialEvent.NEW_TUTORIAL_TEXT, "", true, txtVec));
					break;
			}
		}
		
		public function onEdgeSetChange(evt:EdgeSetChangeEvent):void
		{
			var tips:Vector.<TutorialManagerTextInfo> = new Vector.<TutorialManagerTextInfo>();
			var tip:TutorialManagerTextInfo, widthTxt:String;
			switch (m_tutorialTag) {
				case CLASH_TUTORIAL:
					if (evt.edgeSetChanged.isWide()) {
						tip = new TutorialManagerTextInfo("Clash! Wide Link to\nnarrow Passage", null, pointToClash("e2__IN__"), NineSliceBatch.BOTTOM_LEFT, NineSliceBatch.CENTER);
						tips.push(tip);
					}
					m_currentToolTipsText = tips;
					dispatchEvent(new TutorialEvent(TutorialEvent.NEW_TOOLTIP_TEXT, "", true, tips));
					break;
				case LINKS_TUTORIAL:
					var edgeId:String;
					if (evt.edgeSetChanged.m_id == "SatisfyBoxes1") {
						edgeId = "e1__OUT__";
					} else if (evt.edgeSetChanged.m_id == "SatisfyBoxes3") {
						edgeId = "e3__OUT__";
					} else {
						break;
					}
					widthTxt = evt.edgeSetChanged.isWide() ? "Wide Link" : "Narrow Link";
					tip = new TutorialManagerTextInfo(widthTxt, null, pointToEdge(edgeId), NineSliceBatch.BOTTOM_RIGHT, NineSliceBatch.RIGHT);
					tips.push(tip);
					m_currentToolTipsText = tips;
					dispatchEvent(new TutorialEvent(TutorialEvent.NEW_TOOLTIP_TEXT, "", true, tips));
					break;
				case WIDEN_TUTORIAL:
					if (evt.edgeSetChanged.m_id == "WidenBoxes10") {
						if (!evt.edgeSetChanged.isWide()) {
							tip = new TutorialManagerTextInfo("Clash! Wide Link to\nnarrow Passage", null, pointToClash("e10__IN__"), NineSliceBatch.BOTTOM_LEFT, NineSliceBatch.CENTER);
							tips.push(tip);
						}
						m_currentToolTipsText = tips;
						dispatchEvent(new TutorialEvent(TutorialEvent.NEW_TOOLTIP_TEXT, "", true, tips));
					}
					break;
				case SPLIT_TUTORIAL:
					if (evt.edgeSetChanged.m_id == "Splits1") {
						widthTxt = evt.edgeSetChanged.isWide() ? "Wide" : "Narrow";
						tip = new TutorialManagerTextInfo(widthTxt + " Input", null, pointToEdge("e1__OUT__"), NineSliceBatch.TOP_LEFT, NineSliceBatch.CENTER);
						tips.push(tip);
						tip = new TutorialManagerTextInfo(widthTxt + " Output", null, pointToEdge("e2__IN__"), NineSliceBatch.TOP_LEFT, NineSliceBatch.LEFT);
						tips.push(tip);
						m_currentToolTipsText = tips;
						dispatchEvent(new TutorialEvent(TutorialEvent.NEW_TOOLTIP_TEXT, "", true, tips));
					}
					break;
				case MERGE_TUTORIAL:
					if ((evt.edgeSetChanged.m_id == "Merges1") || (evt.edgeSetChanged.m_id == "Merges2")) {
						if (evt.edgeSetChanged.m_outgoingEdges.length != 1) break;
						if (evt.edgeSetChanged.m_outgoingEdges[0].m_toComponent == null) break;
						if (evt.edgeSetChanged.m_outgoingEdges[0].m_toComponent.m_incomingEdges.length != 2) break;
						var edge1:GameEdgeContainer = evt.edgeSetChanged.m_outgoingEdges[0].m_toComponent.m_incomingEdges[0];
						var edge2:GameEdgeContainer = evt.edgeSetChanged.m_outgoingEdges[0].m_toComponent.m_incomingEdges[1];
						if (edge2.m_id == "e1__OUT__") {
							edge1 = evt.edgeSetChanged.m_outgoingEdges[0].m_toComponent.m_incomingEdges[1];
							edge2 = evt.edgeSetChanged.m_outgoingEdges[0].m_toComponent.m_incomingEdges[0];
						}
						var edge1Wide:Boolean = edge1.isWide();
						var edge2Wide:Boolean = edge2.isWide();
						if ((edge1.m_id != "e1__OUT__") || (edge2.m_id != "e2__OUT__")) break;
						if (evt.edgeSetChanged.m_id == "Merges1") edge1Wide = evt.edgeSetChanged.isWide();
						if (evt.edgeSetChanged.m_id == "Merges2") edge2Wide = evt.edgeSetChanged.isWide();
						if (edge1Wide || edge2Wide) {
							if (edge1Wide) {
								tip = new TutorialManagerTextInfo("Wide Input", null, pointToEdge("e1__OUT__"), NineSliceBatch.BOTTOM_LEFT, NineSliceBatch.LEFT);
								tips.push(tip);
							}
							if (edge2Wide) {
								tip = new TutorialManagerTextInfo("Wide Input", null, pointToEdge("e2__OUT__"), NineSliceBatch.BOTTOM_RIGHT, NineSliceBatch.RIGHT);
								tips.push(tip);
							}
							tip = new TutorialManagerTextInfo("Wide Output", null, pointToEdge("e3__IN__"), NineSliceBatch.TOP_LEFT, NineSliceBatch.LEFT);
							tips.push(tip);
						}
						m_currentToolTipsText = tips;
						dispatchEvent(new TutorialEvent(TutorialEvent.NEW_TOOLTIP_TEXT, "", true, tips));
					}
					break;
			}
		}
		
		public function onGameNodeMoved(updatedGameNodes:Vector.<GameNode>):void
		{
			var tips:Vector.<TutorialManagerTextInfo> = new Vector.<TutorialManagerTextInfo>();
			switch (m_tutorialTag) {
				case GROUP_SELECT_TUTORIAL:
					if (!m_levelFinished && (updatedGameNodes.length > 1)) {
						m_levelFinished = true;
						Starling.juggler.delayCall(function():void {
							dispatchEvent(new TutorialEvent(TutorialEvent.SHOW_CONTINUE));
						}, 0.5);
					}
					break;
				case LAYOUT_TUTORIAL:
					for (var i:int = 0; i < updatedGameNodes.length; i++) {
						if (updatedGameNodes[i].m_id == "Layout1") {
							m_currentToolTipsText = tips;
							dispatchEvent(new TutorialEvent(TutorialEvent.NEW_TOOLTIP_TEXT, "", true, tips));
							break;
						}
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
				case GROUP_SELECT_TUTORIAL:
					return 0.6;
				case PASSAGE_TUTORIAL:
				case SPLIT_MERGE_PRACTICE_TUTORIAL:
					return 1.2;
				case CLASH_TUTORIAL:
				case MERGE_TUTORIAL:
					return 1.5;
				case LINKS_TUTORIAL:
				case PINCH_TUTORIAL:
				case WIDEN_TUTORIAL:
				case NARROW_TUTORIAL:
				case OPTIMIZE_TUTORIAL:
				case COLOR_TUTORIAL:
				case SPLIT_TUTORIAL:
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
				case SPLIT_MERGE_PRACTICE_TUTORIAL:
					return new Point(0, 5);// move down by 5px (pan up)
				case GROUP_SELECT_TUTORIAL:
				case OPTIMIZE_TUTORIAL:
					return new Point(0, 11);// move down by 15px
				case LINKS_TUTORIAL:
				case PASSAGE_TUTORIAL:
					return new Point(15, 0);//move right 15px (pan left)
				case PINCH_TUTORIAL:
					return new Point(0, -10);// move up by 10px
				case MERGE_TUTORIAL:
					return new Point(-5, 0);//move left 5px
				case ZOOM_PAN_TUTORIAL:
					return new Point(40, -10);// move right 40px, up by 10px
				case CLASH_TUTORIAL:
				case NARROW_TUTORIAL:
				case COLOR_TUTORIAL:
				case SPLIT_TUTORIAL:
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
		
		public function getPersistentToolTipsInfo():Vector.<TutorialManagerTextInfo>
		{
			if (m_currentToolTipsText != null) return m_currentToolTipsText;
			var tips:Vector.<TutorialManagerTextInfo> = new Vector.<TutorialManagerTextInfo>();
			var tip:TutorialManagerTextInfo;
			switch (m_tutorialTag) {
				case LOCKED_TUTORIAL:
					tip = new TutorialManagerTextInfo("Locked\nNarrow\nWidget", null, pointToNode("LockedWidget2"), NineSliceBatch.BOTTOM, NineSliceBatch.CENTER);
					tips.push(tip);
					tip = new TutorialManagerTextInfo("Locked\nWide\nWidget", null, pointToNode("LockedWidget5"), NineSliceBatch.BOTTOM, NineSliceBatch.CENTER);
					tips.push(tip);
					break;
				case CLASH_TUTORIAL:
					tip = new TutorialManagerTextInfo("Clash! Wide Link to\nnarrow Passage", null, pointToClash("e2__IN__"), NineSliceBatch.BOTTOM_LEFT, NineSliceBatch.CENTER);
					tips.push(tip);
					break;
				case LINKS_TUTORIAL:
					tip = new TutorialManagerTextInfo("Narrow Link", null, pointToEdge("e1__OUT__"), NineSliceBatch.BOTTOM_RIGHT, NineSliceBatch.RIGHT);
					tips.push(tip);
					tip = new TutorialManagerTextInfo("Wide Link", null, pointToEdge("e3__OUT__"), NineSliceBatch.BOTTOM_RIGHT, NineSliceBatch.RIGHT);
					tips.push(tip);
					break;
				case PASSAGE_TUTORIAL:
					tip = new TutorialManagerTextInfo("Start Passage", null, pointToPassage("e33__OUT__"), NineSliceBatch.BOTTOM_RIGHT, NineSliceBatch.CENTER);
					tips.push(tip);
					tip = new TutorialManagerTextInfo("Thru Passage", null, pointToPassage("e32__OUT__"), NineSliceBatch.TOP_RIGHT, NineSliceBatch.TOP);
					tips.push(tip);
					tip = new TutorialManagerTextInfo("End Passage", null, pointToPassage("e53__IN__"), NineSliceBatch.BOTTOM_RIGHT, NineSliceBatch.CENTER);
					tips.push(tip);
					break;
				case WIDEN_TUTORIAL:
					tip = new TutorialManagerTextInfo("Clash! Wide Link to\nnarrow Passage", null, pointToClash("e10__IN__"), NineSliceBatch.BOTTOM_LEFT, NineSliceBatch.CENTER);
					tips.push(tip);
					break;
				case PINCH_TUTORIAL:
					//tip = new TutorialManagerTextInfo("Locked\nGray\nPassage", null, pointToPassage("e20__IN__"), NineSliceBatch.BOTTOM_RIGHT, NineSliceBatch.CENTER);
					//tips.push(tip);
					tip = new TutorialManagerTextInfo("Unlocked\nBlue\nPassage", null, pointToPassage("e30__IN__"), NineSliceBatch.BOTTOM_LEFT, NineSliceBatch.CENTER);
					tips.push(tip);
					tip = new TutorialManagerTextInfo("Locked\nGray\nPassage", null, pointToPassage("e40__IN__"), NineSliceBatch.BOTTOM_RIGHT, NineSliceBatch.CENTER);
					tips.push(tip);
					break;
				case SPLIT_TUTORIAL:
					tip = new TutorialManagerTextInfo("Wide Input", null, pointToEdge("e1__OUT__"), NineSliceBatch.TOP_LEFT, NineSliceBatch.CENTER);
					tips.push(tip);
					tip = new TutorialManagerTextInfo("Wide Output", null, pointToEdge("e2__IN__"), NineSliceBatch.TOP_LEFT, NineSliceBatch.LEFT);
					tips.push(tip);
					break;
				case MERGE_TUTORIAL:
					tip = new TutorialManagerTextInfo("Wide Input", null, pointToEdge("e1__OUT__"), NineSliceBatch.BOTTOM_LEFT, NineSliceBatch.LEFT);
					tips.push(tip);
					tip = new TutorialManagerTextInfo("Wide Input", null, pointToEdge("e2__OUT__"), NineSliceBatch.BOTTOM_RIGHT, NineSliceBatch.RIGHT);
					tips.push(tip);
					tip = new TutorialManagerTextInfo("Wide Output", null, pointToEdge("e3__IN__"), NineSliceBatch.TOP_LEFT, NineSliceBatch.LEFT);
					tips.push(tip);
					break;
				case LAYOUT_TUTORIAL:
					tip = new TutorialManagerTextInfo(
						"Widgets can be dragged to\n" +
						"help organize the layout.\n" +
						"Separate the Widgets.",
						null,
						pointToNode("Layout1"),
						NineSliceBatch.BOTTOM_LEFT, null);
					tips.push(tip);
					break;
				case WIDGET_TUTORIAL:
				case WIDGET_PRACTICE_TUTORIAL:
				case OPTIMIZE_TUTORIAL:
				case SPLIT_MERGE_PRACTICE_TUTORIAL:
				case ZOOM_PAN_TUTORIAL:
				case GROUP_SELECT_TUTORIAL:
				case CREATE_JOINT_TUTORIAL:
				case SKILLS_A_TUTORIAL:
				case SKILLS_B_TUTORIAL:
				// Not used:
				case END_TUTORIAL:
				case NARROW_TUTORIAL:
				case COLOR_TUTORIAL:
					break;
			}
			return tips;
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
						"Practice clicking on Widgets and matching colors.\n",
						null,
						null,
						null, null);
				case LOCKED_TUTORIAL:
					return new TutorialManagerTextInfo(
						"Gray Widgets are locked.\n" +
						"Their colors can't be changed.",
						null,
						pointToNode("LockedWidget2"),
						NineSliceBatch.TOP, null);
				case LINKS_TUTORIAL:
					return new TutorialManagerTextInfo(
						"Widgets are connected\n" +
						"by LINKS. Light Widgets\n" +
						"create narrow Links, dark\n" +
						"Widgets create wide\n" +
						"Links.",
						null,
						pointToEdge("e1__OUT__"),
						NineSliceBatch.LEFT, null);
				case PASSAGE_TUTORIAL:
					return new TutorialManagerTextInfo(
						"Links can begin in, end in, or go\n" +
						"thru PASSAGES. Change a Widget's\n" +
						"color to change its Passages.",
						null,
						pointToPassage("e32__IN__"),
						NineSliceBatch.LEFT, NineSliceBatch.BOTTOM_LEFT);
				case CLASH_TUTORIAL:
					return new TutorialManagerTextInfo(
						"CLASHES happen when wide Links enter\n" +
						"narrow Passages. Each Clash penalizes\n" +
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
						"GRAY Passages are LOCKED and\n" +
						"won't change width even if\n" +
						"their Widget is changed.",
						null,
						pointToPassage("e20__IN__"),
						NineSliceBatch.BOTTOM_LEFT, NineSliceBatch.LEFT);
				case OPTIMIZE_TUTORIAL:
					return new TutorialManagerTextInfo(
						"Sometimes the best score still has Clashes.\n" +
						"Try different configurations to improve your score!",
						null,
						null,
						null, null);
				case SPLIT_TUTORIAL:
					return new TutorialManagerTextInfo(
						"When a link is SPLIT, the output\n" +
						"Links will match the input Link.",
						null,
						pointToJoint("n10__IN__0"),
						NineSliceBatch.TOP_RIGHT, null);
				case MERGE_TUTORIAL:
					return new TutorialManagerTextInfo(
						"When Links MERGE, the output\n" +
						"Link will be wide if any\n" +
						"input Link is wide.",
						null,
						pointToJoint("n123"),
						NineSliceBatch.RIGHT, null);
				case SPLIT_MERGE_PRACTICE_TUTORIAL:
					return new TutorialManagerTextInfo(
						"Practice Splits and Merges.",
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
						"The LAYOUT can be changed to help visualize the\n" +
						"problem. Layout moves will not affect your score.",
						null,
						null,
						null, null);
				case GROUP_SELECT_TUTORIAL:
					return new TutorialManagerTextInfo(
						"SELECT groups of Widgets by holding <SHIFT>\n" +
						"and click-dragging the mouse. SELECT and\n" +
						"move a group of Widgets to continue.",
						null,
						null,
						null, null);
				case CREATE_JOINT_TUTORIAL:
					return new TutorialManagerTextInfo(
						"Create a joint on any Link by\n" +
						"double-clicking a spot on the Link.",
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
						"Click the upper Widgets to narrow their Links\n" +
						"and fix the Clashes.",
						null,
						null,
						null, null);
				case COLOR_TUTORIAL:
					return new TutorialManagerTextInfo(
						"Some Widgets want to be a certain color. Match\n" +
						"the Widgets to the color squares to collect\n" +
						"bonus points.",
						null,
						null,
						null, null);
			}
			return null;
		}
	}
}
