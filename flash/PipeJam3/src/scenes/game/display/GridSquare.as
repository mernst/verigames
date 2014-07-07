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
		protected var edgeDrawingBoard:Sprite;
		protected var nodeList:Vector.<Node>;
		protected var edgeList:Array;
		public var NumNodesSelected:int = 0;
		public var visited:Boolean = false;
		public var isDirty:Boolean = true;
		protected var isActivated:Boolean = false;
		
		protected var gridXOffset:Number;
		protected var gridYOffset:Number;
		
		public var m_errorProps:PropDictionary;
		
		protected var componentXDisplacement:Number;
		protected var componentYDisplacement:Number;
		
		static public const SKIN_DIAMETER:Number = 20;
		
		public function GridSquare( x:Number, y:Number, height:Number, width:Number)
		{
			id = x+"_"+y;
			gridXOffset = x;
			gridYOffset = y;
			componentXDisplacement = gridXOffset*Level.GRID_SIZE;
			componentYDisplacement = gridYOffset*Level.GRID_SIZE;
			nodeList = new Vector.<Node>();
			edgeList = new Array;
		}
		
		protected function onTouch(event:TouchEvent):void
		{
			if(event.getTouches(nodeDrawingBoard, TouchPhase.ENDED).length)
			{
				var touches:Vector.<Touch> = event.getTouches(nodeDrawingBoard, TouchPhase.ENDED);
				var loc:Point = touches[0].getLocation(nodeDrawingBoard);
				var node:Node = findNodeAtPoint(loc);
				if(node)
				{
					if(!event.shiftKey)
					{
						if(!node.isLocked)
						{
							var globPt:Point = nodeDrawingBoard.localToGlobal(loc);
							onClicked(node, globPt);
						}
					}
					else
					{
						if(!event.ctrlKey)
						{
							if(!node.isSelected)
								node.selectNode(World.m_world.active_level.selectedNodes);
							else
								node.unselectNode(World.m_world.active_level.selectedNodes);
						}
						else
						{
							nodeDrawingBoard.dispatchEvent(new SelectionEvent(SelectionEvent.GROUP_SELECTED, node));
						}
					}
				}
			}
		}
		
		public function findNodeAtPoint(pt:Point):Node
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
		
		public function onClicked(node:Node, loc:Point):void
		{
			var changeEvent:VarChangeEvent,  undoEvent:UndoEvent;
			var constraintVar:ConstraintVar = node["graphVar"];
			if(!constraintVar.constant)
			{
				node.isNarrow = !node.isNarrow;
				isDirty = true;
				node.setNodeDirty(true);
			}
		//	var propVal:Boolean = constraintVar.getProps().hasProp(PropDictionary.PROP_NARROW);
		//	if (propVal) {
				if(node.isEditable) {
					changeEvent = new VarChangeEvent(VarChangeEvent.VAR_CHANGE_USER, constraintVar, PropDictionary.PROP_NARROW, node.isNarrow, loc);
					if (!node.isNarrow) {
						// Wide
						AudioManager.getInstance().audioDriver().playSfx(AssetsAudio.SFX_LOW_BELT);
					} else {
						// Narrow
						AudioManager.getInstance().audioDriver().playSfx(AssetsAudio.SFX_HIGH_BELT);
					}
				}
//			} else if (m_propertyMode.indexOf(PropDictionary.PROP_KEYFOR_PREFIX) == 0) {
//				var propVal:Boolean = constraintVar.getProps().hasProp(m_propertyMode);
//				changeEvent = new VarChangeEvent(VarChangeEvent.VAR_CHANGE_USER, constraintVar, m_propertyMode, propVal, pt);
//			}
			if (changeEvent) nodeDrawingBoard.dispatchEvent(changeEvent);
		}
		
		public function addNode(node:Node):void
		{
			nodeList.push(node);
			updateNodeSkin(node);
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
				if(edgeDrawingBoard)
					edgeDrawingBoard.removeFromParent(true);
				nodeDrawingBoard = new Sprite;
				edgeDrawingBoard = new Sprite;
								
				nodeDrawingBoard.addEventListener(TouchEvent.TOUCH, onTouch);

				edgeList = new Array;
				for each(var node:Node in nodeList)
				{											
					if(!node.skin)
						updateNodeSkin(node);
					
					createEdges(node);
				}
				
				nodeDrawingBoard.x = componentXDisplacement;
				nodeDrawingBoard.y = componentYDisplacement;
				edgeDrawingBoard.x = componentXDisplacement;
				edgeDrawingBoard.y = componentYDisplacement;
				World.m_world.active_level.addChildToNodeLevel(nodeDrawingBoard);
				World.m_world.active_level.addChildToEdgeLevel(edgeDrawingBoard);
				nodeDrawingBoard.flatten();
				edgeDrawingBoard.flatten();
				isActivated = true;
				isDirty = true;
			}
		}
		
		public function draw():void
		{
			if(!isDirty)
				return;
			nodeDrawingBoard.unflatten();
			edgeDrawingBoard.unflatten();
			for each(var node:Node in nodeList)
			{
				if(node.isDirty)
				{
					node.skin.draw();
					if(node.skin.parent == null)
						nodeDrawingBoard.addChild(node.skin);
					node.skin.x = node.centerPoint.x - componentXDisplacement - 0.5 * node.skin.width;
					node.skin.y = node.centerPoint.y - componentYDisplacement - 0.5 * node.skin.height;
					
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
			}
			nodeDrawingBoard.flatten();
			edgeDrawingBoard.flatten();
			isDirty = false;
		}
		
		protected function updateNodeSkin(node:Node):void
		{
			if (node.skin) {
				node.skin.removeFromParent();
				node.skin.disableSkin();
			}
			
			var skin:NodeSkin = NodeSkin.getNextSkin();
			skin.setNode(node);
			node.skin = skin;
			skin.draw();

			skin.x = node.centerPoint.x - componentXDisplacement - 0.5 * skin.width;
			skin.y = node.centerPoint.y - componentYDisplacement - 0.5 * skin.height;
			
			node.setNodeDirty(true);
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
		public static const LINE_THICKNESS:Number = 5;
		//need to keep track of lines
		public function drawLine(fromNodeObj:Node, toNodeObj:Node):Quad
		{
			var p1:Point = fromNodeObj.centerPoint;
			var p2:Point = toNodeObj.centerPoint;
			//a^2 + b^2 = c^2
			var a:Number = (p2.x - p1.x) * (p2.x - p1.x);
			var b:Number = (p2.y - p1.y) * (p2.y - p1.y);
			var hyp:Number = Math.sqrt(a+b);
			
			//draw the quad flat, rotate later
			var lineQuad:Quad = new Triangle(hyp, LINE_THICKNESS);
			setupLine(fromNodeObj, toNodeObj, lineQuad, true);
			//trace("drawing Line from ", fromNodeObj.id, " -> ", toNodeObj.id);
			var otherEdgeId:String = toNodeObj.id + " -> " + fromNodeObj.id;
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
		
		public function removeNode(node:Node, dispose:Boolean = false):void
		{
			for each(var gameEdgeID:String in node.connectedEdgeIds)
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
					if(toNodeObj == node)
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
			if (node.skin) {
				node.skin.removeFromParent();
				node.skin.disableSkin();
			}
		}
		
		public function removeFromParent(dispose:Boolean):void
		{
			for each (var node:Node in nodeList) {
				removeNode(node, dispose);
			}
			nodeDrawingBoard.removeFromParent(dispose);
			edgeDrawingBoard.removeFromParent(dispose);
			isActivated = false;
		}
		
		public function handleSelection(marqueeRect:Rectangle, selectedNodes:Dictionary):void
		{
			if(marqueeRect.intersects(nodeDrawingBoard.bounds))
			{
				//adjust rectangle
				marqueeRect.offset(-componentXDisplacement, -componentYDisplacement);
				if(visited == false)
				{
					//record the current selection state of all nodes
					for(var ii:int = 0; ii< nodeList.length; ii++)
					{
						var node1:Node = nodeList[ii];
						node1.startingSelectionState = node1.isSelected;
					}
					visited = true;
				}
				else
				{
					for(var i:int = 0; i< nodeList.length; i++)
					{
						var node:Node = nodeList[i];
						var skin:NodeSkin = node.skin;
						var makeNodeSelected:Boolean = false;
						var makeNodeUnselected:Boolean = false;
						
						if(skin && marqueeRect.containsRect(skin.bounds))
						{
							if(node.isSelected == false)
							{
								if(node.startingSelectionState == false)
								{
									makeNodeSelected = true;		
								}
							}
							else
							{
								if(node.startingSelectionState == true)
								{
									makeNodeUnselected = true;	
								}
							}
						}
						else
						{
							if(node.isSelected == false)
							{
								if(node.startingSelectionState == true)
								{
									makeNodeSelected = true;	
								}
							}
							else
							{
								if(node.startingSelectionState == false)
								{
									makeNodeUnselected = true;	

								}
							}
						}
						
						if(makeNodeSelected)
						{
							node.selectNode(selectedNodes);
						}
						else if(makeNodeUnselected)
						{
							node.unselectNode(selectedNodes);

						}
					}
				}
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
						node.setNodeDirty(false);
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
			if(nodeDrawingBoard.bounds.intersects(viewRect) ||
				edgeDrawingBoard.bounds.intersects(viewRect))
					return true;
			else
				return false
		}
	}
}