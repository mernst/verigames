package scenes.game.display
{
	import display.NineSliceBatch;
	import graph.Edge;
	import graph.EdgeSetRef;
	import graph.Network;
	import graph.NodeTypes;
	import graph.Port;
	
	import flash.utils.Dictionary;
	
	public class GameNode extends GameNodeBase
	{
		protected var m_edgeSet:EdgeSetRef;
		
		public var m_numIncomingNodeEdges:int;
		public var m_numOutgoingNodeEdges:int;

		private var m_edgeSetEdges:Vector.<Edge>;
		private var m_gameNodeDictionary:Dictionary = new Dictionary;
		private var m_scoreBlock:ScoreBlock;
		
		public function GameNode(nodeXML:XML, edgeSet:EdgeSetRef = null, edgeSetEdges:Vector.<Edge> = null)
		{
			super(nodeXML);
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
		
		override public function draw():void
		{
			if (m_box9slice) {
				m_box9slice.removeFromParent(true);
			}
			
			var assetName:String;
			if(m_isEditable == true)
			{
				if(m_isWide == true)
					assetName = "RoundRectWidePNG";
				else
					assetName = "RoundRectNarrowPNG";
			}
			else //not adjustable
			{
				if(m_isWide == true)
					assetName = "RoundRectDarkGrayPNG";
				else
					assetName = "RoundRectLightGrayPNG";
			}
			
			m_box9slice = new NineSliceBatch(shapeWidth, shapeHeight, shapeHeight / 5.0, shapeHeight / 5.0, "Game", assetName, "Box9SliceXML", "Box");
			addChild(m_box9slice);
			
			var wideScore:Number = getWideScore();
			var narrowScore:Number = getNarrowScore();
			const BLK_SZ:Number = 20; // create an upscaled version for better quality, then update width/height to shrink
			if (wideScore > narrowScore) {
				m_scoreBlock = new ScoreBlock("RoundRectWidePNG", (wideScore - narrowScore).toString(), BLK_SZ, BLK_SZ, BLK_SZ, null, (shapeHeight / 5.0) * (BLK_SZ * 2 / m_boundingBox.height));
				m_scoreBlock.width = m_scoreBlock.height = m_boundingBox.height / 2;
				addChild(m_scoreBlock);
			} else if (narrowScore > wideScore) {
				m_scoreBlock = new ScoreBlock("RoundRectNarrowPNG", (narrowScore - wideScore).toString(), BLK_SZ, BLK_SZ, BLK_SZ, null, (shapeHeight / 5.0) * (BLK_SZ * 2 / m_boundingBox.height));
				m_scoreBlock.width = m_scoreBlock.height = m_boundingBox.height / 2;
				addChild(m_scoreBlock);
			}
			useHandCursor = m_isEditable;
			
			//			var number:String = ""+m_id.substring(4);
			//			var txt:TextField = new TextField(m_shape.width, m_shape.height, number, "Veranda", 6); 
			//			txt.y = 0;
			//			txt.x = 0;
			//			m_shape.addChild(txt);
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