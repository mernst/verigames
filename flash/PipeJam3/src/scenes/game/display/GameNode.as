package scenes.game.display
{
	import assets.AssetInterface;
	
	import display.NineSliceBatch;
	
	import events.EdgeSetChangeEvent;
	import events.UndoEvent;
	
	import flash.geom.Point;
	import flash.utils.Dictionary;
	
	import graph.Edge;
	import graph.EdgeSetRef;
	import graph.Network;
	import graph.NodeTypes;
	import graph.Port;
	
	import starling.display.DisplayObjectContainer;
	import starling.events.Event;
	
	public class GameNode extends GameNodeBase
	{
		protected var m_edgeSet:EdgeSetRef;
		
		public var m_numIncomingNodeEdges:int;
		public var m_numOutgoingNodeEdges:int;

		private var m_edgeSetEdges:Vector.<Edge>;
		private var m_gameNodeDictionary:Dictionary = new Dictionary;
		private var m_scoreBlock:ScoreBlock;
		
		public function GameNode(nodeXML:XML, _draggable:Boolean = true, edgeSet:EdgeSetRef = null, edgeSetEdges:Vector.<Edge> = null)
		{
			super(nodeXML);
			draggable = _draggable;
			m_edgeSet = edgeSet;
			m_edgeSetEdges = edgeSetEdges;
			
			shapeWidth = m_boundingBox.width;
			shapeHeight = m_boundingBox.height;
			
			if (m_edgeSetEdges == null) {
				m_edgeSetEdges = new Vector.<Edge>();
			}
			if (m_edgeSetEdges.length == 0) {
				m_isEditable = false;
				m_isWide = false;
			} else {
				m_isEditable = m_edgeSetEdges[0].editable;
				m_isWide = m_edgeSetEdges[0].is_wide;
			}
			m_numIncomingNodeEdges = m_numOutgoingNodeEdges = 0;
			for each (var myEdge:Edge in m_edgeSetEdges) {
				if (myEdge.is_wide != isWide()) {
					trace("WARNING: Edge id " + myEdge.edge_id + " isWide doesn't match edgeSet value = " + isWide().toString);
				}
				if (myEdge.editable != m_isEditable) {
					trace("WARNING: Edge id " + myEdge.edge_id + " editable doesn't match edgeSet value = " + m_isEditable.toString);
					m_isEditable = true; // default to editable for this case (at least one edge = editable, whole edgeSet = editable)
				}
				if (myEdge.from_port.node.kind == NodeTypes.INCOMING) {
					m_numIncomingNodeEdges++;
				}
				if (myEdge.to_port.node.kind == NodeTypes.OUTGOING) {
					m_numOutgoingNodeEdges++;
				}
			}
			
			draw();
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
		
		public function getExtensionEdge(portID:String, isOutgoingPort:Boolean):GameEdgeContainer
		{
			if(isOutgoingPort)
			{
				for each(var inEdge:GameEdgeContainer in m_incomingEdges)
				{
					if(inEdge.m_toPortID == portID)
						return inEdge;
				}
			}
			else
			{
				for each(var outEdge:GameEdgeContainer in m_outgoingEdges)
				{
					if(outEdge.m_fromPortID == portID)
						return outEdge;
				}
			}
			
			return null;
		}
		
		public override function onClicked(pt:Point):void
		{
			if(m_isEditable)
			{
				var newIsWide:Boolean = !m_isWide;
				handleWidthChange(newIsWide, false, pt);
				//dispatchEvent(new starling.events.Event(Level.UNSELECT_ALL, true, this));
				
				var eventToUndo:EdgeSetChangeEvent = new EdgeSetChangeEvent(EdgeSetChangeEvent.EDGE_SET_CHANGED, this, newIsWide);
				var eventToDispatch:UndoEvent = new UndoEvent(eventToUndo, this);
				dispatchEvent(eventToDispatch);
			}
		}
		
		public override function handleUndoEvent(undoEvent:Event, isUndo:Boolean = true):void
		{
			if (undoEvent is EdgeSetChangeEvent) {
				var evt:EdgeSetChangeEvent = undoEvent as EdgeSetChangeEvent;
				if (isUndo) {
					handleWidthChange(!evt.newIsWide);
				} else {
					handleWidthChange(evt.newIsWide);
				}
			}
		}
		
		public function handleWidthChange(newIsWide:Boolean, silent:Boolean = false, pt:Point = null):void
		{
			if (m_isWide == newIsWide) return;
			m_isWide = newIsWide;
			m_isDirty = true;
			// Need to dispatch AFTER setting width, this will trigger the score update
			// (we don't want to update the score with old values, we only know they're old
			// if we properly mark them dirty first)
			dispatchEvent(new EdgeSetChangeEvent(EdgeSetChangeEvent.EDGE_SET_CHANGED, this, newIsWide, null, silent, pt));
			for each (var iedge:GameEdgeContainer in m_incomingEdges) {
				iedge.updateSize();
				iedge.setInnerSegmentBorderWidth(m_isWide);
			}
			// May need to redraw inner edges
			for each (var oedge:GameEdgeContainer in m_outgoingEdges) {
				oedge.updateSize();
				oedge.setInnerSegmentBorderWidth(m_isWide);
			}
		}
		
		override public function draw():void
		{
			if (m_box9slice) {
				m_box9slice.removeFromParent(true);
			}
			
			var assetName:String;
			if(m_isEditable == true)
			{
				if (m_isWide == true)
					assetName = AssetInterface.PipeJamSubTexture_BlueDarkBoxPrefix;
				else
					assetName = AssetInterface.PipeJamSubTexture_BlueLightBoxPrefix;
			}
			else //not adjustable
			{
				if(m_isWide == true)
					assetName = AssetInterface.PipeJamSubTexture_GrayDarkBoxPrefix;
				else
					assetName = AssetInterface.PipeJamSubTexture_GrayLightBoxPrefix;
			}
			if (m_isSelected) assetName += "Select";
			m_box9slice = new NineSliceBatch(shapeWidth, shapeHeight, shapeHeight / 3.0, shapeHeight / 3.0, "Game", "PipeJamSpriteSheetPNG", "PipeJamSpriteSheetXML", assetName);
			addChild(m_box9slice);
			
			var wideScore:Number = getWideScore();
			var narrowScore:Number = getNarrowScore();
			const BLK_SZ:Number = 20; // create an upscaled version for better quality, then update width/height to shrink
			const BLK_RAD:Number = (shapeHeight / 3.0) * (BLK_SZ * 2 / m_boundingBox.height);
			if (wideScore > narrowScore) {
				m_scoreBlock = new ScoreBlock(AssetInterface.PipeJamSubTexture_BlueDarkBoxPrefix, (wideScore - narrowScore).toString(), BLK_SZ - BLK_RAD, BLK_SZ - BLK_RAD, BLK_SZ, null, BLK_RAD);
				m_scoreBlock.width = m_scoreBlock.height = m_boundingBox.height / 2;
				addChild(m_scoreBlock);
			} else if (narrowScore > wideScore) {
				m_scoreBlock = new ScoreBlock(AssetInterface.PipeJamSubTexture_BlueLightBoxPrefix, (narrowScore - wideScore).toString(), BLK_SZ - BLK_RAD, BLK_SZ - BLK_RAD, BLK_SZ, null, BLK_RAD);
				m_scoreBlock.width = m_scoreBlock.height = m_boundingBox.height / 2;
				addChild(m_scoreBlock);
			}
			useHandCursor = m_isEditable;
			
			//			var number:String = ""+m_id.substring(4);
			//			var txt:TextField = new TextField(m_shape.width, m_shape.height, number, "Veranda", 6); 
			//			txt.y = 0;
			//			txt.x = 0;
			//			m_shape.addChild(txt);
			super.draw();
		}
		
		override public function getWideScore():Number
		{
			if (!m_isEditable) { // don't assign scores for gray boxes (it would just confuse the user)
				return 0;
			} else {
				return Constants.WIDE_INPUT_POINTS * Math.max(0, m_numIncomingNodeEdges - m_numOutgoingNodeEdges);
			}
		}
		
		override public function getNarrowScore():Number
		{
			if (!m_isEditable) { // don't assign scores for gray boxes (it would just confuse the user)
				return 0;
			} else {
				return Constants.NARROW_OUTPUT_POINTS * Math.max(0, m_numOutgoingNodeEdges - m_numIncomingNodeEdges);
			}
		}
		
		override public function isWide():Boolean
		{
			return m_isWide;
		}
	}
}