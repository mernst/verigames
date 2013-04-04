package scenes.game.display
{
	import flash.geom.Point;
	import flash.utils.Dictionary;
	
	import graph.Edge;
	import graph.EdgeSetRef;
	import graph.Network;
	import graph.Port;
	
	import scenes.BaseComponent;
	
	import starling.display.DisplayObjectContainer;
	import starling.display.Shape;
	import starling.events.Event;
	import starling.events.Touch;
	import starling.events.TouchEvent;
	import starling.events.TouchPhase;
	import events.MoveEvent;
	
	public class GameNode extends GameComponent
	{
		protected var m_edgeSet:EdgeSetRef;
		public var m_shape:Shape;
		
		private var imageWidth:uint = 10;
		private var imageHeight:uint = 10;
		private var m_id:String;
		private var m_edge:Edge;
		
		public var positionPoint:Point;
		
		protected var m_gameEdges:Vector.<GameEdgeContainer>;
		
		public var m_outgoingEdges:Vector.<GameEdgeContainer>;
		public var m_incomingEdges:Vector.<GameEdgeContainer>;
		
		protected static var nextNodeNumber:int = 0;
		
		public var m_currentNodeNumber:int;
		
		private var m_nodeXML:XML;
		private var m_edgeArray:Array;
		public var globalPosition:Point;
		private var m_gameNodeDictionary:Dictionary = new Dictionary;
		
		public var addedToStage:Boolean = false;
		
		public function GameNode(nodeXML:XML, edgeSet:EdgeSetRef, edge:Edge)
		{
			super();
			m_nodeXML = nodeXML;
			m_edgeSet = edgeSet;
			m_edge = edge;
			
			m_currentNodeNumber = nextNodeNumber++;			
			
			m_gameEdges = new Vector.<GameEdgeContainer>;
			m_outgoingEdges = new Vector.<GameEdgeContainer>;
			m_incomingEdges = new Vector.<GameEdgeContainer>;
			
			if(m_nodeXML)
			{
				var position:Point = findNodePosition(m_nodeXML);
				globalPosition = new Point(position.x, position.y);
				m_id = m_nodeXML.@id;
				var attrList:XMLList = m_nodeXML.attr;
				for each(var attr:XML in attrList)
				{
					if(attr.@name == 'width')
					{
						var widthXML:XML = attr.string[0];
						imageWidth = widthXML.toString();
					}
					else if(attr.@name == 'height')
					{
						var heightXML:XML = attr.string[0];
						imageHeight = heightXML.toString();
					}
				}
			}
			
			addEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
			addEventListener(Event.REMOVED_FROM_STAGE, onRemovedFromStage);	
		}
		
		public function onAddedToStage(event:starling.events.Event):void
		{
			draw();
			addEventListener(Event.ENTER_FRAME, onEnterFrame);
			addEventListener(TouchEvent.TOUCH, onTouch);
		}
		
		private function onRemovedFromStage():void
		{
			m_shape.removeChildren(0, -1, true);
			m_shape.dispose();
			removeChildren(0, -1, true);
			removeEventListener(Event.ENTER_FRAME, onEnterFrame);
			removeEventListener(TouchEvent.TOUCH, onTouch);
			
		}
		
		private var isTempSelection:Boolean = false;
		private var isMoving:Boolean = false;
		private function onTouch(event:TouchEvent):void
		{
			var touches:Vector.<Touch> = event.touches;
			if(event.getTouches(this, TouchPhase.ENDED).length)
			{
				if(isMoving) //if we were moving, stop it, and exit
				{
					isMoving = false;
					if(isTempSelection)
					{
						isTempSelection = false;
						this.componentSelected(false);
						dispatchEvent(new starling.events.Event(Level.COMPONENT_UNSELECTED, true, this));
					}
					return;
				}
				
				//if shift key, select, else change size
				var touch:Touch = touches[0];
				if(!event.shiftKey)
				{
					//clear selections on all actions with no shift key
					dispatchEvent(new starling.events.Event(Level.COMPONENT_UNSELECTED, true, null));
					if(m_edge.editable)
					{
						dispatchEvent(new starling.events.Event(Level.EDGE_SET_CHANGED, true, m_edgeSet));
						m_isDirty = true;
						for each(var oedge:GameEdgeContainer in this.m_outgoingEdges)
						oedge.m_isDirty = true;
						for each(var iedge:GameEdgeContainer in this.m_incomingEdges)
						iedge.m_isDirty = true;
					}
					
				}
				else //shift key down
				{
					if(touch.tapCount == 1)
						componentSelected(!m_isSelected);	
					else //select whole group
					{
						if(m_isSelected) //we were selected on the first click
							dispatchEvent(new starling.events.Event(Level.GROUP_SELECTED, true, this));
						else
							dispatchEvent(new starling.events.Event(Level.GROUP_UNSELECTED, true, this));
					}
				}
			}
			else if(event.getTouches(this, TouchPhase.MOVED).length){
				if (touches.length == 1)
				{
					if(!m_isSelected) //set up immediate drag here
					{
						//deselect everything else if shift key up
						if(!event.shiftKey)
							dispatchEvent(new starling.events.Event(Level.COMPONENT_UNSELECTED, true, null));
						
						isTempSelection = true;
						this.componentSelected(true);
						dispatchEvent(new starling.events.Event(Level.COMPONENT_SELECTED, true, this));
					}

					isMoving = true;
					dispatchEvent(new starling.events.Event(Level.MOVE_EVENT, true, touches[0]));

				}
			}
		}
		
		override public function componentMoved(delta:Point):void
		{
			super.componentMoved(delta);
			
			rubberBandEdges(delta);
		}
		
		protected function rubberBandEdges(endPt:Point):void
		{
			for each(var oedge1:GameEdgeContainer in this.m_outgoingEdges)
			{
				oedge1.rubberBandEdge(endPt, true);
			}
			for each(var iedge1:GameEdgeContainer in this.m_incomingEdges)
			{
				iedge1.rubberBandEdge(endPt, false);
			}
		}
		
		public function drawEdges(rubberBanding:Boolean = false):void
		{
			for each(var oedge1:GameEdgeContainer in this.m_outgoingEdges)
			{
				oedge1.draw();
			}
			for each(var iedge1:GameEdgeContainer in this.m_incomingEdges)
			{
				iedge1.draw();
			}
		}
		
		public function setOutgoingEdge(edge:GameEdgeContainer):void
		{
			m_outgoingEdges.push(edge);
			//extend the start point into the node
			var startPoint:Point = edge.m_edgeArray[0];
			var newStartPoint:Point = startPoint.clone();
			newStartPoint.x -= 1;
			//add the startPoint in to the front of the array two more times (bezier curve requires three points) and then create a new start point
			edge.m_edgeArray.splice(0, 0, newStartPoint, startPoint, startPoint);
		}
		
		public function setIncomingEdge(edge:GameEdgeContainer):void
		{
			m_incomingEdges.push(edge);
			//extend the end point into the node
			var endPoint:Point = edge.m_edgeArray[edge.m_edgeArray.length-1];
			var newEndPoint:Point = endPoint.clone();
			newEndPoint.x += 1;
			//add the startPoint in to the front of the array two more times (bezier curve requires three points) and then create a new start point
			edge.m_edgeArray.splice(edge.m_edgeArray.length, 0, newEndPoint, newEndPoint, newEndPoint);
		}
		
		public function onEnterFrame(event:Event):void
		{
			if(m_isDirty)
			{
				removeChildren();
				draw();
				m_isDirty = false;
			}
		}
		
		public function isStartingNode():Boolean
		{			
			for each(var edgeID:String in m_edgeSet.edge_ids)
			{
				var edge:Edge = Network.edgeDictionary[edgeID];
				for each(var port:Port in edge.from_node.incoming_ports)
				{
					if(port.edge.linked_edge_set.id != m_edgeSet.id)
						return true;
				}
			}
			return false;
		}
		
		public function draw():void
		{
			var color:uint = getColor();
			
			
			m_shape = new Shape;
			if(color == WIDE_COLOR)
				m_shape.graphics.beginMaterialFill(darkColorMaterial);
			else if(color == NARROW_COLOR)
				m_shape.graphics.beginMaterialFill(lightColorMaterial);
			else if(color == UNADJUSTABLE_COLOR)
				m_shape.graphics.beginMaterialFill(unadjustableColorMaterial);
			
			m_shape.graphics.drawRoundRect(0,0, imageWidth, imageHeight, 1);
			m_shape.graphics.endFill();
			
			if(m_isSelected && !isTempSelection)
			{
				m_shape.graphics.beginMaterialFill(selectedColorMaterial);
				m_shape.graphics.drawRect(0,0, imageWidth, imageHeight);
				m_shape.graphics.endFill();
			}
			
			addChild(m_shape);
			//			var number:String = ""+m_id.substring(4);
			//			var txt:TextField = new TextField(m_shape.width, m_shape.height, number, "Veranda", 6); 
			//			txt.y = 0;
			//			txt.x = 0;
			//			m_shape.addChild(txt);
		}
		
		public function findGroup(dictionary:Dictionary):void
		{
			dictionary[m_currentNodeNumber] = this;
			for each(var oedge1:GameEdgeContainer in this.m_outgoingEdges)
			{
				var node:GameNode = oedge1.m_toNode;
				if(dictionary[node.m_currentNodeNumber] == null)
					node.findGroup(dictionary);
			}
			for each(var iedge1:GameEdgeContainer in this.m_incomingEdges)
			{
				var inode:GameNode = iedge1.m_fromNode;
				if(dictionary[inode.m_currentNodeNumber] == null)
					inode.findGroup(dictionary);
			}
		}
		
		override public function isWide():Boolean
		{
			return m_edge.is_wide;
		}
		
		override public function getColor():int
		{
			if(m_edge.editable)
			{
				if(isWide())
					return WIDE_COLOR;
				else
					return NARROW_COLOR;
			}
			else
				return UNADJUSTABLE_COLOR;
		}
	}
}