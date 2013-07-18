package scenes.game.display
{
	import display.NineSliceBatch;
	
	import events.EdgeSetChangeEvent;
	import events.GameComponentEvent;
	import events.GroupSelectionEvent;
	import events.MoveEvent;
	import events.UndoEvent;
	
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
	
	import utils.XMath;
	
	public class GameNodeBase extends GameComponent
	{
		public var m_box9slice:NineSliceBatch;
		protected var shapeWidth:Number = 100.0;
		protected var shapeHeight:Number = 100.0;
		
		public var storedXPosition:int;
		public var storedYPosition:int;
		
		protected var m_layoutXML:XML;
		public var m_outgoingEdges:Vector.<GameEdgeContainer>;
		public var m_incomingEdges:Vector.<GameEdgeContainer>;
		
		public var m_PortToEdgeArray:Array;
		
		protected static var WIDTH_CHANGE:String = "width_change";
		
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
			
			addEventListener(Event.ENTER_FRAME, onEnterFrame);
			addEventListener(TouchEvent.TOUCH, onTouch);
		}
		
		public function updatePortIndexes():void
		{
			//sort things
			m_outgoingEdges.sort(GameEdgeContainer.sortOutgoingXPositions);
			m_incomingEdges.sort(GameEdgeContainer.sortIncomingXPositions);
			var currentPos:int = 0;
			for(var i:int = 0; i<m_outgoingEdges.length; i++)
			{
				var startingCurrentPos:int = currentPos;
				var oedge:GameEdgeContainer = m_outgoingEdges[i];
				
				var oedgeXPos:Number = oedge.localToGlobal(oedge.m_edgeArray[0]).x;
				
				for(var j:int = 0; j<m_incomingEdges.length; j++)
				{
					var iedge:GameEdgeContainer = m_incomingEdges[j];
					if(iedge.incomingEdgePosition != -1)
						continue;
					
					var iedgeXPos:Number = iedge.localToGlobal(iedge.m_edgeArray[iedge.m_edgeArray.length-1]).x;
					
					//compare positions of all nodes and set positions accordingly
					//if the name's the same, they are the same
					if(oedge.m_fromPortID == iedge.m_toPortID)
					{
						oedge.outgoingEdgePosition = currentPos;
						iedge.incomingEdgePosition = currentPos;
						m_PortToEdgeArray[currentPos] = oedge;
						currentPos++;
						break;
					}
					else if(oedgeXPos < iedgeXPos)
					{
						oedge.outgoingEdgePosition = currentPos;
						m_PortToEdgeArray[currentPos] = oedge;
						currentPos++;
						break;
					}
					else
					{
						iedge.incomingEdgePosition = currentPos;
						m_PortToEdgeArray[currentPos] = iedge;
						currentPos++;
					}
				}
				//no incoming edges, or all incoming edges less than this outgoing edge?
				if(startingCurrentPos == currentPos || oedge.outgoingEdgePosition == -1)
				{
					oedge.outgoingEdgePosition = currentPos;
					m_PortToEdgeArray[currentPos] = oedge;
					currentPos++;
				}
			}
			
			//pick up any missed ones
			for(var j1:int = 0; j1<m_incomingEdges.length; j1++)
			{
				var edge:GameEdgeContainer = m_incomingEdges[j1];
				if(edge.incomingEdgePosition == -1)
				{
					edge.incomingEdgePosition = currentPos;
					m_PortToEdgeArray[currentPos] = edge;
					currentPos++;
				}
			}
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
			if (m_box9slice) {
				m_box9slice.removeFromParent(true);
			}
			if (hasEventListener(Event.ENTER_FRAME)) {
				removeEventListener(Event.ENTER_FRAME, onEnterFrame);
			}
			if (hasEventListener(TouchEvent.TOUCH)) {
				removeEventListener(TouchEvent.TOUCH, onTouch);
			}
			super.dispose();
		}
		
		private var isMoving:Boolean = false;
		private var hasMovedOutsideClickDist:Boolean = false;
		private var startingTouchPoint:Point;
		private var startingPoint:Point;
		private static const CLICK_DIST:Number = 0.2; // if the node is moved just a tiny bit, chances are the user meant to click rather than move
		private function onTouch(event:TouchEvent):void
		{
			var touches:Vector.<Touch> = event.touches;
			var touch:Touch = touches[0];
			//trace(m_id);
			if(event.getTouches(this, TouchPhase.ENDED).length)
			{
				if (DEBUG_TRACE_IDS) trace("GameNodeBase '"+m_id+"'");
				var undoData:Object, undoEvent:Event;
				if(isMoving) //if we were moving, stop it, and exit
				{
					isMoving = false;
					if (draggable && hasMovedOutsideClickDist) {
						var startPoint:Point = startingPoint.clone();
						var endPoint:Point = new Point(x, y);
						undoEvent = new MoveEvent(MoveEvent.MOVE_EVENT, this, startPoint, endPoint);
						var eventToDispatch:UndoEvent = new UndoEvent(undoEvent, this);
						eventToDispatch.levelEvent = true;
						dispatchEvent(eventToDispatch);
						hasMovedOutsideClickDist = false;
						return;
					}
				}
				
				if(event.shiftKey && event.ctrlKey && !PipeJam3.RELEASE_BUILD)
				{
					this.m_isEditable = !this.m_isEditable;
					this.m_isDirty = true;
				}
				
				//if shift key, select, else change size
				if(!event.shiftKey)
				{
					unflattenConnectedEdges();
					
					var touchClick:Touch = event.getTouch(this, TouchPhase.ENDED);
					var touchPoint:Point = touchClick ? new Point(touchClick.globalX, touchClick.globalY) : null;
					
					onClicked(touchPoint);
				}
				else //shift key down
				{
					if (!draggable) return;
					if(touch.tapCount == 1)
					{
						componentSelected(!m_isSelected);	
						if(m_isSelected)
							dispatchEvent(new GameComponentEvent(GameComponentEvent.COMPONENT_SELECTED, this));
						else
							dispatchEvent(new GameComponentEvent(GameComponentEvent.COMPONENT_UNSELECTED, this));
					}
					else //select/unselect whole group
					{
						var groupDictionary:Dictionary = new Dictionary();
						this.findGroup(groupDictionary);
						var selection:Vector.<GameComponent> = new Vector.<GameComponent>();
						for each(var comp:GameComponent in groupDictionary)
						{
							if(selection.indexOf(comp) == -1)
							{
								if(comp is GameNodeBase)
								{
									selection.push(comp);
								}
							}
						}
						if(m_isSelected) //we were selected on the first click
							dispatchEvent(new GroupSelectionEvent(GroupSelectionEvent.GROUP_SELECTED, this, selection));
						else
							dispatchEvent(new GroupSelectionEvent(GroupSelectionEvent.GROUP_UNSELECTED, this, selection));
					}
				}
			}
			else if (event.getTouches(this, TouchPhase.MOVED).length) {
				if (touches.length == 1)
				{
					var touchXY:Point = new Point(touch.globalX, touch.globalY);
					touchXY = this.globalToLocal(touchXY);
					if(!isMoving) {
						startingTouchPoint = touchXY;
						startingPoint = new Point(x, y);
						isMoving = true;
						hasMovedOutsideClickDist = false;
						return;
					} else if (!hasMovedOutsideClickDist) {
						if (XMath.getDist(startingTouchPoint, touchXY) > CLICK_DIST * Constants.GAME_SCALE) {
							hasMovedOutsideClickDist = true;
						} else {
							// Don't move if haven't moved outside CLICK_DIST
							return;
						}
					}
					if (!draggable) return;
					var currentMoveLocation:Point = touch.getLocation(this);
					var previousLocation:Point = touch.getPreviousLocation(this);
					unflattenConnectedEdges();
					dispatchEvent(new MoveEvent(MoveEvent.MOVE_EVENT, this, previousLocation, currentMoveLocation));
				}
			}
		}
		
		private function unflattenConnectedEdges():void
		{
			for each(var oedge1:GameEdgeContainer in this.m_outgoingEdges)
			{
				oedge1.unflatten();
			}
			for each(var iedge1:GameEdgeContainer in this.m_incomingEdges)
			{
				iedge1.unflatten();
			}
			
		}
		
		public function onClicked(pt:Point):void
		{
			// overriden by children
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
			if(m_outgoingEdges.indexOf(edge) == -1) {
				m_outgoingEdges.push(edge);
			}
			
			//I want the edges to be in ascending order according to x position, so do that here
			//only works when added to stage, so don't rely on initial placements
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
			//only works when added to stage, so don't rely on initial placements
			m_incomingEdges.sort(GameEdgeContainer.sortIncomingXPositions);
			
			//stick the edge in the array at the port num, doesn't matter if it's replacing something, we just need one
			m_PortToEdgeArray[edge.incomingEdgePosition] = edge;
		}
		
		public function removeEdges():void
		{
			// Delete references to edges, i.e. if recreating them
			m_outgoingEdges = new Vector.<GameEdgeContainer>;
			m_incomingEdges = new Vector.<GameEdgeContainer>;
			m_PortToEdgeArray = new Array;
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
				edgeBeginGlobalPt = edge.localToGlobal(edge.undoObject.m_savedStartPoint);
			}
			else
			{
				edgeIndex = edge.incomingEdgePosition;
				edgeGlobalPt = edge.localToGlobal(edge.m_endPoint);
				edgeBeginGlobalPt = edge.localToGlobal(edge.undoObject.m_savedEndPoint);
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
		//but, by setting the saved point, we will be snapping back to the new position, not the old one
		// in the next function, none of that holds, so we can just directly update the start and end points
		protected function updateEdgePosition(edge:GameEdgeContainer, newPosition:Point):void
		{
			var isEdgeOutgoing:Boolean = edge.m_fromComponent == this ? true : false;
			if(isEdgeOutgoing)
			{
				if(edge.undoObject.m_savedStartPoint)
					edge.undoObject.m_savedStartPoint.x = edge.globalToLocal(newPosition).x;
				if(edge.m_extensionEdge && edge.m_extensionEdge.undoObject.m_savedEndPoint)
					edge.m_extensionEdge.undoObject.m_savedEndPoint.x = edge.m_extensionEdge.globalToLocal(newPosition).x;
			}
			else
			{
				if(edge.undoObject.m_savedEndPoint)
					edge.undoObject.m_savedEndPoint.x = edge.globalToLocal(newPosition).x;
				if(edge.m_extensionEdge && edge.m_extensionEdge.undoObject.m_savedStartPoint)
					edge.m_extensionEdge.undoObject.m_savedStartPoint.x = edge.m_extensionEdge.globalToLocal(newPosition).x;
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
		
		public override function hideComponent(hide:Boolean):void
		{
			super.hideComponent(hide);
			
			for each(var outgoingEdge:GameEdgeContainer in m_outgoingEdges)
				outgoingEdge.hideComponent(hide);
				for each(var incomingEdge:GameEdgeContainer in m_incomingEdges)
				incomingEdge.hideComponent(hide);
		}
	}
}