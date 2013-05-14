package scenes.game.display
{
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import starling.display.DisplayObjectContainer;
	import starling.display.Quad;
	import starling.display.Shape;
	import starling.events.Event;
	
	public class GameEdgeContainer extends GameComponent
	{
		public var m_fromComponent:GameNodeBase;
		public var m_toComponent:GameNodeBase;
		private var m_dir:String;
		
		public var m_edgeArray:Array;
		
		protected var m_edgeSegments:Vector.<GameEdgeSegment>;
		private var m_edgeJoints:Vector.<GameEdgeJoint>;
		
		//save start and end points, so we can remake line
		private var m_startPoint:Point;
		private var m_endPoint:Point;
		public var m_startJoint:GameEdgeJoint;
		public var m_endJoint:GameEdgeJoint;
		
		private var m_jointPoints:Array;
		
		public var incomingEdgePosition:int;
		public var outgoingEdgePosition:int;
		
		//use for figuring out closest wall
		public static var LEFT_WALL:int = 1;
		public static var RIGHT_WALL:int = 2;
		public static var TOP_WALL:int = 3;
		public static var BOTTOM_WALL:int = 4;
		private var m_recreateEdge:Boolean = true;
		
		public static var WIDE_WIDTH:Number = .3;
		public static var NARROW_WIDTH:Number = .1;
		private static var EXTENSION_LENGTH:Number = .3;
		
		public static var CREATE_JOINT:String = "create_joint";
		public static var DIR_BOX_TO_JOINT:String = "2joint";
		public static var DIR_JOINT_TO_BOX:String = "2box";
		
		public function GameEdgeContainer(_id:String, edgeArray:Array, _boundingBox:Rectangle, fromComponent:GameNodeBase, toComponent:GameNodeBase, dir:String)
		{
			super(_id);
			m_edgeArray = edgeArray;
			m_fromComponent = fromComponent;
			m_toComponent = toComponent;
			m_dir = dir;
			if (!toComponent) {
				var d = 1;
			}
			fromComponent.setOutgoingEdge(this);
			toComponent.setIncomingEdge(this);
			
			m_startPoint = edgeArray[0];
			m_endPoint = edgeArray[edgeArray.length-1];
			
			m_boundingBox = _boundingBox;

			createChildren();
			
			addEventListener(Event.ADDED_TO_STAGE, onAddedToStage);	
			addEventListener(CREATE_JOINT, onCreateJoint);
			addEventListener(Event.ENTER_FRAME, onEnterFrame);
			m_isDirty = true;
		}
		
		//assume to and from nodes are set in place, so we can fix our size and bounding box
		protected function onAddedToStage(event:starling.events.Event):void
		{
			//fix up connection points and adjust bounding box if needed
			m_boundingBox.y = m_fromComponent.y + m_fromComponent.height;
			m_boundingBox.height = m_toComponent.y - m_boundingBox.y;
			m_startPoint.y = 0;
			m_endPoint.y =  m_boundingBox.height;
			
			positionChildren();
			
			//touch up color and width
			setIncomingColor(m_fromComponent.getColor());
			setOutgoingColor(m_toComponent.getColor());
			
			setIncomingWidth(m_fromComponent.m_isWide);
			setOutgoingWidth(m_toComponent.m_isWide);
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
			m_edgeSegments = null;
			m_edgeJoints = null;
			if (hasEventListener(CREATE_JOINT)) {
				removeEventListener(CREATE_JOINT, onCreateJoint);
			}
			if (hasEventListener(Event.ADDED_TO_STAGE)) {
				removeEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
			}
			super.dispose();
		}
		
		private function onCreateJoint(event:Event):void
		{
			//get the segment index as a guide to where to add the joint
			var segment:GameEdgeSegment = event.data as GameEdgeSegment;
			var segmentIndex:int = m_edgeSegments.indexOf(segment);
			var startingJointIndex:int = segmentIndex;
			var newJointPt:Point = segment.currentTouch.getLocation(this);
			//if this is a horizontal line, use the y coordinate of the current joints, else visa-versa
			if(m_jointPoints[startingJointIndex].x != m_jointPoints[startingJointIndex+1].x)
				newJointPt.y = m_jointPoints[startingJointIndex].y;
			else
				newJointPt.x = m_jointPoints[startingJointIndex].x;
			
			var secondJointPt:Point = newJointPt.clone();
			m_jointPoints.splice(startingJointIndex+1, 0, newJointPt, secondJointPt);
			m_recreateEdge = true;
			createChildren();
			positionChildren();
			
		}
		
		//create edge segments and joints from simple point list (m_jointPoints)
		public function createChildren(currentDragSegment:GameEdgeSegment = null, segmentIndex:int = -1):void
		{
			m_edgeSegments = new Vector.<GameEdgeSegment>;			
			m_edgeJoints = new Vector.<GameEdgeJoint>;
								
			//create start joint, and then create rest when we create connecting segment
			m_startJoint = new GameEdgeJoint(false, true);
			m_edgeJoints.push(m_startJoint);
						
			var numJoints:int = 6;
			//now create segments and joints for second position to n
			for(var index:int = 1; index<numJoints; index++)
			{
				var isLastSegment:Boolean = false;
				if(index+2 == numJoints)
					isLastSegment = true;
				var segment:GameEdgeSegment = new GameEdgeSegment(m_dir, isLastSegment);
				m_edgeSegments.push(segment);
				
				//add joint at end of segment
				var isMarkerJoint:Boolean = false;
				if(index+2 == numJoints)
					isMarkerJoint = true;
				var isEndJoint:Boolean = false;
				var joint:GameEdgeJoint;
				if(index+1 != numJoints)
				{
					joint = new GameEdgeJoint(isMarkerJoint, isEndJoint);
					m_edgeJoints.push(joint);
				}
			}
			m_endJoint = new GameEdgeJoint(false, true);
			m_edgeJoints.push(m_endJoint);
		}
		
		public function positionChildren():void
		{			
			createJointPointsArray(m_startPoint, m_endPoint);

			var previousSegment:GameEdgeSegment = null;
			//move each segment to where they should be, and add them, then add front joint
			var a:int = 0;
			var b:int = 1;
			
			var segment:GameEdgeSegment;
			for(var segIndex:int = 0; segIndex<m_edgeSegments.length; segIndex++)
			{
				segment = m_edgeSegments[segIndex];
				var startPoint:Point = m_jointPoints[segIndex];
				var endPoint:Point = m_jointPoints[segIndex+1];

				segment.updateSegment(startPoint, endPoint);
				segment.x = m_jointPoints[segIndex].x;
				segment.y = m_jointPoints[segIndex].y;

				addChild(segment);
				
				var joint:GameEdgeJoint = m_edgeJoints[segIndex];
				joint.x = m_jointPoints[segIndex].x;
				joint.y = m_jointPoints[segIndex].y;
				
				addChild(joint);
			}
			
			//deal with last joint special, since it's at the end of a segment
			var lastJoint:GameEdgeJoint = m_edgeJoints[m_edgeSegments.length];
			//add joint at end
			lastJoint.x = m_jointPoints[m_edgeSegments.length].x;
			lastJoint.y = m_jointPoints[m_edgeSegments.length].y;
			addChild(lastJoint);
		}
		
		public function rubberBandEdge(deltaPoint:Point, isOutgoing:Boolean):void 
		{
			if(!m_isSelected)
			{
				if(isOutgoing)
				{
					m_startPoint.x = m_startPoint.x + deltaPoint.x;
					m_startPoint.y = m_startPoint.y + deltaPoint.y;
				}
				else
				{
					m_endPoint.x = m_endPoint.x+deltaPoint.x;
					m_endPoint.y = m_endPoint.y+deltaPoint.y;
				}

				positionChildren();
				
				m_isDirty = true;
			}
		}
		
		public function rubberBandEdgeSegment(deltaPoint:Point, segment:GameEdgeSegment):void 
		{
			//update both end joints, and then redraw
			var segmentIndex:int = m_edgeSegments.indexOf(segment);
			//if connected to end segment, add a expansion joint in between. Test both ends.
			if(segmentIndex == 1)
			{
				m_jointPoints.splice(1, 0, m_jointPoints[1].clone());
				segmentIndex++;
				m_recreateEdge = true;
			}
			if(segmentIndex+3 == m_jointPoints.length)
			{
				m_jointPoints.splice(-2, 0, m_jointPoints[m_jointPoints.length-2].clone());
				m_recreateEdge = true;
			}
		
			//check for horizontal or vertical
			if(m_jointPoints[segmentIndex].x != m_jointPoints[segmentIndex+1].x)
			{
				m_jointPoints[segmentIndex].y += deltaPoint.y;
				m_jointPoints[segmentIndex+1].y += deltaPoint.y;
			}
			else
			{
				m_jointPoints[segmentIndex].x += deltaPoint.x;
				m_jointPoints[segmentIndex+1].x += deltaPoint.x;
			}
			
			//check for any really short segments, and if found, remove them. Start at the end and work backwards
			//don't do if we just added a segment
			//!!Interesting idea, but there are flaws, in that you can now create diagonal lines
//			if(!m_recreateEdge)
//				for(var i:int = m_jointPoints.length - 2; i >= 0; i--)
//				{
//					trace(Math.abs(m_jointPoints[i].x-m_jointPoints[i+1].x) + Math.abs(m_jointPoints[i].y-m_jointPoints[i+1].y));
//					if(Math.abs(m_jointPoints[i].x-m_jointPoints[i+1].x) + Math.abs(m_jointPoints[i].y-m_jointPoints[i+1].y) < .1)
//					{
//						m_jointPoints.splice(i, 1);
//						m_recreateEdge = true;
//						trace("remove " + i); 
//					}
//				}
			
			//need to keep current segment so I have a drag handle still
			createChildren(segment, segmentIndex);
			positionChildren();
			m_isDirty = true;
		}
		
		//create 6 joints
		//  	beginning connection
		//		end of outgoing port extension
		//		bend point 1
		//		bend point 2
		//		start of incoming port extension
		//		end connection
		private function createJointPointsArray(startPoint:Point, endPoint:Point):void
		{			
			m_jointPoints = new Array(6);
			//create easy parts
			makeInitialNodesAndExtension(startPoint, 0, 1, true);
			makeInitialNodesAndExtension(endPoint, 5, 4, false);
			
			makeMainEdgeParts();
			
		}
		
		private function makeInitialNodesAndExtension(connectionPoint:Point, startIndex:int, nodeIndex:int, isStartPoint:Boolean):void
		{
			m_jointPoints[startIndex] = connectionPoint.clone();
			if(isStartPoint)
				m_jointPoints[nodeIndex] = new Point(connectionPoint.x, connectionPoint.y + EXTENSION_LENGTH + incomingEdgePosition*.2);
			else
				m_jointPoints[nodeIndex] = new Point(connectionPoint.x, connectionPoint.y - EXTENSION_LENGTH - outgoingEdgePosition*.2);
		}
		
		
		private function makeMainEdgeParts():void
		{
			var xDistance:Number = m_jointPoints[4].x - m_jointPoints[1].x;
			var yDistance:Number = m_jointPoints[4].y - m_jointPoints[1].y;
			setBottomWallOutputConnection(xDistance, yDistance);

		}
		
		private function setBottomWallOutputConnection(xDistance:Number, yDistance:Number):void
		{
//			var gStartPt:Point = localToGlobal(m_jointPoints[1]);
//			var gEndPt:Point = localToGlobal(m_jointPoints[4]);
//			var gToNodeLeftSide:Number = m_joint.x;
//			var gToNodeRightSide:Number = m_joint.x+m_joint.width;
//			var gToNodeTopSide:Number = m_joint.y;
//			var gToNodeBottomSide:Number = m_joint.y+m_joint.height;
//			var gFromNodeLeftSide:Number = m_node.x;
//			var gFromNodeRightSide:Number = m_node.x+m_node.width;
//			var gFromNodeTopSide:Number = m_node.y;
//			var gFromNodeBottomSide:Number = m_node.y+m_node.height;

			if(m_jointPoints[1].y > m_jointPoints[4].y)
			{
				m_jointPoints[2] = new Point(m_jointPoints[1].x, m_jointPoints[1].y + .5*yDistance);
				m_jointPoints[3] = new Point(m_jointPoints[4].x, m_jointPoints[4].y - .5*yDistance);	
			}
			else
			{
				m_jointPoints[2] = new Point(m_jointPoints[1].x, m_jointPoints[1].y + .5*yDistance);
				m_jointPoints[3] = new Point(m_jointPoints[4].x, m_jointPoints[4].y - .5*yDistance);	
			}
		}
		
		override public function componentSelected(isSelected:Boolean):void
		{
			m_isDirty = true;
			m_isSelected = isSelected;
		}
		
		//only use if the container it's self draws specific items.
		public function draw():void
		{
//			var quad:Quad = new Quad(this.m_boundingBox.width, this.m_boundingBox.height, 0xff0000);
//			addChild(quad);
		}
		
		override public function getScore():Number
		{
			return hasError() ? Constants.ERROR_POINTS : 0;
		}
		
		override public function getWideScore():Number
		{
			return getScore();
		}
		
		override public function getNarrowScore():Number
		{
			return getScore();
		}
		
		public function hasError():Boolean
		{
			if (toJoint) {
				// Edges going into joints can't fail
				return false;
			} else {
				return (!m_fromComponent.m_isWide && m_toComponent.m_isWide);
			}
		}
		
		
		public function onEnterFrame():void
		{					
			if(m_isDirty)
			{
				draw();
				for each(var edgeSegment:GameEdgeSegment in m_edgeSegments)
				{
					edgeSegment.m_isDirty = true;
				}
				
				for each(var joint:GameEdgeJoint in m_edgeJoints)
				{
					if (hasError())
					{
						joint.m_showError = true;
					}
					else
					{
						joint.m_showError = false;
					}
					joint.m_isDirty = true;
				}
				
				m_isDirty = false;
			}
		}
		
		// point should be in local coordinates
		public function setStartPosition(newPoint:Point):void
		{
			m_startJoint.x = newPoint.x;
			m_startJoint.y = newPoint.y;
		}
		
		// point should be in local coordinates
		public function setEndPosition(newPoint:Point):void
		{
			m_endJoint.x = newPoint.x;
			m_endJoint.y = newPoint.y;
		}
		
		public function setOriginalStartPosition(newPoint:Point):void
		{
			m_startJoint.m_originalPoint.x = newPoint.x;
			m_startJoint.m_originalPoint..y = newPoint.y;
		}
		
		public function setOriginalEndPosition(newPoint:Point):void
		{
			m_endJoint.m_originalPoint.x = newPoint.x;
			m_endJoint.m_originalPoint.y = newPoint.y;
		}
		
		public function get toBox():Boolean
		{
			return (m_dir == DIR_JOINT_TO_BOX);
		}
		
		public function get toJoint():Boolean
		{
			return (m_dir == DIR_BOX_TO_JOINT);
		}
		
		public static function sortOutgoingXPositions(x:GameEdgeContainer, y:GameEdgeContainer):Number
		{
			if(x.m_edgeArray[0].x < y.m_edgeArray[0].x)
				return -1;
			else
				return 1;
		}
		
		public static function sortIncomingXPositions(x:GameEdgeContainer, y:GameEdgeContainer):Number
		{
			if(x.m_edgeArray[x.m_edgeArray.length-1].x < y.m_edgeArray[y.m_edgeArray.length-1].x)
				return -1;
			else
				return 1;
		}
		
		//set children's width, based on incoming and outgoing component
		public function setIncomingWidth(isWide:Boolean):void
		{
			if(m_edgeSegments != null)
				for(var segIndex:int = 0; segIndex<m_edgeSegments.length-1; segIndex++)
				{
					var segment:GameEdgeSegment = m_edgeSegments[segIndex];
					if(segment.m_isWide != isWide)
					{
						segment.m_isWide = isWide;
						segment.m_isDirty = true;
					}
				}
			
			if(m_edgeJoints != null)
				for(var jointIndex:int = 0; jointIndex<this.m_edgeJoints.length-1; jointIndex++)
				{
					var joint:GameEdgeJoint = m_edgeJoints[jointIndex];
					if(joint.m_isWide != isWide)
					{
						joint.m_isWide = isWide;
						joint.m_isDirty = true;
					}
				}
		}
		
		//set children's width, based on incoming and outgoing component
		public function setOutgoingWidth(isWide:Boolean):void
		{
			if(m_edgeSegments != null)
			{
				var segment:GameEdgeSegment = m_edgeSegments[m_edgeSegments.length-1];
				if(segment.m_isWide != isWide)
				{
					segment.m_isWide = isWide;
					segment.m_isDirty = true;
				}
			}

			if(m_edgeJoints != null)
			{
				var joint:GameEdgeJoint = m_edgeJoints[m_edgeJoints.length-1];
				if(joint.m_isWide != isWide)
				{
					joint.m_isWide = isWide;
					joint.m_isDirty = true;
				}
			}
		}
		
		//set children's color, based on incoming and outgoing component and error condition
		public function setIncomingColor(color:int):void
		{
			if(m_edgeSegments != null)
				for(var segIndex:int; segIndex<m_edgeSegments.length-1; segIndex++)
				{
					var segment:GameEdgeSegment = m_edgeSegments[segIndex];
					if(segment.m_color != color)
					{
						segment.m_color = color;
						segment.m_isDirty = true;
					}
				}
			
			if(m_edgeJoints != null)
				for(var jointIndex:int; jointIndex<this.m_edgeJoints.length-1; jointIndex++)
				{
					var joint:GameEdgeJoint = m_edgeJoints[jointIndex];
					if(joint.m_color != color)
					{
						joint.m_color = color;
						joint.m_isDirty = true;
					}
				}
		}
		
		//set children's color, based on incoming and outgoing component and error condition
		public function setOutgoingColor(color:int):void
		{
			if(m_edgeSegments != null)
			{
				var segment:GameEdgeSegment = m_edgeSegments[m_edgeSegments.length-1];
				if(segment.m_color != color)
				{
					segment.m_color = color;
					segment.m_isDirty = true;
				}
			}
			
			if(m_edgeJoints != null)
			{
				var joint:GameEdgeJoint = m_edgeJoints[m_edgeJoints.length-1];
					if(joint.m_color != color)
				{
					joint.m_color = color;
					joint.m_isDirty = true;
				}
			}

		}
		

	}
}
