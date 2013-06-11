package scenes.game.display
{
	import events.BallTypeChangeEvent;
	import events.EdgeTroublePointEvent;
	import events.PortTroublePointEvent;
	
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import graph.Edge;
	import graph.NodeTypes;
	import graph.Port;
	import graph.SubnetworkPort;
	
	import starling.display.DisplayObjectContainer;
	import starling.display.Quad;
	import starling.display.Shape;
	import starling.events.Event;
	import starling.events.Touch;
	import starling.events.TouchEvent;
	import starling.events.TouchPhase;
	
	public class GameEdgeContainer extends GameComponent
	{
		public var m_fromComponent:GameNodeBase;
		public var m_toComponent:GameNodeBase;
		public var m_fromPortID:String;
		public var m_toPortID:String;
		public var m_extensionEdge:GameEdgeContainer;
		
		private var m_dir:String;
		private var m_useExistingPoints:Boolean;
		private var m_outgoingIsWide:Boolean = false;
		public var m_edgeArray:Array;
		
		protected var m_edgeSegments:Vector.<GameEdgeSegment>;
		private var m_edgeJoints:Vector.<GameEdgeJoint>;
		public var m_outputSegmentIsEditable:Boolean = true;
		
		//save start and end points, so we can remake line
		public var m_startPoint:Point;
		public var m_endPoint:Point;
		public var m_savedStartPoint:Point;
		public var m_savedEndPoint:Point;
		public var m_startJoint:GameEdgeJoint;
		public var m_endJoint:GameEdgeJoint;
		public var m_markerJoint:GameEdgeJoint;
		
		public var hasChanged:Boolean;
		public var restoreEdge:Boolean;
		
		private var m_innerBoxSegment:InnerBoxSegment;
		private var m_savedInnerBoxSegmentLocation:Point;
		
		public var m_jointPoints:Array;
		public var m_savedJointPoints:Array;
		
		public var incomingEdgePosition:Number;
		public var outgoingEdgePosition:Number;
		
		public var graphEdge:Edge;
		public var edgeIsCopy:Boolean;
		
		//use for figuring out closest wall
		public static var LEFT_WALL:int = 1;
		public static var RIGHT_WALL:int = 2;
		public static var TOP_WALL:int = 3;
		public static var BOTTOM_WALL:int = 4;
		
		public static var WIDE_WIDTH:Number = .3 * Constants.GAME_SCALE;
		public static var NARROW_WIDTH:Number = .1 * Constants.GAME_SCALE;
		private static var EXTENSION_LENGTH:Number = .3 * Constants.GAME_SCALE;
		
		public static var CREATE_JOINT:String = "create_joint";
		public static var DIR_BOX_TO_JOINT:String = "2joint";
		public static var DIR_JOINT_TO_BOX:String = "2box";
		
		public static var HOVER_EVENT_OVER:String = "hover_event_in";
		public static var HOVER_EVENT_OUT:String = "hover_event_out";
		
		public static var RUBBER_BAND_SEGMENT:String = "rubber_band_segment";
		public static var SAVE_CURRENT_LOCATION:String = "save_current_location";
		public static var RESTORE_CURRENT_LOCATION:String = "restore_current_location";
		
		public var NUM_JOINTS:int = 6;
		
		public function GameEdgeContainer(_id:String, edgeArray:Array, _boundingBox:Rectangle, 
										  fromComponent:GameNodeBase, toComponent:GameNodeBase, 
										  _fromPortID:String, _toPortID:String, dir:String,
										  _graphEdge:Edge, useExistingPoints:Boolean = false,
										  _graphEdgeIsCopy:Boolean = false)
		{
			super(_id);
			
			m_edgeArray = edgeArray;
			m_fromComponent = fromComponent;
			m_toComponent = toComponent;
			m_fromPortID = _fromPortID;
			m_toPortID = _toPortID;
			m_dir = dir;
			graphEdge = _graphEdge;
			edgeIsCopy = _graphEdgeIsCopy;
			m_isEditable = graphEdge.editable;
			m_useExistingPoints = useExistingPoints;
			
			m_outputSegmentIsEditable = toBox ? (m_toComponent as GameNodeBase).isEditable() : m_isEditable;
			// Also even if box is editable, if contains a pinch point then make editable = false
			if (toBox && graphEdge.has_pinch && !edgeIsCopy) {
				m_outputSegmentIsEditable = false;
			}
			//start these at their given port numbers
			outgoingEdgePosition = parseInt(m_fromPortID);
			incomingEdgePosition = parseInt(m_toPortID);
			fromComponent.setOutgoingEdge(this);
			toComponent.setIncomingEdge(this);
			
			m_startPoint = edgeArray[0];
			m_endPoint = edgeArray[edgeArray.length-1];
			
			var innerBoxPt:Point;
			var boxHeight:Number;
			var startingCircle:Boolean = false;
			if (toBox) {
				boxHeight =(m_toComponent as GameNode).m_boundingBox.height;
				innerBoxPt = new Point(m_endPoint.x, m_endPoint.y + boxHeight / 2);
			} else {
				boxHeight = (m_fromComponent as GameNode).m_boundingBox.height;
				innerBoxPt = new Point(m_startPoint.x, m_startPoint.y - boxHeight / 2);
				switch (graphEdge.from_port.node.kind) {
					case NodeTypes.INCOMING:
					case NodeTypes.START_PIPE_DEPENDENT_BALL:
						startingCircle = true;
						break;
				}
			}
			if(fromComponent is GameNode)
				m_extensionEdge = (fromComponent as GameNode).getExtensionEdge(_fromPortID, true);
			else
				m_extensionEdge = (toComponent as GameNode).getExtensionEdge(_toPortID, false);
			if(m_extensionEdge)
				m_extensionEdge.m_extensionEdge = this;
			
			m_innerBoxSegment = new InnerBoxSegment(innerBoxPt, boxHeight / 2, m_dir, m_isWide, startingCircle);
			
			m_boundingBox = _boundingBox;
			
			if (isTopOfEdge()) {
				if (graphEdge.has_pinch && !edgeIsCopy) {
					listenToEdgeForTroublePoints(graphEdge);
				}
				listenToPortForTroublePoints(graphEdge.from_port);
			} else {
				listenToPortForTroublePoints(graphEdge.to_port);
			}
			graphEdge.addEventListener(getBallTypeChangeEvent(), onBallTypeChange);
			
			
			addEventListener(Event.ADDED_TO_STAGE, onAddedToStage);	

			m_isDirty = true;
		}
		
		//assume to and from nodes are set in place, so we can fix our size and bounding box
		protected function onAddedToStage(event:starling.events.Event):void
		{
			if(m_edgeArray.length == 2)
			{
				createJointPointsArray(m_startPoint, m_endPoint);
				//fix up edge array also
				m_edgeArray = new Array;
				for(var i:int = 0; i< m_jointPoints.length; i++)
				{
					var pt:Point = m_jointPoints[i];
					m_edgeArray.push(pt.clone());
				}
			}
			else
			{
				m_jointPoints = new Array();
				for(var i1:int = 0; i1< m_edgeArray.length; i1++)
				{
					var pt1:Point = m_edgeArray[i1];
					m_jointPoints.push(pt1.clone());
				}
			}
			
			createChildren()
			positionChildren();
			
			updateSize();
			m_isDirty = true;
			
			addEventListener(CREATE_JOINT, onCreateJoint);
			addEventListener(RUBBER_BAND_SEGMENT, onRubberBandSegment);
			addEventListener(Event.ENTER_FRAME, onEnterFrame);
			addEventListener(HOVER_EVENT_OVER, onHoverOver);
			addEventListener(HOVER_EVENT_OUT, onHoverOut);
			addEventListener(SAVE_CURRENT_LOCATION, onSaveLocation);
			addEventListener(RESTORE_CURRENT_LOCATION, onRestoreLocation);
		}
		
		private function isTopOfEdge():Boolean
		{
			return ((!edgeIsCopy && toBox) || (edgeIsCopy && toJoint));
		}
		
		override public function updateSize():void
		{
			var toComponentNarrow:Boolean = !m_toComponent.isWide();
			var newIsWide:Boolean = m_isWide;
			var newOutgoingIsWide:Boolean = m_outgoingIsWide;
			
			if (isTopOfEdge()) {
				if (edgeIsCopy) {
					// If we're coming OUT of a subboard, use subboard pipe's outgoing width (if we have it) or default
					// NOTE: If the subboard appears on this level, no copy edge should exist, the outgoing edge of the
					// subboard should connect directly to the subboard output for this case (no extra edge)
					if (graphEdge.from_port is SubnetworkPort) {
						newIsWide = isBallWide((graphEdge.from_port as SubnetworkPort).default_ball_type);
						newOutgoingIsWide = toComponentNarrow ? false : newIsWide;
						//trace(graphEdge.from_port.edge.linked_edge_set.id + ":o" + graphEdge.from_port.port_id);
					} else {
						throw new Error("Warning: expecting case where box->joint edge copy is a Subnetwork outgoing edge.");
					}
				} else {
					// Special case: START_LARGE_BALL could possibly lead into narrow edge in which case we want to show
					// the top as being wide
					if (graphEdge.from_port.node.kind == NodeTypes.START_LARGE_BALL) {
						newIsWide = true;
					} else {
						newIsWide = isBallWide(graphEdge.enter_ball_type);
					}
					if (graphEdge.has_pinch && !edgeIsCopy) {
						newOutgoingIsWide = false;
					} else {
						newOutgoingIsWide = toComponentNarrow ? false : newIsWide;
					}
				}
			} else {
				newIsWide = isBallWide(graphEdge.exit_ball_type);
				newOutgoingIsWide = toComponentNarrow ? false : newIsWide;
			}
			
			if (newIsWide != m_isWide) {
				setIncomingWidth(newIsWide);
				if (toBox) {
					// Update the joint, which may restrict the incoming line(s)
					m_fromComponent.updateSize();
				} else {
					m_innerBoxSegment.setIsWide(m_isWide);
					m_innerBoxSegment.draw();
				}
				m_innerBoxSegment.draw();
			}
			if (toBox && m_innerBoxSegment.isWide() != newOutgoingIsWide) {
				m_innerBoxSegment.setIsWide(newOutgoingIsWide);
				m_innerBoxSegment.draw();
			}
			setOutgoingWidth(newOutgoingIsWide);
		}
		
		private function isBallWide(ballType:uint):Boolean
		{
			switch (ballType) {
				case Edge.BALL_TYPE_WIDE:
				case Edge.BALL_TYPE_WIDE_AND_NARROW:
					return true;
			}
			return false;
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
			for each (var removeListEdge:Edge in m_listeningToEdges) {
				removeListEdge.removeEventListener(EdgeTroublePointEvent.EDGE_TROUBLE_POINT_ADDED, onEdgeTroublePointAdded);
				removeListEdge.removeEventListener(EdgeTroublePointEvent.EDGE_TROUBLE_POINT_REMOVED, onEdgeTroublePointRemoved);
			}
			m_listeningToEdges = new Vector.<Edge>();
			for each (var removeListPort:Port in m_listeningToPorts) {
				removeListPort.removeEventListener(PortTroublePointEvent.PORT_TROUBLE_POINT_ADDED, onPortTroublePointAdded);
				removeListPort.removeEventListener(PortTroublePointEvent.PORT_TROUBLE_POINT_REMOVED, onPortTroublePointRemoved);
			}
			m_listeningToPorts = new Vector.<Port>();
			if (graphEdge) {
				graphEdge.removeEventListener(getBallTypeChangeEvent(), onBallTypeChange);
			}
			super.dispose();
		}
		
		private function onBallTypeChange(evt:BallTypeChangeEvent):void
		{
			updateSize();
		}
		
		private var m_listeningToEdges:Vector.<Edge> = new Vector.<Edge>();
		public function listenToEdgeForTroublePoints(_edge:Edge):void
		{
			if (m_listeningToEdges.indexOf(_edge) == -1) {
				if (_edge.has_error) {
					onEdgeTroublePointAdded(null);
				}
				_edge.addEventListener(EdgeTroublePointEvent.EDGE_TROUBLE_POINT_ADDED, onEdgeTroublePointAdded);
				_edge.addEventListener(EdgeTroublePointEvent.EDGE_TROUBLE_POINT_REMOVED, onEdgeTroublePointRemoved);
				m_listeningToEdges.push(_edge);
			}
		}
		
		private function onEdgeTroublePointAdded(evt:EdgeTroublePointEvent):void
		{
			if (m_hasError) {
				return;
			}
			m_hasError = true;
			m_isDirty = true;
		}
		
		private function onEdgeTroublePointRemoved(evt:EdgeTroublePointEvent):void
		{
			if (!m_hasError) {
				return;
			}
			m_hasError = false;
			m_isDirty = true;
		}
		
		private var m_listeningToPorts:Vector.<Port> = new Vector.<Port>();
		public function listenToPortForTroublePoints(_port:Port):void
		{
			if (m_listeningToPorts.indexOf(_port) == -1) {
				if (_port.has_error) {
					onPortTroublePointAdded(null);
				}
				_port.addEventListener(PortTroublePointEvent.PORT_TROUBLE_POINT_ADDED, onPortTroublePointAdded);
				_port.addEventListener(PortTroublePointEvent.PORT_TROUBLE_POINT_REMOVED, onPortTroublePointRemoved);
				m_listeningToPorts.push(_port);
			}
		}
		
		public function getListeningToPorts():Vector.<Port>
		{
			return m_listeningToPorts;
		}
		
		public function stopListeningToPort(_port:Port):void
		{
			var portIndx:int = m_listeningToPorts.indexOf(_port);
			if (portIndx > -1) {
				_port.removeEventListener(PortTroublePointEvent.PORT_TROUBLE_POINT_ADDED, onPortTroublePointAdded);
				_port.removeEventListener(PortTroublePointEvent.PORT_TROUBLE_POINT_REMOVED, onPortTroublePointRemoved);
				onPortTroublePointRemoved(null);
				m_listeningToPorts.splice(portIndx, 1);
			}
		}
		
		public function removeDuplicatePortListeners(_otherLine:GameEdgeContainer):void
		{
			var otherListeningPorts:Vector.<Port> = _otherLine.getListeningToPorts();
			for each (var listPort:Port in otherListeningPorts) {
				stopListeningToPort(listPort);
			}
		}
		
		private function onPortTroublePointAdded(evt:PortTroublePointEvent):void
		{
			if (m_hasError) {
				return;
			}
			m_hasError = true;
			if (m_markerJoint) {
				m_markerJoint.m_hasError = true;
			}
			m_isDirty = true;
		}
		
		private function onPortTroublePointRemoved(evt:PortTroublePointEvent):void
		{
			if (!m_hasError) {
				return;
			}
			m_hasError = false;
			if (m_markerJoint) {
				m_markerJoint.m_hasError = false;
			}
			m_isDirty = true;
		}
		
		private function onHoverOver(event:Event):void
		{
			handleHover(true);
			if(m_extensionEdge)
				m_extensionEdge.handleHover(true);
		}
		
		private function onHoverOut(event:Event):void
		{
			handleHover(false);
			if(m_extensionEdge)
				m_extensionEdge.handleHover(false);
		}
		
		private function onSaveLocation(event:Event):void
		{
			saveLocation();
			if(m_extensionEdge)
				m_extensionEdge.saveLocation();
		}
		
		private function saveLocation():void
		{
			hasChanged = false;
			restoreEdge = true;
			m_savedJointPoints = new Array;
			
			m_savedStartPoint = m_startPoint.clone();
			m_savedEndPoint = m_endPoint.clone();
			
			for each(var pt:Point in m_jointPoints)
				m_savedJointPoints.push(pt.clone());
			
			m_savedInnerBoxSegmentLocation = new Point(m_innerBoxSegment.interiorPt.x, m_innerBoxSegment.interiorPt.y);
		}
		
		private function onRestoreLocation(event:Event):void
		{
			restoreLocation();
						
			if(m_extensionEdge)
				m_extensionEdge.restoreLocation();
		}
		
		private function restoreLocation():void
		{
			if(restoreEdge)
			{
				m_jointPoints = m_savedJointPoints;
				m_startPoint = m_savedStartPoint;
				m_endPoint = m_savedEndPoint;
				positionChildren();
				m_innerBoxSegment.interiorPt.x = m_savedInnerBoxSegmentLocation.x;
				m_innerBoxSegment.interiorPt.y = m_savedInnerBoxSegmentLocation.y;
			}
			else
			{
				m_startPoint = m_savedStartPoint;
				m_endPoint = m_savedEndPoint;
				rubberBandEdge(new Point(), true);
			}
			m_isDirty = true;
		}
		
		private function handleHover(turnHoverOn:Boolean):void
		{
			for each (var joint:GameEdgeJoint in m_edgeJoints) 
			{
				joint.isHoverOn = turnHoverOn;
				joint.m_isDirty = true;
			}
			
			var segment:GameEdgeSegment;
			for(var segIndex:int = 0; segIndex<m_edgeSegments.length; segIndex++)
			{
				segment = m_edgeSegments[segIndex];
				segment.isHoverOn = turnHoverOn;
				segment.m_isDirty = true;
			}
			
			m_innerBoxSegment.edgeSegment.isHoverOn = turnHoverOn;
			m_innerBoxSegment.edgeSegment.m_isDirty = true;
			
			if(turnHoverOn)
			{
				//reorder to place on top
				parent.setChildIndex(this, parent.numChildren);
			}
		}
		
		private function getBallTypeChangeEvent():String
		{
			return isTopOfEdge() ? BallTypeChangeEvent.ENTER_BALL_TYPE_CHANGED : BallTypeChangeEvent.EXIT_BALL_TYPE_CHANGED;
		}
		
		//called when a segment is double-clicked on
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
			createChildren();
			positionChildren();
			
		}
		
		//create edge segments and joints from simple point list (m_jointPoints)
		public function createChildren():void
		{
			//make sure we remove the old ones
			removeChildren();
			
			m_edgeSegments = new Vector.<GameEdgeSegment>;			
			m_edgeJoints = new Vector.<GameEdgeJoint>;
			
			//create start joint, and then create rest when we create connecting segment
			m_startJoint = new GameEdgeJoint(0, m_isWide);
			m_startJoint.m_isEditable = m_isEditable;
			m_edgeJoints.push(m_startJoint);
			
			//now create segments and joints for second position to n
			var numJoints:int = m_jointPoints.length;
			for(var index:int = 1; index<numJoints; index++)
			{
				var isLastSegment:Boolean = false;
				var isNodeExtensionSegment:Boolean = false;
				if(index+1 == numJoints)
				{
					isLastSegment = true;
					isNodeExtensionSegment = true;
				}
				if(index == 1)
					isNodeExtensionSegment = true;
					
				var segment:GameEdgeSegment = new GameEdgeSegment(m_dir, isNodeExtensionSegment, isLastSegment, isLastSegment ? m_outgoingIsWide : m_isWide);
				if(!isLastSegment)
					segment.m_isEditable = m_isEditable;
				else
					segment.m_isEditable = m_outputSegmentIsEditable;
				m_edgeSegments.push(segment);
				
				//add joint at end of segment
				var jointType:int = GameEdgeJoint.STANDARD_JOINT;
				if(index+2 == numJoints)
					jointType = GameEdgeJoint.MARKER_JOINT;
				var joint:GameEdgeJoint;
				if(index+1 != numJoints)
				{
					joint = new GameEdgeJoint(jointType, m_isWide);
					joint.m_isEditable = m_isEditable;
					m_edgeJoints.push(joint);
					if (jointType == GameEdgeJoint.MARKER_JOINT) {
						m_markerJoint = joint;
					}
				}
			}
			m_endJoint = new GameEdgeJoint(GameEdgeJoint.END_JOINT, m_outgoingIsWide);
			m_edgeJoints.push(m_endJoint);
			
			m_endJoint.m_isEditable = m_outputSegmentIsEditable;

		}
		
		public function positionChildren():void
		{
			var innerBoxPt:Point;
			var boxHeight:Number;
			if (toBox) {
				boxHeight =(m_toComponent as GameNode).m_boundingBox.height;
				innerBoxPt = new Point(m_endPoint.x, m_endPoint.y + boxHeight / 2);
			} else {
				boxHeight = (m_fromComponent as GameNode).m_boundingBox.height;
				innerBoxPt = new Point(m_startPoint.x, m_startPoint.y - boxHeight / 2);
			}
			m_innerBoxSegment.interiorPt = innerBoxPt;
			m_innerBoxSegment.draw();
			addChild(m_innerBoxSegment);
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
				
				createJointPointsArray(m_startPoint, m_endPoint);
				positionChildren();
				
				m_isDirty = true;
			}
		}
		
		private function onRubberBandSegment(event:Event):void
		{
			if(event.target as GameEdgeSegment)
			{
				var segment:GameEdgeSegment = event.target as GameEdgeSegment;
				
				if(segment.parent is InnerBoxSegment)
				{
					rubberBandEdgeSegment(segment.updatePoint, segment);
			//		rubberBandEdgeSegment(segment.updatePoint, (segment.parent as InnerBoxSegment).m_extensionEdge);
				}
				else
					rubberBandEdgeSegment(segment.updatePoint, segment);
			}
		}
		
		public function rubberBandEdgeSegment(deltaPoint:Point, segment:GameEdgeSegment):void 
		{
			//update both end joints, and then redraw
			var segmentIndex:int = m_edgeSegments.indexOf(segment);
			//not a innerbox segment or end segment
			if(segmentIndex != -1 && segmentIndex != 0 && segmentIndex != m_edgeSegments.length-1) 
			{				
				//if connected to end segment, add a expansion joint in between. Test both ends.
				if(segmentIndex == 1 || segmentIndex+3 == m_jointPoints.length)
				{
					if(segmentIndex == 1)
					{
						m_jointPoints.splice(1, 0, m_jointPoints[1].clone());
						segmentIndex++;
						var newJoint:GameEdgeJoint = new GameEdgeJoint(0, m_isWide);
						m_edgeJoints.splice(1, 0, newJoint);
						newJoint.isHoverOn = true;
	
						var newSegment:GameEdgeSegment = new GameEdgeSegment(segment.m_dir, false, false, m_isWide);
						this.m_edgeSegments.splice(1,0,newSegment);	
						newSegment.isHoverOn = true;
					}
					if(segmentIndex+3 == m_jointPoints.length)
					{
						m_jointPoints.splice(-2, 0, m_jointPoints[m_jointPoints.length-2].clone());
					var newEndJoint:GameEdgeJoint = new GameEdgeJoint(0, m_isWide);
						m_edgeJoints.splice(-2, 0, newEndJoint);
						newEndJoint.isHoverOn = true;
						
					var newEndSegment:GameEdgeSegment = new GameEdgeSegment(segment.m_dir, false, false, m_isWide);
						this.m_edgeSegments.splice(-1,0,newEndSegment);	
						newEndSegment.isHoverOn = true;
					}
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
				
				positionChildren();
				m_isDirty = true;
			}
			else //handle innerBoxSegment/connectionSegment updating
			{
				trackConnector(deltaPoint, segmentIndex, segment);
			}
		}
		
		protected function trackConnector(deltaPoint:Point, segmentIndex:int, segment:GameEdgeSegment):void
		{
			var totalScaleXFactorNumber:Number = 1;
			var currentObj:DisplayObjectContainer = this;
			while(currentObj != null)
			{
				totalScaleXFactorNumber *= currentObj.scaleX;
				currentObj = currentObj.parent;
			}
			
			var containerComponent:GameNodeBase;
			if(m_fromComponent is GameNode)
				containerComponent = m_fromComponent;
			else 
				containerComponent = m_toComponent;
			
			var jointPoint:Point = new Point;
			if(segmentIndex == -1)
			{
				if(segment.m_dir == GameEdgeContainer.DIR_JOINT_TO_BOX)
					jointPoint.x = m_edgeJoints[m_jointPoints.length-1].x;
				else
					jointPoint.x = m_edgeJoints[0].x;
			}
			else if(segmentIndex == 0)
				jointPoint.x = m_edgeJoints[0].x;
			else
				jointPoint.x = m_edgeJoints[m_jointPoints.length-1].x;
			
			//find global coordinates of container, subtracting off joints height and width
			var containerPt:Point = new Point(containerComponent.x,containerComponent.y);
			var containerGlobalPt:Point = containerComponent.parent.localToGlobal(containerPt);						
			var boundsGlobalPt:Point = containerComponent.parent.localToGlobal(new Point(containerComponent.x + containerComponent.width,
																					containerComponent.y + containerComponent.height));
			var jointGlobalPt:Point = localToGlobal(jointPoint);	
			
			//make sure we are in bounds
			var lineSize:Number = isWide() ? GameEdgeContainer.WIDE_WIDTH : GameEdgeContainer.NARROW_WIDTH;
			var newDeltaX:Number = deltaPoint.x;
			if(containerGlobalPt.x > jointGlobalPt.x+deltaPoint.x-totalScaleXFactorNumber*lineSize)
			{
				if(deltaPoint.x < 0)
					newDeltaX = 0;
			}
			else if(boundsGlobalPt.x < jointGlobalPt.x+deltaPoint.x+totalScaleXFactorNumber*lineSize)
			{
				if(deltaPoint.x > 0)
					newDeltaX = 0;
			}
			//always take the smallest delta
			if(Math.abs(newDeltaX) < Math.abs(deltaPoint.x))
				deltaPoint.x = newDeltaX;
			deltaPoint.y = 0;
			//need to rubber band edges and extension edges, if they exist
			var segmentOutgoing:Boolean = false;
			if(segmentIndex == -1)
			{
				if(m_dir == GameEdgeContainer.DIR_BOX_TO_JOINT)
					segmentOutgoing = true;
			}
			if(segmentIndex == 0 || segmentOutgoing)
			{
				rubberBandEdge(deltaPoint, true);
				segmentOutgoing = true;
				if(this.m_extensionEdge)
				{
					m_extensionEdge.rubberBandEdge(deltaPoint, false);
				}
			}
			else
			{
				rubberBandEdge(deltaPoint, false);
				if(this.m_extensionEdge)
				{
					m_extensionEdge.rubberBandEdge(deltaPoint, true);
				}
			}
			var movingRight:Boolean = deltaPoint.x > 0 ? true : false;
			if(deltaPoint.x != 0)
				containerComponent.organizePorts(this, movingRight);
			
			
			/*
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
					//var oNewPos:Number = node.setOutgoingEdge(oNextEdge);
					//oNextEdge.outgoingEdgePosition = oNewPos; // probably want to update the edge at this point
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
					//	var iNewPos:Number = node.setOutgoingEdge(iNextEdge);
					//	iNextEdge.outgoingEdgePosition = iNewPos; // probably want to update the edge at this point
				}
			}
			if (m_parentEdge) {
				m_parentEdge.rubberBandEdge(updatePoint, isOutgoingEdge);
			}*/
		}
		
		
		//create 6 joints
		//  	beginning connection
		//		end of outgoing port extension
		//		middle point 1
		//		middle point 2
		//		start of incoming port extension
		//		end connection
		private function createJointPointsArray(startPoint:Point, endPoint:Point):void
		{		
			//recreate if we have a non-initialized or non-standard line
			//it might be nice to deal with non-standard lines better than wiping out the changes....
			if(!m_jointPoints || m_jointPoints.length != NUM_JOINTS)
			{
				m_jointPoints = new Array(NUM_JOINTS);
				createChildren();
			}
			
			//create easy parts
			makeInitialNodesAndExtension(startPoint, 0, 1, true);
			makeInitialNodesAndExtension(endPoint, NUM_JOINTS-1, NUM_JOINTS-2, false);
			
			makeMainEdgeParts();			
		}
		
		//uses edge position to determine hight of connection segments. currently stepped upwards, might want to step up and then down
		private function makeInitialNodesAndExtension(connectionPoint:Point, startIndex:int, nodeIndex:int, isStartPoint:Boolean):void
		{
			m_jointPoints[startIndex] = connectionPoint.clone();
			if(isStartPoint)
				m_jointPoints[nodeIndex] = new Point(connectionPoint.x, connectionPoint.y + EXTENSION_LENGTH + outgoingEdgePosition*.2);
			else
				m_jointPoints[nodeIndex] = new Point(connectionPoint.x, connectionPoint.y - EXTENSION_LENGTH - incomingEdgePosition*.2);
		}
		
		
		private function makeMainEdgeParts():void
		{
			var xDistance:Number = m_jointPoints[NUM_JOINTS-2].x - m_jointPoints[1].x; 
			var yDistance:Number = m_jointPoints[NUM_JOINTS-2].y - m_jointPoints[1].y;
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

//			if(m_jointPoints[1].y > m_jointPoints[4].y)
			{
				m_jointPoints[2] = new Point(m_jointPoints[1].x + .5*xDistance, m_jointPoints[1].y);
				m_jointPoints[3] = new Point(m_jointPoints[2].x, m_jointPoints[NUM_JOINTS-2].y);
			}
//			else
//			{
//				m_jointPoints[2] = new Point(m_jointPoints[1].x, m_jointPoints[1].y + .5*yDistance);
//				m_jointPoints[3] = new Point(m_jointPoints[4].x, m_jointPoints[4].y - .5*yDistance);	
//			}
		}
		
		override public function componentSelected(isSelected:Boolean):void
		{
			m_isDirty = true;
			m_isSelected = isSelected;
		}
		
		//only use if the container it's self draws specific items.
		public function draw():void
		{
			for each (var seg:GameEdgeSegment in m_edgeSegments) {
				seg.draw();
			}
			for each (var joint:GameEdgeJoint in m_edgeJoints) {
				joint.draw();
			}
			m_innerBoxSegment.draw();
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
					if (hasError() && joint.m_jointType == GameEdgeJoint.MARKER_JOINT)
					{
						joint.m_hasError = true;
					}
					else
					{
						joint.m_hasError = false;
					}
					joint.m_isDirty = true;
				}
				
				m_innerBoxSegment.draw();
				
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
		
		public function getOriginalStartPosition():Point
		{
			return m_startJoint.m_originalPoint.clone();
		}
		
		public function setOriginalStartPosition(newPoint:Point):void
		{
			m_startJoint.m_originalPoint.x = newPoint.x;
			m_startJoint.m_originalPoint.y = newPoint.y;
		}
		
		
		public function getOriginalEndPosition():Point
		{
			return m_endJoint.m_originalPoint.clone();
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
			if (x.m_edgeArray.length == 0 || y.m_edgeArray.length == 0) {
				return -1;
			}
			if(x.m_edgeArray[0].x < y.m_edgeArray[0].x)
				return -1;
			else
				return 1;
		}
		
		public static function sortIncomingXPositions(x:GameEdgeContainer, y:GameEdgeContainer):Number
		{
			if (x.m_edgeArray.length == 0 || y.m_edgeArray.length == 0) {
				return -1;
			}
			if(x.m_edgeArray[x.m_edgeArray.length-1].x < y.m_edgeArray[y.m_edgeArray.length-1].x)
				return -1;
			else
				return 1;
		}
		
		//set children's width, based on incoming and outgoing component
		public function setIncomingWidth(_isWide:Boolean):void
		{
			if (m_isWide == _isWide) {
				return;
			}
			m_isWide = _isWide;
			if (m_edgeSegments != null)
			{
				for(var segIndex:int = 0; segIndex<m_edgeSegments.length-1; segIndex++)
				{
					var segment:GameEdgeSegment = m_edgeSegments[segIndex];
					if(segment.isWide() != _isWide)
					{
						segment.setIsWide(_isWide);
						segment.m_isDirty = true;
					}
				}
			}
			if (m_edgeJoints != null)
			{
				for(var jointIndex:int = 0; jointIndex<this.m_edgeJoints.length-1; jointIndex++)
				{
					var joint:GameEdgeJoint = m_edgeJoints[jointIndex];
					if(joint.isWide() != _isWide)
					{
						joint.setIsWide(_isWide);
						joint.m_isDirty = true;
					}
				}
			}
		}
		
		//set children's width, based on incoming and outgoing component
		public function setOutgoingWidth(_isWide:Boolean):void
		{
			if (m_outgoingIsWide == _isWide) {
				return;
			}
			m_outgoingIsWide = _isWide;
			if(m_edgeSegments != null)
			{
				var segment:GameEdgeSegment = m_edgeSegments[m_edgeSegments.length-1];
				if(segment.isWide() != _isWide)
				{
					segment.setIsWide(_isWide);
					segment.m_isDirty = true;
				}
			}
			
			if(m_edgeJoints != null)
			{
				var joint:GameEdgeJoint = m_edgeJoints[m_edgeJoints.length-1];
				if(joint.isWide() != _isWide)
				{
					joint.setIsWide(_isWide);
					joint.m_isDirty = true;
				}
			}
		}
	}
}


