package scenes.game.display
{
	import constraints.ConstraintClause;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.ui.Keyboard;
	import flash.utils.Dictionary;
	
	import assets.AssetsAudio;
	
	import audio.AudioManager;
	
	import constraints.ConstraintVar;
	import constraints.events.VarChangeEvent;
	
	import events.SelectionEvent;
	import events.UndoEvent;
	
	import utils.PropDictionary;
	
	import starling.display.Quad;
	import starling.display.Sprite;
	import starling.events.Event;
	import starling.events.Touch;
	import starling.events.TouchEvent;
	import starling.events.TouchPhase;
	import starling.display.DisplayObject;

	public class GridSquare
	{
		public function GridSquare( x:Number, y:Number, height:Number, width:Number)
		{
			
		}
		/*
		protected function onTouch(event:TouchEvent):void
		{
			var touchedDrawingBoard:Sprite;
			if (event.getTouches(nodeDrawingBoard, TouchPhase.ENDED).length) {
				touchedDrawingBoard = nodeDrawingBoard;
			} else {
				return;
			}
			
			var touches:Vector.<Touch> = event.getTouches(touchedDrawingBoard, TouchPhase.ENDED);
			var loc:Point = touches[0].getLocation(touchedDrawingBoard);
			var gridChild:GridChild = findNodeAtPoint(loc);
			if(gridChild)
			{
				if(event.shiftKey)
				{
					World.m_world.edgeSetGraphViewPanel.hidePaintBrush();
					
					if(!event.ctrlKey)
					{
						var globPt:Point = touchedDrawingBoard.localToGlobal(loc);
						var node:VariableNode;
						if (gridChild is VariableNode) {
							node = gridChild as VariableNode;
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
			return null;
		}
		
		private function onClicked(node:VariableNode, newIsNarrow:Boolean, dispatchChangeEvent:Boolean, loc:Point = null):void
		{
			var constraintVar:ConstraintVar = node.graphVar;
			if (!constraintVar.constant && node.isEditable && node.isNarrow != newIsNarrow) {
				node.isNarrow = newIsNarrow;
				isDirty = true;
				node.setDirty(true);
				if (dispatchChangeEvent) {
					var changeEvent:VarChangeEvent = new VarChangeEvent(VarChangeEvent.VAR_CHANGE_USER, constraintVar, PropDictionary.PROP_NARROW, node.isNarrow, loc, node);
					nodeDrawingBoard.dispatchEvent(changeEvent);
				}
			}
		}
		
		public function addGridChild(gridChild:GridChild):void
		{
			if (gridChild is Node) {
				nodeList.push(gridChild as Node);
			}
			gridChild.createSkin();
			gridChild.scaleSkin(m_nodeScaleX, m_nodeScaleY);
		}
		
		public function addEdge(edge:Edge):void
		{
			edgeList.push(edge);
			edge.updateEdge();
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
			m_bb = new Rectangle(minX, minY, maxX - minX, maxY - minY);
		}
		
		protected function onAddedToStage(event:starling.events.Event):void
		{
		}

		public function activate():void
		{			
			if(!isActivated)
			{
				if (conflictBackgroundDrawingBoard)
					conflictBackgroundDrawingBoard.removeFromParent(true);
				if(nodeDrawingBoard)
					nodeDrawingBoard.removeFromParent(true);
				if(edgeDrawingBoard)
					edgeDrawingBoard.removeFromParent(true);
				conflictBackgroundDrawingBoard = new Sprite;
				conflictBackgroundDrawingBoard.touchable = false;
				nodeDrawingBoard = new Sprite;
				edgeDrawingBoard = new Sprite;
				
				nodeDrawingBoard.addEventListener(TouchEvent.TOUCH, onTouch);
				
				for each(var node:Node in nodeList)
				{											
					if (!node.skin) node.createSkin();
					node.scaleSkin(m_nodeScaleX, m_nodeScaleY);
				}
				createEdges();
				
				for each(var edge:Edge in edgeList)
				{											
					if(!edge.skin)
						edge.updateEdge();
				}
				
				conflictBackgroundDrawingBoard.x = componentXDisplacement;
				conflictBackgroundDrawingBoard.y = componentYDisplacement;
				nodeDrawingBoard.x = componentXDisplacement;
				nodeDrawingBoard.y = componentYDisplacement;
				edgeDrawingBoard.x = componentXDisplacement;
				edgeDrawingBoard.y = componentYDisplacement;
				World.m_world.active_level.addChildToConflictBackgroundLevel(conflictBackgroundDrawingBoard);
				World.m_world.active_level.addChildToNodeLevel(nodeDrawingBoard);
				World.m_world.active_level.addChildToEdgeLevel(edgeDrawingBoard);
				conflictBackgroundDrawingBoard.flatten();
				nodeDrawingBoard.flatten();
				edgeDrawingBoard.flatten();
				isActivated = true;
				isDirty = true;
			}
		}
		
		//Used to show which GridSquare is being referenced for debug
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
		
		public function scaleNodes(nodeScaleX:Number, nodeScaleY:Number):void
		{
			if (m_nodeScaleX == nodeScaleX && m_nodeScaleY == nodeScaleY) return;
			const len:int = nodeList.length;
			for (var i:int = 0; i < len; i++)
			{
				nodeList[i].scaleSkin(nodeScaleX, nodeScaleY);
			}
			m_nodeScaleX = nodeScaleX;
			m_nodeScaleY = nodeScaleY;
		}
		
		public function draw():void
		{
			if(!isDirty)
				return;
			conflictBackgroundDrawingBoard.unflatten();
			nodeDrawingBoard.unflatten();
			edgeDrawingBoard.unflatten();
			for each(var node:Node in nodeList)
			{
				if(node.isDirty)
				{
					node.createSkin();
					node.scaleSkin(m_nodeScaleX, m_nodeScaleY);
					if (node.skin) nodeDrawingBoard.addChild(node.skin);
					if (node.backgroundSkin) conflictBackgroundDrawingBoard.addChild(node.backgroundSkin);
				}
				node.isDirty = false;
			}
			var edge:Edge;
			for each(edge in edgeList)
			{				
				if(edge.skin && edge.isDirty) //needs to be created  before here if we want it
				{
					edge.updateEdge(node);
					if(edge.skin.parent != edgeDrawingBoard)
					{
						if(edge.skin.parent != null)
						{
							//move to current gridsquare and adjust x/y boundaries to force drawing
							var currentXOffset:Number = edge.skin.parent.x;
							var currentYOffset:Number = edge.skin.parent.y;
							
							//put into global space
							edge.skin.x += currentXOffset;
							edge.skin.y += currentYOffset;
							
							//adjust to current displacement
							edge.skin.x -= componentXDisplacement;
							edge.skin.y -= componentYDisplacement;
							
							edge.skin.addToParent(edgeDrawingBoard);
							edge.parentXOffset = gridXOffset;
							edge.parentYOffset = gridYOffset; 
							//	trace(edgeObj.parentXOffset, edgeObj.parentYOffset, edgeObj.edgeSkin.x, edgeObj.edgeSkin.y);
						}
					}
					
					if(edge.skin.parent.parent == null)
						World.m_world.active_level.addChildToEdgeLevel(edgeDrawingBoard);
				}
			}
			
			conflictBackgroundDrawingBoard.flatten();
			nodeDrawingBoard.flatten();
			
			for each(edge in edgeList)
			{
				if(edge.skin == null)
				{
					var edgeSkin:EdgeSkin = edge.createEdgeSkin();
					edgeSkin.addToParent(edgeDrawingBoard);
					edgeSkin.x -= componentXDisplacement;
					edgeSkin.y -= componentYDisplacement;
				}
			}
			edgeDrawingBoard.flatten();
			isDirty = false;
		}
		
		private function createEdges():void
		{
			if(!edgeDrawingBoard)
			{
				edgeDrawingBoard = new Sprite;
				edgeDrawingBoard.x = componentXDisplacement;
				edgeDrawingBoard.y = componentYDisplacement;
				World.m_world.active_level.addChildToEdgeLevel(edgeDrawingBoard);
			}
			edgeDrawingBoard.unflatten();
			for each(var edge:Edge in edgeList)
			{
				if(edge.skin == null)
				{
					var edgeSkin:EdgeSkin = edge.createEdgeSkin();
					edgeSkin.addToParent(edgeDrawingBoard);
					edgeSkin.x -= componentXDisplacement;
					edgeSkin.y -= componentYDisplacement;
				}
			}
			edgeDrawingBoard.flatten();
		}
		
		private function updateEdge(edge:Edge):void
		{
			if(edge.skin)
			{	
				var toNode:Node = World.m_world.active_level.nodeLayoutObjs[edge.toNode.id];
				var fromNode:Node = World.m_world.active_level.nodeLayoutObjs[ edge.fromNode.id];
				
				(edge.skin.parent as Sprite).unflatten();
		//		setupLine(fromNode, toNode, edge.skin, true);
				(edge.skin.parent as Sprite).flatten();
			}
			edge.isDirty = false;
		}
		
		
		public function removeGridChild(gridChild:GridChild, dispose:Boolean = false):void
		{
			for each(var gameEdgeID:String in gridChild.connectedEdgeIds)
			{
				var edge:Edge = World.m_world.active_level.edgeLayoutObjs[gameEdgeID];
				if(edge && edge.skin)
				{
					//need to check if the other end is on screen, and if it is, pass this edge off to that node
					var toNodeObj:Object = edge.toNode;
					var fromNodeObj:Object = edge.fromNode;
					
					var otherNode:Object = toNodeObj;
					if(toNodeObj == gridChild)
						otherNode = fromNodeObj;
					
					edge.skin.removeFromParent(dispose);
					edge.skin = null;
					
					if(edge && edge.skin && edge.skin.parent == edgeDrawingBoard)
					{
						var newParent:GridSquare;

						//need to check if the one end is on screen, and if it is, pass this edge off to that grid
						if(edge.toNode.parentGrid != this && edge.toNode.parentGrid.isActivated == true)
							newParent = edge.toNode.parentGrid;
						else if(edge.fromNode.parentGrid != this && edge.fromNode.parentGrid.isActivated == true)
							newParent = edge.fromNode.parentGrid;
						else
						{
							edge.skin.removeFromParent(dispose);
							edge.skin = null;
						}
						
						//if the other end has a skin (it's on screen), but a different parent (not this one, that we are disposing of currently), attach this edge to that node
						if(newParent)
						{
							//destroy edge and recreate
							newParent.createEdges();
							newParent.isDirty = true;
						}
					}

				}
			}
			gridChild.removeSkin();
		}
		
		public function removeFromParent(dispose:Boolean):void
		{
			isActivated = false; //do first, so we can check against it in removeEdge
			
			for each (var node:Node in nodeList) {
				removeGridChild(node, dispose);
			}
			
		//	for each (var edge:Edge in edgeList) {
		//		removeGridChild(edge, dispose);
		//	}
			nodeDrawingBoard.removeFromParent(dispose);
			edgeDrawingBoard.removeFromParent(dispose);
		}
		
		public function handlePaintSelection(paintPt:Point, paintRadiusSquared:Number, selectedNodes:Vector.<GridChild>, maxSelectable:int):Boolean
		{
			var selectionChanged:Boolean = false;
			for(var i:int = 0; i < nodeList.length; i++)
			{
				var node:Node = nodeList[i];
				if (!node.skin) continue;
				var dX:Number = paintPt.x - node.centerPoint.x;
				var dY:Number = paintPt.y - node.centerPoint.y;
				if (dX * dX > paintRadiusSquared) continue;
				if (dY * dY > paintRadiusSquared) continue;
				if (dX * dX + dY * dY <= paintRadiusSquared && !node.isSelected) {
					if (false) { // use this branch for actively unselecting when max is reached 
						while (selectedNodes.length >= maxSelectable) {
							selectedNodes.shift().unselect();
						}
					} else if (selectedNodes.length >= maxSelectable) {
						break; // done selecting
					}
					node.select();
					trace("select " + node.id);
					selectedNodes.push(node);
					selectionChanged = true;
				}
			}
			return selectionChanged;
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
					if(node.isSelected)
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
						var edgeObj:Edge = World.m_world.active_level.edgeLayoutObjs[gameEdgeID];
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
				edgeDrawingBoard.bounds.intersects(viewRect))
					return true;
			else
				return false;
		}
		*/
	}
}