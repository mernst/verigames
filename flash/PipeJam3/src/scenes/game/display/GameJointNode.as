package scenes.game.display 
{
	import assets.AssetInterface;
	import display.NineSliceBatch;
	import flash.events.Event;
	import flash.geom.Rectangle;
	import graph.Node;
	import graph.Port;
	import scenes.BaseComponent;
	import starling.display.Quad;
	import starling.events.TouchEvent;
	import utils.XSprite;
	
	public class GameJointNode extends GameNodeBase
	{	
		private var m_node:Node;
		private var m_port:Port;
		
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
		
		override public function isWide():Boolean
		{
			return m_isWide;
		}
	}

}