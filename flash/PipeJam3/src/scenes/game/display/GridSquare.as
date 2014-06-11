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
		protected var nodeList:Array;
		protected var edgeList:Array;
		protected var gridHasSelection:Boolean = false;
		public var visited:Boolean = false;
		public var isDirty:Boolean = true;
		protected var isActivated:Boolean = false;
		
		protected var gridXOffset:Number;
		protected var gridYOffset:Number;
		
		public var m_errorProps:PropDictionary;
		
		protected var componentXDisplacement:Number;
		protected var componentYDisplacement:Number;
		
		protected var selectedSkins:Vector.<NodeSkin>;

		
		static public const SKIN_DIAMETER:Number = 20;
		
		public function GridSquare( x:Number, y:Number, height:Number, width:Number)
		{
			id = x+"_"+y;
			gridXOffset = x;
			gridYOffset = y;
			componentXDisplacement = gridXOffset*Level.gridSize;
			componentYDisplacement = gridYOffset*Level.gridSize;
			nodeList = new Array;
			edgeList = new Array;
			selectedSkins = new Vector.<NodeSkin>;
		}
		
		protected function onTouch(event:TouchEvent):void
		{
			if(event.getTouches(nodeDrawingBoard, TouchPhase.ENDED).length)
			{
				var touches:Vector.<Touch> = event.getTouches(nodeDrawingBoard, TouchPhase.ENDED);
				var loc:Point = touches[0].getLocation(nodeDrawingBoard);
				var node:Object = findNodeAtPoint(loc);
				if(node)
				{
					if(!event.shiftKey)
					{
						var globPt:Point = nodeDrawingBoard.localToGlobal(loc);
						onClicked(node, globPt);
					}
					else
					{
						if(!node.isSelected)
							selectNode(node, World.m_world.active_level.selectedNodeConstraintDict);
						else
							unselectNode(node, World.m_world.active_level.selectedNodeConstraintDict);
					}
				}
			}
		}
		
		public function findNodeAtPoint(pt:Point):Object
		{
			for each(var node:Object in nodeList)
			{
				if(pt.x < node.bb.left - componentXDisplacement - .5*SKIN_DIAMETER) continue;
				if(pt.x > node.bb.right - componentXDisplacement + .5*SKIN_DIAMETER) continue;
				if(pt.y < node.bb.top - componentYDisplacement - .5*SKIN_DIAMETER) continue;
				if(pt.y > node.bb.bottom - componentYDisplacement + .5*SKIN_DIAMETER) continue;
				
				return node;
			}
			
			return null;
		}
		
		public function onClicked(node:Object, loc:Point):void
		{
			var changeEvent:VarChangeEvent,  undoEvent:UndoEvent;
			var constraintVar:ConstraintVar = node["var"];
			if(!constraintVar.constant)
			{
				node.isNarrow = !node.isNarrow;
				isDirty = true;
				setNodeDirty(node, true);
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
		
		public function setNodeDirty(node:Object, dirtyEdges:Boolean = false):void
		{
			//set self dirty also
			isDirty = true;
			node.isDirty = true;
			if(dirtyEdges)
			{
				for each(var gameEdgeID:String in node.connectedEdges)
				{
					var edgeObj:Object = World.m_world.active_level.edgeLayoutObjs[gameEdgeID];
					edgeObj.isDirty = true;
				}
			}
		}
		
		public function addNode(boxLayoutObj:Object):void
		{
			nodeList.push(boxLayoutObj);
			boxLayoutObj.parentGrid = this;
			
			//calculate center point
			var xCenter:Number = boxLayoutObj.bb.x+boxLayoutObj.bb.width*.5;
			var yCenter:Number = boxLayoutObj.bb.y+boxLayoutObj.bb.height*.5;
			boxLayoutObj.centerPoint = new Point(xCenter, yCenter);
			var constraintVar:ConstraintVar = boxLayoutObj["var"];
			boxLayoutObj.isNarrow = constraintVar.getProps().hasProp(PropDictionary.PROP_NARROW);
			boxLayoutObj.isEditable = !constraintVar.constant;
			boxLayoutObj.skin = null;
			boxLayoutObj.isDirty = true;
			boxLayoutObj.gridID = id;
			boxLayoutObj.isSelected = false;
			boxLayoutObj.startingSelectionState = false;

			updateNode(boxLayoutObj);
			
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

				for each(var node:Object in nodeList)
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
			for each(var node:Object in nodeList)
			{
				if(node.isDirty)
				{
					node.skin.draw();
					if(node.skin.parent == null)
						nodeDrawingBoard.addChild(node.skin);

					for each(var gameEdgeID:String in node.connectedEdges)
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
		
		protected function updateNode(node:Object):void
		{
			
			var skin:NodeSkin = NodeSkin.getNextSkin();
			skin.setNode(node);
			node.skin = skin;
			skin.width = skin.height = SKIN_DIAMETER;			

			skin.x = node.bb.x - componentXDisplacement;
			skin.y = node.bb.y - componentYDisplacement;
			
			setNodeDirty(node, true);
		}
		
		protected function createEdges(node:Object):void
		{
			for each(var gameEdgeID:String in node.connectedEdges)
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
			 
			 var hasError:Boolean = false;
			 if(!fromNodeObj.isNarrow && toNodeObj.isNarrow)
					 hasError = true;

			 edge.edgeSprite = drawLine(fromNodeObj, toNodeObj, hasError);
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
				
				var hasError:Boolean = false;
				if(!fromNodeObj.isNarrow && toNodeObj.isNarrow)
					hasError = true;
				
				var fromColor:int = NodeSkin.getColor(fromNodeObj);
				var toColor:int =  NodeSkin.getColor(toNodeObj);
				
				if(hasError)
					toColor = 0xff0000;
			
				edge.edgeSprite.parent.unflatten();
				edge.edgeSprite.setVertexColor(0, fromColor);
				edge.edgeSprite.setVertexColor(1, toColor);
				edge.edgeSprite.setVertexColor(2, fromColor);
				edge.edgeSprite.setVertexColor(3, toColor);
				edge.edgeSprite.parent.flatten();
			}				
			edge.isDirty = false;

		}
		
		//need to keep track of lines
		public function drawLine(fromNodeObj:Object, toNodeObj:Object, hasError:Boolean):Quad
		{
			var height:Number = 1;
			
			var p1:Point = fromNodeObj.centerPoint;
			var p2:Point = toNodeObj.centerPoint;
			//a^2 + b^2 = c^2
			var a:Number = (p2.x - p1.x) * (p2.x - p1.x);
			var b:Number = (p2.y - p1.y) * (p2.y - p1.y);
			var hyp:Number = Math.sqrt(a+b);
			
			//draw the quad flat, rotate later
			var lineQuad:Quad = new Quad(hyp, height);
			var fromColor:int = NodeSkin.getColor(fromNodeObj);
			var toColor:int = NodeSkin.getColor(toNodeObj);
			
			if(hasError)
				toColor = 0xff0000;
			
			lineQuad.setVertexColor(0, fromColor);
			lineQuad.setVertexColor(1, toColor);
			lineQuad.setVertexColor(2, fromColor);
			lineQuad.setVertexColor(3, toColor);
			
			
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
		
		public function removeFromParent(dispose:Boolean):void
		{
			for(var i:int = nodeDrawingBoard.numChildren-1; i>=0; i--)
			{
				var skin:NodeSkin = nodeDrawingBoard.getChildAt(i) as NodeSkin;
				var node:Object = skin.associatedNode;
				for each(var gameEdgeID:String in node.connectedEdges)
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
		
		public function handleSelection(marqueeRect:Rectangle, selectedNodeConstraintDict:Dictionary):void
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
						var node1:Object = nodeList[ii];
						node1.startingSelectionState = node1.isSelected;
					}
					visited = true;
				}
				else
				{
					for(var i:int = 0; i< nodeList.length; i++)
					{
						var node:Object = nodeList[i];
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
									node.on = true;
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
							selectNode(node, selectedNodeConstraintDict);
						}
						else if(makeNodeUnselected)
						{
							unselectNode(node, selectedNodeConstraintDict);

						}
					}
				}
			}
		}
		
		public function selectNode(node:Object, selectedNodeConstraintDict:Dictionary):void
		{
			node.isSelected = true;
			setNodeDirty(node, false);
			gridHasSelection = true;
			selectedSkins.push(node.skin);	
			selectedNodeConstraintDict[node.id] = node;
						
		}
		
		public function unselectNode(node:Object, selectedNodeConstraintDict:Dictionary):void
		{
			node.isSelected = false;
			setNodeDirty(node, false);
			var index:int = selectedSkins.indexOf(node.skin);
			selectedSkins.splice(index, 1);	
			if(selectedSkins.length == 0)
				gridHasSelection = false;
			delete selectedNodeConstraintDict[node.id];

		}
		
		public function markVisited():void
		{
			visited = true;
		}
		
		public function unselectAll():void
		{
			if(gridHasSelection)
			{
				nodeDrawingBoard.unflatten();
				for(var i:int = 0; i< selectedSkins.length; i++)
				{
					var skin:NodeSkin = selectedSkins[i];
					skin.associatedNode.isSelected = false;
					setNodeDirty(skin.associatedNode, false);
				}
				nodeDrawingBoard.flatten();
				selectedSkins = new Vector.<NodeSkin>;
				gridHasSelection = false;
			}
			
		}
		
		public function updateSelectedNodesAssignment(assignmentIsWide:Boolean):void
		{
			if(gridHasSelection)
			{
				if(nodeDrawingBoard)
					nodeDrawingBoard.unflatten();
				for(var index:int = 0; index<selectedSkins.length; index++)
				{
					var skin:NodeSkin = selectedSkins[index];
					skin.updateSelectionAssignment(assignmentIsWide);
				}
				if(selectedSkins.length)
					isDirty = true;
				if(nodeDrawingBoard)
					nodeDrawingBoard.flatten();
			}
		}
		
		public function updateSelectedEdges():void
		{
			if(gridHasSelection)
			{
				if(edgeDrawingBoard)
					edgeDrawingBoard.unflatten();
				for(var index:int = 0; index<selectedSkins.length; index++)
				{
					var skin:NodeSkin = selectedSkins[index];
					for each(var gameEdgeID:String in skin.associatedNode.connectedEdges)
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