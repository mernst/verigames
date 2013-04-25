package scenes.game.display
{
	import assets.AssetInterface;
	
	import events.MoveEvent;
	
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.Dictionary;
	
	import graph.Edge;
	import graph.EdgeSetRef;
	import graph.Network;
	import graph.NodeTypes;
	import graph.Port;
	
	import scenes.BaseComponent;
	
	import starling.display.DisplayObjectContainer;
	import starling.display.Image;
	import starling.display.Shape;
	import starling.events.Event;
	import starling.events.Touch;
	import starling.events.TouchEvent;
	import starling.events.TouchPhase;
	import starling.textures.Texture;
	
	public class GameNode extends GameComponent
	{
		protected var m_edgeSet:EdgeSetRef;
		public var m_shape:Shape;
		
		private var imageWidth:Number = 100.0;
		private var imageHeight:Number = 100.0;
		public var m_numIncomingNodeEdges:int;
		public var m_numOutgoingNodeEdges:int;
		private var m_id:String;
		private var m_edgeSetEdges:Vector.<Edge>;
		private var m_editable:Boolean;
		
		public var positionPoint:Point;
		
		protected var m_gameEdges:Vector.<GameEdgeContainer>;
		
		public var m_outgoingEdges:Vector.<GameEdgeContainer>;
		public var m_incomingEdges:Vector.<GameEdgeContainer>;
		
		protected static var nextNodeNumber:int = 0;
		
		public var m_currentNodeNumber:int;
		
		private var m_nodeXML:XML;
		private var m_edgeArray:Array;
		public var boundingBox:Rectangle;
		public var globalPosition:Point;
		private var m_gameNodeDictionary:Dictionary = new Dictionary;
		
		public var addedToStage:Boolean = false;
		
		public function GameNode(nodeXML:XML, edgeSet:EdgeSetRef, edgeSetEdges:Vector.<Edge>)
		{
			super();
			m_nodeXML = nodeXML;
			m_edgeSet = edgeSet;
			m_edgeSetEdges = edgeSetEdges;
			
			m_currentNodeNumber = nextNodeNumber++;			
			
			m_gameEdges = new Vector.<GameEdgeContainer>;
			m_outgoingEdges = new Vector.<GameEdgeContainer>;
			m_incomingEdges = new Vector.<GameEdgeContainer>;
			
			if(m_nodeXML)
			{
				boundingBox = findBoundingBox(m_nodeXML);
				globalPosition = new Point(boundingBox.x, boundingBox.y);
				m_id = m_nodeXML.@id;
				imageWidth = boundingBox.width;
				imageHeight = boundingBox.height;
			}
			
			if (m_edgeSetEdges.length == 0) {
				throw new Error("GameNode created with no associated edge objects");
			}
			m_editable = m_edgeSetEdges[0].editable;
			m_numIncomingNodeEdges = m_numOutgoingNodeEdges = 0;
			for each (var myEdge:Edge in m_edgeSetEdges) {
				if (myEdge.is_wide != isWide()) {
					trace("WARNING: Edge id " + myEdge.edge_id + " isWide doesn't match edgeSet value = " + isWide().toString);
				}
				if (myEdge.editable != m_editable) {
					trace("WARNING: Edge id " + myEdge.edge_id + " editable doesn't match edgeSet value = " + m_editable.toString);
					m_editable = true; // default to editable for this case (at least one edge = editable, whole edgeSet = editable)
				}
				if (myEdge.from_port.node.kind == NodeTypes.INCOMING) {
					m_numIncomingNodeEdges++;
				}
				if (myEdge.to_port.node.kind == NodeTypes.OUTGOING) {
					m_numOutgoingNodeEdges++;
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
					if(m_editable)
					{
						m_isDirty = true;
						for each(var oedge:GameEdgeContainer in this.m_outgoingEdges)
						oedge.m_isDirty = true;
						for each(var iedge:GameEdgeContainer in this.m_incomingEdges)
						iedge.m_isDirty = true;
						// Need to dispatch AFTER marking dirty, this will trigger the score update
						// (we don't want to update the score with old values, we only know they're old
						// if we properly mark them dirty first)
						dispatchEvent(new starling.events.Event(Level.EDGE_SET_CHANGED, true, m_edgeSet));
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
		
		//adds edge to outgoing edge method (unless currently in vector), then sorts
		public function setOutgoingEdge(edge:GameEdgeContainer):void
		{
			if(m_outgoingEdges.indexOf(edge) == -1)
				m_outgoingEdges.push(edge);
			edge.outgoingEdgePosition = m_outgoingEdges.length-1;
			//I want the edges to be in ascending order according to x position, so do that here
			m_outgoingEdges.sort(sortOutgoingXPositions);
			
		}
		
		protected function sortOutgoingXPositions(x:GameEdgeContainer, y:GameEdgeContainer):Number
		{
			if(x.m_edgeArray[0].x < y.m_edgeArray[0].x)
				return -1;
			else
				return 1;
		}
		
		//adds edge to incoming edge method (unless currently in vector), then sorts
		public function setIncomingEdge(edge:GameEdgeContainer):void
		{
			if(m_incomingEdges.indexOf(edge) == -1)
				m_incomingEdges.push(edge);
			edge.incomingEdgePosition = m_incomingEdges.length-1;
			//I want the edges to be in ascending order according to x position, so do that here
			m_incomingEdges.sort(sortIncomingXPositions);
		}
		
		protected function sortIncomingXPositions(x:GameEdgeContainer, y:GameEdgeContainer):Number
		{
			if(x.m_edgeArray[x.m_edgeArray.length-1].x < y.m_edgeArray[y.m_edgeArray.length-1].x)
				return -1;
			else
				return 1;
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
		
		private var m_star:ScoreStar;
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
			
			m_shape.graphics.drawRoundRect(0, 0, imageWidth, imageHeight, 1.0);
			m_shape.graphics.endFill();
			
			if (false)// !isWide())
			{
				// Draw inner black outline to appear smaller if this is a narrow node
				m_shape.graphics.lineStyle(1.5, 0x0);
				m_shape.graphics.drawRoundRect(1.0, 1.0, (imageWidth - 2.0), (imageHeight - 2.0), 1.0);
			}
			
			if(m_isSelected && !isTempSelection)
			{
				m_shape.graphics.beginMaterialFill(selectedColorMaterial);
				m_shape.graphics.drawRect(0, 0, imageWidth, imageHeight);
				m_shape.graphics.endFill();
			}
			
			addChild(m_shape);
			
			var wideScore:Number = getWideScore();
			var narrowScore:Number = getNarrowScore();
			if (wideScore > narrowScore) {
				m_star = new ScoreStar((wideScore - narrowScore).toString(), WIDE_COLOR);
				addChild(m_star);
			} else if (narrowScore > wideScore) {
				m_star = new ScoreStar((narrowScore - wideScore).toString(), NARROW_COLOR);
				addChild(m_star);
			}
			useHandCursor = m_editable;
			
			//			var number:String = ""+m_id.substring(4);
			//			var txt:TextField = new TextField(m_shape.width, m_shape.height, number, "Veranda", 6); 
			//			txt.y = 0;
			//			txt.x = 0;
			//			m_shape.addChild(txt);
		}
		
		override public function getWideScore():Number
		{
			if (!m_editable) { // don't assign scores for gray boxes (it would just confuse the user)
				return 0;
			} else {
				return Constants.WIDE_INPUT_POINTS * Math.max(0, m_numIncomingNodeEdges - m_numOutgoingNodeEdges);
			}
		}
		
		override public function getNarrowScore():Number
		{
			if (!m_editable) { // don't assign scores for gray boxes (it would just confuse the user)
				return 0;
			} else {
				return Constants.NARROW_OUTPUT_POINTS * Math.max(0, m_numOutgoingNodeEdges - m_numIncomingNodeEdges);
			}
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
		
		public function isEditable():Boolean
		{
			return m_editable;
		}
		
		override public function isWide():Boolean
		{
			return m_edgeSetEdges[0].is_wide;
		}
		
		override public function getColor():int
		{
			if(m_editable)
			{
				if (isWide())
				{
					return WIDE_COLOR;
				}
				else
				{
					return NARROW_COLOR;
				}
			}
			else
			{
				return UNADJUSTABLE_COLOR;
			}
		}
	}
}