package scenes.game.display
{
	import flash.geom.Point;
	
	import starling.display.DisplayObjectContainer;
	import starling.display.Shape;
	import starling.events.Event;
	
	public class GameEdgeContainer extends GameComponent
	{
		public var m_fromNode:GameNode;
		public var m_toNode:GameNode;
		
		public var m_edgeArray:Array;
		public var globalPosition:Point;
		
		protected var m_edgeSegments:Vector.<GameEdgeSegment>;
		private var m_edgeJoints:Vector.<GameEdgeJoint>;
		
		//save start and end points, so we can remake line
		private var m_startPoint:Point;
		private var m_endPoint:Point;
		public var m_startJoint:GameEdgeJoint;
		public var m_endJoint:GameEdgeJoint;
		
		private var m_jointPoints:Array;
		
		private var m_nodeExtensionDistance:Number = 3;
		public var incomingEdgePosition:int;
		public var outgoingEdgePosition:int;
		public var m_originalEdge:Boolean;
		
		//use for figuring out closest wall
		public static var LEFT_WALL:int = 1;
		public static var RIGHT_WALL:int = 2;
		public static var TOP_WALL:int = 3;
		public static var BOTTOM_WALL:int = 4;
		private var m_recreateEdge:Boolean = true;
		
		public static var WIDE_WIDTH:int = 3;
		public static var NARROW_WIDTH:int = 1;
		
		public static var CREATE_JOINT:String = "create_joint";
		
		public function GameEdgeContainer(edgeArray:Array, fromNode:GameNode, toNode:GameNode)
		{
			super();
			m_edgeArray = edgeArray;
			m_fromNode = fromNode;
			m_toNode = toNode;
			m_originalEdge = true;
			
			m_startPoint = edgeArray[0];
			m_endPoint = edgeArray[edgeArray.length-1];
			
			addEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
			addEventListener(Event.REMOVED_FROM_STAGE, onRemovedFromStage);	
		}
		
		public function onAddedToStage(event:starling.events.Event):void
		{
			createOriginalChildren();
			positionOriginalChildren();

			rubberBandEdge(new Point(), true);
			addEventListener(Event.ENTER_FRAME, onEnterFrame);
			addEventListener(CREATE_JOINT, onCreateJoint);
			m_isDirty = true;
			
		}
		
		private function onRemovedFromStage():void
		{
			this.removeChildren(0, -1, true);
			
			m_edgeSegments = null;
			m_edgeJoints = null;
			
			removeEventListener(Event.ENTER_FRAME, onEnterFrame);
			removeEventListener(CREATE_JOINT, onCreateJoint);
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
		
		//create edge from cubic bezier curve points
		public function createOriginalChildren():void
		{
			if(m_edgeSegments == null)
			{
				m_edgeSegments = new Vector.<GameEdgeSegment>;			
				m_edgeJoints = new Vector.<GameEdgeJoint>;
				
				var previousSegment:GameComponent = m_fromNode;
				//draw each edge segment separately, move to where they should be, and add them
				for(var index:int = 1; index<m_edgeArray.length; index+=3)
				{
					var segment:GameEdgeSegment;
					var isLastSegment:Boolean = false;
					//check to see if we are at the end of the edges
					if(index+1 == m_edgeArray.length)
						isLastSegment = true;
					
					segment = new GameEdgeSegment(this, m_fromNode, m_toNode, isLastSegment, isLastSegment);
					m_edgeSegments.push(segment);
					
					//add joint at start of segment
					var joint:GameEdgeJoint;
					var connectionJoint:Boolean = false;
					if(index == 1)
					{
						if(m_startJoint)
							joint = m_startJoint;
						else
						{
							connectionJoint = true;
							joint = new GameEdgeJoint(this, previousSegment, segment, false, connectionJoint);
							m_startJoint = joint;
						}
					}
					else
						joint = new GameEdgeJoint(this, previousSegment, segment, isLastSegment, connectionJoint);
					
					joint.count = index;
					m_edgeJoints.push(joint);
					previousSegment = segment;
				}
				//add joint at end
				if(m_endJoint)
					m_edgeJoints.push(m_endJoint);
				else
				{
					m_endJoint = new GameEdgeJoint(this, previousSegment, m_toNode, false, true);
					m_edgeJoints.push(m_endJoint);
				}
			}
		}
		
		//create edge segments and joints from simple point list (m_jointPoints)
		public function createChildren(currentDragSegment:GameEdgeSegment = null, segmentIndex:int = -1):void
		{
			if(m_recreateEdge)
			{
				m_recreateEdge = false;
				disposeChildren();
				
				m_edgeSegments = new Vector.<GameEdgeSegment>;			
				m_edgeJoints = new Vector.<GameEdgeJoint>;
				

				m_edgeJoints.push(m_startJoint);
				
				var previousSegment:GameComponent = m_fromNode;
				//draw each edge segment separately, move to where they should be, and add them
				for(var index:int = 1; index<m_jointPoints.length; index++)
				{
					var segment:GameEdgeSegment;
					//nodeExtension and extensionExtensions can't be dragged
					var isNodeExtensionSegment:Boolean = false;
					if(index == 1 ||  index+1 == m_jointPoints.length)
						isNodeExtensionSegment = true;
					var islastSegment:Boolean = false;
					if(index+1 == m_jointPoints.length)
						islastSegment = true;
					
					//add back in current drag segment
					if(index-1 == segmentIndex)
						segment = currentDragSegment;
					else
						segment = new GameEdgeSegment(this, m_fromNode, m_toNode, isNodeExtensionSegment, islastSegment);
					segment.index = index-1;
					m_edgeSegments.push(segment);
					addChild(segment);
					//add joint at start of segment
					var isMarkerJoint:Boolean = false;
					if(index+2 == m_jointPoints.length)
						isMarkerJoint = true;
					var joint:GameEdgeJoint;
					if(index+1 == m_jointPoints.length)
						joint = m_endJoint;
					else
						joint = new GameEdgeJoint(this, previousSegment, segment, isMarkerJoint, false);
					addChild(joint);
					joint.count = index;
					m_edgeJoints.push(joint);
					previousSegment = segment;
				}
			}
		}
		
		public function positionOriginalChildren():void
		{			
			var previousSegment:GameEdgeSegment = null;
			//move each segment to where they should be, and add them
			var segIndex:int = 0;
			var segment:GameEdgeSegment;
			for(; segIndex<m_edgeSegments.length; segIndex++)
			{
				segment = m_edgeSegments[segIndex];
				var relatedEdgeIndex:int = segIndex*3;
				segment.updateSegment(m_edgeArray[relatedEdgeIndex], m_edgeArray[relatedEdgeIndex+1]);
				var lineSize:Number = segment.isWide() ? GameEdgeContainer.WIDE_WIDTH : GameEdgeContainer.NARROW_WIDTH;
				segment.x = m_edgeArray[relatedEdgeIndex].x - .5*lineSize;
				segment.y = m_edgeArray[relatedEdgeIndex].y;
				addChild(segment);
				
				var joint:GameEdgeJoint = m_edgeJoints[segIndex];
				joint.x = segment.x;
				joint.y = segment.y;
				addChild(joint);
			}
			
			//deal with last joint special, since it's at the end of a segment
			var lastJoint:GameEdgeJoint = m_edgeJoints[segIndex];
			//add joint at end
			lastJoint.x = segment.x+segment.m_endPt.x;
			lastJoint.y = segment.y+segment.m_endPt.y;
			addChild(lastJoint);
		}
		
		public function positionChildren():void
		{			
			var previousSegment:GameEdgeSegment = null;
			//move each segment to where they should be, and add them
			var segIndex:int = 0;
			var segment:GameEdgeSegment;
			for(; segIndex<m_edgeSegments.length; segIndex++)
			{
				segment = m_edgeSegments[segIndex];
				var startPoint:Point = m_jointPoints[segIndex];
				var endPoint:Point = m_jointPoints[segIndex+1];

				//if(startPoint.x < endPoint.x || startPoint.y < endPoint.y)
				//{
					segment.updateSegment(startPoint, endPoint);
					segment.x = m_jointPoints[segIndex].x;
					segment.y = m_jointPoints[segIndex].y;
				//}
				//else
				//{
					//segment.updateSegment(endPoint, startPoint);
					//segment.x = m_jointPoints[segIndex+1].x;
					//segment.y = m_jointPoints[segIndex+1].y;
				//}
				addChild(segment);
				
				var joint:GameEdgeJoint = m_edgeJoints[segIndex];
				if(segIndex != 0)
				{ 
					joint.x = m_jointPoints[segIndex].x;
					joint.y = m_jointPoints[segIndex].y;
				}
				addChild(joint);
			}
			
			//deal with last joint special, since it's at the end of a segment
			var lastJoint:GameEdgeJoint = m_edgeJoints[segIndex];
			//add joint at end
			if(segment.m_endPt.x > 0 || segment.m_endPt.y > 0)
			{
				lastJoint.x = segment.x+segment.m_endPt.x;
				lastJoint.y = segment.y+segment.m_endPt.y;
			}
			else
			{
				lastJoint.x = segment.x-segment.m_endPt.x;
				lastJoint.y = segment.y-segment.m_endPt.y;
								
			}
			addChild(lastJoint);
		}
		
		public function rubberBandEdge(deltaPoint:Point, isOutgoing:Boolean):void 
		{
			if(!m_isSelected)
			{
				if(m_originalEdge)
				{
					removeChildren();
					m_originalEdge = false;
					m_edgeSegments = null;
				}
				
				if(isOutgoing)
				{
					m_startJoint.x = m_startJoint.x + deltaPoint.x;
					m_startJoint.y = m_startJoint.y + deltaPoint.y;
				}
				else
				{
					m_endJoint.x = m_endJoint.x+deltaPoint.x;
					m_endJoint.y = m_endJoint.y+deltaPoint.y;
				}
				
				var startingJointPointsLength:int = 0;
				if(m_jointPoints)
					startingJointPointsLength = m_jointPoints.length;
				removeChildren();
				createJointPointsArray();
				
				if(m_jointPoints.length != startingJointPointsLength)
					m_recreateEdge = true;
				else
					m_recreateEdge = false;
				
				createChildren();
				positionChildren();
				m_isDirty = true;
			}
		}
		
		public function rubberBandEdgeSegment(deltaPoint:Point, segment:GameEdgeSegment):void 
		{
			//probably should somehow make this work
			if(this.m_originalEdge)
				return;
			
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
		//create edge
		private function createJointPointsArray():void
		{
			m_jointPoints = new Array(6);
			//create easy parts
			makeInitialNodesAndExtension(m_startJoint, 0, 1);
			makeInitialNodesAndExtension(m_endJoint, 5, 4);
			
			makeMainEdgeParts();
			
		}
		
		//nodeExtension and the extensionExtension are the same to start
		private function makeInitialNodesAndExtension(joint:GameEdgeJoint, startIndex:int, nodeIndex:int):void
		{
			m_jointPoints[startIndex] = new Point(joint.x, joint.y);
			switch(joint.m_closestWall)
			{
				case TOP_WALL:
					m_jointPoints[nodeIndex] = new Point(joint.x, joint.y - m_nodeExtensionDistance - incomingEdgePosition*3);
					break;
				case BOTTOM_WALL:
					m_jointPoints[nodeIndex] = new Point(joint.x, joint.y + m_nodeExtensionDistance + outgoingEdgePosition*3);
					break;
			}
		}
		
		
		private function makeMainEdgeParts():void
		{
			var xDistance:Number = m_jointPoints[4].x - m_jointPoints[1].x;
			var yDistance:Number = m_jointPoints[4].y - m_jointPoints[1].y;
			setBottomWallOutputConnection(xDistance, yDistance);

		}
		
		private function setBottomWallOutputConnection(xDistance:Number, yDistance:Number):void
		{
			var gStartPt:Point = localToGlobal(m_jointPoints[1]);
			var gEndPt:Point = localToGlobal(m_jointPoints[4]);
			var gToNodeLeftSide:Number = m_toNode.x;
			var gToNodeRightSide:Number = m_toNode.x+m_toNode.width;
			var gToNodeTopSide:Number = m_toNode.y;
			var gToNodeBottomSide:Number = m_toNode.y+m_toNode.height;
			var gFromNodeLeftSide:Number = m_fromNode.x;
			var gFromNodeRightSide:Number = m_fromNode.x+m_fromNode.width;
			var gFromNodeTopSide:Number = m_fromNode.y;
			var gFromNodeBottomSide:Number = m_fromNode.y+m_fromNode.height;

			//this is really simple compared to how it was, is this really right
			m_jointPoints[2] = new Point(m_jointPoints[1].x + .5*xDistance, m_jointPoints[1].y);
			m_jointPoints[3] = new Point(m_jointPoints[1].x + .5*xDistance, m_jointPoints[4].y);						
		}
		
		override public function componentSelected(isSelected:Boolean):void
		{
			m_isDirty = true;
			m_isSelected = isSelected;
		}
		
		public function draw():void
		{
			onEnterFrame();
			
			//redraw connection node
			m_toNode.draw();
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
			return (m_fromNode.isWide() && !m_toNode.isWide());
		}
		
		override public function getColor():int
		{
			return hasError() ? ERROR_COLOR : super.getColor();
		}
		
		public function onEnterFrame():void
		{					
			if(m_isDirty)
			{
				trace("dirty edge");
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
	}
}
