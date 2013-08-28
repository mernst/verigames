package scenes.game.display 
{
	import assets.AssetInterface;
	
	import display.NineSliceBatch;
	
	import events.EdgePropChangeEvent;
	import events.PropertyModeChangeEvent;
	import events.StampChangeEvent;
	
	import flash.events.Event;
	import flash.geom.Point;
	
	import graph.Edge;
	import graph.MapGetNode;
	import graph.Node;
	import graph.NodeTypes;
	import graph.Port;
	import graph.PropDictionary;
	
	import starling.display.Image;
	import starling.display.Quad;
	import starling.display.Sprite;
	
	public class GameMapGetJoint extends GameJointNode 
	{
		private var m_valueEdge:GameEdgeContainer;
		private var m_argumentEdge:GameEdgeContainer;
		private var m_outputEdge:GameEdgeContainer;
		private var m_connectionLayer:Sprite;
		
		public function GameMapGetJoint(_layoutXML:XML, _draggable:Boolean, _node:Node, _port:Port=null) 
		{
			super(_layoutXML, _draggable, _node, _port);
			if (!(_node is MapGetNode)) {
				throw new Error("MapGetJoint created for node where node is not type MapGetNode.");
			}
		}
		
		override public function setIncomingEdge(edge:GameEdgeContainer):void
		{
			super.setIncomingEdge(edge);
			if (edge.graphEdge == getNode.valueEdge) {
				if (m_valueEdge) m_valueEdge.graphEdge.removeEventListener(EdgePropChangeEvent.EXIT_BALL_TYPE_CHANGED, update);
				m_valueEdge = edge;
				m_valueEdge.graphEdge.addEventListener(EdgePropChangeEvent.EXIT_BALL_TYPE_CHANGED, update);
				alignOutputEdge();
			} else if (edge.graphEdge == getNode.argumentEdge) {
				if (m_argumentEdge) m_argumentEdge.graphEdge.linked_edge_set.removeEventListener(StampChangeEvent.STAMP_ACTIVATION, update);
				m_argumentEdge = edge;
				m_argumentEdge.graphEdge.linked_edge_set.addEventListener(StampChangeEvent.STAMP_ACTIVATION, update);
			}
		}
		
		public function getUpstreamEdgeContainers():Vector.<GameEdgeContainer>
		{
			var vec:Vector.<GameEdgeContainer> = new Vector.<GameEdgeContainer>();
			if (!m_argumentEdge) return vec;
			var edgesToCheck:Vector.<GameEdgeContainer> = new Vector.<GameEdgeContainer>();
			edgesToCheck.push(m_argumentEdge);
			var visitedEdges:Vector.<GameEdgeContainer> = new Vector.<GameEdgeContainer>();
			while (edgesToCheck.length > 0) {
				var edge:GameEdgeContainer = edgesToCheck.shift();
				if (visitedEdges.indexOf(edge) > -1) continue; // avoid looping
				visitedEdges.push(edge);
				if (edge.graphEdge) {
					// TODO: do we need to enforce edge.graphEdge.linked_edge_set.stamp_dictionary[getNode.mapEdge.linked_edge_set.id] ??
					if (vec.indexOf(edge) == -1) {
						vec.push(edge);
						switch (edge.graphEdge.from_node.kind) {
							case NodeTypes.GET:
								// Don't continue traversing through this node, KeyFor does not propagate thru
								continue;
							case NodeTypes.BALL_SIZE_TEST:
							case NodeTypes.CONNECT:
							case NodeTypes.MERGE:
							case NodeTypes.SPLIT:
							case NodeTypes.SUBBOARD: // ??
							case NodeTypes.BALL_SIZE_TEST:
								// Continue traversing back through these nodes, KeyFor propagates through these
								break;
						}
						if (edge.m_fromComponent) {
							var i:int;
							for (i = 0; i < edge.m_fromComponent.m_incomingEdges.length; i++) {
								edgesToCheck.push(edge.m_fromComponent.m_incomingEdges[i]);
							}
						}
					}
				}
			}
			return vec;
		}
		
		private function update(evt:Event):void
		{
			m_isDirty = true;
		}
		
		override public function setOutgoingEdge(edge:GameEdgeContainer):void
		{
			super.setOutgoingEdge(edge);
			m_outputEdge = edge;
			alignOutputEdge();
		}
		
		private function alignOutputEdge():void
		{
			if (!m_outputEdge || !m_valueEdge) return;
			// Have output edge line up with value edge
			var newStart:Point = new Point(m_valueEdge.m_endPoint.x + m_valueEdge.x - m_outputEdge.x, m_outputEdge.m_startPoint.y);
			m_outputEdge.setStartPosition(newStart);
		}
		
		public function get getNode():MapGetNode
		{
			return m_node as MapGetNode;
		}
	
		override public function draw():void
		{
			if (m_box9slice)
				m_box9slice.removeFromParent(true);
			
			var assetName:String = m_isSelected ? AssetInterface.PipeJamSubTexture_GrayDarkBoxSelectPrefix : AssetInterface.PipeJamSubTexture_GrayDarkBoxPrefix;
			m_box9slice = new NineSliceBatch(m_boundingBox.width, m_boundingBox.height, m_boundingBox.height / 3.0, m_boundingBox.height / 3.0, "Game", "PipeJamSpriteSheetPNG", "PipeJamSpriteSheetXML", assetName);
			addChild(m_box9slice);
			
			if (m_connectionLayer) m_connectionLayer.removeFromParent(true);
			m_connectionLayer = new Sprite();
			if (m_valueEdge && m_argumentEdge && m_outputEdge) {
				var valWidth:Number = m_valueEdge.isWide() ? GameEdgeContainer.WIDE_WIDTH : GameEdgeContainer.NARROW_WIDTH;
				var q1:Quad, q2:Quad, q3:Quad, j1:Image, j2:Image;
				if (getNode.argumentHasMapStamp()) {
					q1 = new Quad(valWidth, m_boundingBox.height / 2.0, m_valueEdge.getColor());
					q1.x = m_valueEdge.m_endPoint.x - q1.width / 2.0 + m_valueEdge.x - this.x;
					q1.y = m_valueEdge.m_endPoint.y + m_valueEdge.y - this.y;
					m_connectionLayer.addChild(q1);
					j1 = GameEdgeJoint.createJoint(false, m_valueEdge.isEditable(), m_valueEdge.isWide());
					j1.width = j1.height = valWidth;
					j1.x = q1.x;
					j1.y = q1.y + q1.height - j1.height / 2.0;
					m_connectionLayer.addChildAt(j1, 0);
					q3 = new Quad(valWidth, m_boundingBox.height / 2.0, m_valueEdge.getColor());
					q3.x = m_outputEdge.m_startPoint.x - q3.width / 2.0 + m_outputEdge.x - this.x;
					q3.y = m_outputEdge.m_startPoint.y + m_outputEdge.y - this.y - q3.height;
					m_connectionLayer.addChild(q3);
					j2 = GameEdgeJoint.createJoint(false, m_valueEdge.isEditable(), m_valueEdge.isWide());
					j2.width = j2.height = valWidth;
					j2.x = q3.x;
					j2.y = q3.y - j2.height / 2.0;
					m_connectionLayer.addChildAt(j2, 0);
					q2 = new Quad(Math.abs(q3.x - q1.x), valWidth, m_valueEdge.getColor());
					q2.x = Math.min(q3.x, q1.x) + valWidth / 2.0;
					q2.y = m_boundingBox.height / 2.0 - valWidth / 2.0;
					addChild(q2);
				} else {
					q1 = new Quad(valWidth, m_boundingBox.height / 3.0, m_valueEdge.getColor());
					q1.x = m_valueEdge.m_endPoint.x - q1.width / 2.0 + m_valueEdge.x - this.x;
					q1.y = m_valueEdge.m_endPoint.y + m_valueEdge.y - this.y;
					m_connectionLayer.addChild(q1);
					j1 = GameEdgeJoint.createJoint(false, m_valueEdge.isEditable(), m_valueEdge.isWide());
					j1.width = j1.height = valWidth;
					j1.x = q1.x;
					j1.y = q1.y + q1.height - j1.height / 2.0;
					m_connectionLayer.addChildAt(j1, 0);
					var outWidth:Number = GameEdgeContainer.WIDE_WIDTH;
					var outColor:int = UNADJUSTABLE_WIDE_COLOR;
					q3 = new Quad(outWidth, m_boundingBox.height / 3.0, outColor);
					q3.x = m_outputEdge.m_startPoint.x - q3.width / 2.0 + m_outputEdge.x - this.x;
					q3.y = m_outputEdge.m_startPoint.y + m_outputEdge.y - this.y - q3.height;
					q3.color = 0x0;
					m_connectionLayer.addChild(q3);
					j2 = GameEdgeJoint.createJoint(false, false, true);
					j2.width = j2.height = outWidth;
					j2.x = q3.x;
					j2.y = q3.y - j2.height / 2.0;
					j2.color = 0x0;
					m_connectionLayer.addChildAt(j2, 0);
				}
			}
			addChild(m_connectionLayer);
			
			this.flatten();
		}
		
		override public function onClicked(pt:Point):void
		{
			var prop:String = getNode.getMapProperty();
			// If already in mode for this map, revert to NARROW mode
			if (m_propertyMode == prop) prop = PropDictionary.PROP_NARROW;
			dispatchEvent(new PropertyModeChangeEvent(PropertyModeChangeEvent.PROPERTY_MODE_CHANGE, prop));
		}
	}

}