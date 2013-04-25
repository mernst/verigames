package scenes.game.display
{
	import assets.AssetsFont;
	import scenes.game.display.GameComponent;
	
	import starling.display.Quad;
	import starling.events.Event;
	import starling.events.Touch;
	import starling.events.TouchEvent;
	import starling.events.TouchPhase;
	
	public class ScoreBlock extends GameComponent
	{
		public static const WIDTH:Number = 15;
		public static const VERTICAL_GAP:Number = 1;
		private static const MIN_HEIGHT:Number = 5;
		
		/** Component associated with this score, GameNodes have points for wide inputs/narrow outputs
		 * while GameEdgeContainers have negative points for errrors */
		private var m_gameComponent:GameComponent;
		
		/** Text showing current score on score_pane */
		private var m_text:TextFieldWrapper;
		
		public function ScoreBlock(gameComponent:GameComponent)
		{
			m_gameComponent = gameComponent;
			var blockHeight:Number = Math.abs(gameComponent.getScore()) - VERTICAL_GAP;
			blockHeight = Math.max(blockHeight, MIN_HEIGHT);
			var blockWidth:Number = WIDTH;
			var outline:Quad = new Quad(blockWidth, blockHeight, 0x000000);
			var quad:Quad = new Quad(blockWidth-1, blockHeight-1, gameComponent.getColor());
			//set center point offset
			addChild(outline);
			addChild(quad);
			quad.x = .5;
			quad.y = .5;
			
			m_text = TextFactory.getInstance().createTextField(gameComponent.getScore().toString(), AssetsFont.FONT_NUMERIC, blockWidth, blockHeight, MIN_HEIGHT, 0x00000);
			m_text.x = -5; 
			TextFactory.getInstance().updateAlign(m_text, 2, 1);
			addChild(m_text);
			
			addEventListener(TouchEvent.TOUCH, onTouch);
			this.useHandCursor = true;
			m_isDirty = true;
		}
		
		override public function dispose():void
		{
			disposeChildren();
			m_text = null;
			if (hasEventListener(TouchEvent.TOUCH)) {
				removeEventListener(TouchEvent.TOUCH, onTouch);
			}
			super.dispose();
		}
		
		private function onTouch(event:TouchEvent):void
		{
			var touches:Vector.<Touch> = event.touches;
			if(event.getTouches(this, TouchPhase.ENDED).length)
			{
				if (touches.length == 1)
				{
					dispatchEvent(new Event(Level.CENTER_ON_COMPONENT, true, m_gameComponent));
				}
			}
		}
	}
}