import flash.geom.Point;
import scenes.game.display.GameComponent;
import scenes.game.display.GameEdgeJoint;
import scenes.game.display.GameEdgeSegment;
import scenes.game.display.GameEdgeContainer;

class InnerBoxSegment extends GameComponent
{
	private static var id:int = 0;
	public var innerCircleJoint:GameEdgeJoint;
	public var edgeSegment:GameEdgeSegment;
	public var interiorPt:Point;
	private var m_dir:String;
	private var m_height:Number;
	private var m_createStartingCircle:Boolean;
	
	public function InnerBoxSegment(_interiorPt:Point, height:Number, dir:String, isWide:Boolean, createStartingCircle:Boolean)
	{
		super("IS" + id++);
		interiorPt = _interiorPt;
		m_height = height;
		m_dir = dir;
		m_isWide = isWide;
		m_createStartingCircle = createStartingCircle;
		
		edgeSegment = new GameEdgeSegment(m_dir, true, false, m_isWide);
		edgeSegment.forceColor(0x0);
		edgeSegment.updateSegment(new Point(0, 0), new Point(0, m_height));
		if (createStartingCircle) {
			innerCircleJoint = new GameEdgeJoint(GameEdgeJoint.INNER_CIRCLE_JOINT, m_isWide);
			innerCircleJoint.forceColor(0x0);
		}
		draw();
		addChild(edgeSegment);
		if (innerCircleJoint) {
			addChild(innerCircleJoint);
		}
	}
	
	public function draw():void
	{
		if (m_dir == GameEdgeContainer.DIR_JOINT_TO_BOX) {
			edgeSegment.x = interiorPt.x;
			edgeSegment.y = interiorPt.y - m_height;
		} else {
			edgeSegment.x = interiorPt.x;
			edgeSegment.y = interiorPt.y;
		}
		edgeSegment.setIsWide(m_isWide);
		edgeSegment.draw();
		if (innerCircleJoint) {
			innerCircleJoint.x = interiorPt.x;
			innerCircleJoint.y = interiorPt.y;
			innerCircleJoint.setIsWide(m_isWide);
			innerCircleJoint.draw();
		}
	}
	
	override public function dispose():void
	{
		if (edgeSegment) {
			edgeSegment.removeFromParent(true);
		}
		if (innerCircleJoint) {
			innerCircleJoint.removeFromParent(true);
		}
		super.dispose();
	}
}
