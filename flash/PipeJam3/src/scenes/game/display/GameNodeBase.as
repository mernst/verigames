package scenes.game.display
{
	import display.RoundedRect;
	import events.EdgeSetChangeEvent;
	
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.Dictionary;
	import starling.display.BlendMode;
	import starling.display.Quad;
	import starling.display.Shape;
	
	import starling.events.Event;
	import starling.events.Touch;
	import starling.events.TouchEvent;
	import starling.events.TouchPhase;
	
	public class GameNodeBase extends GameComponent
	{
		public var m_quad:Quad;
		public var m_rect:RoundedRect;
		protected var shapeWidth:Number = 100.0;
		protected var shapeHeight:Number = 100.0;

		protected var m_layoutXML:XML;
		public var m_outgoingEdges:Vector.<GameEdgeContainer>;
		public var m_incomingEdges:Vector.<GameEdgeContainer>;
		
		public var m_PortToEdgeArray:Array;
		
		protected var m_gameEdges:Vector.<GameEdgeContainer>;
		
		public function GameNodeBase(_layoutXML:XML)
		{
			super(_layoutXML.@id);

			m_layoutXML = _layoutXML;
			m_boundingBox = findBoundingBox(m_layoutXML);
			
			//adjust bounding box by half dimensions since layout is from center of node
			m_boundingBox.x -= m_boundingBox.width/2;
			m_boundingBox.y -= m_boundingBox.height/2;
			
			m_outgoingEdges = new Vector.<GameEdgeContainer>;
			m_incomingEdges = new Vector.<GameEdgeContainer>;
			m_PortToEdgeArray = new Array;
			
			m_gameEdges = new Vector.<GameEdgeContainer>;
			
			addEventListener(Event.ENTER_FRAME, onEnterFrame);
			addEventListener(TouchEvent.TOUCH, onTouch);
		}
		
		public function getNumLines():int
		{
			if (m_layoutXML) {
				var linesStr:String = m_layoutXML.@lines;
				if (!isNaN(int(linesStr))) {
					return int(linesStr);
				}
			}
			return 0;
		}
		
		override public function dispose():void
		{
			if (m_disposed) {
				return;
			}
			disposeChildren();
			if (m_quad) {
				m_quad.removeFromParent(true);
			}
			if (m_rect) {
				m_rect.removeFromParent(true);
			}
			if (hasEventListener(Event.ENTER_FRAME)) {
				removeEventListener(Event.ENTER_FRAME, onEnterFrame);
			}
			if (hasEventListener(TouchEvent.TOUCH)) {
				removeEventListener(TouchEvent.TOUCH, onTouch);
			}
			super.dispose();
		}
		
		protected var isTempSelection:Boolean = false;
		private var isMoving:Boolean = false;
		private function onTouch(event:TouchEvent):void
		{
			var touches:Vector.<Touch> = event.touches;
			//trace(m_id);
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
					if(m_isEditable)
					{
						m_isWide = !m_isWide;
						m_isDirty = true;
						for each (var iedge:GameEdgeContainer in m_incomingEdges) {
							if (!m_isWide || iedge.isWide()) {
								iedge.setOutgoingWidth(m_isWide);
							}
						}
						// Need to dispatch AFTER setting width, this will trigger the score update
						// (we don't want to update the score with old values, we only know they're old
						// if we properly mark them dirty first)
						dispatchEvent(new EdgeSetChangeEvent(EdgeSetChangeEvent.EDGE_SET_CHANGED, this));
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
		
		public function onEnterFrame(event:Event):void
		{
			if(m_isDirty)
			{
				removeChildren();
				draw();
				m_isDirty = false;
			}
		}
		
		public function draw():void
		{
			
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
		
		//adds edge to outgoing edge method (unless currently in vector), then sorts
		public function setOutgoingEdge(edge:GameEdgeContainer):void
		{
			if(m_outgoingEdges.indexOf(edge) == -1)
				m_outgoingEdges.push(edge);
			
			//I want the edges to be in ascending order according to x position, so do that here
			m_outgoingEdges.sort(GameEdgeContainer.sortOutgoingXPositions);
			
			//stick the edge in the array at the port num, doesn't matter if it's replacing something, we just need one
			m_PortToEdgeArray[edge.outgoingEdgePosition] = edge;
		}
		
		//adds edge to incoming edge method (unless currently in vector), then sorts
		public function setIncomingEdge(edge:GameEdgeContainer):void
		{
			if(m_incomingEdges.indexOf(edge) == -1)
				m_incomingEdges.push(edge);
			
			//I want the edges to be in ascending order according to x position, so do that here
			m_incomingEdges.sort(GameEdgeContainer.sortIncomingXPositions);
			
			//stick the edge in the array at the port num, doesn't matter if it's replacing something, we just need one
			m_PortToEdgeArray[edge.incomingEdgePosition] = edge;

		}
		
		//used when double clicking a node, handles selecting entire group. 
		public function findGroup(dictionary:Dictionary):void
		{
			dictionary[m_id] = this;
			for each(var oedge1:GameEdgeContainer in this.m_outgoingEdges)
			{
				if(dictionary[oedge1.m_toComponent.m_id] == null)
					oedge1.m_toComponent.findGroup(dictionary);
			}
			for each(var iedge1:GameEdgeContainer in this.m_incomingEdges)
			{
				if(dictionary[iedge1.m_fromComponent.m_id] == null)
					iedge1.m_fromComponent.findGroup(dictionary);
			}
		}
		
		public function organizePorts(edge:GameEdgeContainer, incrementing:Boolean):void
		{
			var edgeIndex:int;
			var nextEdgeIndex:int;
			var nextEdge:GameEdgeContainer = null;
			var edgeGlobalPt:Point;
			var nextEdgeGlobalPt:Point;
			var edgeBeginGlobalPt:Point;
			
			var isEdgeOutgoing:Boolean = edge.m_fromComponent == this ? true : false;
			var isNextEdgeOutgoing:Boolean;
			
			if(isEdgeOutgoing)
			{
				edgeIndex = edge.outgoingEdgePosition;
				edgeGlobalPt = edge.localToGlobal(edge.m_startPoint);
				edgeBeginGlobalPt = edge.localToGlobal(edge.m_savedStartPoint);
			}
			else
			{
				edgeIndex = edge.incomingEdgePosition;
				edgeGlobalPt = edge.localToGlobal(edge.m_endPoint);
				edgeBeginGlobalPt = edge.localToGlobal(edge.m_savedEndPoint);
			}

			nextEdgeIndex = getNextEdgePosition(edgeIndex, incrementing);
			if(nextEdgeIndex != -1)
			{
				nextEdge = m_PortToEdgeArray[nextEdgeIndex];
				isNextEdgeOutgoing = nextEdge.m_fromComponent == this ? true : false;
				if(isNextEdgeOutgoing)
					nextEdgeGlobalPt = nextEdge.localToGlobal(nextEdge.m_startPoint);
				else
					nextEdgeGlobalPt = nextEdge.localToGlobal(nextEdge.m_endPoint);
				
				if(incrementing)
				{
					if(nextEdgeGlobalPt.x < edgeGlobalPt.x)
						updateEdges(edge, nextEdgeGlobalPt, nextEdge, edgeBeginGlobalPt);
				
				}
				else 
				{
					if(nextEdgeGlobalPt.x > edgeGlobalPt.x)
						updateEdges(edge, nextEdgeGlobalPt, nextEdge, edgeBeginGlobalPt);
				}
			
				if(edge.hasChanged && nextEdge)
					switchEdgePositions(edge, edgeIndex, nextEdge, nextEdgeIndex);
			}
		}
		
		//find and return the position in the port array for the next edge, or -1
		protected function getNextEdgePosition(currentPos:int, increasing:Boolean):int
		{
			var nextEdge:GameEdgeContainer;
			var nextEdgeIndex:int = -1;
			if(increasing)
			{
				currentPos++;
				while(nextEdgeIndex == -1 && currentPos < m_PortToEdgeArray.length)
				{
					nextEdge = m_PortToEdgeArray[currentPos];
					if(nextEdge)
						nextEdgeIndex = currentPos;
					else
						currentPos++;
				}
			}
			else
			{
				currentPos--;
				while(nextEdgeIndex == -1 && currentPos>=0)
				{
					nextEdge = m_PortToEdgeArray[currentPos];
					if(nextEdge)
						nextEdgeIndex = currentPos;
					else
						currentPos--;
				}
			}
			return nextEdgeIndex;
		}
		
		protected function updateEdges(edge:GameEdgeContainer, newPosition:Point, nextEdge:GameEdgeContainer, newNextPosition:Point):void
		{
			updateEdgePosition(edge, newPosition);
			updateNextEdgePosition(nextEdge, newNextPosition);
			
			var isNextEdgeOutgoing:Boolean = nextEdge.m_fromComponent == this ? true : false;
			nextEdge.rubberBandEdge(new Point(), isNextEdgeOutgoing);
			if(nextEdge.m_extensionEdge)
			{
				var isNextExtensionEdgeOutgoing:Boolean = nextEdge.m_extensionEdge.m_fromComponent == this ? true : false;
				updateNextEdgePosition(nextEdge.m_extensionEdge, newNextPosition);
				nextEdge.m_extensionEdge.rubberBandEdge(new Point(), isNextExtensionEdgeOutgoing);
			}
			
			edge.hasChanged = true;
			edge.restoreEdge = false;
		}
		
		//update edge and extension edge to be at newPosition.x
		//the difference between this function and the next one, is that the mechanism is going to try to restore this
		//edge to the beginning state (as when you drag it a little bit, and it snaps back)
		//but, but setting the saved point, we will be snapping back to the new position, not the old one
		// in the next function, none of that holds, so we can just directly update the start and end points
		protected function updateEdgePosition(edge:GameEdgeContainer, newPosition:Point):void
		{
			var isEdgeOutgoing:Boolean = edge.m_fromComponent == this ? true : false;
			if(isEdgeOutgoing)
			{
				if(edge.m_savedStartPoint)
					edge.m_savedStartPoint.x = edge.globalToLocal(newPosition).x;
				if(edge.m_extensionEdge && edge.m_extensionEdge.m_savedEndPoint)
					edge.m_extensionEdge.m_savedEndPoint.x = edge.m_extensionEdge.globalToLocal(newPosition).x;
			}
			else
			{
				if(edge.m_savedEndPoint)
					edge.m_savedEndPoint.x = edge.globalToLocal(newPosition).x;
				if(edge.m_extensionEdge && edge.m_extensionEdge.m_savedStartPoint)
					edge.m_extensionEdge.m_savedStartPoint.x = edge.m_extensionEdge.globalToLocal(newPosition).x;
			}
		}
		
		//update edge and extension edge to be at newPosition.x
		protected function updateNextEdgePosition(edge:GameEdgeContainer, newPosition:Point):void
		{
			var isEdgeOutgoing:Boolean = edge.m_fromComponent == this ? true : false;
			if(isEdgeOutgoing)
			{
				edge.m_startPoint.x = edge.globalToLocal(newPosition).x;
				if(edge.m_extensionEdge)
					edge.m_extensionEdge.m_endPoint.x = edge.m_extensionEdge.globalToLocal(newPosition).x;
			}
			else
			{
				edge.m_endPoint.x = edge.globalToLocal(newPosition).x;
				if(edge.m_extensionEdge)
					edge.m_extensionEdge.m_startPoint.x = edge.m_extensionEdge.globalToLocal(newPosition).x;
			}
		}
		
		//switch edge port positions - both in the port index array and internally in the incoming and outgoing position variables
		protected function switchEdgePositions(currentEdgeContainer:GameEdgeContainer, currentPosition:int, nextEdgeContainer:GameEdgeContainer, nextPosition:int):void
		{
			var isEdgeOutgoing:Boolean = currentEdgeContainer.m_fromComponent == this ? true : false;
			var isNextEdgeOutgoing:Boolean = nextEdgeContainer.m_fromComponent == this ? true : false;
			
			currentEdgeContainer.hasChanged = false;
			if(currentEdgeContainer.m_extensionEdge)
				currentEdgeContainer.m_extensionEdge.restoreEdge = false;
			
			m_PortToEdgeArray[currentPosition] = nextEdgeContainer;
			m_PortToEdgeArray[nextPosition] = currentEdgeContainer;
			
			if(isEdgeOutgoing)
			{
				currentEdgeContainer.outgoingEdgePosition = nextPosition;
				if(currentEdgeContainer.m_extensionEdge)
					currentEdgeContainer.m_extensionEdge.incomingEdgePosition = nextPosition;
				if(isNextEdgeOutgoing)
				{
					nextEdgeContainer.outgoingEdgePosition = currentPosition;
					if(nextEdgeContainer.m_extensionEdge)
						nextEdgeContainer.m_extensionEdge.incomingEdgePosition = currentPosition;
				}
				else
				{
					nextEdgeContainer.incomingEdgePosition = currentPosition;
					if(nextEdgeContainer.m_extensionEdge)
						nextEdgeContainer.m_extensionEdge.outgoingEdgePosition = currentPosition;
				}
			}
			else
			{
				currentEdgeContainer.incomingEdgePosition = nextPosition;
				if(currentEdgeContainer.m_extensionEdge)
					currentEdgeContainer.m_extensionEdge.outgoingEdgePosition = nextPosition;
				if(isNextEdgeOutgoing)
				{
					nextEdgeContainer.outgoingEdgePosition = currentPosition;
					if(nextEdgeContainer.m_extensionEdge)
						nextEdgeContainer.m_extensionEdge.incomingEdgePosition = currentPosition;
				}
				else
				{
					nextEdgeContainer.incomingEdgePosition = currentPosition;
					if(nextEdgeContainer.m_extensionEdge)
						nextEdgeContainer.m_extensionEdge.outgoingEdgePosition = currentPosition;
				}
			}
		}
	}
}