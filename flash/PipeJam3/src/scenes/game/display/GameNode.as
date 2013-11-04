package scenes.game.display
{
	import assets.AssetInterface;
	import graph.PropDictionary;
	import events.ToolTipEvent;
	import starling.display.Quad;
	
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
		public var m_edgeSet:EdgeSetRef;
		
		public var m_numIncomingNodeEdges:int;
		public var m_numOutgoingNodeEdges:int;

		private var m_edgeSetEdges:Vector.<Edge>;
		private var m_gameNodeDictionary:Dictionary = new Dictionary;
		private var m_scoreBlock:ScoreBlock;
		
		public function GameNode(nodeXML:XML, _draggable:Boolean = true, edgeSet:EdgeSetRef = null, levelEdgeSetEdges:Vector.<Edge> = null)
		{
			super(nodeXML);
			draggable = _draggable;
			m_edgeSet = edgeSet;
			if (levelEdgeSetEdges != null) {
				m_edgeSetEdges = levelEdgeSetEdges.concat();
			} else {
				m_edgeSetEdges = new Vector.<Edge>();
			}
			if (m_edgeSet) m_props = m_edgeSet.getProps().clone();
			
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
					trace("WARNING: Edge id " + myEdge.edge_id + " editable doesn't match edgeSet value = " + m_isEditable.toString());
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
		
		public override function onClicked(pt:Point):void
		{
			var eventToUndo:EdgeSetChangeEvent,  eventToDispatch:UndoEvent;
			if (m_propertyMode == PropDictionary.PROP_NARROW) {
				if(m_isEditable) {
					var newIsWide:Boolean = !m_isWide;
					handleWidthChange(newIsWide, false, pt);
					//dispatchEvent(new starling.events.Event(Level.UNSELECT_ALL, true, this));
					eventToUndo = new EdgeSetChangeEvent(EdgeSetChangeEvent.EDGE_SET_CHANGED, this, PropDictionary.PROP_NARROW, !newIsWide);
					eventToDispatch = new UndoEvent(eventToUndo, this);
					dispatchEvent(eventToDispatch);
				}
			} else if (m_propertyMode.indexOf(PropDictionary.PROP_KEYFOR_PREFIX) == 0) {
				if (m_edgeSet.canSetProp(m_propertyMode)) {
					var edgeSetValue:Boolean = m_edgeSet.getProps().hasProp(m_propertyMode);
					dispatchEvent(new EdgeSetChangeEvent(EdgeSetChangeEvent.EDGE_SET_CHANGED, this, m_propertyMode, !edgeSetValue, null, false, pt));
					eventToUndo = new EdgeSetChangeEvent(EdgeSetChangeEvent.EDGE_SET_CHANGED, this, m_propertyMode, !edgeSetValue);
					eventToDispatch = new UndoEvent(eventToUndo, this);
					dispatchEvent(eventToDispatch);
					m_isDirty = true;
				}
			}
		}
		
		public override function handleUndoEvent(undoEvent:Event, isUndo:Boolean = true):void
		{
			if (undoEvent is EdgeSetChangeEvent) {
				var evt:EdgeSetChangeEvent = undoEvent as EdgeSetChangeEvent;
				if (evt.prop == PropDictionary.PROP_NARROW) {
					// This is a confusing double negative, if narrow is TRUE then isWide = false, but negate for undo
					handleWidthChange(isUndo ? evt.propValue : !evt.propValue);
				} else if (m_propertyMode.indexOf(PropDictionary.PROP_KEYFOR_PREFIX) == 0) {
					dispatchEvent(new EdgeSetChangeEvent(EdgeSetChangeEvent.EDGE_SET_CHANGED, this, m_propertyMode, isUndo ? !evt.propValue : evt.propValue, null, false, null));
					m_isDirty = true;
				}
			} else {
				m_isDirty = true;
			}
		}
		
		public function handleWidthChange(newIsWide:Boolean, silent:Boolean = false, pt:Point = null):void
		{
			var redraw:Boolean = (m_isWide != newIsWide);
			m_isWide = newIsWide;
			m_isDirty = redraw;
			// Need to dispatch AFTER setting width, this will trigger the score update
			// (we don't want to update the score with old values, we only know they're old
			// if we properly mark them dirty first)
			dispatchEvent(new EdgeSetChangeEvent(EdgeSetChangeEvent.EDGE_SET_CHANGED, this, PropDictionary.PROP_NARROW, !newIsWide, null, silent, pt));
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
			if (m_costume) {
				m_costume.removeFromParent(true);
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
			m_costume = new NineSliceBatch(shapeWidth, shapeHeight, shapeHeight / 3.0, shapeHeight / 3.0, "Game", "PipeJamSpriteSheetPNG", "PipeJamSpriteSheetXML", assetName);
			addChild(m_costume);
			
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
			
			if (m_edgeSet) {
				var i:int = 0;
				for (var prop:String in m_edgeSet.getProps().iterProps()) {
					if (prop == PropDictionary.PROP_NARROW) continue;
					if (prop == m_propertyMode) {
						var keyQuad:Quad = new Quad(3, 3, KEYFOR_COLOR);
						keyQuad.x = 1 + i * 4;
						keyQuad.y = m_boundingBox.height - 4;
						addChild(keyQuad);
						i++;
					}
				}
			}
			
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
		
		override protected function getToolTipEvent():ToolTipEvent
		{
			var lockedTxt:String = isEditable() ? "" : "Locked ";
			var wideTxt:String = isWide() ? "Wide " : "Narrow ";
			return new ToolTipEvent(ToolTipEvent.ADD_TOOL_TIP, this, lockedTxt + wideTxt + "Widget", 8);
		}
		
	}
}