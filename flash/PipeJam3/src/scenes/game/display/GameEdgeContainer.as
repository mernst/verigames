package scenes.game.display
{
	import display.NineSliceBatch;
	import display.TextBubble;
	
	import events.ConflictChangeEvent;
	import events.EdgeContainerEvent;
	import events.EdgePropChangeEvent;
	import events.ToolTipEvent;
	
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import graph.Edge;
	import graph.NodeTypes;
	import graph.Port;
	import graph.PropDictionary;
	
	import particle.ErrorParticleSystem;
	
	import starling.display.DisplayObject;
	import starling.display.DisplayObjectContainer;
	import starling.display.Quad;
	import starling.display.Sprite;
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
		//if there's an extension edge, this tells us if it's outgoing or incoming
		private var m_extensionEdgeIsOutgoing:Boolean;
		
		private var m_dir:String;
		private var m_innerSegmentBorderIsWide:Boolean = false;
		public var m_edgeArray:Array;
		
		private var m_edgeSegments:Vector.<GameEdgeSegment> = new Vector.<GameEdgeSegment>();
		private var m_edgeJoints:Vector.<GameEdgeJoint> = new Vector.<GameEdgeJoint>();
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
		
		private var m_errorProps:PropDictionary;
		private var m_listeningToEdges:Vector.<Edge> = new Vector.<Edge>();
		private var m_listeningToPorts:Vector.<Port> = new Vector.<Port>();
		private var m_hidingErrorText:Boolean = false;
		public var initialized:Boolean = false;
		public var hideSegments:Boolean;
		public var hideInnerSegment:Boolean;
		
		//use for figuring out closest wall
		public static var LEFT_WALL:int = 1;
		public static var RIGHT_WALL:int = 2;
		public static var TOP_WALL:int = 3;
		public static var BOTTOM_WALL:int = 4;
		
		public static const EDGES_OVERLAPPING_JOINTS:Boolean = true;
		public static var WIDE_WIDTH:Number = .3 * Constants.GAME_SCALE;
		public static var NARROW_WIDTH:Number = .1 * Constants.GAME_SCALE;
		public static var ERROR_WIDTH:Number = .6 * Constants.GAME_SCALE;
		
		public static var DIR_BOX_TO_JOINT:String = "2joint";
		public static var DIR_JOINT_TO_BOX:String = "2box";
		
		public static const NUM_JOINTS:int = 6;
		public static const DEBUG_BOUNDING_BOX:Boolean = false;
		
		public function GameEdgeContainer(_id:String, edgeArray:Array, 
										  fromComponent:GameNodeBase, toComponent:GameNodeBase, 
										  _fromPortID:String, _toPortID:String, dir:String,
										  _graphEdge:Edge, _draggable:Boolean,
										  _graphEdgeIsCopy:Boolean = false, _hideSegments:Boolean = false)
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
			hideSegments = hideInnerSegment = _hideSegments;
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
			
			setupPoints();
			
			fromComponent.setOutgoingEdge(this);
			toComponent.setIncomingEdge(this);
			
			var innerBoxPt:Point;
			var boxHeight:Number;
			var innerCircle:Boolean = false;
			if (toBox) {
				boxHeight = (m_toComponent as GameNode).m_boundingBox.height + 0.5;
				innerBoxPt = new Point(m_endPoint.x, m_endPoint.y + boxHeight / 2.0);
				switch (graphEdge.to_port.node.kind) {
					case NodeTypes.OUTGOING:
					case NodeTypes.END:
					case NodeTypes.SUBBOARD:
						innerCircle = true;
						break;
				}
			} else {
				boxHeight = (m_fromComponent as GameNode).m_boundingBox.height + 0.5;
				innerBoxPt = new Point(m_startPoint.x, m_startPoint.y - boxHeight / 2.0);
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
			if (m_extensionEdge && m_extensionEdge.hideSegments && hideSegments) {
				// If both edges hidden, show innerCircle for outgoing Edge
				if (m_extensionEdgeIsOutgoing) {
					m_extensionEdge.hideInnerSegment = false;
					m_extensionEdge.m_innerBoxSegment.visible = true;
				} else {
					hideInnerSegment = false; // mark invisible when created below
				}
			} else {
				// Don't associate extension edges if one edge is hidden
				if (m_extensionEdge && m_extensionEdge.hideSegments) m_extensionEdge = null;
				if (hideSegments) m_extensionEdge = null;
			}
			if (m_extensionEdge) {
				innerCircle = false;
				m_extensionEdge.m_extensionEdge = this;
				if (m_extensionEdge.m_innerBoxSegment && 
					m_extensionEdge.m_innerBoxSegment.isEnd) {
					// Since we have two edges linked here, this shouldn't be an end
					m_extensionEdge.m_innerBoxSegment.isEnd = false;
					if (m_extensionEdge.m_innerBoxSegment.innerCircleJoint) {
						m_extensionEdge.m_innerBoxSegment.innerCircleJoint.removeFromParent(true);
						m_extensionEdge.m_innerBoxSegment.innerCircleJoint = null;
					}
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
			var innerIsEnd:Boolean = (m_extensionEdge == null) ? toBox : (toBox && !m_extensionEdge.visible);
			trace(m_id + " hideSegments:" + hideSegments + " innerCircle:" + innerCircle + " innerIsEnd:" + innerIsEnd);
			m_innerBoxSegment = new InnerBoxSegment(innerBoxPt, boxHeight / 2.0, m_dir, m_isEditable ? m_isWide : m_innerSegmentBorderIsWide, m_innerSegmentBorderIsWide, m_innerSegmentIsEditable, innerCircle, innerIsEnd, m_isWide, true, draggable);
			if (hideInnerSegment) m_innerBoxSegment.visible = false;
			// Initialize props
			if (isTopOfEdge()) {
				graphEdge.addEventListener(EdgePropChangeEvent.ENTER_BALL_TYPE_CHANGED, onBallTypeChange);
				graphEdge.addEventListener(EdgePropChangeEvent.ENTER_PROPS_CHANGED, onPropsChange);
				// Also need to update the inner box segment when the exit ball type changes
				graphEdge.addEventListener(EdgePropChangeEvent.EXIT_BALL_TYPE_CHANGED, onBallTypeChange);
				graphEdge.addEventListener(EdgePropChangeEvent.EXIT_PROPS_CHANGED, onPropsChange);
				if (!edgeIsCopy) {
					// If normal edge leading into box, mark trouble points
					listenToEdgeForTroublePoints(graphEdge);
				}
				// If edge is copy and top of edge (an edge leading from an external SUBBOARD box to a joint)
				// then listen for trouble points at the actual edge which will leading from the joint above
				// to the actual edge-set box
			} else {
				graphEdge.addEventListener(EdgePropChangeEvent.EXIT_BALL_TYPE_CHANGED, onBallTypeChange);
				graphEdge.addEventListener(EdgePropChangeEvent.EXIT_PROPS_CHANGED, onPropsChange);
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
				addEventListener(EdgeContainerEvent.SEGMENT_DELETED, onSegmentDeleted);
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
				//trace("creating joint points for " + m_id);
				m_jointPoints = new Array();
				for(var i1:int = 0; i1< m_edgeArray.length; i1++)
				{
					//trace("joint pt " + m_edgeArray[i1]);
					var pt1:Point = m_edgeArray[i1];
					m_jointPoints.push(pt1.clone());
				}
				correctJointPointDiagonals();
				updateBoundingBox();
			}
		}
		
		private var m_debugBoundingBox:Quad = new Quad(1, 1, 0xff00ff);
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
			m_boundingBox = new Rectangle(minX + this.x, minY + this.y, maxX - minX, maxY - minY);
			m_debugBoundingBox.width = m_boundingBox.width;
			m_debugBoundingBox.height = m_boundingBox.height;
			m_debugBoundingBox.x = m_boundingBox.x - this.x;
			m_debugBoundingBox.y = m_boundingBox.y - this.y;
			m_debugBoundingBox.alpha = 0.2;
			m_debugBoundingBox.touchable = false;
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
			removeEventListener(EdgeContainerEvent.SEGMENT_DELETED, onSegmentDeleted);
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
			m_edgeSegments = new Vector.<GameEdgeSegment>();
			m_edgeJoints = new Vector.<GameEdgeJoint>();
			if (hasEventListener(EdgeContainerEvent.CREATE_JOINT)) {
				removeEventListener(EdgeContainerEvent.CREATE_JOINT, onCreateJoint);
			}
			for each (var removeListEdge:Edge in m_listeningToEdges) {
				removeListEdge.removeEventListener(ConflictChangeEvent.CONFLICT_CHANGE, onConflictChange);
			}
			m_listeningToEdges = new Vector.<Edge>();
			for each (var removeListPort:Port in m_listeningToPorts) {
				removeListPort.removeEventListener(ConflictChangeEvent.CONFLICT_CHANGE, onConflictChange);
			}
			m_listeningToPorts = new Vector.<Port>();
			if (graphEdge) {
				graphEdge.removeEventListener(EdgePropChangeEvent.ENTER_BALL_TYPE_CHANGED, onBallTypeChange);
				graphEdge.removeEventListener(EdgePropChangeEvent.EXIT_BALL_TYPE_CHANGED, onBallTypeChange);
				graphEdge.removeEventListener(EdgePropChangeEvent.ENTER_PROPS_CHANGED, onPropsChange);
				graphEdge.removeEventListener(EdgePropChangeEvent.EXIT_PROPS_CHANGED, onPropsChange);
			}
			super.dispose();
		}
		
		private function onBallTypeChange(evt:EdgePropChangeEvent):void
		{
			updateSize();
		}
		
		private function onPropsChange(evt:EdgePropChangeEvent):void
		{
			var updateInnerSegment:Boolean = false;
			if (isTopOfEdge() && (evt.type == EdgePropChangeEvent.EXIT_PROPS_CHANGED)) {
				updateInnerSegment = true;
			} else {
				setProps(evt.newProps);
				m_isDirty = true;
				if (!isTopOfEdge()) updateInnerSegment = true;
			}
			if (updateInnerSegment && m_innerBoxSegment) {
				// Change inner box segment
				if (m_innerBoxSegment.edgeSegment)      m_innerBoxSegment.edgeSegment.setProps(evt.newProps);
				if (m_innerBoxSegment.innerCircleJoint) m_innerBoxSegment.innerCircleJoint.setProps(evt.newProps);
				m_innerBoxSegment.m_isDirty = true;
			}
		}
		
		public function listenToEdgeForTroublePoints(_edge:Edge):void
		{
			if (m_listeningToEdges.indexOf(_edge) == -1) {
				_edge.addEventListener(ConflictChangeEvent.CONFLICT_CHANGE, onConflictChange);
				m_listeningToEdges.push(_edge);
				onConflictChange();
			}
		}
		
		public function onConflictChange(evt:ConflictChangeEvent = null):void
		{
			m_errorProps = new PropDictionary();
			var i:int, prop:String, added:Boolean;
			var conflicts:int = 0;
			for (i = 0; i < m_listeningToEdges.length; i++) {
				for (prop in m_listeningToEdges[i].getConflictProps().iterProps()) {
					added = m_errorProps.setPropCheck(prop, true);
					if (added) conflicts++;
				}
			}
			for (i = 0; i < m_listeningToPorts.length; i++) {
				for (prop in m_listeningToPorts[i].getConflictProps().iterProps()) {
					added = m_errorProps.setPropCheck(prop, true);
					if (added) conflicts++;
				}
			}
			if (conflicts > 0) {
				addError();
				m_hasError = true;
			} else {
				removeError();
				m_hasError = false;
			}
		}
		
		public function listenToPortForTroublePoints(_port:Port):void
		{
			if (m_listeningToPorts.indexOf(_port) == -1) {
				_port.addEventListener(ConflictChangeEvent.CONFLICT_CHANGE, onConflictChange);
				m_listeningToPorts.push(_port);
				onConflictChange();
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
				_port.removeEventListener(ConflictChangeEvent.CONFLICT_CHANGE, onConflictChange);
				m_listeningToPorts.splice(portIndx, 1);
				onConflictChange();
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
			m_hidingErrorText = true;
			if (errorTextBubble != null) errorTextBubble.hideText();
		}
		
		public function showErrorText():void
		{
			m_hidingErrorText = false;
			if (errorTextBubble != null) errorTextBubble.showText();
		}
		
		private function addError():void
		{
			if (m_errorParticleSystem) m_errorParticleSystem.removeFromParent(true);
			m_errorParticleSystem = new ErrorParticleSystem(m_errorProps);
			m_errorParticleSystem.touchable = false;
			m_errorParticleSystem.scaleX = m_errorParticleSystem.scaleY = 4.0 / Constants.GAME_SCALE;
			
			errorContainer.touchable = false;
			errorContainer.addChild(m_errorParticleSystem);
			
			if (errorTextBubble == null) {
				errorTextBubble = new TextBubble(Constants.ERROR_POINTS.toString(), 16, ERROR_COLOR, errorContainer, null, NineSliceBatch.BOTTOM_RIGHT, NineSliceBatch.CENTER, null, true, 10, 2, 0.5, 1, false, ERROR_COLOR);
			}
			if (m_hidingErrorText) {
				errorTextBubble.hideText();
			} else {
				errorTextBubble.showText();
			}
			errorTextBubbleContainer.scaleX = errorTextBubbleContainer.scaleY = 0.5;
			errorTextBubbleContainer.addChild(errorTextBubble);
			
			if (toBox && m_innerBoxSegment && !m_innerBoxSegment.m_hasError) {
				m_innerBoxSegment.m_hasError = true;
				m_innerBoxSegment.m_isDirty = true;
				
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
				m_innerBoxSegment.m_isDirty = true;
				positionChildren(); // last segment's endpoint will change as the plug moves up/down
			}
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
				updateBoundingBox();
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
		
		private function onSegmentDeleted(event:EdgeContainerEvent):void
		{
			var segment:GameEdgeSegment = event.segment;
			var segmentIndex:int = event.segmentIndex;
			if (!segment) return;
			if (isNaN(segmentIndex)) return;
			if (segmentIndex - 1 < 0) return;
			if (segmentIndex + 2 > m_jointPoints.length - 1) return;
			if (m_jointPoints.length <= 4) return;
			// Remove pt1, pt2. Update pt0, pt3
			var pt0:Point = m_jointPoints[segmentIndex - 1];
			var pt1:Point = m_jointPoints[segmentIndex];
			var pt2:Point = m_jointPoints[segmentIndex + 1];
			var pt3:Point = m_jointPoints[segmentIndex + 2];
			var isHoriz:Boolean;
			// 0: vert, 1:horiz, 2: vert, etc. abort if this alternating pattern is untrue
			if (pt1.x == pt2.x) {
				if (segmentIndex % 2 != 0) return;
				isHoriz = false;
			} else if (pt1.y == pt2.y) {
				if (segmentIndex % 2 != 1) return;
				isHoriz = true;
			} else {
				return; // diagonal found, abort
			}
			if (isHoriz) {
				if (segmentIndex + 2 == m_jointPoints.length - 1) {
					// If pt3 is endpoint
					pt0.x = pt3.x;
				} else {
					pt3.x = pt0.x;
				}
			} else {
				if (segmentIndex + 2 == m_jointPoints.length - 1) {
					// If pt3 is endpoint
					pt0.y = pt3.y;
				} else {
					pt3.y = pt0.y
				}
			}
			// Remove pt1, pt2
			m_jointPoints.splice(segmentIndex, 2);
			createChildren();
			positionChildren();
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
			
			if (hideSegments) return;
			
			//create start joint, and then create rest when we create connecting segment
			m_startJoint = new GameEdgeJoint(0, m_isWide, m_isEditable, draggable, m_props, m_propertyMode);
			m_startJoint.visible = !hideSegments;
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
				var segment:GameEdgeSegment = new GameEdgeSegment(m_dir, false, isFirstSegment, isLastSegment, m_isWide, true, draggable, m_props, m_propertyMode);
				segment.visible = !hideSegments;
				m_edgeSegments.push(segment);
				
				//add joint at end of segment
				var jointType:int = GameEdgeJoint.STANDARD_JOINT;
				if(index+2 == numJoints)
					jointType = GameEdgeJoint.MARKER_JOINT;
				var joint:GameEdgeJoint;
				if(index+1 != numJoints)
				{
					joint = new GameEdgeJoint(jointType, m_isWide, m_isEditable, draggable, m_props, m_propertyMode);
					joint.visible = !hideSegments;
					m_edgeJoints.push(joint);
					if (jointType == GameEdgeJoint.MARKER_JOINT) {
						m_markerJoint = joint;
					}
				}
			}
			m_endJoint = new GameEdgeJoint(GameEdgeJoint.END_JOINT, m_isWide, m_isEditable, draggable, m_props, m_propertyMode);
			m_endJoint.visible = !hideSegments;
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
				boxHeight =(m_toComponent as GameNode).m_boundingBox.height + 0.5;
				innerBoxPt = new Point(m_endPoint.x, m_endPoint.y + boxHeight / 2.0);
			} else {
				boxHeight = (m_fromComponent as GameNode).m_boundingBox.height + 0.5;
				innerBoxPt = new Point(m_startPoint.x, m_startPoint.y - boxHeight / 2.0);
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
				if (!hideSegments) trace("Warning! " + m_id + "m_edgeSegments:" + m_edgeSegments.length + " m_jointPoints:" + m_jointPoints.length + ". Calling createChildren");
				createChildren();
				return;
			}
			for(var segIndex:int = 0; segIndex<m_edgeSegments.length; segIndex++)
			{
				segment = m_edgeSegments[segIndex];
				var prevPoint:Point = (segIndex > 0) ? m_jointPoints[segIndex - 1].clone() : null;
				var startPoint:Point = m_jointPoints[segIndex].clone();
				var endPoint:Point = m_jointPoints[segIndex+1].clone();
				
				// For plugs, make the end segment stop in the center of the plug rather than
				// connecting all the way to the box
				if (toBox && segment.m_isLastSegment && m_innerBoxSegment && (m_innerBoxSegment.getPlugYOffset() != 0)) {
					endPoint.y -= m_innerBoxSegment.getPlugYOffset() - InnerBoxSegment.PLUG_HEIGHT / 2.0;
				}
				
				segment.updateSegment(startPoint, endPoint);
				var diff:Point = endPoint.subtract(startPoint);
				var dx:Number = 0;
				var dy:Number = 0;
				if (!EDGES_OVERLAPPING_JOINTS) {
					var lineSize:Number = isWide() ? WIDE_WIDTH : NARROW_WIDTH;
					if (diff.x != 0) {
						dx = (diff.x > 0) ? (lineSize / 2.0) : (-lineSize / 2.0);
					} else {
						dy = (diff.y > 0) ? (lineSize / 2.0) : (-lineSize / 2.0);
					}
				}
				segment.x = m_jointPoints[segIndex].x + dx;
				segment.y = m_jointPoints[segIndex].y + dy;
				
				addChildAt(segment, 0);
				
				var joint:GameEdgeJoint = m_edgeJoints[segIndex];
				if (prevPoint) joint.setIncomingPoint(prevPoint.subtract(m_jointPoints[segIndex]));
				joint.setOutgoingPoint(endPoint.subtract(m_jointPoints[segIndex]));
				joint.x = m_jointPoints[segIndex].x;
				joint.y = m_jointPoints[segIndex].y;
				
				if (joint.m_jointType == GameEdgeJoint.END_JOINT) {
					errorContainer.x = this.x + joint.x;
					errorContainer.y = this.y + joint.y;
				}
				if (segIndex > 0) {
					addChild(joint);
				}
			}
			
			//deal with last joint special, since it's at the end of a segment
			var lastJoint:GameEdgeJoint = m_edgeJoints[m_edgeSegments.length];
			//add joint at end
			lastJoint.x = m_jointPoints[m_edgeSegments.length].x;
			lastJoint.y = m_jointPoints[m_edgeSegments.length].y;
			if (m_edgeSegments.length - 1 >= 0) {
				var inPoint:Point = m_jointPoints[m_edgeSegments.length - 1].clone();
				lastJoint.setIncomingPoint(inPoint.subtract(m_jointPoints[m_edgeSegments.length]));
			}
			//addChildAt(lastJoint, 0);
			
			addChild(m_innerBoxSegment); // inner segment topmost
			if (DEBUG_BOUNDING_BOX) addChild(m_debugBoundingBox);
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
			var segmentOutgoing:Boolean = (segmentIndex == 0);
			if(segmentIndex == -1)
			{
				if(m_dir == GameEdgeContainer.DIR_BOX_TO_JOINT)
					segmentOutgoing = true;
			}
			
			rubberBandEdge(deltaPoint, segmentOutgoing);
			segmentOutgoing = true;
			if(this.m_extensionEdge)// && m_extensionEdgeIsOutgoing)
			{
				m_extensionEdge.rubberBandEdge(deltaPoint, !segmentOutgoing);
			}
			
			if(deltaPoint.x != 0) {
				var movingRight:Boolean = deltaPoint.x > 0 ? true : false;
				containerComponent.organizePorts(this, movingRight);
				//trace("segInd:" + segmentIndex + " out:" + segmentOutgoing + " right:" + movingRight);
			}
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
			
			newEdgesNeeded = newEdgesNeeded || correctJointPointDiagonals();
			// If there are more joint points now than when the method began, create the edge segements
			// for those new joints
			if (newEdgesNeeded) {
				createChildren();
			}
			updateBoundingBox();
		}
		
		/**
		 * Add extra joints where needed such that there are only alternating vertical and horizontal edges,
		 * no edges where we're going from p1->pt2 where pt1.x != pt2.x AND pt1.y != pt2.y
		 * @return
		 */
		private function correctJointPointDiagonals():Boolean
		{
			var newJointsCreated:Boolean = false;
			var previousSegmentVertical:Boolean = false;
			for (var i:int = 1; i < m_jointPoints.length; i++) {
				var xmismatch:Boolean = ((m_jointPoints[i-1] as Point).x != (m_jointPoints[i] as Point).x);
				var ymismatch:Boolean = ((m_jointPoints[i-1] as Point).y != (m_jointPoints[i] as Point).y);
				var newPt1:Point, newPt2:Point;
				if (xmismatch && ymismatch) {
					if (previousSegmentVertical) {
						// Make horizonal->vertical->horizonal segments
						var midx:Number = ((m_jointPoints[i] as Point).x + (m_jointPoints[i-1] as Point).x) / 2.0;
						newPt1 = new Point(midx, (m_jointPoints[i-1] as Point).y);
						newPt2 = new Point(midx, (m_jointPoints[i] as Point).y);
						previousSegmentVertical = false;
					} else {
						// Make vertical->horizonal->vertical segments
						var midy:Number = ((m_jointPoints[i] as Point).y + (m_jointPoints[i-1] as Point).y) / 2.0;
						newPt1 = new Point((m_jointPoints[i-1] as Point).x, midy);
						newPt2 = new Point((m_jointPoints[i] as Point).x, midy);
						previousSegmentVertical = true;
					}
					m_jointPoints.splice(i, 0, newPt1, newPt2);
					newJointsCreated = true;
					i += 2; // we've just filled in m_jointPoints[i] and m_jointPoints[i+1] so move to i+3, i+2 check
					continue;
				} else if ((ymismatch && previousSegmentVertical) || (xmismatch && !previousSegmentVertical)) {
					// Don't want two vertical or horizontal segments in a row, duplicate prev joint
					newPt1 = (m_jointPoints[i-1] as Point).clone();
					m_jointPoints.splice(i, 0, newPt1);
					newJointsCreated = true;
				}
				previousSegmentVertical = !previousSegmentVertical;
			}
			return newJointsCreated;
		}
		
		override protected function onTouch(event:TouchEvent):void
		{
			if (!event.target) return;
			if (event.target is DisplayObject) {
				var doc:DisplayObject = event.target as DisplayObject;
				while (doc.parent) {
					if (doc.parent is InnerBoxSegment) {
						return; // let tool tip events flow through to inner box segment
					}
					doc = doc.parent;
				}
			}
			super.onTouch(event);
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
			// Refresh props
			var enterPropsEvt:EdgePropChangeEvent = new EdgePropChangeEvent(EdgePropChangeEvent.ENTER_PROPS_CHANGED, graphEdge, graphEdge.getEnterProps(), graphEdge.getEnterProps());
			var exitPropsEvt:EdgePropChangeEvent = new EdgePropChangeEvent(EdgePropChangeEvent.EXIT_PROPS_CHANGED, graphEdge, graphEdge.getExitProps(), graphEdge.getExitProps());
			if (isTopOfEdge()) {
				onPropsChange(enterPropsEvt);
				// Also need to update the inner box segment when the exit ball type changes
				onPropsChange(exitPropsEvt);
			} else {
				onPropsChange(exitPropsEvt);
			}
			onConflictChange();
			
			for each (var seg:GameEdgeSegment in m_edgeSegments) {
				seg.m_isDirty = true;//.draw();
			}
			for each (var joint:GameEdgeJoint in m_edgeJoints) {
				joint.m_isDirty = true;//.draw();
				if (joint.m_jointType == GameEdgeJoint.END_JOINT) {
					errorContainer.x = this.x + joint.x;
					errorContainer.y = this.y + joint.y;
				}
			}
			m_innerBoxSegment.m_isDirty = true;
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
				
				m_innerBoxSegment.m_isDirty = true;
				
				m_isDirty = false;
			}
		}
		
		public function setStartPosition(newPoint:Point):void
		{
			m_startPoint = newPoint.clone();
			createJointPointsArray(m_startPoint, m_endPoint);
			if (m_edgeSegments && m_edgeJoints) {
				positionChildren();
				m_isDirty = true;
			}
		}
		
		public function setEndPosition(newPoint:Point):void
		{
			m_endPoint = newPoint.clone();
			createJointPointsArray(m_startPoint, m_endPoint);
			if (m_edgeSegments && m_edgeJoints) {
				positionChildren();
				m_isDirty = true;
			}
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
		}
		
		override public function setProps(props:PropDictionary):void
		{
			super.setProps(props);
			var i:int;
			for (i = 0; i < m_edgeJoints.length; i++) {
				m_edgeJoints[i].setProps(props);
			}
			for (i = 0; i < m_edgeSegments.length; i++) {
				m_edgeSegments[i].setProps(props);
			}
		}
		
		override public function setPropertyMode(prop:String):void
		{
			super.setPropertyMode(prop);
			var i:int;
			for (i = 0; i < m_edgeJoints.length; i++) {
				m_edgeJoints[i].setPropertyMode(prop);
			}
			for (i = 0; i < m_edgeSegments.length; i++) {
				m_edgeSegments[i].setPropertyMode(prop);
			}
			if (m_innerBoxSegment) {
				if (m_innerBoxSegment.edgeSegment)      m_innerBoxSegment.edgeSegment.setPropertyMode(prop);
				if (m_innerBoxSegment.innerCircleJoint) m_innerBoxSegment.innerCircleJoint.setPropertyMode(prop);
			}
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
		
		override protected function getToolTipEvent():ToolTipEvent
		{
			// TODO: Edges appear to have isEditable == false that shouldn't, until this is fixed don't display "Locked" text
			var lockedTxt:String = "";//isEditable() ? "" : "Locked ";
			var widthTxt:String = isWide() ? "Wide " : "Narrow ";
			var jamTxt:String = hasError() ? "\nwith Jam" : "";
			return new ToolTipEvent(ToolTipEvent.ADD_TOOL_TIP, this, lockedTxt + widthTxt + "Link" + jamTxt, 8);
		}
	}
}
