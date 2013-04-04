package scenes.game.display
{
	import scenes.game.display.GameComponent;
	
	import starling.display.Quad;
	import starling.events.Event;
	import starling.events.Touch;
	import starling.events.TouchEvent;
	import starling.events.TouchPhase;
	
	public class ScoreBlock extends GameComponent
	{
		public static var wideHeight:Number;
		public static var narrowHeight:Number;
		
		public static var maxWidth:Number;
		
		protected var m_node:GameNode;
		
		public function ScoreBlock(node:GameNode)
		{
			m_node = node;
			var color:uint = 0;
			if(node.isWide() == false)
			{
				for each(var edge:GameEdgeContainer in node.m_incomingEdges)
				{
					if(edge.m_fromNode && edge.m_fromNode.isWide())
					{
						color = 0xff0000;
						break;
					}
				}
			}
			if(color == 0)
				color = node.getColor();
			
			var blockHeight:Number = node.isWide() ? wideHeight : narrowHeight;
			var blockWidth:Number = node.height < maxWidth ? node.height : maxWidth;
			var outline:Quad = new Quad(blockWidth, blockHeight, 0x000000);
			var quad:Quad = new Quad(blockWidth-1, blockHeight-1, color);
			//set center point offset
			addChild(outline);
			addChild(quad);
			quad.x = .5;
			quad.y = .5;
			
			this.x = -node.height/2;
			
			addEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
			addEventListener(Event.REMOVED_FROM_STAGE, onRemovedFromStage);	

		}
		
		public function onAddedToStage(event:starling.events.Event):void
		{
			addEventListener(TouchEvent.TOUCH, onTouch);

			m_isDirty = true;
			
		}
		
		private function onRemovedFromStage():void
		{
			
			removeEventListener(TouchEvent.TOUCH, onTouch);
		}
		
		private function onTouch(event:TouchEvent):void
		{
			var touches:Vector.<Touch> = event.touches;
			if(event.getTouches(this, TouchPhase.ENDED).length)
			{
				if (touches.length == 1)
				{
					dispatchEvent(new Event(Level.CENTER_ON_NODE, true, m_node));
				}

			}
		}
	}
}