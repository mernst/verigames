package scenes.game.display
{
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.Dictionary;
	
	import assets.AssetInterface;
	
	import constraints.ConstraintGraph;
	import constraints.ConstraintVar;
	
	import events.EdgeContainerEvent;
	import events.ErrorEvent;
	import events.GameComponentEvent;
	import events.GroupSelectionEvent;
	import events.MoveEvent;
	import events.PropertyModeChangeEvent;
	import events.WidgetChangeEvent;
	
	import scenes.game.newdisplay.GameEdge;
	import scenes.game.newdisplay.GameNode2;
	
	import starling.display.BlendMode;
	import starling.display.Image;
	import starling.display.Sprite;
	import starling.textures.Texture;
	import constraints.Constraint;

	public class Level2 extends Level
	{
		
		public function Level2(_name:String, _levelGraph:ConstraintGraph, _levelObj:Object, _levelLayoutObj:Object, _levelAssignmentsObj:Object, _originalLevelName:String)
		{
			super(_name, _levelGraph, _levelObj, _levelLayoutObj, _levelAssignmentsObj, _originalLevelName);
		}
		
		override public function initialize():void
		{
			if (initialized) return;
			trace("Level.initialize()...");
			if (USE_TILED_BACKGROUND && !m_backgroundImage) {
				// TODO: may need to refine GridViewPanel .onTouch method as well to get this to work: if(this.m_currentLevel && event.target == m_backgroundImage)
				var background:Texture = AssetInterface.getTexture("Game", "BoxesGamePanelBackgroundImageClass");
				background.repeat = true;
				m_backgroundImage = new Image(background);
				m_backgroundImage.width = m_backgroundImage.height = 2 * MIN_BORDER;
				m_backgroundImage.x = m_backgroundImage.y = -MIN_BORDER;
				m_backgroundImage.blendMode = BlendMode.NONE;
				addChild(m_backgroundImage);
			}
			
			if (inactiveLayer == null)  inactiveLayer  = new Sprite();
			if (m_nodesInactiveContainer == null)  m_nodesInactiveContainer  = new Sprite();
			if (m_errorInactiveContainer == null)  m_errorInactiveContainer  = new Sprite();
			if (m_edgesInactiveContainer == null)  m_edgesInactiveContainer  = new Sprite();
			if (m_plugsInactiveContainer == null)  m_plugsInactiveContainer  = new Sprite();
			inactiveLayer.addChild(m_nodesInactiveContainer);
			inactiveLayer.addChild(m_errorInactiveContainer);
			inactiveLayer.addChild(m_edgesInactiveContainer);
			inactiveLayer.addChild(m_plugsInactiveContainer);
			
			if (m_nodesContainer == null)  m_nodesContainer  = new Sprite();
			if (m_errorContainer == null)  m_errorContainer  = new Sprite();
			if (m_edgesContainer == null)  m_edgesContainer  = new Sprite();
			if (m_plugsContainer == null)  m_plugsContainer  = new Sprite();
			//m_nodesContainer.filter = BlurFilter.createDropShadow(4.0, 0.78, 0x0, 0.85, 2, 1); //only works up to 2048px
			addChild(m_nodesContainer);
			addChild(m_errorContainer);
			addChild(m_edgesContainer);
			addChild(m_plugsContainer);
			
			this.alpha = .999;
			
			m_edgeList = new Vector.<GameEdge>;
			selectedComponents = new Vector.<GameComponent>;
			totalMoveDist = new Point();
			
			trace(m_levelLayoutObj["id"]);
			
			var minX:Number, minY:Number, maxX:Number, maxY:Number;
			minX = minY = Number.POSITIVE_INFINITY;
			maxX = maxY = Number.NEGATIVE_INFINITY;
			
			//create node for sets
			m_nodeList = new Vector.<GameNode2>(); 
			boxDictionary = new Dictionary();
			edgeContainerDictionary = new Dictionary();
			
			// Process <box> 's
			var visibleNodes:int = 0;
			for (var varId:String in m_levelLayoutObj["layout"]["vars"])
			{
				var gameNode:GameNode;
				var boxLayoutObj:Object = m_levelLayoutObj["layout"]["vars"][varId];
				if (!levelGraph.variableDict.hasOwnProperty(varId)) {
					throw new Error("Couldn't find edge set for var id: " + varId);
				} else {
					var constraintVar:ConstraintVar = levelGraph.variableDict[varId];
					
					gameNode = new GameNode2(boxLayoutObj, constraintVar, !m_layoutFixed);
					addChild(gameNode);
				}
				
				gameNode.addEventListener(WidgetChangeEvent.WIDGET_CHANGED, onWidgetChange);
				
				var boxVisible:Boolean = true;
				if (boxLayoutObj.hasOwnProperty("visible") && (boxLayoutObj["visible"] == "false")) boxVisible = false;
				if (boxVisible) {
					visibleNodes++;
					minX = Math.min(minX, gameNode.boundingBox.left);
					minY = Math.min(minY, gameNode.boundingBox.top);
					maxX = Math.max(maxX, gameNode.boundingBox.right);
					maxY = Math.max(maxY, gameNode.boundingBox.bottom);
				} else {
					gameNode.hideComponent(true);
					boxLayoutObj["visible"] = "false";
				}
				m_nodeList.push(gameNode);
				boxDictionary[varId] = gameNode;
			}
			trace("gamenodeset count = " + m_nodeList.length);
			
			// Process <line> 's
			var visibleLines:int = 0;
			for (var constraintId:String in m_levelLayoutObj["layout"]["constraints"])
			{
				var edgeLayoutObj:Object = m_levelLayoutObj["layout"]["constraints"][constraintId];
				var gameEdge:GameEdge = createLine(constraintId, edgeLayoutObj);
				if (!gameEdge.hidden) {
					var boundingBox:Rectangle = gameEdge.boundingBox;
					visibleLines++;
					minX = Math.min(minX, boundingBox.x);
					minY = Math.min(minY, boundingBox.y);
					maxX = Math.max(maxX, boundingBox.x + boundingBox.width);
					maxY = Math.max(maxY, boundingBox.y + boundingBox.height);
				}
			}
			
			//set bounds based on largest x, y found in boxes, joints, edges
			m_boundingBox = new Rectangle(minX, minY, maxX - minX, maxY - minY);
			trace("Level " + m_levelLayoutObj["id"] + " m_boundingBox = " + m_boundingBox);
			
			addEventListeners();
			
			//			trace(visibleNodes, visibleLines);
			
			setNodesFromAssignments(m_levelAssignmentsObj);
			//force update of conflict count dictionary, ignore return value
			getNextConflict(true);
			
			initialized = true;
		}
		
		private function createLine(edgeId:String, edgeLayoutObj:Object):GameEdge
		{
			var pattern:RegExp = /(.*) -> (.*)/i;
			var result:Object = pattern.exec(edgeId);
			if (result == null) throw new Error("Invalid constraint layout string found: " + edgeId);
			if (result.length != 3) throw new Error("Invalid constraint layout string found: " + edgeId);
			var edgeFromVarId:String = result[1];
			var edgeToVarId:String = result[2];
			if (!boxDictionary.hasOwnProperty(edgeFromVarId)) throw new Error("From var not found in boxDictionary:" + edgeFromVarId);
			if (!boxDictionary.hasOwnProperty(edgeToVarId)) throw new Error("To var not found in boxDictionary:" + edgeToVarId);
			var fromNode:GameNode2 = boxDictionary[edgeFromVarId] as GameNode2;
			var toNode:GameNode2 = boxDictionary[edgeToVarId] as GameNode2;
			if (!levelGraph.constraintsDict.hasOwnProperty(edgeId)) throw new Error("Edge not found in levelGraph.constraintsDict:" + edgeId);
			var constraint:Constraint = levelGraph.constraintsDict[edgeId];
			
			//create edge array
			var edgeArray:Array = new Array();
			var ptsArr:Array = edgeLayoutObj["pts"] as Array;
			if (!ptsArr) throw new Error("No layout pts found for edge:" + edgeId);
			if (ptsArr.length < 4) throw new Error("Not enough points found in layout for edge:" + edgeId);
			for (var i:int = 0; i < ptsArr.length; i++) {
				var ptx:Number = Number(ptsArr[i]["x"]);
				var pty:Number = Number(ptsArr[i]["y"]);
				var pt:Point = new Point(ptx * Constants.GAME_SCALE, pty * Constants.GAME_SCALE);
				edgeArray.push(pt);
			}
			
			var newGameEdge:GameEdge = new GameEdge(edgeId, edgeArray, fromNode, toNode, constraint, !m_layoutFixed);
			//if (!getVisible(edgeLayoutObj)) newGameEdge.hideComponent(true);
			
			m_edgeList.push(newGameEdge);
			
			//			if (edgeContainerDictionary.hasOwnProperty(edgeId) && (edgeContainerDictionary[edgeId] is GameEdgeContainer)) {
			//				var oldEdgeContainer:GameEdgeContainer = edgeContainerDictionary[edgeId] as GameEdgeContainer;
			//				if (m_edgeList.indexOf(oldEdgeContainer) > -1) {
			//					m_edgeList.splice(m_edgeList.indexOf(oldEdgeContainer), 1);
			//				}
			//				oldEdgeContainer.removeFromParent(true);
			//			}
			
			edgeContainerDictionary[edgeId] = newGameEdge;
			return newGameEdge;
		}
		

	}
}