package scenes.game.display
{
	import assets.AssetsFont;
	import display.RoundedRect;
	import scenes.game.display.GameComponent;
	
	import starling.display.Quad;
	import starling.events.Event;
	import starling.events.Touch;
	import starling.events.TouchEvent;
	import starling.events.TouchPhase;
	
	public class ScoreBlock extends GameComponent
	{
		/** Component associated with this score, GameNodes have points for wide inputs/narrow outputs
		 * while GameEdgeContainers have negative points for errors. Assigning no gameComponent will
		 * just display the score and the ScoreBlock will not be interactive */
		private var m_gameComponent:GameComponent;
		private var m_color:Number;
		private var m_score:String;
		private var m_width:Number;
		private var m_height:Number;
		private var m_fontSize:Number;
		
		/** Text showing current score on score_pane */
		private var m_text:TextFieldWrapper;
		
		public function ScoreBlock(_color:Number, _score:String, _width:Number, _height:Number, _fontSize:Number, _gameComponent:GameComponent = null, _radius:Number = -1)
		{
			super("");
			
			m_color = _color;
			m_score = _score;
			m_width = _width;
			m_height = _height;
			m_fontSize = _fontSize;
			m_gameComponent = _gameComponent;
			if (_radius <= 0) {
				_radius = Math.min(m_width, m_height) / 5.0;
			}
			var rect:RoundedRect = new RoundedRect(m_width-1, m_height-1, _radius, _color, true, false, false, false);
			addChild(rect);
			
			m_text = TextFactory.getInstance().createTextField(m_score, AssetsFont.FONT_NUMERIC, m_width, m_height, m_fontSize, 0x00000);
			TextFactory.getInstance().updateAlign(m_text, 1, 1);
			m_text.width = m_width;
			m_text.height = m_height;
			addChild(m_text);
			if (m_gameComponent) {
				addEventListener(TouchEvent.TOUCH, onTouch);
				this.useHandCursor = true;
			}
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
					if (m_gameComponent is GameEdgeContainer) {
						// Center on marker joint - this is where we actually display the error
						var jointToCenter:GameEdgeJoint = (m_gameComponent as GameEdgeContainer).m_markerJoint;
						dispatchEvent(new Event(Level.CENTER_ON_COMPONENT, true, jointToCenter));
					} else {
						dispatchEvent(new Event(Level.CENTER_ON_COMPONENT, true, m_gameComponent));
					}
				}
			}
		}
	}
}