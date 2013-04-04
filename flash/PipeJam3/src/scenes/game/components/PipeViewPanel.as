package scenes.game.components
{
	import flash.display.BitmapData;
	import flash.display.Shape;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import scenes.game.display.*;
	
	import starling.display.Image;
	import starling.display.Sprite;
	import starling.events.*;
	import starling.textures.Texture;
	import scenes.BaseComponent;
	
	public class PipeViewPanel extends BaseComponent
	{
		protected var m_activeBoard:BoardView;
		protected var m_needsUpdate:Boolean;
		
		public function PipeViewPanel()
		{
			super();
						
			addEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
			addEventListener(Event.REMOVED_FROM_STAGE, onRemovedFromStage);			
		}
		
		
		protected function onAddedToStage(event:starling.events.Event):void
		{
			addEventListener(TouchEvent.TOUCH, onTouch);
			addEventListener(Board.BOARD_SCROLLED, onBoardScrolled);	
			m_needsUpdate = true;
		}
		
		public function onBoardScrolled(event:starling.events.Event):void
		{
			m_activeBoard.x -= (event.data as Point).x*width/100;
			m_activeBoard.y -= (event.data as Point).y*height/100;
			trace(m_activeBoard.x + " " + m_activeBoard.y);
			//this creates a rectangle were all values are percentages of view
			var rectangleDisplayed:Rectangle = new Rectangle(m_activeBoard.x*100/m_activeBoard.width, m_activeBoard.y*100/m_activeBoard.height, 
				m_activeBoard.internalScaleFactors.x,
				m_activeBoard.internalScaleFactors.y);
			dispatchEvent(new starling.events.Event(Board.BOARD_SECTION_DISPLAYED, true, rectangleDisplayed));
			
		}
		
		public function onBoardSelected(event:starling.events.Event):void
		{
			if(m_activeBoard == (event.data as Board).getMainView())
				return; 
			
			if(m_activeBoard)
				m_activeBoard.removeFromParent();
			
			m_activeBoard = (event.data as Board).getMainView();
			m_activeBoard.scaleX = width/m_activeBoard.m_parentBoard.boardViewDefaultSize.x;
			m_activeBoard.scaleY = height/m_activeBoard.m_parentBoard.boardViewDefaultSize.y;
			if(m_activeBoard.max_pipe_x>200)
			{
				m_activeBoard.scaleX = m_activeBoard.scaleX*Math.round(m_activeBoard.max_pipe_x/200);
				m_activeBoard.internalScaleFactors.x = 100/Math.round(m_activeBoard.max_pipe_x/200);
			}
			if(m_activeBoard.max_pipe_y>200)
			{
				m_activeBoard.scaleY = m_activeBoard.scaleY*Math.round(m_activeBoard.max_pipe_y/200);
				m_activeBoard.internalScaleFactors.y = 100/Math.round(m_activeBoard.max_pipe_y/200);
			}
			m_needsUpdate = true;

			addChild(m_activeBoard);

			//this creates a rectangle were all values are percentages of view
			var rectangleDisplayed:Rectangle = new Rectangle(m_activeBoard.x*100/m_activeBoard.width, m_activeBoard.y*100/m_activeBoard.height, 
				m_activeBoard.internalScaleFactors.x,
				m_activeBoard.internalScaleFactors.y);

			dispatchEvent(new starling.events.Event(Board.BOARD_SECTION_DISPLAYED, true, rectangleDisplayed));
		}
		
		private function onRemovedFromStage():void
		{
			removeEventListener(Event.ENTER_FRAME, onEnterFrame);
			removeEventListener(TouchEvent.TOUCH, onTouch);
		}
		
		private function onTouch(event:TouchEvent):void
		{
			var touches:Vector.<Touch> = event.touches;
			if(event.getTouches(this, TouchPhase.ENDED).length){
				if (touches.length == 1)
				{
					var touch:Touch = event.getTouch(this, TouchPhase.ENDED);
					trace("View touch " + touch.target);
					
					//try removing pipes and recreating them on click
					removeChild(m_activeBoard);
					addChild(m_activeBoard);
				}
			}
		}
		
		public function onEnterFrame(event:Event):void
		{

		}
	}
}