package scenes.game.display
{
	import assets.AssetInterface;
	import starling.display.DisplayObject;
	
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
	
	public class GameNode extends GameNodeBase
	{
		protected var m_edgeSet:EdgeSetRef;
		
		public var m_numIncomingNodeEdges:int;
		public var m_numOutgoingNodeEdges:int;

		private var m_edgeSetEdges:Vector.<Edge>;
		
		private var m_gameNodeDictionary:Dictionary = new Dictionary;
		
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
			} else {
				m_isEditable = m_edgeSetEdges[0].editable;
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
		
		private var m_star:ScoreStar;
		override public function draw():void
		{
			var color:uint = getColor();
			
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
			m_shape.graphics.endFill();
			
			if (!isWide())
			{
				// Draw inner black outline to appear smaller if this is a narrow node
				m_shape.graphics.lineStyle(1.5, 0x0);
				m_shape.graphics.drawRoundRect(1.0, 1.0, (shapeWidth - 2.0), (shapeHeight - 2.0), shapeHeight/5.0);
			}
			
			if(m_isSelected && !isTempSelection)
			{
				m_shape.graphics.beginMaterialFill(selectedColorMaterial);
				m_shape.graphics.drawRect(0, 0, shapeWidth, shapeHeight);
				m_shape.graphics.endFill();
			}
			
			addChild(m_shape);
			
			var wideScore:Number = getWideScore();
			var narrowScore:Number = getNarrowScore();
			if (wideScore > narrowScore) {
				m_star = new ScoreStar((wideScore - narrowScore).toString(), WIDE_COLOR);
				m_star.width = m_star.height = m_boundingBox.height/2.0;
				m_star.x = m_star.y = m_boundingBox.height/8.0;
				addChild(m_star);
			} else if (narrowScore > wideScore) {
				m_star = new ScoreStar((narrowScore - wideScore).toString(), NARROW_COLOR);
				m_star.width = m_star.height = 0.5;
				m_star.width = m_star.height = m_boundingBox.height/2.0;
				m_star.x = m_star.y = m_boundingBox.height/8.0;
				addChild(m_star);
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