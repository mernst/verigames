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
	
	import starling.display.DisplayObject;
	import starling.display.DisplayObjectContainer;
	import starling.display.Image;
	import starling.display.Shape;
	import starling.events.Event;
	import starling.events.Touch;
	import starling.events.TouchEvent;
	import starling.events.TouchPhase;
	import starling.textures.Texture;
	
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
			var color:uint = getColor();
			if (m_shape) {
				m_shape.removeFromParent(true);
			}
			m_shape = new Shape;
			if(color == WIDE_COLOR)
				m_shape.graphics.beginMaterialFill(darkColorMaterial);
			else if(color == NARROW_COLOR)
				m_shape.graphics.beginMaterialFill(lightColorMaterial);
			else if(color == UNADJUSTABLE_WIDE_COLOR)
				m_shape.graphics.beginMaterialFill(unadjustableWideColorMaterial);
			else if(color == UNADJUSTABLE_NARROW_COLOR)
				m_shape.graphics.beginMaterialFill(unadjustableNarrowColorMaterial);
			
			m_shape.graphics.drawRoundRect(0, 0, shapeWidth, shapeHeight, shapeHeight/5.0);
			
			if(m_isSelected && !isTempSelection)
			{
				m_shape.graphics.beginMaterialFill(selectedColorMaterial);
				m_shape.graphics.drawRect(0, 0, shapeWidth, shapeHeight);
			}
			m_shape.graphics.endFill();
			
			addChild(m_shape);
			
			var wideScore:Number = getWideScore();
			var narrowScore:Number = getNarrowScore();
			const BLK_SZ:Number = 20; // create an upscaled version for better quality, then update width/height to shrink
			if (wideScore > narrowScore) {
				m_scoreBlock = new ScoreBlock(WIDE_COLOR, (wideScore - narrowScore).toString(), BLK_SZ, BLK_SZ, BLK_SZ);
				m_scoreBlock.width = m_scoreBlock.height = m_boundingBox.height/2.0;
				m_scoreBlock.x = m_scoreBlock.y = m_scoreBlock.height/8.0;
				addChild(m_scoreBlock);
			} else if (narrowScore > wideScore) {
				m_scoreBlock = new ScoreBlock(NARROW_COLOR, (narrowScore - wideScore).toString(), BLK_SZ, BLK_SZ, BLK_SZ);
				m_scoreBlock.width = m_scoreBlock.height = m_boundingBox.height/2.0;
				m_scoreBlock.x = m_scoreBlock.y = m_scoreBlock.height/8.0;
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