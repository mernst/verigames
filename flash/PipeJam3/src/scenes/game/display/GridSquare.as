package scenes.game.display
{
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.Dictionary;
	
	import assets.AssetsAudio;
	
	import audio.AudioManager;
	
	import constraints.ConstraintVar;
	import constraints.events.VarChangeEvent;
	
	import events.SelectionEvent;
	import events.UndoEvent;
	
	import graph.PropDictionary;
	
	import starling.display.Quad;
	import starling.display.Sprite;
	import starling.events.Event;
	import starling.events.Touch;
	import starling.events.TouchEvent;
	import starling.events.TouchPhase;

	public class GridSquare
	{
		public var id:String;
		
		protected var nodeDrawingBoard:Sprite;
		protected var groupDrawingBoard:Sprite;
		protected var edgeDrawingBoard:Sprite;
		protected var nodeList:Vector.<Node>;
		protected var groupList:Vector.<NodeGroup>;
		protected var edgeList:Array;
		public var NumNodesSelected:int = 0;
		public var visited:Boolean = false;
		public var isDirty:Boolean = true;
		protected var isActivated:Boolean = false;
		
		protected var gridXOffset:Number;
		protected var gridYOffset:Number;
		
		public var m_errorProps:PropDictionary;
		
		public var componentXDisplacement:Number;
		public var componentYDisplacement:Number;
		
		private static const LINE_THICKNESS:Number = 5;
		static public const SKIN_DIAMETER:Number = 20;
		
		private var m_bb:Rectangle;
		
		public function GridSquare( x:Number, y:Number, height:Number, width:Number)
		{
			id = x+"_"+y;
			gridXOffset = x;
			gridYOffset = y;
			componentXDisplacement = gridXOffset*Level.GRID_SIZE;
			componentYDisplacement = gridYOffset*Level.GRID_SIZE;
			nodeList = new Vector.<Node>();
			groupList = new Vector.<NodeGroup>();
			edgeList = new Array;
		}
		
		protected function onTouch(event:TouchEvent):void
		{
			var touchedDrawingBoard:Sprite;
			if (event.getTouches(nodeDrawingBoard, TouchPhase.ENDED).length) {
				touchedDrawingBoard = nodeDrawingBoard;
			} else if (event.getTouches(groupDrawingBoard, TouchPhase.ENDED).length) {
				touchedDrawingBoard = groupDrawingBoard;
			} else {
				return;
			}
			var touches:Vector.<Touch> = event.getTouches(touchedDrawingBoard, TouchPhase.ENDED);
			var loc:Point = touches[0].getLocation(touchedDrawingBoard);
			var gridChild:GridChild = findNodeAtPoint(loc);
			if(gridChild)
			{
				if(!event.shiftKey)
				{
					if(!gridChild.isLocked)
					{
						var globPt:Point = touchedDrawingBoard.localToGlobal(loc);
						var node:Node;
						if (gridChild is Node) {
							node = gridChild as Node;
							onClicked(node, !node.isNarrow, true, globPt);
							if (node.isEditable && !node.graphVar.constant) {
								if (!node.isNarrow) {
									// Wide
									AudioManager.getInstance().audioDriver().playSfx(AssetsAudio.SFX_LOW_BELT);
								} else {
									// Narrow
									AudioManager.getInstance().audioDriver().playSfx(AssetsAudio.SFX_HIGH_BELT);
								}
							}
						} else if (gridChild is NodeGroup) {
							var nodeGroup:NodeGroup = gridChild as NodeGroup;
							nodeGroup.isNarrow = !nodeGroup.isNarrow;
							nodeGroup.setDirty(true);
							if (!nodeGroup.isNarrow) {
								// Wide (after it will be changed)
								AudioManager.getInstance().audioDriver().playSfx(AssetsAudio.SFX_LOW_BELT);
							} else {
								// Narrow
								AudioManager.getInstance().audioDriver().playSfx(AssetsAudio.SFX_HIGH_BELT);
							}
							for each (node in nodeGroup.nodeDict)
							{
								onClicked(node, nodeGroup.isNarrow, false);
							}
							nodeGroup.calculateNodeInfo();
							var changeEvent:VarChangeEvent = new VarChangeEvent(VarChangeEvent.VAR_CHANGE_USER, null, PropDictionary.PROP_NARROW, nodeGroup.isNarrow, null);
							nodeDrawingBoard.dispatchEvent(changeEvent);
						}
					}
				}
				//disable individual node selection for paint 
				//else
				//{
					//if(!event.ctrlKey)
					//{
						//if(!gridChild.isSelected)
							//gridChild.select(World.m_world.active_level.selectedNodes);
						//else
							//gridChild.unselect(World.m_world.active_level.selectedNodes);
					//}
					//else
					//{
						//touchedDrawingBoard.dispatchEvent(new SelectionEvent(SelectionEvent.GROUP_SELECTED, gridChild));
					//}
				//}
			}
		}
		
		private function findNodeAtPoint(pt:Point):GridChild
		{
			for each(var node:Node in nodeList)
			{
				if(pt.x < node.bb.left - componentXDisplacement - .5*SKIN_DIAMETER) continue;
				if(pt.x > node.bb.right - componentXDisplacement + .5*SKIN_DIAMETER) continue;
				if(pt.y < node.bb.top - componentYDisplacement - .5*SKIN_DIAMETER) continue;
				if(pt.y > node.bb.bottom - componentYDisplacement + .5*SKIN_DIAMETER) continue;
				return node;
			}
			for each(var nodeGroup:NodeGroup in groupList)
			{
				if(pt.x < nodeGroup.bb.left - componentXDisplacement - .5*nodeGroup.bb.width) continue;
				if(pt.x > nodeGroup.bb.right - componentXDisplacement + .5*nodeGroup.bb.width) continue;
				if(pt.y < nodeGroup.bb.top - componentYDisplacement - .5*nodeGroup.bb.height) continue;
				if(pt.y > nodeGroup.bb.bottom - componentYDisplacement + .5*nodeGroup.bb.height) continue;
				return nodeGroup;
			}
			return null;
		}
		
		private function onClicked(node:Node, newIsNarrow:Boolean, dispatchChangeEvent:Boolean, loc:Point = null):void
		{
			var constraintVar:ConstraintVar = node.graphVar;
			if (!constraintVar.constant && node.isEditable && node.isNarrow != newIsNarrow) {
				node.isNarrow = newIsNarrow
				isDirty = true;
				node.setDirty(true);
				if (dispatchChangeEvent) {
					var changeEvent:VarChangeEvent = new VarChangeEvent(VarChangeEvent.VAR_CHANGE_USER, constraintVar, PropDictionary.PROP_NARROW, node.isNarrow, loc);
					nodeDrawingBoard.dispatchEvent(changeEvent);
				}
			}
		}
		
		public function addGridChild(gridChild:GridChild):void
		{
			if (gridChild is NodeGroup) {
				groupList.push(gridChild as NodeGroup);
			} else if (gridChild is Node) {
				nodeList.push(gridChild as Node);
			}
			gridChild.createSkin();
		}
		
		public function get bb():Rectangle
		{
			if (!m_bb) calculateBounds();
			return m_bb.clone();
		}
		
		public function calculateBounds():void
		{
			var minX:Number = Number.POSITIVE_INFINITY;
			var minY:Number = Number.POSITIVE_INFINITY;
			var maxX:Number = Number.NEGATIVE_INFINITY;
			var maxY:Number = Number.NEGATIVE_INFINITY;
			for each (var node:Node in nodeList) {
				minX = Math.min(minX, node.bb.left);
				minY = Math.min(minY, node.bb.top);
				maxX = Math.max(maxX, node.bb.right);
				maxY = Math.max(maxY, node.bb.bottom);
			}
			for each (var nodeGroup:NodeGroup in groupList) {
				minX = Math.min(minX, nodeGroup.bb.left);
				minY = Math.min(minY, nodeGroup.bb.top);
				maxX = Math.max(maxX, nodeGroup.bb.right);
				maxY = Math.max(maxY, nodeGroup.bb.bottom);
			}
			m_bb = new Rectangle(minX, minY, maxX - minX, maxY - minY);
		}
		
		protected function onAddedToStage(event:starling.events.Event):void
		{
		}

		public function activate():void
		{			
			if(!isActivated)
			{
				if(nodeDrawingBoard)
					nodeDrawingBoard.removeFromParent(true);
				if(groupDrawingBoard)
					groupDrawingBoard.removeFromParent(true);
				if(edgeDrawingBoard)
					edgeDrawingBoard.removeFromParent(true);
				nodeDrawingBoard = new Sprite;
				groupDrawingBoard = new Sprite;
				edgeDrawingBoard = new Sprite;
				
				nodeDrawingBoard.addEventListener(TouchEvent.TOUCH, onTouch);
				groupDrawingBoard.addEventListener(TouchEvent.TOUCH, onTouch);

				edgeList = new Array;
				for each(var node:Node in nodeList)
				{											
					if (!node.skin) node.createSkin();
					createEdges(node);
				}
				
				for each(var nodeGroup:NodeGroup in groupList)
				{
					if (!nodeGroup.skin) nodeGroup.createSkin();
				}
				
				nodeDrawingBoard.x = componentXDisplacement;
				nodeDrawingBoard.y = componentYDisplacement;
				groupDrawingBoard.x = componentXDisplacement;
				groupDrawingBoard.y = componentYDisplacement;
				edgeDrawingBoard.x = componentXDisplacement;
				edgeDrawingBoard.y = componentYDisplacement;
				World.m_world.active_level.addChildToGroupLevel(groupDrawingBoard);
				World.m_world.active_level.addChildToNodeLevel(nodeDrawingBoard);
				World.m_world.active_level.addChildToEdgeLevel(edgeDrawingBoard);
				nodeDrawingBoard.flatten();
				groupDrawingBoard.flatten();
				edgeDrawingBoard.flatten();
				isActivated = true;
				isDirty = true;
			}
		}
		
		/*
		 * Used to show which GridSquare is being referenced for debug
		 */
		private var debugQ:Quad;
		public function showDebugQuad():void
		{
			if (nodeDrawingBoard) {
				hideDebugQuad();
				const BORD:Number = 5.0;
				debugQ = new Quad(Level.GRID_SIZE - 2 * BORD, Level.GRID_SIZE - 2 * BORD, 0x0);
				debugQ.x = BORD;
				debugQ.y = BORD;
				debugQ.alpha = 0.2;
				nodeDrawingBoard.addChild(debugQ);
				nodeDrawingBoard.flatten();
			}
		}
		
		public function hideDebugQuad():void
		{
			if (debugQ) debugQ.removeFromParent(true);
		}
		
		public function showGroups():void
		{
			for each (var nodeGroup:NodeGroup in groupList)
			{
				nodeGroup.isDirty = true;
			}
			isDirty = true;
		}
		
		public function hideGroups():void
		{
			for each (var nodeGroup:NodeGroup in groupList)
			{
				nodeGroup.removeSkin();
			}
			isDirty = true;
		}
		
		public function draw():void
		{
			if(!isDirty)
				return;
			nodeDrawingBoard.unflatten();
			groupDrawingBoard.unflatten();
			edgeDrawingBoard.unflatten();
			for each(var node:Node in nodeList)
			{
				if(node.isDirty)
				{
					node.createSkin();
					nodeDrawingBoard.addChild(node.skin);
					
					for each(var gameEdgeID:String in node.connectedEdgeIds)
					{
						var edgeObj:Object = World.m_world.active_level.edgeLayoutObjs[gameEdgeID];
						if(edgeObj.edgeSprite && edgeObj.isDirty) //needs to be created  before here if we want it
						{
							updateEdge(edgeObj);
							if(edgeObj.edgeSprite.parent != edgeDrawingBoard)
							{
								if(edgeObj.edgeSprite.parent != null)
								{
									//move to current gridsquare and adjust x/y boundaries to force drawing
									var currentXOffset:Number = edgeObj.parentXOffset;
									var currentYOffset:Number = edgeObj.parentYOffset;
									
									var toNodeID:String = edgeObj["to_var_id"];
									var toNodeObj:Object = World.m_world.active_level.nodeLayoutObjs[toNodeID];
									var fromNodeID:String = edgeObj["from_var_id"];
							 		var fromNodeObj:Object = World.m_world.active_level.nodeLayoutObjs[fromNodeID];
									
									edgeObj.edgeSprite.x += currentXOffset*Level.GRID_SIZE;
									edgeObj.edgeSprite.x -= componentXDisplacement;
									edgeObj.edgeSprite.y += currentYOffset*Level.GRID_SIZE;
									edgeObj.edgeSprite.y -= componentYDisplacement;
									edgeDrawingBoard.addChild(edgeObj.edgeSprite);
									edgeObj.parentXOffset = gridXOffset;
									edgeObj.parentYOffset = gridYOffset;
								}
							}
							
							if(edgeObj.edgeSprite.parent.parent == null)
								World.m_world.active_level.addChildToEdgeLevel(edgeDrawingBoard);
						}
						
					}
					node.isDirty = false;
				}
				else if (node.filterIsDirty && node.skin is NodeSkin)
				{
					(node.skin as NodeSkin).updateFilter();
					node.filterIsDirty = false;
				}
			}
			for each (var nodeGroup:NodeGroup in groupList)
			{
				if (nodeGroup.isDirty) nodeGroup.createSkin();
				nodeGroup.isDirty = false;
				if (nodeGroup.skin) groupDrawingBoard.addChild(nodeGroup.skin);
			}
			nodeDrawingBoard.flatten();
			groupDrawingBoard.flatten();
			edgeDrawingBoard.flatten();
			isDirty = false;
		}
		
		protected function createEdges(node:Node):void
		{
			for each(var gameEdgeID:String in node.connectedEdgeIds)
			{
				var edgeObj:Object = World.m_world.active_level.edgeLayoutObjs[gameEdgeID];
				edgeList.push(edgeObj);
				if(edgeObj.edgeSprite == null)
				{
					createEdge(edgeObj);
				}
			}
		}
		
		private function createEdge(edge:Object):void
		{
			var toNodeID:String = edge["to_var_id"];
			var toNodeObj:Node = World.m_world.active_level.nodeLayoutObjs[toNodeID];
			var fromNodeID:String = edge["from_var_id"];
			var fromNodeObj:Node = World.m_world.active_level.nodeLayoutObjs[fromNodeID];

			if(fromNodeObj == toNodeObj) return;
			
			edge.edgeSprite = drawLine(fromNodeObj, toNodeObj);
			edge.parentXOffset = gridXOffset;
			edge.parentYOffset = gridYOffset;
			edge.isDirty = true;
		}
		
		private function updateEdge(edge:Object):void
		{
			if(edge.edgeSprite)
			{	
				var toNodeID:String = edge["to_var_id"];
				var toNodeObj:Node = World.m_world.active_level.nodeLayoutObjs[toNodeID];
				var fromNodeID:String = edge["from_var_id"];
				var fromNodeObj:Node = World.m_world.active_level.nodeLayoutObjs[fromNodeID];
				
				edge.edgeSprite.parent.unflatten();
				setupLine(fromNodeObj, toNodeObj, edge.edgeSprite, true);
				edge.edgeSprite.parent.flatten();
			}
			edge.isDirty = false;
		}
		
		//need to keep track of lines
		public function drawLine(fromNode:Node, toNode:Node):Quad
		{
			var p1:Point = fromNode.centerPoint;
			var p2:Point = toNode.centerPoint;
			//a^2 + b^2 = c^2
			var a:Number = (p2.x - p1.x) * (p2.x - p1.x);
			var b:Number = (p2.y - p1.y) * (p2.y - p1.y);
			var hyp:Number = Math.sqrt(a+b);
			
			//draw the quad flat, rotate later
			var lineQuad:Quad = new Triangle(hyp, LINE_THICKNESS);
			setupLine(fromNode, toNode, lineQuad, true);
			//trace("drawing Line from ", fromNodeObj.id, " -> ", toNodeObj.id);
			var otherEdgeId:String = toNode.id + " -> " + fromNode.id;
			var otherEdgeObj:Object = World.m_world.active_level.edgeLayoutObjs[otherEdgeId];
			rotateLine(p1, p2, hyp, lineQuad, otherEdgeObj);
			
			if(edgeDrawingBoard == null)
				edgeDrawingBoard = new Sprite;
			edgeDrawingBoard.addChild(lineQuad);
			return lineQuad;
		}
		
		protected function rotateLine(p1:Point, p2:Point, hyp:Number, line:Quad, offsetDoubleLine:Boolean):void
		{
			//get theta
			//Sin(x) = opp/hyp
			var theta:Number = Math.asin( (p2.y-p1.y) / hyp );  // radians
			
			var dX:Number = p1.x - p2.x;
			var dY:Number = p1.y - p2.y;
			
			var centerDx:Number = 0;
			var centerDy:Number = 0;
			if (dX <= 0 && dY < 0) { // Q4
				// theta = theta
				centerDx = -0.5 * LINE_THICKNESS * Math.sin(theta);
				centerDy = -0.5 * LINE_THICKNESS * Math.cos(theta);
			} else if (dX > 0 && dY <= 0) { // Q3
				if (dY == 0) { // -180
					theta = -Math.PI;
				} else {
					theta = (Math.PI / 2) + ((Math.PI / 2) - theta);
				}
				centerDy = 0.5 * LINE_THICKNESS * Math.cos(theta);
			} else if (dX >= 0 && dY > 0) { // Q2
				theta = -Math.PI - theta;
				if (dX == 0) {
					centerDx = -0.5 * LINE_THICKNESS;
				}
			} else { // Q1
				centerDx = 0.5 * LINE_THICKNESS * Math.sin(theta);
				if (dY == 0) {
					centerDy = -0.5 * LINE_THICKNESS * Math.cos(theta);
				}
			}
			line.rotation = theta;
			
			if (offsetDoubleLine) {
				centerDx += 1.5 * Math.sin(theta);
				centerDy += 1.5 * Math.cos(theta);;
			}
			
			line.x = -line.bounds.left + Math.min(p1.x, p2.x) - componentXDisplacement + centerDx;
			line.y = -line.bounds.top + Math.min(p1.y, p2.y) -  componentYDisplacement + centerDy;
			
			//trace(centerDx, centerDy, theta, dX, dY, " <-- Line made");
		}
		
		private function setupLine(fromNodeObj:Node, toNodeObj:Node, lineQuad:Quad, line1:Boolean):void
		{
			var fromColor:int = NodeSkin.getColor(fromNodeObj);
			var toColor:int = NodeSkin.getColor(toNodeObj);
			var fromColorComplement:int = NodeSkin.getComplementColor(toNodeObj);
			
			if(!fromNodeObj.isNarrow && toNodeObj.isNarrow)
				toColor = 0xff0000;
			
			lineQuad.setVertexColor(0, fromColorComplement);
			lineQuad.setVertexColor(1, toColor);
			lineQuad.setVertexColor(2, fromColor);
			lineQuad.setVertexColor(3, fromColorComplement);
		}
		
		public function removeGridChild(gridChild:GridChild, dispose:Boolean = false):void
		{
			for each(var gameEdgeID:String in gridChild.connectedEdgeIds)
			{
				var edgeObj:Object = World.m_world.active_level.edgeLayoutObjs[gameEdgeID];
				if(edgeObj && edgeObj.edgeSprite)
				{
					//need to check if the other end is on screen, and if it is, pass this edge off to that node
					var toNodeID:String = edgeObj["to_var_id"];
					var toNodeObj:Object = World.m_world.active_level.nodeLayoutObjs[toNodeID];
					var fromNodeID:String = edgeObj["from_var_id"];
					var fromNodeObj:Object = World.m_world.active_level.nodeLayoutObjs[fromNodeID];
					
					var otherNode:Object = toNodeObj;
					if(toNodeObj == gridChild)
						otherNode = fromNodeObj;
					
					edgeObj.edgeSprite.removeFromParent(dispose);
					edgeObj.edgeSprite = null;
					
					//if the other end has a skin (it's on screen), but a different parent (not this one, that we are disposing of currently), attach this edge to that node
					if(otherNode && otherNode.skin && otherNode.skin.parent != nodeDrawingBoard)
					{
						//destroy edge and recreate
						otherNode.parentGrid.createEdges(otherNode);
						otherNode.parentGrid.isDirty = true;
						otherNode.isDirty = true;
					}
				}
			}
			gridChild.removeSkin();
		}
		
		public function removeFromParent(dispose:Boolean):void
		{
			for each (var node:Node in nodeList) {
				removeGridChild(node, dispose);
			}
			nodeDrawingBoard.removeFromParent(dispose);
			groupDrawingBoard.removeFromParent(dispose);
			edgeDrawingBoard.removeFromParent(dispose);
			isActivated = false;
		}
		
		public function handleMarqueeSelection(marqueeRect:Rectangle, selectedNodes:Dictionary):void
		{
			if(marqueeRect.intersects(bb))
			{
				if(visited == false)
				{
					//record the current selection state of all nodes
					for(var ii:int = 0; ii< nodeList.length; ii++)
					{
						var node1:Node = nodeList[ii];
						var nodeSelected:Boolean = node1.isSelected ? true : false
						node1.startingSelectionState = nodeSelected;
					}
					visited = true;
				}
				else
				{
					for(var i:int = 0; i < nodeList.length; i++)
					{
						var node:Node = nodeList[i];
						if (!node.skin) continue;
						if (node.centerPoint.x < marqueeRect.left ||
							node.centerPoint.x > marqueeRect.right ||
							node.centerPoint.y < marqueeRect.top ||
							node.centerPoint.y > marqueeRect.bottom) {
							// If out of rect (most likely scenario) unselect if selected
							if (node.startingSelectionState) node.unselect(selectedNodes);
							continue;
						}
						if (!node.startingSelectionState) node.select(selectedNodes);
					}
				}
			}
		}
		
		public function handlePaintSelection(paintPt:Point, paintRadiusSquared:Number, selectedNodes:Dictionary):void
		{
			for(var i:int = 0; i < nodeList.length; i++)
			{
				var node:Node = nodeList[i];
				if (!node.skin) continue;
				if (node.graphVar.constant) continue;
				var dX:Number = paintPt.x - node.centerPoint.x;
				var dY:Number = paintPt.y - node.centerPoint.y;
				if (dX * dX > paintRadiusSquared) continue;
				if (dY * dY > paintRadiusSquared) continue;
				if (dX * dX + dY * dY <= paintRadiusSquared && !node.isSelected) node.select(selectedNodes);
			}
		}
		
		public function markVisited():void
		{
			visited = true;
		}
		
		public function unselectAll():void
		{
			if(NumNodesSelected)
			{
				nodeDrawingBoard.unflatten();
				for(var i:int = 0; i< nodeList.length; i++)
				{
					var node:Node = nodeList[i];
					if(node.isSelected == true)
					{
						node.isSelected = false;
						node.setDirty(false);
					}
				}
				nodeDrawingBoard.flatten();
				groupDrawingBoard.unflatten();
				for each (var nodeGroup:NodeGroup in groupList)
				{
					if (nodeGroup.isSelected) {
						nodeGroup.isSelected = false;
						nodeGroup.setDirty(false);
					}
				}
				groupDrawingBoard.flatten();
				NumNodesSelected = 0;
			}
			
		}
		
		public function updateSelectedNodesAssignment(assignmentIsWide:Boolean):void
		{
			if(NumNodesSelected)
			{
				if(nodeDrawingBoard)
					nodeDrawingBoard.unflatten();
				for(var index:int = 0; index<nodeList.length; index++)
				{
					var node:Node = nodeList[index];
					if(node.isSelected && !node.isLocked)
						node.updateSelectionAssignment(assignmentIsWide, World.m_world.active_level.levelGraph);
				}
				isDirty = true;
				if(nodeDrawingBoard)
					nodeDrawingBoard.flatten();
			}
		}
		

		public function updateSelectedEdges():void
		{
			if(NumNodesSelected)
			{
				if(edgeDrawingBoard)
					edgeDrawingBoard.unflatten();
				for(var index:int = 0; index<nodeList.length; index++)
				{
					var node:Node = nodeList[index];
					for each(var gameEdgeID:String in node.connectedEdgeIds)
					{
						var edgeObj:Object = World.m_world.active_level.edgeLayoutObjs[gameEdgeID];
						updateEdge(edgeObj);
						edgeList.push(edgeObj);
					}
				}
				if(edgeDrawingBoard)
					edgeDrawingBoard.flatten();
			}
		}
		
		public function intersects(viewRect:Rectangle):Boolean
		{
			if (nodeDrawingBoard.bounds.intersects(viewRect) ||
				groupDrawingBoard.bounds.intersects(viewRect) ||
				edgeDrawingBoard.bounds.intersects(viewRect))
					return true;
			else
				return false
		}
	}
}