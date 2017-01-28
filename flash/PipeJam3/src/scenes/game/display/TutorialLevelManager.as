package scenes.game.display 
{
	import assets.StringTable;
	import assets.AssetInterface;
	import constraints.ConstraintEdge;
	import constraints.ConstraintGraph;
	import constraints.ConstraintVar;
	import events.TutorialEvent;
	import starling.display.Image;
	import starling.textures.Texture;
	import utils.PropDictionary;
	import starling.core.Starling;
	import networking.TutorialController;
	
	import flash.geom.Point;
	
	import starling.display.DisplayObject;
	import starling.events.Event;
	import starling.events.EventDispatcher;
	
	public class TutorialLevelManager extends EventDispatcher
	{
		// This is the order the tutorials appears in:
		// TODO
		
		private var m_tutorialTag:String;
		private var m_levelStarted:Boolean = false;
		private var m_levelFinished:Boolean = false;
		// If default text is ovewridden, store here (otherwise if null, use default text)
		private var m_currentTutorialText:TutorialManagerTextInfo;
		private var m_currentToolTipsText:Vector.<TutorialManagerTextInfo>;
		
		public static const WIDEN_BRUSH:int    = 0x000001;
		public static const NARROW_BRUSH:int   = 0x000002;
		public static const SOLVER1_BRUSH:int  = 0x000004;
		public static const SOLVER2_BRUSH:int  = 0x000008;
		
		public static function excludeLevel(id:String):Boolean
		{
			if (!GameConfig.ENABLE_SOLVER_LEVELS)
			{
				switch (id) {
					case "004":
					case "02":
					case "005":
						return true;
				}
			}
			return false;
		}
		
		public function TutorialLevelManager(_tutorialTag:String)
		{
			m_tutorialTag = _tutorialTag;
			switch (m_tutorialTag) {
				case "001":
				case "002":
				case "01":
				case "004":
				case "02":
				case "005":
				case "03":
				case "04":
				case "1":
				case "2":
				case "3":
				case "4":
				case "5":
				case "6":
				case "7":
				case "8":
				case "10":
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
		
		public function onWidgetChange(idChanged:String, propChanged:String, propValue:Boolean, levelGraph:ConstraintGraph):void
		{
			var tips:Vector.<TutorialManagerTextInfo> = new Vector.<TutorialManagerTextInfo>();
			var tip:TutorialManagerTextInfo, widthTxt:String;
			switch (m_tutorialTag) {
				case "01":
					var var_98011_1:ConstraintVar = levelGraph.variableDict["var_98011"];
					var var_98019_1:ConstraintVar = levelGraph.variableDict["var_98019"];
					if (var_98011_1 && var_98011_1.getValue().intVal == 1) {
						tip = new TutorialManagerTextInfo("Paradox", null, pointToNode("c_74452"), Constants.TOP, Constants.TOP);
						tips.push(tip);
					}
					if (var_98019_1 && var_98019_1.getValue().intVal == 1) {
						tip = new TutorialManagerTextInfo("Paradox", null, pointToNode("c_74407"), Constants.TOP, Constants.TOP);
						tips.push(tip);
					}
					m_currentToolTipsText = tips;
					dispatchEvent(new TutorialEvent(TutorialEvent.NEW_TOOLTIP_TEXT, "", true, tips));
					break;
				case "02":
					var var_98011_2:ConstraintVar = levelGraph.variableDict["var_98011"];
					var var_98019_2:ConstraintVar = levelGraph.variableDict["var_98019"];
					if (var_98011_2 && var_98011_2.getValue().intVal == 1) {
						tip = new TutorialManagerTextInfo("Paradox", null, pointToNode("c_74452"), Constants.TOP, Constants.TOP);
						tips.push(tip);
					}
					if (var_98019_2 && var_98019_2.getValue().intVal == 1) {
						tip = new TutorialManagerTextInfo("Paradox", null, pointToNode("c_74407"), Constants.TOP, Constants.TOP);
						tips.push(tip);
					}
					if (tips.length == 0) {
						tip = new TutorialManagerTextInfo("To remove this paradox two others\nwould be created, so leaving this\nparadox is the optimal solution", null, pointToNode("c_111708"), Constants.TOP, Constants.TOP);
						tips.push(tip);
					} else {
						tip = new TutorialManagerTextInfo("Paradox", null, pointToNode("c_111708"), Constants.BOTTOM, Constants.BOTTOM);
						tips.push(tip);
					}
					m_currentToolTipsText = tips;
					dispatchEvent(new TutorialEvent(TutorialEvent.NEW_TOOLTIP_TEXT, "", true, tips));
					break;
			}
		}
		
		public function afterScoreUpdate(levelGraph:ConstraintGraph):void
		{
			var tips:Vector.<TutorialManagerTextInfo> = new Vector.<TutorialManagerTextInfo>();
			var tip:TutorialManagerTextInfo, num:int, longConflictFound:Boolean, key:String;
			switch (m_tutorialTag) {
				case "001":
					num = 0;
					for (key in levelGraph.unsatisfiedConstraintDict) num++;
					if (num == 0) { // End of level, display summary
						tip = new TutorialManagerTextInfo(
							"Great work! The target score for this level was reached by\n" + 
							"satisfying all the constraints. Move on to the next level to learn more!",
							null, 
							null, 
							Constants.BOTTOM, null);
						m_currentTutorialText = tip;
						tips.push(tip);
						dispatchEvent(new TutorialEvent(TutorialEvent.NEW_TUTORIAL_TEXT, "", true, tips));
					}
					break;
				case "002":
					tip = new TutorialManagerTextInfo(levelGraph.unsatisfiedConstraintDict["c_4"] ? "constraint\nwith\nparadox" : "paradox\nremoved!", null, pointToNode("c_4"), Constants.TOP, Constants.TOP);
					tips.push(tip);
					tip = new TutorialManagerTextInfo(levelGraph.unsatisfiedConstraintDict["c_9"] ? "constraint\nwith\nparadox" : "paradox\nremoved!", null, pointToNode("c_9"), Constants.TOP, Constants.TOP);
					tips.push(tip);
					m_currentToolTipsText = tips;
					dispatchEvent(new TutorialEvent(TutorialEvent.NEW_TOOLTIP_TEXT, "", true, tips));
					break;
				case "01":
					var var_98011_1:ConstraintVar = levelGraph.variableDict["var_98011"];
					var var_98019_1:ConstraintVar = levelGraph.variableDict["var_98019"];
					if (var_98011_1 && var_98011_1.getValue().intVal == 1) {
						tip = new TutorialManagerTextInfo("Paradox", null, pointToNode("c_74452"), Constants.TOP, Constants.TOP);
						tips.push(tip);
					}
					if (var_98019_1 && var_98019_1.getValue().intVal == 1) {
						tip = new TutorialManagerTextInfo("Paradox", null, pointToNode("c_74407"), Constants.TOP, Constants.TOP);
						tips.push(tip);
					}
					m_currentToolTipsText = tips;
					dispatchEvent(new TutorialEvent(TutorialEvent.NEW_TOOLTIP_TEXT, "", true, tips));
					break;
				case "02":
					var var_98011_2:ConstraintVar = levelGraph.variableDict["var_98011"];
					var var_98019_2:ConstraintVar = levelGraph.variableDict["var_98019"];
					if (var_98011_2 && var_98011_2.getValue().intVal == 1) {
						tip = new TutorialManagerTextInfo("Paradox", null, pointToNode("c_74452"), Constants.TOP, Constants.TOP);
						tips.push(tip);
					}
					if (var_98019_2 && var_98019_2.getValue().intVal == 1) {
						tip = new TutorialManagerTextInfo("Paradox", null, pointToNode("c_74407"), Constants.TOP, Constants.TOP);
						tips.push(tip);
					}
					if (tips.length == 0) {
						tip = new TutorialManagerTextInfo("To remove this paradox two others\nwould be created, so leaving this\nparadox is the optimal solution", null, pointToNode("c_111708"), Constants.TOP, Constants.TOP);
						tips.push(tip);
					} else {
						tip = new TutorialManagerTextInfo("Paradox", null, pointToNode("c_111708"), Constants.BOTTOM, Constants.BOTTOM);
						tips.push(tip);
					}
					m_currentToolTipsText = tips;
					dispatchEvent(new TutorialEvent(TutorialEvent.NEW_TOOLTIP_TEXT, "", true, tips));
					break;
				case "04":
					num = 0;
					longConflictFound = false;
					for (key in levelGraph.unsatisfiedConstraintDict) {
						num++;
						if (key == "c_80002" || key == "c_150843" || key == "c_13896") longConflictFound = true;
					}
					if (num == 1 && longConflictFound) {
						tip = new TutorialManagerTextInfo("Try selecting from here   ", null, pointToNode("var_86825"), Constants.LEFT, Constants.LEFT);
						tips.push(tip);
						tip = new TutorialManagerTextInfo("To here", null, pointToNode("var_86622"), Constants.TOP_RIGHT, Constants.TOP_RIGHT);
						tips.push(tip);
						tip = new TutorialManagerTextInfo("To here", null, pointToNode("var_86623"), Constants.TOP_LEFT, Constants.TOP_LEFT);
						tips.push(tip);
					}
					m_currentToolTipsText = tips;
					dispatchEvent(new TutorialEvent(TutorialEvent.NEW_TOOLTIP_TEXT, "", true, tips));
					break;
				case "6":
					num = 0;
					longConflictFound = false;
					for (key in levelGraph.unsatisfiedConstraintDict) {
						num++;
						if (key == "c_61618" || key == "c_102237" || key == "c_27250") longConflictFound = true;
					}
					if (num == 1 && longConflictFound) {
						tip = new TutorialManagerTextInfo("Try selecting\nfrom here", null, pointToNode("c_61618"), Constants.BOTTOM, Constants.BOTTOM);
						tips.push(tip);
						tip = new TutorialManagerTextInfo("To here", null, pointToNode("var_2596"), Constants.TOP_LEFT, Constants.TOP_LEFT);
						tips.push(tip);
						tip = new TutorialManagerTextInfo("To here", null, pointToNode("var_2646"), Constants.TOP_LEFT, Constants.TOP_LEFT);
						tips.push(tip);
						tip = new TutorialManagerTextInfo("To here", null, pointToNode("var_2657"), Constants.BOTTOM_RIGHT, Constants.BOTTOM_RIGHT);
						tips.push(tip);
						tip = new TutorialManagerTextInfo("To here and this\nwhole cluster", null, pointToNode("var_3561"), Constants.BOTTOM_RIGHT, Constants.BOTTOM_RIGHT);
						tips.push(tip);
					}
					m_currentToolTipsText = tips;
					dispatchEvent(new TutorialEvent(TutorialEvent.NEW_TOOLTIP_TEXT, "", true, tips));
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
				case "001":
				case "002":
				case "01":
				case "004":
				case "02":
				case "005":
				case "03":
				case "04":
				case "1":
					return false;
			}
			return true;
		}
		
		public function getMiniMapShown():Boolean
		{
			switch (m_tutorialTag) {
				case "001":
				case "002":
				case "01":
				case "004":
				case "02":
				case "005":
				case "03":
				case "04":
				case "1":
				case "2":
				case "3":
				case "4":
				case "5":
				case "6":
				case "7":
				case "8":
				case "10":
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
				case "001":
				case "002":
				case "01":
				case "02":
					return 0.75;
				case "2":
					return 1.3;
				case "004":
					return 0.95;
				case "005":
				case "03":
				case "04":
				case "1":
				case "3":
				case "4":
				case "5":
				case "6":
				case "7":
				case "8":
				case "10":
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
				case "001":
				case "01":
				case "004":
				case "02":
				case "005":
				case "03":
				case "04":
				case "1":
					return new Point(0, 10); // shift level down by 10px
				case "002":
					return new Point(-50, 0); // shift level left by 50px
				case "2":
				case "3":
				case "4":
				case "5":
				case "6":
				case "7":
				case "8":
					return new Point();
			}
			return new Point();
		}
		
		public function getMaxSelectableWidgets():int
		{
			if (PipeJam3.SELECTION_STYLE != PipeJam3.SELECTION_STYLE_CLASSIC) {
				switch (m_tutorialTag) {
					case "001":
					case "002":
						return 2;
					case "01":
					case "004":
					case "02":
					case "005":
						return 5;
					case "03":
					case "04":
						return 20;
					case "1":
						return 30;
					case "2":
						return 50;
					case "3":
					case "4":
					case "5":
						return 75;
					case "6":
					case "7":
					case "8":
						return 100;
					case "10":
						return 125;
				}
				return 250;
			} else {
				switch (m_tutorialTag) {
					case "001":
					case "002":
					case "01":
					case "004":
					case "02":
					case "005":
						return 10;
					case "03":
					case "04":
						return 50;
					case "1":
						return 100;
					case "2":
						return 150;
					case "3":
					case "4":
					case "5":
						return 225;
					case "6":
					case "7":
					case "8":
						return 350;
					case "10":
						return 400;
					case "12":
						return 1000;
					case "13":
					case "14":
						return 2000;
				}
			}
			return -1;
		}
		
		public function getPerformSmallAutosolveGroupCheck():Boolean
		{
			switch (m_tutorialTag) {
				case "001":
				case "002":
				case "01":
				case "004":
				case "02":
				case "005":
					return false;
				case "03":
				case "04":
				case "1":
				case "2":
				case "3":
				case "4":
				case "5":
				case "6":
				case "7":
				case "8":
				case "10":
					return true;
			}
			return true;
		}
		
		public function getVisibleBrushes():int
		{
			var brushes:int = 0;

			switch (m_tutorialTag) {
				case "001":
					brushes = WIDEN_BRUSH;
					break;
				case "002":
				case "01":
					brushes = WIDEN_BRUSH | NARROW_BRUSH;
					break;
				case "004":
				case "02":
					brushes = WIDEN_BRUSH | NARROW_BRUSH;
					if (GameConfig.ENABLE_SOLVER1_BRUSH) brushes = brushes | SOLVER1_BRUSH;
					else if (GameConfig.ENABLE_SOLVER2_BRUSH) brushes = brushes | SOLVER2_BRUSH;
					break;
				case "005":
					brushes = WIDEN_BRUSH | NARROW_BRUSH;
					if (GameConfig.ENABLE_SOLVER2_BRUSH) brushes = brushes | SOLVER2_BRUSH;
					else if (GameConfig.ENABLE_SOLVER1_BRUSH) brushes = brushes | SOLVER1_BRUSH;
					break;
				case "03":
				case "04":
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
				default:
					brushes = WIDEN_BRUSH | NARROW_BRUSH;
					if (GameConfig.ENABLE_SOLVER1_BRUSH) brushes = brushes | SOLVER1_BRUSH;
					if (GameConfig.ENABLE_SOLVER2_BRUSH) brushes = brushes | SOLVER2_BRUSH;
					break;
			}
			return brushes;
		}
		
		public function getStartingBrush():Number
		{
			switch (m_tutorialTag) {
				case "002":
				case "01":
				case "004":
				case "02":
				case "005":
					return WIDEN_BRUSH
			}
			return NaN;
		}
		
		public function emphasizeBrushes():int
		{
			switch(m_tutorialTag) {
				case "002":
				case "01":
					return NARROW_BRUSH;
				case "004":
				case "02":
					if (GameConfig.ENABLE_SOLVER1_BRUSH) return SOLVER1_BRUSH;
				case "005":
					if (GameConfig.ENABLE_SOLVER2_BRUSH) return SOLVER2_BRUSH;
			}
			return 0x0;
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
				case "001":
					tip = new TutorialManagerTextInfo("variable", null, pointToNode("var_1"), Constants.BOTTOM_RIGHT, Constants.CENTER);
					tips.push(tip);
					tip = new TutorialManagerTextInfo("variable", null, pointToNode("var_2"), Constants.BOTTOM_LEFT, Constants.CENTER);
					tips.push(tip);
					
					tip = new TutorialManagerTextInfo("constraint", null, pointToNode("c_4"), Constants.TOP, Constants.TOP);
					tips.push(tip);
					tip = new TutorialManagerTextInfo("constraint", null, pointToNode("c_9"), Constants.TOP, Constants.TOP);
					tips.push(tip);
					break;
				case "002":
					tip = new TutorialManagerTextInfo("constraint\nwith\nparadox", null, pointToNode("c_4"), Constants.TOP, Constants.TOP);
					tips.push(tip);
					tip = new TutorialManagerTextInfo("constraint\nwith\nparadox", null, pointToNode("c_9"), Constants.TOP, Constants.TOP);
					tips.push(tip);
					break;
				case "01":
					tip = new TutorialManagerTextInfo("Paradox", null, pointToNode("c_74452"), Constants.TOP, Constants.TOP);
					tips.push(tip);
					tip = new TutorialManagerTextInfo("Paradox", null, pointToNode("c_74407"), Constants.TOP, Constants.TOP);
					tips.push(tip);
					break;
				case "02":
					tip = new TutorialManagerTextInfo("Paradox", null, pointToNode("c_74452"), Constants.TOP, Constants.TOP);
					tips.push(tip);
					tip = new TutorialManagerTextInfo("Paradox", null, pointToNode("c_74407"), Constants.TOP, Constants.TOP);
					tips.push(tip);
					tip = new TutorialManagerTextInfo("Paradox", null, pointToNode("c_111708"), Constants.BOTTOM, Constants.BOTTOM);
					tips.push(tip);
					break;
			}
			return tips;
		}
			
		public function getSplashScreen():Image
		{
			switch (m_tutorialTag) {
				case "002":
					var splashText:Texture = AssetInterface.getTexture("Game", "ConstraintsSplashClass" + PipeJam3.ASSET_SUFFIX);
					var splash:Image = new Image(splashText);
					return splash;
			}
			return null;
		}
		
		public function continueButtonDelay():Number
		{
			switch (m_tutorialTag) {
				case "001":
					return 4.0;
			}
			return 0;
		}
		
		public function showFanfare():Boolean
		{
			switch (m_tutorialTag) {
				case "001":
					return true;
			}
			return true;
		}
		
		public function getTextInfo():TutorialManagerTextInfo
		{
			if (m_currentTutorialText != null) return m_currentTutorialText;
			var text:String = null;
			switch (m_tutorialTag) {
				case "001":
					return new TutorialManagerTextInfo(
						StringTable.lookup(StringTable.INTRO_VARIABLES),
						null,
						null,
						null, null);
				case "002":
					return new TutorialManagerTextInfo(
						StringTable.lookup(StringTable.SELECTOR_UNLOCKED),
						null,
						null,
						Constants.RIGHT, null);
				case "01":
					return new TutorialManagerTextInfo(
						StringTable.lookup(StringTable.ELIMINATE_PARADOX),
						null,
						null,
						null, null);
				case "004":
					if (GameConfig.ENABLE_SOLVER1_BRUSH)      text = StringTable.lookup(StringTable.INTRO_SOLVER1_BRUSH);
					else if (GameConfig.ENABLE_SOLVER2_BRUSH) text = StringTable.lookup(StringTable.INTRO_SOLVER2_BRUSH);
					else                                    text = StringTable.lookup(StringTable.ELIMINATE_PARADOX);
					return new TutorialManagerTextInfo(
						text,
						null,
						null,
						null, null);
				case "02":
					if (GameConfig.ENABLE_SOLVER1_BRUSH)      text = StringTable.lookup(StringTable.FUNCTION_SOLVER1_BRUSH);
					else if (GameConfig.ENABLE_SOLVER2_BRUSH) text = StringTable.lookup(StringTable.FUNCTION_SOLVER2_BRUSH);
					else                                    text = StringTable.lookup(StringTable.ELIMINATE_PARADOX);
					return new TutorialManagerTextInfo(
						text,
						null,
						null,
						null, null);
				case "005":
					if (GameConfig.ENABLE_SOLVER2_BRUSH && GameConfig.ENABLE_SOLVER1_BRUSH)       text = StringTable.lookup(StringTable.BOTH_BRUSHES_ENABLED);
					else if (GameConfig.ENABLE_SOLVER2_BRUSH && !GameConfig.ENABLE_SOLVER1_BRUSH) text = StringTable.lookup(StringTable.ELIMINATE_PARADOX);
					else if (GameConfig.ENABLE_SOLVER1_BRUSH)                                   text = StringTable.lookup(StringTable.ELIMINATE_PARADOX);
					else                                                                      text = StringTable.lookup(StringTable.ELIMINATE_PARADOX);
					return new TutorialManagerTextInfo(
						text,
						null,
						null,
						null, null);
				case "03":
					return new TutorialManagerTextInfo(
						StringTable.lookup(StringTable.INFORM_LIMITS),
						null,
						null,
						null, null);
				case "04":
					return new TutorialManagerTextInfo(
						StringTable.lookup(StringTable.INTRO_SELECTION_AREAS),
						null,
						null,
						null, null);
				case "2":
					return new TutorialManagerTextInfo(
						StringTable.lookup(StringTable.INTRO_ZOOM),
						null,
						null,
						null, null);
				case "1":
				case "3":
				case "4":
				case "5":
				case "6":
				case "7":
				case "8":
				case "10":
				case "13":
				case "14":
					return new TutorialManagerTextInfo(
						StringTable.lookup(StringTable.ELIMINATE_PARADOX),
						null,
						null,
						null, null);
				case "12":
					return new TutorialManagerTextInfo(
						StringTable.lookup(StringTable.MINIMAP),
						null,
						null,
						Constants.TOP_LEFT, null);
				
					return null;
			}
			return null;
		}
	}
}
