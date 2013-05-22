package scenes.game.display
{
	import events.EdgeSetChangeEvent;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.Dictionary;
	
	import starling.display.Shape;
	import starling.events.Event;
	import starling.events.Touch;
	import starling.events.TouchEvent;
	import starling.events.TouchPhase;

	
	public class GameNodeBase extends GameComponent
	{
		public var m_shape:Shape;
		protected var shapeWidth:Number = 100.0;
		protected var shapeHeight:Number = 100.0;

		protected var m_layoutXML:XML;
		public var m_outgoingEdges:Vector.<GameEdgeContainer>;
		public var m_incomingEdges:Vector.<GameEdgeContainer>;
		
		protected var m_gameEdges:Vector.<GameEdgeContainer>;
		
		public function GameNodeBase(_layoutXML:XML)
		{
			super(_layoutXML.@id);

			m_layoutXML = _layoutXML;
			m_boundingBox = findBoundingBox(m_layoutXML);
			
			m_outgoingEdges = new Vector.<GameEdgeContainer>;
			m_incomingEdges = new Vector.<GameEdgeContainer>;
			
			m_gameEdges = new Vector.<GameEdgeContainer>;
			
			addEventListener(Event.ENTER_FRAME, onEnterFrame);
			addEventListener(TouchEvent.TOUCH, onTouch);
		}
		
		override public function dispose():void
		{
			if (m_disposed) {
				return;
			}
			disposeChildren();
			if (m_shape) {
				m_shape.removeChildren(0, -1, true);
				m_shape.dispose();
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
			edge.outgoingEdgePosition = (m_outgoingEdges.length-1)/5;
			//I want the edges to be in ascending order according to x position, so do that here
			m_outgoingEdges.sort(GameEdgeContainer.sortOutgoingXPositions);
			
			//push size info - nope, this is coming from the simulator
			// edge.setIncomingWidth(m_isWide);
			
		}
		
		//adds edge to incoming edge method (unless currently in vector), then sorts
		public function setIncomingEdge(edge:GameEdgeContainer):void
		{
			if(m_incomingEdges.indexOf(edge) == -1)
				m_incomingEdges.push(edge);
			edge.incomingEdgePosition = (m_incomingEdges.length-1)/5;
			//I want the edges to be in ascending order according to x position, so do that here
			m_incomingEdges.sort(GameEdgeContainer.sortIncomingXPositions);
			//push size info - nope, this is coming from the simulator
			//edge.setOutgoingWidth(m_isWide);
		}
		
		public function findGroup(dictionary:Dictionary):void
		{
//			dictionary[id] = this;
//			for each(var oedge1:GameEdgeContainer in this.m_outgoingEdges)
//			{
//				var oJoint:GameJointNode = oedge1.m_joint;
//				for each(var oedge2:GameEdgeContainer in oJoint.m_outgoingEdges)
//				{
//					if(dictionary[oedge2.m_node.id] == null)
//						oedge2.m_node.findGroup(dictionary);
//				}
//			}
//			for each(var iedge1:GameEdgeContainer in this.m_incomingEdges)
//			{
//				var iJoint:GameJointNode = iedge1.m_joint;
//				for each(var iedge2:GameEdgeContainer in iJoint.m_incomingEdges)
//				{
//					if(dictionary[iedge2.m_node.id] == null)
//						iedge2.m_node.findGroup(dictionary);
//				}
//			}
		}
	}
}