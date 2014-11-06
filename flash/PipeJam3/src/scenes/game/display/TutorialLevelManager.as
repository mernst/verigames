package scenes.game.display 
{
	import events.TutorialEvent;
	import utils.PropDictionary;
	import starling.core.Starling;
	import networking.TutorialController;
	
	import flash.geom.Point;
	
	import starling.display.DisplayObject;
	import starling.events.Event;
	import starling.events.EventDispatcher;
	
	public class TutorialLevelManager extends EventDispatcher
	{
		// This is the order the tutorials appers in:
		private static const WIDGET_TUTORIAL:String = "widget";
		private static const WIDGET_PRACTICE_TUTORIAL:String = "widgetpractice";
		private static const LOCKED_TUTORIAL:String = "locked";
		private static const LINKS_TUTORIAL:String = "links";
		private static const JAMS_TUTORIAL:String = "jams";
		private static const WIDEN_TUTORIAL:String = "widen";
		private static const ZOOM_PAN_TUTORIAL:String = "zoompan";
		private static const L13601_TUTORIAL:String = "L13601";
		private static const L13635_TUTORIAL:String = "L13635";
		private static const L13663_TUTORIAL:String = "L13663";
		private static const L13722_TUTORIAL:String = "L13722";
		private static const L13727_TUTORIAL:String = "L13727";
		
		// Not currently used:
		private static const OPTIMIZE_TUTORIAL:String = "optimize";
		private static const LAYOUT_TUTORIAL:String = "layout";
		private static const GROUP_SELECT_TUTORIAL:String = "groupselect";
		private static const CREATE_JOINT_TUTORIAL:String = "createjoint";
		private static const SKILLS_A_TUTORIAL:String = "skillsa";
		private static const SKILLS_B_TUTORIAL:String = "skillsb";
		
		private var m_tutorialTag:String;
		private var m_levelStarted:Boolean = false;
		private var m_levelFinished:Boolean = false;
		// If default text is ovewridden, store here (otherwise if null, use default text)
		private var m_currentTutorialText:TutorialManagerTextInfo;
		private var m_currentToolTipsText:Vector.<TutorialManagerTextInfo>;
		
		public function TutorialLevelManager(_tutorialTag:String)
		{
			m_tutorialTag = _tutorialTag;
			switch (m_tutorialTag) {
				case "1":
				case "2":
				case "3":
				case "4":
				case "5":
				case "6":
				case "7":
				case "8":
				case "9":
				case "10":
				case "11":
				case "12":
				case "13":
				case "14":
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
		
		public function onWidgetChange(idChanged:String, propChanged:String, propValue:Boolean):void
		{
			var tips:Vector.<TutorialManagerTextInfo> = new Vector.<TutorialManagerTextInfo>();
			var tip:TutorialManagerTextInfo, widthTxt:String;
			switch (m_tutorialTag) {
				case JAMS_TUTORIAL:
					var jammed:Boolean = (propChanged == PropDictionary.PROP_NARROW && !propValue);
					var jamText:String = "Jam cleared! +" + 100 /* TODO: get from level*/ + " points.";
					if (jammed) {
						tip = new TutorialManagerTextInfo("Jam! Wide Link to\nNarrow Widget", null, pointToClash("var_0 -> type_0__var_0"), Constants.BOTTOM_LEFT, Constants.CENTER);
						tips.push(tip);
						jamText = "JAMS happen when wide Links enter\n" +
						"narrow Widgets. This Jam penalizes\n" +
						"your score by " + 100 /* TODO: get from level*/ + " points.";
					}
					m_currentToolTipsText = tips;
					dispatchEvent(new TutorialEvent(TutorialEvent.NEW_TOOLTIP_TEXT, "", true, tips));
					m_currentTutorialText = new TutorialManagerTextInfo(
						jamText,
						null,
						pointToClash("var_0 -> type_0__var_0"),
						Constants.TOP_RIGHT, Constants.TOP);
					var txtVec:Vector.<TutorialManagerTextInfo> = new Vector.<TutorialManagerTextInfo>();
					txtVec.push(m_currentTutorialText);
					dispatchEvent(new TutorialEvent(TutorialEvent.NEW_TUTORIAL_TEXT, "", true, txtVec));
					break;
				case LINKS_TUTORIAL:
					var edgeId:String;
					if (idChanged == "var_1") {
						edgeId = "var_1 -> type_1__var_1";
					} else if (idChanged == "var_0") {
						edgeId = "var_0 -> type_1__var_0";
					} else {
						break;
					}
					widthTxt = !propValue ? "Wide Link" : "Narrow Link";
					tip = new TutorialManagerTextInfo(widthTxt, null, pointToEdge(edgeId), Constants.BOTTOM_RIGHT, Constants.RIGHT);
					tips.push(tip);
					m_currentToolTipsText = tips;
					dispatchEvent(new TutorialEvent(TutorialEvent.NEW_TOOLTIP_TEXT, "", true, tips));
					break;
				case WIDEN_TUTORIAL:
					if (idChanged == "var_0") {
						if (propValue) {
							tip = new TutorialManagerTextInfo("Jam! Wide Link to\nNarrow Widget", null, pointToClash("type_1__var_0 -> var_0"), Constants.BOTTOM_LEFT, Constants.CENTER);
							tips.push(tip);
						}
						m_currentToolTipsText = tips;
						dispatchEvent(new TutorialEvent(TutorialEvent.NEW_TOOLTIP_TEXT, "", true, tips));
					}
					break;
			}
		}
		
		public function onGameNodeMoved(updatedGameNodes:Vector.<Node>):void
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
						if (updatedGameNodes[i].id == "var_3") {
							m_currentToolTipsText = tips;
							dispatchEvent(new TutorialEvent(TutorialEvent.NEW_TOOLTIP_TEXT, "", true, tips));
							break;
						}
					}
					break;
			}
		}
		
		public function getAutoSolveAllowed():Boolean
		{
			return true;
		}
		
		public function getPanZoomAllowed():Boolean
		{
			switch (m_tutorialTag) {
				case "1":
					return false;
			}
			return true;
		}
		
		public function getMiniMapShown():Boolean
		{
			switch (m_tutorialTag) {
				case "1":
				case "2":
				case "3":
				case "4":
				case "5":
				case "6":
				case "7":
				case "8":
				case "9":
				case "10":
				case "11":
					return false;
			}
			return true;
		}
		
		public function getLayoutFixed():Boolean
		{
			return true;
		}
		
		public function getStartScaleFactor():Number
		{
			switch (m_tutorialTag) {
				case "1":
				case "2":
				case "3":
				case "4":
				case "5":
				case "6":
				case "7":
				case "8":
				case "9":
				case "10":
				case "11":
				case "12":
				case "13":
				case "14":
					return 1.0
			}
			return 1.0;
		}
		
		public function getStartPanOffset():Point
		{
			switch (m_tutorialTag) {
				case "1":
					return new Point(0, 10); // shift level down by 10px
				case "2":
				case "3":
				case "4":
				case "5":
				case "6":
				case "7":
				case "8":
				case "9":
					return new Point();
			}
			return new Point();
		}
		
		public function getMaxSelectableWidgets():int
		{
			switch (m_tutorialTag) {
				case "1":
					return 100;
				case "2":
					return 150;
				case "3":
				case "4":
				case "5":
					return 200;
				case "6":
				case "7":
				case "8":
					return 300;
				case "9":
				case "10":
				case "11":
					return 400;
				case "12":
				case "13":
				case "14":
					return 500;
			}
			return -1;
		}
		
		private function pointToNode(name:String):Function
		{
			return function(currentLevel:Level):DisplayObject { return currentLevel.getNode(name).skin; };
		}
		
		private function pointToEdge(name:String):Function
		{
			return function(currentLevel:Level):DisplayObject
			{
				return currentLevel.getEdgeContainer(name);
			};
		}
		
		private function pointToEdgeSegment(edgeName:String, segmentIndex:int):Function
		{
			return function(currentLevel:Level):DisplayObject {
				var container:DisplayObject = currentLevel.getEdgeContainer(edgeName);
				if (container != null) return container.getSegment(segmentIndex);
				return null;
			};
		}
		
		private function pointToPassage(name:String):Function
		{
			return function(currentLevel:Level):DisplayObject {
				var edge:DisplayObject = currentLevel.getEdgeContainer(name);
				if (edge && edge.innerFromBoxSegment) {
					return edge.innerFromBoxSegment;
				} else {
					return null;
				}
			};
		}
		
		private function pointToClash(name:String):Function
		{
			return function(currentLevel:Level):DisplayObject {
				var edge:DisplayObject = currentLevel.getEdgeContainer(name);
				return edge; // TODO: bottom of edge
			};
		}
		
		public function getPersistentToolTipsInfo():Vector.<TutorialManagerTextInfo>
		{
			if (m_currentToolTipsText != null) return m_currentToolTipsText;
			var tips:Vector.<TutorialManagerTextInfo> = new Vector.<TutorialManagerTextInfo>();
			var tip:TutorialManagerTextInfo;
			switch (m_tutorialTag) {
				case LOCKED_TUTORIAL:
					tip = new TutorialManagerTextInfo("Locked\nNarrow\nWidget", null, pointToNode("var_0"), Constants.BOTTOM, Constants.CENTER);
					tips.push(tip);
					tip = new TutorialManagerTextInfo("Locked\nWide\nWidget", null, pointToNode("var_1"), Constants.BOTTOM, Constants.CENTER);
					tips.push(tip);
					break;
				case JAMS_TUTORIAL:
					tip = new TutorialManagerTextInfo("Jam! Wide Link to\nNarrow Widget", null, pointToClash("var_0 -> type_0__var_0"), Constants.BOTTOM_LEFT, Constants.CENTER);
					tips.push(tip);
					break;
				case LINKS_TUTORIAL:
					tip = new TutorialManagerTextInfo("Narrow Link", null, pointToEdge("var_0 -> type_1__var_0"), Constants.BOTTOM_RIGHT, Constants.RIGHT);
					tips.push(tip);
					tip = new TutorialManagerTextInfo("Wide Link", null, pointToEdge("var_1 -> type_1__var_1"), Constants.BOTTOM_RIGHT, Constants.RIGHT);
					tips.push(tip);
					break;
				case WIDEN_TUTORIAL:
					tip = new TutorialManagerTextInfo("Jam! Wide Link to\nNarrow Widget", null, pointToClash("type_1__var_0 -> var_0"), Constants.BOTTOM_LEFT, Constants.CENTER);
					tips.push(tip);
					break;
				// Not used
				case LAYOUT_TUTORIAL:
					tip = new TutorialManagerTextInfo(
						"Widgets can be dragged to\n" +
						"help organize the layout.\n" +
						"Separate the Widgets.",
						null,
						pointToNode("var_3"),
						Constants.BOTTOM_LEFT, null);
					tips.push(tip);
					break;
			}
			return tips;
		}
		
		public function getTextInfo():TutorialManagerTextInfo
		{
			if (m_currentTutorialText != null) return m_currentTutorialText;
			switch (m_tutorialTag) {
				case "1":
					return new TutorialManagerTextInfo(
						"Click and drag to paint! Release to autosolve!\nEliminate as many red conflicts as you can!",
						null,
						null,
						null, null);
				case "2":
					return new TutorialManagerTextInfo(
						"Use the arrow keys or mouse to the edge of the screen to pan! Use +/- to zoom!",
						null,
						null,
						null, null);
				case "3":
				case "4":
				case "7":
				case "8":
				case "9":
				case "10":
				case "11":
				case "13":
				case "14":
					return new TutorialManagerTextInfo(
						"Keep eliminating the red conflicts!",
						null,
						null,
						null, null);
				case "5":
					return new TutorialManagerTextInfo(
						"Sometimes areas need to be painted multiple times.\nKeep eliminating the red conflicts!",
						null,
						null,
						null, null);
				case "6":
					return new TutorialManagerTextInfo(
						"Sometimes large selection areas are needed to eliminate a conflict.\nKeep eliminating the red conflicts!",
						null,
						null,
						null, null);
				case "12":
					return new TutorialManagerTextInfo(
						"For larger levels use on the minimap in the top right to navigate!",
						null,
						null,
						Constants.TOP_LEFT, null);
				
					return null;
				case WIDGET_TUTORIAL:
					return new TutorialManagerTextInfo(
						"Click on WIDGETS to change their color.\n" +
						"Get 1 point for matching a Widget to its outline color!",
						null,
						pointToNode("var_1"),
						Constants.TOP, null);
				case WIDGET_PRACTICE_TUTORIAL:
					return new TutorialManagerTextInfo(
						"Practice clicking on Widgets and matching colors.\n",
						null,
						null,
						null, null);
				case LOCKED_TUTORIAL:
					return new TutorialManagerTextInfo(
						"Transparent Widgets are locked.\n" +
						"Their colors can't be changed.",
						null,
						pointToNode("var_0"),
						Constants.TOP, null);
				case LINKS_TUTORIAL:
					return new TutorialManagerTextInfo(
						"Widgets are connected\n" +
						"by LINKS. Light Widgets\n" +
						"create narrow Links, dark\n" +
						"Widgets create wide\n" +
						"Links.",
						null,
						pointToEdge("var_0 -> type_1__var_0"),
						Constants.LEFT, null);
				case JAMS_TUTORIAL:
					return new TutorialManagerTextInfo(
						"JAMS happen when wide Links enter\n" +
						"narrow Widgets. Each Jam penalizes\n" +
						"your score by " + 100 /* TODO: get from level*/ + " points.",
						null,
						pointToClash("var_0 -> type_0__var_0"),
						Constants.TOP_RIGHT, Constants.TOP);
				case WIDEN_TUTORIAL:
					return null;/* new TutorialManagerTextInfo(
						"Click the widgets to widen their links\n" +
						"and fix the jams.",
						null,
						null,
						null, null);*/
				case ZOOM_PAN_TUTORIAL:
					return new TutorialManagerTextInfo(
						"       Larger levels require navigation:      \n" +
						" Drag the background to move around the level.\n" +
						"      Use the +/- buttons to zoom in and out. \n" +
						"Navigate between jams using Tab and Shift+Tab.",
						null,
						null,
						null, null);
				case L13601_TUTORIAL:
					return new TutorialManagerTextInfo(
						"Now try a level generated from real code!",
						null,
						null,
						null, null);
				case L13635_TUTORIAL:
					return new TutorialManagerTextInfo(
						"For larger levels we provide an autosolver.\n" + 
						"Paint a group of Widgets by holding Shift and\n" +
						"Click+Dragging the mouse. When the mouse is released\n" +
						"the autosolver will begin solving the selected Widgets.",
						null,
						null,
						null, null);
				case L13663_TUTORIAL:
					break;
				case L13722_TUTORIAL:
					return new TutorialManagerTextInfo(
						"Try using the map in the top right\n" +
						"        to navigate around.       ",
						null,
						null,
						null, null);
				case L13727_TUTORIAL:
					break;
				// The following are not currently in use:
				case OPTIMIZE_TUTORIAL:
					return new TutorialManagerTextInfo(
						"Sometimes the best score still has Jams.\n" +
						"Try different configurations to improve your score!",
						null,
						null,
						Constants.BOTTOM_LEFT, null);
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
						"Use the skills\nyou've learned to\nsolve a bigger\nchallenge!",
						null,
						null,
						Constants.TOP_LEFT, null);
				case SKILLS_B_TUTORIAL:
					return new TutorialManagerTextInfo(
						"Good work!\nTry using the map\nin the top right\nto navigate this\nlarger level.",
						null,
						null,
						Constants.TOP_LEFT, null);
			}
			return null;
		}
	}
}
