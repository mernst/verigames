package scenes.game.display
{
	import assets.AssetInterface;
	import assets.AssetsFont;
	
	import display.NineSliceBatch;
	import display.TextBubble;
	
	import events.BallTypeChangeEvent;
	import events.EdgeContainerEvent;
	import events.EdgeTroublePointEvent;
	import events.PortTroublePointEvent;
	
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import graph.Edge;
	import graph.NodeTypes;
	import graph.Port;
	
	import particle.ErrorParticleSystem;
	
	import starling.display.DisplayObjectContainer;
	import starling.display.Image;
	import starling.display.Sprite;
	import starling.events.Event;
	import starling.events.Touch;
	import starling.events.TouchEvent;
	import starling.events.TouchPhase;
	import starling.textures.Texture;
	import starling.textures.TextureAtlas;
	
	import utils.XSprite;
	
	public class GameEdgeContainer extends GameComponent
	{
		public var m_fromComponent:GameNodeBase;
		public var m_toComponent:GameNodeBase;
		public var m_fromPortID:String;
		public var m_toPortID:String;
		public var m_extensionEdge:GameEdgeContainer;
		//if there's an extension edge, this tells us if it's outgoing or incoming
		protected var m_extensionEdgeIsOutgoing:Boolean;
		
		private var m_dir:String;
		private var m_innerSegmentBorderIsWide:Boolean = false;
		public var m_edgeArray:Array;
		
		protected var m_edgeSegments:Vector.<GameEdgeSegment>;
		private var m_edgeJoints:Vector.<GameEdgeJoint>;
		public var m_innerSegmentIsEditable:Boolean = true;
		
		//save start and end points, so we can remake line
		public var m_startPoint:Point;
		public var m_endPoint:Point;
		public var m_startJoint:GameEdgeJoint;
		public var m_endJoint:GameEdgeJoint;
		public var m_markerJoint:GameEdgeJoint;
		
		public var hasChanged:Boolean;
		public var restoreEdge:Boolean;
		
		//used to record current position for both undoing and port tracking (snap back to original)
		public var undoObject:Object;
		
		public var m_innerBoxSegment:InnerBoxSegment;
		
		public var m_jointPoints:Array;
		
		public var incomingEdgePosition:Number;
		public var outgoingEdgePosition:Number;
		
		public var graphEdge:Edge;
		public var edgeIsCopy:Boolean;
		
		public var errorContainer:Sprite = new Sprite();
		private var m_errorParticleSystem:ErrorParticleSystem;
		public var errorTextBubbleContainer:Sprite = new Sprite();
		public var errorTextBubble:TextBubble;
		
		private var m_edgeHasError:Boolean = false;
		private var m_portHasError:Boolean = false;
		private var m_listeningToEdges:Vector.<Edge> = new Vector.<Edge>();
		private var m_listeningToPorts:Vector.<Port> = new Vector.<Port>();
		public var initialized:Boolean = false;
		
		//use for figuring out closest wall
		public static var LEFT_WALL:int = 1;
		public static var RIGHT_WALL:int = 2;
		public static var TOP_WALL:int = 3;
		public static var BOTTOM_WALL:int = 4;
		
		public static var WIDE_WIDTH:Number = .3 * Constants.GAME_SCALE;
		public static var NARROW_WIDTH:Number = .1 * Constants.GAME_SCALE;
		public static var ERROR_WIDTH:Number = .6 * Constants.GAME_SCALE;
		
		public static var DIR_BOX_TO_JOINT:String = "2joint";
		public static var DIR_JOINT_TO_BOX:String = "2box";
		
		public static const NUM_JOINTS:int = 6;
		
		public function GameEdgeContainer(_id:String, edgeArray:Array, 
										  fromComponent:GameNodeBase, toComponent:GameNodeBase, 
										  _fromPortID:String, _toPortID:String, dir:String,
										  _graphEdge:Edge, _draggable:Boolean,
										  _graphEdgeIsCopy:Boolean = false)
		{
			super(_id);
			draggable = _draggable;
			m_edgeArray = edgeArray;
			m_fromComponent = fromComponent;
			m_toComponent = toComponent;
			m_fromPortID = _fromPortID;
			m_toPortID = _toPortID;
			m_dir = dir;
			graphEdge = _graphEdge;
			edgeIsCopy = _graphEdgeIsCopy;
			m_isEditable = graphEdge.editable;
			
			m_innerSegmentBorderIsWide = toBox ? (m_toComponent as GameNodeBase).isWide() : (m_fromComponent as GameNodeBase).isWide();
			m_innerSegmentIsEditable = toBox ? (m_toComponent as GameNodeBase).isEditable() : (m_fromComponent as GameNodeBase).isEditable();
			// Also even if box is editable, if contains a pinch point then make editable = false
			if (toBox && graphEdge.has_pinch && !edgeIsCopy) {
				m_innerSegmentIsEditable = false;
				m_innerSegmentBorderIsWide = false;
			}
			
			//mark these as undefined
			outgoingEdgePosition = -1;
			incomingEdgePosition = -1;
			
			fromComponent.setOutgoingEdge(this);
			toComponent.setIncomingEdge(this);
			
			setupPoints();
			
			var innerBoxPt:Point;
			var boxHeight:Number;
			var innerCircle:Boolean = false;
			if (toBox) {
				boxHeight = (m_toComponent as GameNode).m_boundingBox.height;
				innerBoxPt = new Point(m_endPoint.x, m_endPoint.y + boxHeight / 2);
				switch (graphEdge.to_port.node.kind) {
					case NodeTypes.OUTGOING:
					case NodeTypes.END:
					case NodeTypes.SUBBOARD:
						innerCircle = true;
						break;
				}
			} else {
				boxHeight = (m_fromComponent as GameNode).m_boundingBox.height;
				innerBoxPt = new Point(m_startPoint.x, m_startPoint.y - boxHeight / 2);
				switch (graphEdge.from_port.node.kind) {
					case NodeTypes.INCOMING:
					case NodeTypes.START_PIPE_DEPENDENT_BALL:
						innerCircle = true;
						break;
				}
			}
			if (fromComponent is GameNode) {
				m_extensionEdge = (fromComponent as GameNode).getExtensionEdge(_fromPortID, true);
				m_extensionEdgeIsOutgoing = true;
			} else {
				m_extensionEdge = (toComponent as GameNode).getExtensionEdge(_toPortID, false);
				m_extensionEdgeIsOutgoing = false;
			}
			if (m_extensionEdge) {
				m_extensionEdge.m_extensionEdge = this;
				if (m_extensionEdge.m_innerBoxSegment && m_extensionEdge.m_innerBoxSegment.isEnd) {
					// Since we have two edges linked here, this shouldn't be an end
					m_extensionEdge.m_innerBoxSegment.isEnd = false;
					m_extensionEdge.m_innerBoxSegment.m_isDirty = true;
				}
				if (toBox) {
					m_extensionEdge.m_innerSegmentIsEditable = m_innerSegmentIsEditable;
					m_extensionEdge.m_innerSegmentBorderIsWide = m_innerSegmentBorderIsWide;
					if (m_extensionEdge.m_innerBoxSegment) {
						m_extensionEdge.m_innerBoxSegment.m_isDirty = true;
					}
				} else {
					m_innerSegmentIsEditable = m_extensionEdge.m_innerSegmentIsEditable;
					m_innerSegmentBorderIsWide = m_extensionEdge.m_innerSegmentBorderIsWide;
				}
			}
			var innerIsEnd:Boolean = toBox && (m_extensionEdge == null);
			
			m_innerBoxSegment = new InnerBoxSegment(innerBoxPt, boxHeight / 2, m_dir, m_isEditable ? m_isWide : m_innerSegmentBorderIsWide, m_innerSegmentBorderIsWide, m_innerSegmentIsEditable, innerCircle, innerIsEnd, m_isWide, true, draggable);
			
			if (isTopOfEdge()) {
				graphEdge.addEventListener(BallTypeChangeEvent.ENTER_BALL_TYPE_CHANGED, onBallTypeChange);
				// Also need to update the inner box segment when the exit ball type changes
				graphEdge.addEventListener(BallTypeChangeEvent.EXIT_BALL_TYPE_CHANGED, onBallTypeChange);
				if (!edgeIsCopy) {
					// If normal edge leading into box, mark trouble points
					listenToEdgeForTroublePoints(graphEdge);
				}
				// If edge is copy and top of edge (an edge leading from an external SUBBOARD box to a joint)
				// then listen for trouble points at the actual edge which will leading from the joint above
				// to the actual edge-set box
			} else {
				graphEdge.addEventListener(BallTypeChangeEvent.EXIT_BALL_TYPE_CHANGED, onBallTypeChange);
			}
			// For edges leading into SUBNETWORK (the lower CPY lines) the edge.to_port could
			// have trouble points
			switch (graphEdge.to_node.kind) {
				case NodeTypes.SUBBOARD:
					if (edgeIsCopy) {
						// There are two lines for every connection INTO a subboard, the box to joint is the line corresponding
						// to the edge, and the joint to the box which is the CPY line. We want to show trouble points on the lower
						// CPY line only
						listenToPortForTroublePoints(graphEdge.to_port);
					}
					break;
			}
			
			m_isDirty = true;
			addEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
		}
		
		private function onAddedToStage(evt:Event):void
		{
			if(!initialized)
			{
				initialized = true;
				createLine();
				
				addEventListener(EdgeContainerEvent.CREATE_JOINT, onCreateJoint);
				addEventListener(EdgeContainerEvent.RUBBER_BAND_SEGMENT, onRubberBandSegment);
				addEventListener(EdgeContainerEvent.HOVER_EVENT_OVER, onHoverOver);
				addEventListener(EdgeContainerEvent.HOVER_EVENT_OUT, onHoverOut);
				addEventListener(EdgeContainerEvent.SAVE_CURRENT_LOCATION, onSaveLocation);
				addEventListener(EdgeContainerEvent.RESTORE_CURRENT_LOCATION, onRestoreLocation);
				addEventListener(EdgeContainerEvent.INNER_SEGMENT_CLICKED, onInnerBoxSegmentClicked);
				addEventListener(Event.ENTER_FRAME, onEnterFrame);
			}
		}
		
		public function setupPoints(newEdgeArray:Array = null):void
		{
			if(newEdgeArray) m_edgeArray = newEdgeArray;
			var startPt:Point = m_edgeArray[0];
			var endPt:Point = m_edgeArray[m_edgeArray.length-1];
			var minXedge:Number = Math.min(startPt.x, endPt.x);
			var minYedge:Number = Math.min(startPt.y, endPt.y);
			this.x = minXedge;
			this.y = minYedge;
			if(!newEdgeArray) {
				//adjust by min
				for(var i0:int = 0; i0<m_edgeArray.length; i0++)
				{
					m_edgeArray[i0].x -= minXedge;
					m_edgeArray[i0].y -= minYedge;
				}
			}
			
			m_startPoint = m_edgeArray[0];
			m_endPoint = m_edgeArray[m_edgeArray.length-1];
			
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
				updateBoundingBox();
			}
		}
		
		private function updateBoundingBox():void
		{
			var minX:Number = Number.POSITIVE_INFINITY;
			var maxX:Number = Number.NEGATIVE_INFINITY;
			var minY:Number = Number.POSITIVE_INFINITY;
			var maxY:Number = Number.NEGATIVE_INFINITY;
			for(var i1:int = 0; i1< m_jointPoints.length; i1++)
			{
				var pt1:Point = m_jointPoints[i1];
				minX = Math.min(minX, pt1.x - WIDE_WIDTH);
				maxX = Math.max(maxX, pt1.x + WIDE_WIDTH);
				minY = Math.min(minY, pt1.y - WIDE_WIDTH);
				maxY = Math.max(maxY, pt1.y + WIDE_WIDTH);
			}
			m_boundingBox = new Rectangle(minX, minY, maxX - minX, maxY - minY);
		}
		
		/**
		 * Create visuals
		*/
		public function createLine():void
		{
			createChildren();
			positionChildren();
			
			updateSize();
			
			m_isDirty = true;
		}
		
		private function isTopOfEdge():Boolean
		{
			return ((!edgeIsCopy && toBox) || (edgeIsCopy && toJoint));
		}
		
		override public function updateSize():void
		{
			var newIsWide:Boolean = m_isWide;
			
			if (isTopOfEdge()) {
				newIsWide = isBallWide(graphEdge.enter_ball_type);
			} else {
				newIsWide = isBallWide(graphEdge.exit_ball_type);
			}
			
			// Update line width
			if (m_isWide != newIsWide) {
				setWidths(newIsWide);
				if (toJoint) {
					m_innerBoxSegment.setIsWide(m_isWide);
				} else {
					m_innerBoxSegment.setPlugIsWide(m_isWide);
				}
			}
			
			// Update inner line width to match exit_ball_type
			if (toBox) {
				var newExitIsWide:Boolean = isBallWide(graphEdge.exit_ball_type);
				if (edgeIsCopy) {
					newExitIsWide = newIsWide;
				}
				if (m_innerBoxSegment.isWide() != newExitIsWide) {
					m_innerBoxSegment.setIsWide(newExitIsWide);
					m_innerBoxSegment.m_isDirty = true;
				}
			}
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
			
			removeEventListener(Event.ENTER_FRAME, onEnterFrame);
			removeEventListener(EdgeContainerEvent.CREATE_JOINT, onCreateJoint);
			removeEventListener(EdgeContainerEvent.RUBBER_BAND_SEGMENT, onRubberBandSegment);
			removeEventListener(EdgeContainerEvent.HOVER_EVENT_OVER, onHoverOver);
			removeEventListener(EdgeContainerEvent.HOVER_EVENT_OUT, onHoverOut);
			removeEventListener(EdgeContainerEvent.SAVE_CURRENT_LOCATION, onSaveLocation);
			removeEventListener(EdgeContainerEvent.RESTORE_CURRENT_LOCATION, onRestoreLocation);
			removeEventListener(EdgeContainerEvent.INNER_SEGMENT_CLICKED, onInnerBoxSegmentClicked);
			
			if (errorContainer) {
				errorContainer.removeFromParent(true);
			}
			if (m_errorParticleSystem) {
				m_errorParticleSystem.removeFromParent(true);
			}
			disposeChildren();
			m_edgeSegments = null;
			m_edgeJoints = null;
			if (hasEventListener(EdgeContainerEvent.CREATE_JOINT)) {
				removeEventListener(EdgeContainerEvent.CREATE_JOINT, onCreateJoint);
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
				graphEdge.removeEventListener(BallTypeChangeEvent.ENTER_BALL_TYPE_CHANGED, onBallTypeChange);
				graphEdge.removeEventListener(BallTypeChangeEvent.EXIT_BALL_TYPE_CHANGED, onBallTypeChange);
			}
			super.dispose();
		}
		
		private function onBallTypeChange(evt:BallTypeChangeEvent):void
		{
			updateSize();
		}
		
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
			m_edgeHasError = true;
			if (m_hasError) {
				return;
			}
			m_hasError = true;
			addError();
		}
		
		private function onEdgeTroublePointRemoved(evt:EdgeTroublePointEvent):void
		{
			m_edgeHasError = false;
			m_hasError = m_portHasError;
			if (m_hasError) {
				return;
			}
			removeError();
		}
		
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
		
		public function hideErrorText():void
		{
			if (errorTextBubble != null) errorTextBubble.hideText();
		}
		
		public function showErrorText():void
		{
			if (errorTextBubble != null) errorTextBubble.showText();
		}
		
		private function addError():void
		{
			if (m_errorParticleSystem == null) {
				m_errorParticleSystem = new ErrorParticleSystem();
				m_errorParticleSystem.touchable = false;
				m_errorParticleSystem.scaleX = m_errorParticleSystem.scaleY = 4.0 / Constants.GAME_SCALE;
			}
			errorContainer.addChild(m_errorParticleSystem);
			
			if (errorTextBubble == null) {
				errorTextBubble = new TextBubble(Constants.ERROR_POINTS.toString(), 16, ERROR_COLOR, errorContainer, null, NineSliceBatch.BOTTOM_RIGHT, NineSliceBatch.CENTER, null, true, 10, 2, 0.5, 1, false, ERROR_COLOR);
			}
			errorTextBubbleContainer.scaleX = errorTextBubbleContainer.scaleY = 0.5;
			errorTextBubbleContainer.addChild(errorTextBubble);
			
			if (toBox && m_innerBoxSegment && !m_innerBoxSegment.m_hasError) {
				m_innerBoxSegment.m_hasError = true;
				m_innerBoxSegment.draw();
				
				positionChildren(); // last segment's endpoint will change as the plug moves up/down
			}
		}
		
		private function removeError():void
		{
			if (m_errorParticleSystem != null) m_errorParticleSystem.removeFromParent(true);
			m_errorParticleSystem = null;
			if (errorTextBubble) errorTextBubble.removeFromParent();
			if (toBox && m_innerBoxSegment && m_innerBoxSegment.m_hasError) {
				m_innerBoxSegment.m_hasError = false;
				m_innerBoxSegment.draw();
				positionChildren(); // last segment's endpoint will change as the plug moves up/down
			}
		}
		
		/**
		 * Check all appropriate graph edges/ports for errors, in case they have changed while we
		 * are out of synch (after loading new constraints, etc)
		 */
		public function refreshTroublePoints():void
		{
			var anyPortErrors:Boolean = false;
			for (var p:int = 0; p < m_listeningToPorts.length; p++) {
				if (m_listeningToPorts[p].has_error) {
					anyPortErrors = true;
					break;
				}
			}
			if (anyPortErrors) {
				if (!m_portHasError) onPortTroublePointAdded(null);
			} else {
				if (m_portHasError) onPortTroublePointRemoved(null);
			}
			
			var anyEdgeErrors:Boolean = false;
			for (var e:int = 0; e < m_listeningToEdges.length; e++) {
				if (m_listeningToEdges[e].has_error) {
					anyEdgeErrors = true;
					break;
				}
			}
			if (anyEdgeErrors) {
				if (!m_edgeHasError) onEdgeTroublePointAdded(null);
			} else {
				if (m_edgeHasError) onEdgeTroublePointRemoved(null);
			}
		}
		
		private function onPortTroublePointAdded(evt:PortTroublePointEvent):void
		{
			m_portHasError = true;
			if (m_hasError) {
				return;
			}
			m_hasError = true;
			addError();
		}
		
		private function onPortTroublePointRemoved(evt:PortTroublePointEvent):void
		{
			m_portHasError = false;
			m_hasError = m_edgeHasError;
			if (m_hasError) {
				return;
			}
			removeError();
		}
		
		private function onHoverOver(event:EdgeContainerEvent):void
		{
			unflatten();
			handleHover(true);
			if(m_extensionEdge)
				m_extensionEdge.handleHover(true);
		}
		
		private function onHoverOut(event:EdgeContainerEvent):void
		{
			handleHover(false);
			if(m_extensionEdge)
				m_extensionEdge.handleHover(false);
		}
		
		//these next 4 functions deal with moving internal to node segments, or the extension pieces
		public function onSaveLocation(event:EdgeContainerEvent):void
		{
			saveLocation();
			if(m_extensionEdge)
				m_extensionEdge.saveLocation();
		}
		
		private function saveLocation():void
		{
			hasChanged = false;
			restoreEdge = true;
			
			undoObject = new Object;
			undoObject.m_savedJointPoints = new Array;
			
			undoObject.m_savedStartPoint = m_startPoint.clone();
			undoObject.m_savedEndPoint = m_endPoint.clone();
			
			for each(var pt:Point in m_jointPoints)
				undoObject.m_savedJointPoints.push(pt.clone());
			
			undoObject.initialOutgoingEdgePosition = outgoingEdgePosition;
			undoObject.initialIncomingEdgePosition = incomingEdgePosition;
			
			undoObject.m_savedInnerBoxSegmentLocation = new Point(m_innerBoxSegment.interiorPt.x, m_innerBoxSegment.interiorPt.y);
		}
		
		public function onRestoreLocation(event:EdgeContainerEvent):void
		{
			restoreLocation();
			
			if(m_extensionEdge)
				m_extensionEdge.restoreLocation();
		}
		
		private function restoreLocation():void
		{
			if(restoreEdge)
			{
				m_jointPoints = undoObject.m_savedJointPoints;
				m_startPoint = undoObject.m_savedStartPoint;
				m_endPoint = undoObject.m_savedEndPoint;
				positionChildren();
				m_innerBoxSegment.interiorPt.x = undoObject.m_savedInnerBoxSegmentLocation.x;
				m_innerBoxSegment.interiorPt.y = undoObject.m_savedInnerBoxSegmentLocation.y;
			}
			else
			{
				m_startPoint = undoObject.m_savedStartPoint;
				m_endPoint = undoObject.m_savedEndPoint;
				rubberBandEdge(new Point(), true); //just force a redrawing
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
			
			m_innerBoxSegment.isHoverOn = turnHoverOn;
			m_innerBoxSegment.m_isDirty = true;
			
			if(turnHoverOn)
			{
				//reorder to place on top
				parent.setChildIndex(this, parent.numChildren);
			}
		}
		
		//called when a segment is double-clicked on
		private function onCreateJoint(event:EdgeContainerEvent):void
		{
			//get the segment index as a guide to where to add the joint
			var segment:GameEdgeSegment = event.segment;
			var segmentIndex:int = event.segmentIndex;
			var startingJointIndex:int = segmentIndex;
			var newJointPt:Point = segment.currentTouch.getLocation(this);
			//if this is a horizontal line, use the y coordinate of the current joints, else visa-versa
			if(m_jointPoints[startingJointIndex].x != m_jointPoints[startingJointIndex+1].x)
				newJointPt.y = m_jointPoints[startingJointIndex].y;
			else
				newJointPt.x = m_jointPoints[startingJointIndex].x;
			
			var secondJointPt:Point = newJointPt.clone();
			m_jointPoints.splice(startingJointIndex+1, 0, newJointPt, secondJointPt);
			
			//trace("inserted to " + m_jointPoints.indexOf(newJointPt) + " , " + m_jointPoints.indexOf(secondJointPt) + " of " + m_jointPoints.length);
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
			m_startJoint = new GameEdgeJoint(0, m_isWide, m_isEditable, draggable);
			m_edgeJoints.push(m_startJoint);
			
			//now create segments and joints for second position to n
			var numJoints:int = m_jointPoints.length;
			for(var index:int = 1; index<numJoints; index++)
			{
				var isLastSegment:Boolean = false;
				var isFirstSegment:Boolean = false;
				if(index+1 == numJoints)
				{
					isLastSegment = true;
				}
				else if (index == 1)
				{
					isFirstSegment = true;
				}
				var segment:GameEdgeSegment = new GameEdgeSegment(m_dir, false, isFirstSegment, isLastSegment, m_isWide, true, draggable);
				m_edgeSegments.push(segment);
				
				//add joint at end of segment
				var jointType:int = GameEdgeJoint.STANDARD_JOINT;
				if(index+2 == numJoints)
					jointType = GameEdgeJoint.MARKER_JOINT;
				var joint:GameEdgeJoint;
				if(index+1 != numJoints)
				{
					joint = new GameEdgeJoint(jointType, m_isWide, m_isEditable, draggable);
					m_edgeJoints.push(joint);
					if (jointType == GameEdgeJoint.MARKER_JOINT) {
						m_markerJoint = joint;
					}
				}
			}
			m_endJoint = new GameEdgeJoint(GameEdgeJoint.END_JOINT, m_isWide, m_isEditable, draggable);
			m_edgeJoints.push(m_endJoint);
		}
		
		public function positionChildren():void
		{
			if (!initialized) {
				return;
			}
			var innerBoxPt:Point;
			var boxHeight:Number;
			if (toBox) {
				boxHeight =(m_toComponent as GameNode).m_boundingBox.height;
				innerBoxPt = new Point(m_endPoint.x, m_endPoint.y + boxHeight / 2);
			} else {
				boxHeight = (m_fromComponent as GameNode).m_boundingBox.height;
				innerBoxPt = new Point(m_startPoint.x, m_startPoint.y - boxHeight / 2);
			}
			if (m_innerBoxSegment) {
				m_innerBoxSegment.interiorPt = innerBoxPt;
				if (toBox) {
					m_innerBoxSegment.m_isEditable = m_innerSegmentIsEditable;
					if (m_extensionEdge && m_extensionEdge.m_innerBoxSegment) {
						m_extensionEdge.m_innerBoxSegment.m_isEditable = m_innerSegmentIsEditable;
						m_extensionEdge.m_innerBoxSegment.m_isDirty = true;
					}
				}
				m_innerBoxSegment.m_isDirty = true;
			}
			
			var previousSegment:GameEdgeSegment = null;
			//move each segment to where they should be, and add them, then add front joint
			var a:int = 0;
			var b:int = 1;
			
			var segment:GameEdgeSegment;
			if (m_edgeSegments.length + 1 != m_jointPoints.length) {
				trace("Warning! m_edgeSegments:" + m_edgeSegments.length + " m_jointPoints:" + m_jointPoints.length + ". Calling createChildren");
				createChildren();
				return;
			}
			for(var segIndex:int = 0; segIndex<m_edgeSegments.length; segIndex++)
			{
				segment = m_edgeSegments[segIndex];
				var startPoint:Point = m_jointPoints[segIndex];
				var endPoint:Point = m_jointPoints[segIndex+1].clone();
				
				// For plugs, make the end segment stop in the center of the plug rather than
				// connecting all the way to the box
				if (toBox && segment.m_isLastSegment && m_innerBoxSegment && (m_innerBoxSegment.getPlugYOffset() != 0)) {
					endPoint.y -= m_innerBoxSegment.getPlugYOffset() - InnerBoxSegment.PLUG_HEIGHT / 2.0;
				}
				
				segment.updateSegment(startPoint, endPoint);
				segment.x = m_jointPoints[segIndex].x;
				segment.y = m_jointPoints[segIndex].y;
				
				addChild(segment);
				
				var joint:GameEdgeJoint = m_edgeJoints[segIndex];
				joint.x = m_jointPoints[segIndex].x;
				joint.y = m_jointPoints[segIndex].y;
				
				if (joint.m_jointType == GameEdgeJoint.END_JOINT) {
					errorContainer.x = this.x + joint.x;
					errorContainer.y = this.y + joint.y;
				}
				if (segIndex > 0) {
					addChildAt(joint, 0);
				}
			}
			
			//deal with last joint special, since it's at the end of a segment
			var lastJoint:GameEdgeJoint = m_edgeJoints[m_edgeSegments.length];
			//add joint at end
			lastJoint.x = m_jointPoints[m_edgeSegments.length].x;
			lastJoint.y = m_jointPoints[m_edgeSegments.length].y;
			//addChildAt(lastJoint, 0);
			
			addChild(m_innerBoxSegment); // inner segment topmost
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
				var prevPoints:int = m_jointPoints ? m_jointPoints.length : 0;
				createJointPointsArray(m_startPoint, m_endPoint);
			}
			positionChildren();
			m_isDirty = true;
		}
		
		private function onRubberBandSegment(event:EdgeContainerEvent):void
		{
			if(event.segment != null) {
				rubberBandEdgeSegment(event.segment.updatePoint, event.segment);
				dispatchEvent(new EdgeContainerEvent(EdgeContainerEvent.SEGMENT_MOVED, event.segment, event.joint));
			}
		}
		
		public function rubberBandEdgeSegment(deltaPoint:Point, segment:GameEdgeSegment):void 
		{
			//update both end joints, and then redraw
			var segmentIndex:int = m_edgeSegments.indexOf(segment);
			//not a innerbox segment or end segment
			if(segmentIndex != -1 && segmentIndex != 0 && segmentIndex != m_edgeSegments.length-1) 
			{				
				/*
				// Don't create new joint here, instead extend the current end joint so its extension
				// height is maintained and edges will therefor follow a horizontal->vertical->horizontal
				// alternating fashion
				if(segmentIndex == 1 || segmentIndex+3 == m_jointPoints.length)
				{
					if(segmentIndex == 1)
					{
						m_jointPoints.splice(1, 0, m_jointPoints[1].clone());
						segmentIndex++;
						var newJoint:GameEdgeJoint = new GameEdgeJoint(0, m_isWide, true, draggable);
						m_edgeJoints.splice(1, 0, newJoint);
						newJoint.isHoverOn = true;
						
						var newSegment:GameEdgeSegment = new GameEdgeSegment(segment.m_dir, false, false, false, m_isWide, true, draggable);
						this.m_edgeSegments.splice(1,0,newSegment);	
						newSegment.isHoverOn = true;
					}
					if(segmentIndex+3 == m_jointPoints.length)
					{
						m_jointPoints.splice(-2, 0, m_jointPoints[m_jointPoints.length-2].clone());
						var newEndJoint:GameEdgeJoint = new GameEdgeJoint(0, m_isWide, true, draggable);
						m_edgeJoints.splice(-2, 0, newEndJoint);
						newEndJoint.isHoverOn = true;
						
						var newEndSegment:GameEdgeSegment = new GameEdgeSegment(segment.m_dir, false, false, false, m_isWide, true, draggable);
						this.m_edgeSegments.splice(-1,0,newEndSegment);	
						newEndSegment.isHoverOn = true;
					}
				}
				*/
				
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
				updateBoundingBox();
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
			
			var jointPoint:Point = new Point;
			if(segmentIndex == -1)
			{
				if(segment.m_dir == GameEdgeContainer.DIR_JOINT_TO_BOX)
				{
					jointPoint.x = m_edgeJoints[m_jointPoints.length-1].x;
					containerComponent = m_toComponent;
				}
				else
				{
					jointPoint.x = m_edgeJoints[0].x;
					containerComponent = m_fromComponent;
				}
			}
			else if(segmentIndex == 0)
			{
				jointPoint.x = m_edgeJoints[0].x;
				containerComponent = m_fromComponent;
			}
			else
			{
				jointPoint.x = m_edgeJoints[m_jointPoints.length-1].x;
				containerComponent = m_toComponent;
			}
			
			//don't allow switching at joints
			if(containerComponent is GameJointNode)
				return;
			
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
				if(this.m_extensionEdge && m_extensionEdgeIsOutgoing)
				{
					m_extensionEdge.rubberBandEdge(deltaPoint, false);
				}
			}
			else
			{
				rubberBandEdge(deltaPoint, false);
				if(this.m_extensionEdge && !m_extensionEdgeIsOutgoing)
				{
					m_extensionEdge.rubberBandEdge(deltaPoint, true);
				}
			}
			var movingRight:Boolean = deltaPoint.x > 0 ? true : false;
			if(deltaPoint.x != 0)
				containerComponent.organizePorts(this, movingRight);
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
			var newEdgesNeeded:Boolean = false;
			//recreate if we have a non-initialized line
			if(!m_jointPoints) m_jointPoints = new Array();
			if(m_jointPoints.length == 0)
			{
				m_jointPoints = new Array(NUM_JOINTS);
				newEdgesNeeded = true;
			}
			
			//makeInitialNodesAndExtension
			if ((m_jointPoints[0] as Point != null) && (m_jointPoints[1] as Point != null)) {
				var inputHeight:Number = (m_jointPoints[1] as Point).y - (m_jointPoints[0] as Point).y;
				m_jointPoints[0] = startPoint.clone();
				m_jointPoints[1] = new Point(startPoint.x, startPoint.y + inputHeight);
			} else {
				m_jointPoints[0] = startPoint.clone();
				m_jointPoints[1] = new Point(startPoint.x, startPoint.y + InnerBoxSegment.PLUG_HEIGHT + outgoingEdgePosition*0.2);
			}
			const LNGTH:Number = m_jointPoints.length;
			if ((m_jointPoints[LNGTH-1] as Point != null) && (m_jointPoints[LNGTH-2] as Point != null)) {
				var outputHeight:Number = (m_jointPoints[LNGTH-1] as Point).y - (m_jointPoints[LNGTH-2] as Point).y;
				m_jointPoints[LNGTH-1] = endPoint.clone();
				m_jointPoints[LNGTH-2] = new Point(endPoint.x, endPoint.y - outputHeight);
			} else {
				m_jointPoints[LNGTH-1] = endPoint.clone();
				m_jointPoints[LNGTH-2] = new Point(endPoint.x, endPoint.y - InnerBoxSegment.PLUG_HEIGHT - incomingEdgePosition*0.2);
			}
			
			//setBottomWallOutputConnection
			if (LNGTH == NUM_JOINTS) {
				var xDistance:Number = m_jointPoints[LNGTH-2].x - m_jointPoints[1].x; 
				m_jointPoints[2] = new Point(m_jointPoints[1].x + .5*xDistance, m_jointPoints[1].y);
				m_jointPoints[LNGTH-3] = new Point(m_jointPoints[2].x, m_jointPoints[LNGTH-2].y);
			} else if (m_jointPoints.length > NUM_JOINTS) {
				// Leave other interconnecting joints/segments alone, but 
				// need to update the next joints' y to match the changes above
				m_jointPoints[2].y = m_jointPoints[1].y;
				m_jointPoints[LNGTH-3].y = m_jointPoints[LNGTH-2].y;
			}
			
			// Correct any diagonals
			for (var i:int = 1; i < m_jointPoints.length; i++) {
				if (((m_jointPoints[i-1] as Point).x != (m_jointPoints[i] as Point).x) 
					&& ((m_jointPoints[i-1] as Point).y != (m_jointPoints[i] as Point).y)) {
					// This can happen if legacy joint points that don't alternate in vertical->horiz->vert are loaded
					// Create new joint points between these to correct it - arbitrarily chose to make a horizontal line here
					var midy:Number = ((m_jointPoints[i] as Point).y + (m_jointPoints[i-1] as Point).y) / 2.0;
					var newPt1:Point = new Point((m_jointPoints[i-1] as Point).x, midy);
					var newPt2:Point = new Point((m_jointPoints[i] as Point).x, midy);
					m_jointPoints.splice(i, 0, newPt1, newPt2);
					newEdgesNeeded = true;
					i += 2; // we've just filled in m_jointPoints[i] and m_jointPoints[i+1] so move to i+3, i+2 check
					//throw new Error("Diagonal created: m_jointPoints["+i+"]:" + m_jointPoints[i] + " m_jointPoints["+(i-1)+"]:" + m_jointPoints[i-1]);
				}
			}
			updateBoundingBox();
			// If there are more joint points now than when the method began, create the edge segements
			// for those new joints
			if (newEdgesNeeded) {
				createChildren();
			}
		}
		
		private function onInnerBoxSegmentClicked(event:TouchEvent):void
		{
			var touchClick:Touch = event.getTouch(this, TouchPhase.ENDED);
			var touchPoint:Point = touchClick ? new Point(touchClick.globalX, touchClick.globalY) : null;
			
			if (m_fromComponent is GameNode) {
				(m_fromComponent as GameNode).onClicked(touchPoint);
			} else if (m_toComponent is GameNode) {
				(m_toComponent as GameNode).onClicked(touchPoint);
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
			for each (var seg:GameEdgeSegment in m_edgeSegments) {
				seg.draw();
			}
			for each (var joint:GameEdgeJoint in m_edgeJoints) {
				joint.draw();
				if (joint.m_jointType == GameEdgeJoint.END_JOINT) {
					errorContainer.x = this.x + joint.x;
					errorContainer.y = this.y + joint.y;
				}
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
					//if (hasError() && joint.m_jointType == GameEdgeJoint.MARKER_JOINT)
					//{
					//joint.m_hasError = true;
					//}
					//else
					//{
					//joint.m_hasError = false;
					//}
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
		
		public function getSegment(indx:int):GameEdgeSegment
		{
			if ((indx >= 0) && (indx < m_edgeSegments.length)) return m_edgeSegments[indx];
			return null;
		}
		
		public function getSegmentIndex(segment:GameEdgeSegment):int
		{
			return m_edgeSegments.indexOf(segment);
		}
		
		public function getJointIndex(joint:GameEdgeJoint):int
		{
			return m_edgeJoints.indexOf(joint);
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
			if(x.localToGlobal(x.m_edgeArray[0]).x < y.localToGlobal(y.m_edgeArray[0]).x)
				return -1;
			else
				return 1;
		}
		
		public static function sortIncomingXPositions(x:GameEdgeContainer, y:GameEdgeContainer):Number
		{
			if (x.m_edgeArray.length == 0 || y.m_edgeArray.length == 0) {
				return -1;
			}
			if(x.localToGlobal(x.m_edgeArray[x.m_edgeArray.length-1]).x < y.localToGlobal(y.m_edgeArray[y.m_edgeArray.length-1]).x)
				return -1;
			else
				return 1;
		}
		
		// set widths of all edge segments based on ball size from Simulator
		private function setWidths(_isWide:Boolean):void
		{
			if (m_isWide == _isWide) {
				return;
			}
			unflatten();
			m_isWide = _isWide;
			if (m_edgeSegments != null)
			{
				for(var segIndex:int = 0; segIndex<m_edgeSegments.length; segIndex++)
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
				for(var jointIndex:int = 0; jointIndex<this.m_edgeJoints.length; jointIndex++)
				{
					var joint:GameEdgeJoint = m_edgeJoints[jointIndex];
					if(joint.isWide() != _isWide)
					{
						joint.setIsWide(_isWide);
						joint.m_isDirty = true;
					}
				}
			}
			flatten();
		}
		
		override public function flatten():void {
			return;
		}
		
		//set width of innersegment 
		public function setInnerSegmentBorderWidth(_isWide:Boolean):void
		{
			if (m_innerSegmentBorderIsWide == _isWide) {
				return;
			}
			m_innerSegmentBorderIsWide = _isWide;
			
			if(m_innerBoxSegment != null)
			{
				m_innerBoxSegment.updateBorderWidth(_isWide);
			}
		}
	}
}


import assets.AssetInterface;

import flash.geom.Point;

import scenes.game.display.GameComponent;
import scenes.game.display.GameEdgeContainer;
import scenes.game.display.GameEdgeJoint;
import scenes.game.display.GameEdgeSegment;

import starling.display.Image;
import starling.display.Quad;
import starling.display.Sprite;
import starling.events.EnterFrameEvent;
import starling.events.Event;
import starling.events.Touch;
import starling.events.TouchEvent;
import starling.textures.Texture;
import starling.textures.TextureAtlas;

class InnerBoxSegment extends GameComponent
{
	public static const PLUG_HEIGHT:Number = 0.44 * Constants.GAME_SCALE;
	public static const SOCKET_HEIGHT:Number = 0.17 * Constants.GAME_SCALE;
	private static const BORDER_SIZE:Number = 0.02 * Constants.GAME_SCALE;
	
	private static var id:int = 0;
	
	public var innerCircleJoint:GameEdgeJoint;
	public var edgeSegment:GameEdgeSegment;
	public var edgeSegmentOutline:Quad;
	public var interiorPt:Point;
	private var m_dir:String;
	private var m_height:Number;
	private var m_borderIsWide:Boolean;
	public var isEnd:Boolean;
	private var m_plugIsWide:Boolean;
	private var m_plugIsEditable:Boolean;
	private var m_socketContainer:Sprite;
	private var m_plugContainer:Sprite;
	private var m_socketAssetName:String = "";
	private var m_plugAssetName:String = "";
	private var m_socket:Image;
	private var m_plug:Image;
	
	public function InnerBoxSegment(_interiorPt:Point, height:Number, dir:String, isWide:Boolean, borderIsWide:Boolean, isEditable:Boolean, createInnerCircle:Boolean, _isEnd:Boolean, plugIsWide:Boolean, plugIsEditable:Boolean, _draggable:Boolean)
	{
		super("IS" + id++);
		draggable = _draggable;
		interiorPt = _interiorPt;
		m_height = height;
		m_dir = dir;
		m_isWide = isWide;
		m_borderIsWide = borderIsWide;
		m_isEditable = isEditable;
		isEnd = _isEnd;
		m_plugIsWide = plugIsWide;
		m_plugIsEditable = plugIsEditable;
		edgeSegmentOutline = new Quad(getBorderWidth(), m_height, getBorderColor());
		edgeSegment = new GameEdgeSegment(m_dir, true, false, false, m_isWide, m_isEditable, draggable);
		edgeSegment.updateSegment(new Point(0, 0), new Point(0, m_height));
		if (createInnerCircle) {
			innerCircleJoint = new GameEdgeJoint(GameEdgeJoint.INNER_CIRCLE_JOINT, m_isWide, m_isEditable, draggable);
		}
		m_socketContainer = new Sprite();
		m_plugContainer = new Sprite();
		
		draw();
		addChild(edgeSegmentOutline);
		addChild(edgeSegment);
		if (innerCircleJoint) {
			addChild(innerCircleJoint);
		}
		edgeSegment.socket = m_socketContainer;
		edgeSegment.plug = m_plugContainer;
		edgeSegment.m_isDirty = true;
		
		m_isDirty = false;
		addEventListener(EnterFrameEvent.ENTER_FRAME, onEnterFrame);
	}
	
	public function getPlugYOffset():Number
	{
		if (hasError()) {
			return PLUG_HEIGHT;
		} else if (isEnd) {
			return (PLUG_HEIGHT - SOCKET_HEIGHT + 0.01 * Constants.GAME_SCALE);
		} else {
			return 0;
		}
	}
	
	public function updatePlug():void
	{
		if (!(isEnd || hasError())) {
			// Only show plugs/sockets for end with no extension or errors (two prong into one prong)
			if (m_plug) {
				m_plug.removeFromParent(true);
			}
			m_plug = null;
			m_plugAssetName = "";
			return;
		}
		var assetName:String;
		if (m_plugIsEditable) {
			if (m_plugIsWide) {
				assetName = AssetInterface.PipeJamSubTexture_BlueDarkPlug;
			} else {
				assetName = AssetInterface.PipeJamSubTexture_BlueLightPlug;
			}
		} else {
			if (m_plugIsWide) {
				assetName = AssetInterface.PipeJamSubTexture_GrayDarkPlug;
			} else {
				assetName = AssetInterface.PipeJamSubTexture_GrayLightPlug;
			}
		}
		if (assetName == m_plugAssetName) {
			// No need to change image
			return;
		}
		if (m_plug) {
			m_plug.removeFromParent(true);
		}
		m_plugAssetName = assetName;
		var atlas:TextureAtlas = AssetInterface.getTextureAtlas("Game", "PipeJamSpriteSheetPNG", "PipeJamSpriteSheetXML");
		var plugTexture:Texture = atlas.getTexture(m_plugAssetName);
		m_plug = new Image(plugTexture);
		var scale:Number = PLUG_HEIGHT / m_plug.height;
		m_plug.width *= scale;
		m_plug.height *= scale;
		m_plugContainer.addChild(m_plug);
	}
	
	public function updateSocket():void
	{
		if (!(isEnd || hasError())) {
			// Only show plugs/sockets for end with no extension or errors (two prong into one prong)
			if (m_socket) {
				m_socket.removeFromParent(true);
			}
			m_socket = null;
			m_socketAssetName = "";
			return;
		}
		var assetName:String;
		if (m_isEditable) {
			if (m_borderIsWide) {
				assetName = AssetInterface.PipeJamSubTexture_BlueDarkEnd;
			} else {
				assetName = AssetInterface.PipeJamSubTexture_BlueLightEnd;
			}
		} else {
			if (m_borderIsWide) {
				assetName = AssetInterface.PipeJamSubTexture_GrayDarkEnd;
			} else {
				assetName = AssetInterface.PipeJamSubTexture_GrayLightEnd;
			}
		}
		if (assetName == m_socketAssetName) {
			// No need to change image
			return;
		}
		if (m_socket) {
			m_socket.removeFromParent(true);
		}
		m_socketAssetName = assetName;
		var atlas:TextureAtlas = AssetInterface.getTextureAtlas("Game", "PipeJamSpriteSheetPNG", "PipeJamSpriteSheetXML");
		var socketTexture:Texture = atlas.getTexture(m_socketAssetName);
		m_socket = new Image(socketTexture);
		m_socket.touchable = false;
		var scale:Number = SOCKET_HEIGHT / m_socket.height;
		m_socket.width *= scale;
		m_socket.height *= scale;
		m_socketContainer.addChild(m_socket);
	}
	
	private static function getWidth(_isWide:Boolean):Number
	{
		return _isWide ? GameEdgeContainer.WIDE_WIDTH : GameEdgeContainer.NARROW_WIDTH;
	}
	
	private function getBorderWidth():Number
	{
		// Make pinch points stand out with thicker border
		if (!m_isEditable && !m_borderIsWide) return 4 * BORDER_SIZE + GameEdgeContainer.NARROW_WIDTH;
		return 2 * BORDER_SIZE + (m_borderIsWide ? GameEdgeContainer.WIDE_WIDTH : GameEdgeContainer.NARROW_WIDTH);
	}
	
	private function getBorderColor():uint
	{
		if (m_isEditable) {
			return m_isWide ? GameComponent.WIDE_COLOR_BORDER : GameComponent.NARROW_COLOR_BORDER;
		} else {
			return m_isWide ? GameComponent.UNADJUSTABLE_WIDE_COLOR_BORDER : GameComponent.UNADJUSTABLE_NARROW_COLOR_BORDER;
		}
	}
	
	private function onEnterFrame(event:Event):void
	{
		if(m_isDirty)
		{
			draw();
			m_isDirty = false;
		}
	}
	
	public function updateBorderWidth(_isWide:Boolean):void
	{
		if (m_borderIsWide == _isWide) {
			return;
		}
		if (!m_isEditable) {
			return;
		}
		m_borderIsWide = _isWide;
		m_isDirty = true;
	}
	
	public function draw():void
	{
		unflatten();
		
		var singleProngToDoubleOffset:Number = 0.0;
		if (!m_isWide && m_borderIsWide) {
			singleProngToDoubleOffset = 0.075 * Constants.GAME_SCALE;
		}
		
		updatePlug();
		if (m_plug) {
			m_plug.x = - m_plug.width / 2;
			m_plug.y = - getPlugYOffset();
		}
		updateSocket();
		if (m_socket) {
			m_socket.x = - m_socket.width / 2 + singleProngToDoubleOffset;
			m_socket.y = 0;
		}
		
		if (m_dir == GameEdgeContainer.DIR_JOINT_TO_BOX) {
			edgeSegment.x = interiorPt.x;
			edgeSegment.y = interiorPt.y - m_height;
		} else {
			edgeSegment.x = interiorPt.x;
			edgeSegment.y = interiorPt.y;
		}
		edgeSegment.isHoverOn = isHoverOn;
		if (edgeSegmentOutline.width != getBorderWidth()) {
			edgeSegmentOutline.width = getBorderWidth();
		}
		if (edgeSegmentOutline.color != getBorderColor()) {
			edgeSegmentOutline.color = getBorderColor();
		}
		edgeSegmentOutline.x = interiorPt.x - edgeSegmentOutline.width / 2.0 + singleProngToDoubleOffset;
		edgeSegmentOutline.y = edgeSegment.y;
		edgeSegment.setIsWide(m_isWide);
		edgeSegment.draw();
		
		if (innerCircleJoint) {
			innerCircleJoint.x = interiorPt.x;
			innerCircleJoint.y = interiorPt.y;
			innerCircleJoint.setIsWide(m_isWide);
			innerCircleJoint.draw();
		}

		if (m_socket && !m_plugIsWide && m_isWide) {
			const offset:Number = 0.075 * Constants.GAME_SCALE;
			edgeSegmentOutline.x += offset;
			edgeSegment.x += offset;
			if (m_plug) {
				m_plug.x -= offset;
			}
			if (innerCircleJoint) {
				innerCircleJoint.x += offset;
			}
		}
		
		flatten();
	}
	
	override public function setIsWide(b:Boolean):void
	{
		if (m_isWide == b) {
			return;
		}
		if (!m_isEditable) {
			return;
		}
		m_isWide = b;
		m_isDirty = true;
	}
	
	public function setPlugIsWide(_plugWide:Boolean):void
	{
		if (m_plugIsWide == _plugWide) {
			return;
		}
		m_plugIsWide = _plugWide;
		m_isDirty = true;
	}
	
	override public function dispose():void
	{
		if (edgeSegment) {
			edgeSegment.removeFromParent(true);
		}
		if (innerCircleJoint) {
			innerCircleJoint.removeFromParent(true);
		}
		removeEventListener(Event.ENTER_FRAME, onEnterFrame);
		
		super.dispose();
	}
}
