package scenes.game.display
{
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.Dictionary;
	
	import assets.AssetsAudio;
	import assets.AssetsFont;
	
	import audio.AudioManager;
	
	import constraints.Constraint;
	import constraints.ConstraintGraph;
	import constraints.ConstraintVar;
	import constraints.events.VarChangeEvent;
	
	import events.MoveEvent;
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
			componentXDisplacement = gridXOffset*Level.gridSize;
			componentYDisplacement = gridYOffset*Level.gridSize;
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
			node.parentGrid = this;
			
			//calculate center point
			var xCenter:Number = node.bb.x+node.bb.width*.5;
			var yCenter:Number = node.bb.y+node.bb.height*.5;
			node.centerPoint = new Point(xCenter, yCenter);
			var constraintVar:ConstraintVar = node.graphVar;
			node.isNarrow = constraintVar.getProps().hasProp(PropDictionary.PROP_NARROW);
			node.isEditable = !constraintVar.constant;
			node.skin = null;
			node.isDirty = true;
			node.gridID = id;
			node.isSelected = false;
			node.startingSelectionState = false;

			updateNode(node);
			
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
		//		nodeDrawingBoard.addEventListener(starling.events.Event.ADDED_TO_STAGE, onAddedToStage); 
		//		nodeDrawingBoard.addEventListener(starling.events.Event.REMOVED_FROM_STAGE, onAddedToStage); 
				
				nodeDrawingBoard.addEventListener(TouchEvent.TOUCH, onTouch);

				edgeList = new Array;

				for each(var node:Node in nodeList)
				{											
					if(!node.skin)
						updateNode(node);
					
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
	
									edgeObj.edgeSprite.x += currentXOffset*Level.gridSize;
									edgeObj.edgeSprite.x -= componentXDisplacement;
									edgeObj.edgeSprite.y += currentYOffset*Level.gridSize;
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
		
		protected function updateNode(node:Node):void
		{
			
			var skin:NodeSkin = NodeSkin.getNextSkin();
			skin.setNode(node);
			node.skin = skin;
			skin.width = skin.height = SKIN_DIAMETER;			

			skin.x = node.bb.x - componentXDisplacement;
			skin.y = node.bb.y - componentYDisplacement;
			
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
			var toNodeObj:Object = World.m_world.active_level.nodeLayoutObjs[toNodeID];
			var fromNodeID:String = edge["from_var_id"];
			var fromNodeObj:Object = World.m_world.active_level.nodeLayoutObjs[fromNodeID];

			if(fromNodeObj == toNodeObj)
			return;

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
				var toNodeObj:Object = World.m_world.active_level.nodeLayoutObjs[toNodeID];
				var fromNodeID:String = edge["from_var_id"];
				var fromNodeObj:Object = World.m_world.active_level.nodeLayoutObjs[fromNodeID];
			
				edge.edgeSprite.parent.unflatten();
				setupLine(fromNodeObj, toNodeObj, edge.edgeSprite);
				edge.edgeSprite.parent.flatten();
			}
			edge.isDirty = false;
		}
		
		//need to keep track of lines
		public function drawLine(fromNodeObj:Object, toNodeObj:Object):Quad
		{
			var p1:Point = fromNodeObj.centerPoint;
			var p2:Point = toNodeObj.centerPoint;
			//a^2 + b^2 = c^2
			var a:Number = (p2.x - p1.x) * (p2.x - p1.x);
			var b:Number = (p2.y - p1.y) * (p2.y - p1.y);
			var hyp:Number = Math.sqrt(a+b);
			
			//draw the quad flat, rotate later
			var lineQuad:Quad = new Quad(hyp, 5);
			
			setupLine(fromNodeObj, toNodeObj, lineQuad);
			
			//get theta
			//Sin(x) = opp/hyp
			var theta:Number = Math.asin( (p2.y-p1.y) / hyp );  // radians
			
			var dX:Number = p1.x - p2.x;
			var dY:Number = p1.y - p2.y;
			
			if(dX>0 && dY<0) // Q2
				theta = (Math.PI/2) + ((Math.PI/2) - theta);
			else if(dX>0 && dY>0) // Q3
				theta = -Math.PI - theta;
			lineQuad.y = 1;
			lineQuad.rotation = theta;
			
			lineQuad.x = -lineQuad.bounds.left + Math.min(p1.x, p2.x) - componentXDisplacement;
			lineQuad.y = -lineQuad.bounds.top + Math.min(p1.y, p2.y) -  componentYDisplacement;
			var levelBB:Rectangle = World.m_world.active_level.m_boundingBox;

			edgeDrawingBoard.addChild(lineQuad);

			return lineQuad;
		}
		
		private function setupLine(fromNodeObj:Object, toNodeObj:Object, lineQuad:Quad):void
		{
			var fromColor:int = NodeSkin.getColor(fromNodeObj);
			var toColor:int = fromColor;
			
			if (!fromNodeObj.isNarrow && toNodeObj.isNarrow)
			{
				toColor = 0xff0000;
				lineQuad.setVertexAlpha(0, 1);
				lineQuad.setVertexAlpha(1, 0.6);
				lineQuad.setVertexAlpha(2, 1);
				lineQuad.setVertexAlpha(3, 0.6);
			}
			else
			{
				lineQuad.setVertexAlpha(0, fromNodeObj.isNarrow ? 0 : 1);
				lineQuad.setVertexAlpha(1, toNodeObj.isNarrow ? 0 : 0.1);
				lineQuad.setVertexAlpha(2, 1);
				lineQuad.setVertexAlpha(3, 0.1);
			}
			lineQuad.setVertexColor(0, fromColor);
			lineQuad.setVertexColor(1, toColor);
			lineQuad.setVertexColor(2, fromColor);
			lineQuad.setVertexColor(3, toColor);
		}
		
		public function removeFromParent(dispose:Boolean):void
		{
			for(var i:int = nodeDrawingBoard.numChildren-1; i>=0; i--)
			{
				var skin:NodeSkin = nodeDrawingBoard.getChildAt(i) as NodeSkin;
				var node:Node = skin.associatedNode;
				for each(var gameEdgeID:String in node.connectedEdgeIds)
				{
					var edgeObj:Object = World.m_world.active_level.edgeLayoutObjs[gameEdgeID];
					if(edgeObj.edgeSprite)
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
							
						if(otherNode.skin && otherNode.skin.parent && otherNode.skin.parent != nodeDrawingBoard)
						{
							//destroy edge and recreate
							otherNode.parentGrid.createEdges(otherNode);
							otherNode.parentGrid.isDirty = true;
							otherNode.isDirty = true;
						}
					}
				}
				skin.disableSkin();
				skin.removeFromParent();
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