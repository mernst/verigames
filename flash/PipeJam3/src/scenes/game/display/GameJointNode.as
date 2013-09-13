package scenes.game.display 
{
	import assets.AssetInterface;
	import display.NineSliceBatch;
	import events.ToolTipEvent;
	import flash.events.Event;
	import flash.geom.Rectangle;
	import graph.Node;
	import graph.NodeTypes;
	import graph.Port;
	import scenes.BaseComponent;
	import starling.display.Quad;
	import starling.events.TouchEvent;
	import utils.XSprite;
	
	public class GameJointNode extends GameNodeBase
	{	
		protected var m_node:Node;
		protected var m_port:Port;
		
		public function GameJointNode( _layoutXML:XML, _draggable:Boolean, _node:Node = null, _port:Port = null) 
		{
			super(_layoutXML);
			draggable = _draggable;
			m_node = _node;
			m_port = _port;
			updateSize();
			draw();
		}
		
		override public function draw():void
		{
			if (m_box9slice)
				m_box9slice.removeFromParent(true);
			
			var assetName:String = m_isSelected ? AssetInterface.PipeJamSubTexture_GrayDarkBoxSelectPrefix : AssetInterface.PipeJamSubTexture_GrayDarkBoxPrefix;
			m_box9slice = new NineSliceBatch(m_boundingBox.width, m_boundingBox.height, m_boundingBox.height / 3.0, m_boundingBox.height / 3.0, "Game", "PipeJamSpriteSheetPNG", "PipeJamSpriteSheetXML", assetName);
			addChild(m_box9slice);
			this.flatten();
		}
		
		override public function updateSize():void
		{
			// joints have no concept of width at this point
		}
		
		override public function updatePortIndexes():void
		{
			
		}
		
		override public function isWide():Boolean
		{
			return m_isWide;
		}
		
		override protected function getToolTipEvent():ToolTipEvent
		{
			var label:String = "Link connector";
			if (m_node) {
				switch (m_node.kind) {
					case NodeTypes.SPLIT:
					case NodeTypes.OUTGOING:
						if (m_outgoingEdges.length > 1) {
							label = "Split";
						}
						break;
					case NodeTypes.MERGE:
						if (m_incomingEdges.length > 1) {
							label = "Merge";
						}
						break;
					case NodeTypes.GET:
						label = "Map";
						break;
					case NodeTypes.BALL_SIZE_TEST:
						label = "Diverter";
						break;
					case NodeTypes.START_LARGE_BALL:
						label = "Wide link start";
						break;
					case NodeTypes.START_NO_BALL:
					case NodeTypes.START_SMALL_BALL:
						label = "Narrow link start";
						break;
				}
			}
			return new ToolTipEvent(ToolTipEvent.ADD_TOOL_TIP, this, label, 8);
		}
	}

}