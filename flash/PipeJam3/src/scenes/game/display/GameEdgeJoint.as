package scenes.game.display
{
	import flash.geom.Point;
	
	import scenes.BaseComponent;
	
	import starling.display.Quad;
	import starling.display.Shape;
	import starling.display.materials.StandardMaterial;
	import starling.events.Event;
	import starling.events.Touch;
	import starling.events.TouchEvent;
	import starling.events.TouchPhase;
	import starling.text.TextField;

	public class GameEdgeJoint extends GameComponent
	{		
		public var m_jointType:int;
		
		//used when moving connection points to allow for snapping back to start, or swapping positions with other connections
		public var m_originalPoint:Point;
		public var m_position:int;
		
		protected var m_parentEdge:GameEdgeContainer;
		public var m_closestWall:int = 0;
		
		public var count:int = 0;
		private var m_quad:Quad;
		
		static public var STANDARD_JOINT:int = 0;
		static public var MARKER_JOINT:int = 1;
		static public var END_JOINT:int = 2;
		
		public function GameEdgeJoint(jointType:int = 0)
		{
			super("");
			
			m_jointType = jointType;
			m_originalPoint = new Point;
			m_isDirty = true;
			
			//default to true
			m_isEditable = true;
			
			addEventListener(Event.ENTER_FRAME, onEnterFrame);
		}
		
		override public function dispose():void
		{
			if (m_disposed) {
				return;
			}
			if (hasEventListener(Event.ENTER_FRAME)) {
				removeEventListener(Event.ENTER_FRAME, onEnterFrame);
			}

			disposeChildren();
			if(m_quad)
				m_quad.dispose();

			super.dispose();
		}
		
		protected function trackConnector(currentMoveLocation:Point, previousLocation:Point):void
		{
			var containerComponent:GameComponent;
//			if(m_fromComponent is GameNode)
//				containerComponent = m_fromComponent;
//			else 
//				containerComponent = m_toComponent;
			
			var startPt:Point = new Point(x,y);
			
			//find difference in mouse movement, and apply to x,y
			var differencePt:Point = currentMoveLocation.subtract(previousLocation);						
			//zero out y movement
			differencePt.y = 0;
			var updatedXY:Point = startPt.add(differencePt);
			var jointStartGlobalPt:Point = parent.localToGlobal(startPt);
			var jointUpdatedGlobalPt:Point = parent.localToGlobal(updatedXY);
			
			//find global coordinates of container, subtracting off joints height and width
			var containerPt:Point = new Point(containerComponent.x+0.5*width,containerComponent.y+0.5*height);
			var containerGlobalPt:Point = containerComponent.parent.localToGlobal(containerPt);						
			var boundsGlobalPt:Point = containerComponent.parent.localToGlobal(new Point(containerComponent.x + containerComponent.width-0.5*width, containerComponent.y + containerComponent.height-0.5*height));
			
			//make sure we are in bounds and on glued to same edge
			if(jointUpdatedGlobalPt.x < containerGlobalPt.x)
			{
				jointUpdatedGlobalPt.x = containerGlobalPt.x;
			}
			else if(jointUpdatedGlobalPt.x > boundsGlobalPt.x)
			{
				jointUpdatedGlobalPt.x = boundsGlobalPt.x;
			}
			if(jointUpdatedGlobalPt.y < containerGlobalPt.y)
			{
				jointUpdatedGlobalPt.y = containerGlobalPt.y;
			}
			else if(jointUpdatedGlobalPt.y > boundsGlobalPt.y)
			{
				jointUpdatedGlobalPt.y = boundsGlobalPt.y;
			}
			
			
			var finalPt:Point = parent.globalToLocal(jointUpdatedGlobalPt);
			var updatePoint:Point = finalPt.subtract(startPt);	
			
			var isOutgoingEdge:Boolean;// = m_fromComponent is GameNode ? true : false;
			
			//now compare current point with other connection points, and if we've overlapped one of them, switch places
			//moving towards the right
			var gameEdgeContainer:GameEdgeContainer = parent as GameEdgeContainer;
			
			var node:GameNode = containerComponent as GameNode;
			if(isOutgoingEdge)
			{
				node.m_outgoingEdges.sort(sortOutgoingXPositions);
				var oEdgePosition:int = node.m_outgoingEdges.indexOf(parent);
				if(oEdgePosition != m_position)
				{
					m_position = oEdgePosition;
					//get the node we just passed, and switch end points
					var oNextEdge:GameEdgeContainer;
					if(updatePoint.x>0) 
						if(oEdgePosition>0)
							oNextEdge = node.m_outgoingEdges[oEdgePosition-1];
						else
							return;
					else
						if(node.m_outgoingEdges.length > oEdgePosition+1)
							oNextEdge = node.m_outgoingEdges[oEdgePosition+1];
						else
							return;
					//save next edge current start point
					var globalNextStartPt:Point = oNextEdge.localToGlobal(new Point(oNextEdge.m_startJoint.x, oNextEdge.m_startJoint.y));
					//set next edge start position using our current original point
					var globalOriginalStartPt:Point = parent.localToGlobal(m_originalPoint);
					oNextEdge.setStartPosition(oNextEdge.globalToLocal(globalOriginalStartPt));
					//set our original point from saved next edge point
					m_originalPoint = parent.globalToLocal(globalNextStartPt);
					
					//redraw nextEdge, passing update point = 0,0
					oNextEdge.rubberBandEdge(new Point(), isOutgoingEdge);
					//reorder outgoing edge array
					node.setOutgoingEdge(oNextEdge);
				}
			}
			else
			{
				
				node.m_incomingEdges.sort(sortIncomingXPositions);
				var iEdgePosition:int = node.m_incomingEdges.indexOf(parent);
				if(iEdgePosition != m_position)
				{
					m_position = iEdgePosition;
					//get the node we just passed, and switch end points
					var iNextEdge:GameEdgeContainer;
					if(updatePoint.x>0) 
						if(iEdgePosition>0)
							iNextEdge = node.m_incomingEdges[iEdgePosition-1];
						else
							return;
					else
						if(node.m_incomingEdges.length > iEdgePosition+1)
							iNextEdge = node.m_incomingEdges[iEdgePosition+1];
						else
							return;
					
					//save next edge current start point
					var globalNextEndPt:Point = iNextEdge.localToGlobal(new Point(iNextEdge.m_endJoint.x, iNextEdge.m_endJoint.y));
					//set next edge start position using our current original point
					var globalOriginalEndPt:Point = parent.localToGlobal(m_originalPoint);
					iNextEdge.setEndPosition(iNextEdge.globalToLocal(globalOriginalEndPt));
					//set our original point from saved next edge point
					m_originalPoint = parent.globalToLocal(globalNextEndPt);
					
					//redraw nextEdge, passing update point = 0,0
					iNextEdge.rubberBandEdge(new Point(), isOutgoingEdge);
					//reorder outgoing edge array
					node.setOutgoingEdge(iNextEdge);
				}
			}
			if (m_parentEdge) {
				m_parentEdge.rubberBandEdge(updatePoint, isOutgoingEdge);
			}
		}
		

		protected function sortOutgoingXPositions(x:GameEdgeContainer, y:GameEdgeContainer):Number
		{
			var pt1:Point = x.localToGlobal(new Point(x.m_startJoint.x, x.m_startJoint.y));
			var pt2:Point = y.localToGlobal(new Point(y.m_startJoint.x, y.m_startJoint.y));
			//	trace(pt1.x + " " +pt2.x);
			if(pt1.x < pt2.x)
				return -1;
			else
				return 1;
		}
			
		protected function sortIncomingXPositions(x:GameEdgeContainer, y:GameEdgeContainer):Number
		{
			var pt1:Point = x.localToGlobal(new Point(x.m_endJoint.x, x.m_endJoint.y));
			var pt2:Point = y.localToGlobal(new Point(y.m_endJoint.x, y.m_endJoint.y));
			trace(pt1.x + " " +pt2.x);
			if(pt1.x < pt2.x)
				return -1;
			else
				return 1;
		}
	
	
		public function draw():void
		{
			var lineSize:Number = m_isWide ? GameEdgeContainer.WIDE_WIDTH : GameEdgeContainer.NARROW_WIDTH;
		
			var color:int = getColor();
			removeChildren();

			if(m_quad)
				m_quad.dispose();		

			m_quad = new Quad(lineSize, lineSize, color);
			m_quad.x = -lineSize/2;
			m_quad.y = -lineSize/2;
			addChild(m_quad);
			

//			var number:String = ""+count;
//			var txt:TextField = new TextField(10, 10, number, "Veranda", 6,0x00ff00); 
//			txt.y = 1;
//			txt.x = 1;
//			m_shape.addChild(txt);
//			addChild(m_shape);
		}
		
		override public function hasError():Boolean
		{
			return m_hasError;
		}
		
		public function onEnterFrame(event:Event):void
		{
			if(m_isDirty)
			{
				draw();
				m_isDirty = false;
			}
		}
	}
}