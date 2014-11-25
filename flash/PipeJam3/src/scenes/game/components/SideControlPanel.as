package scenes.game.components
{
	import assets.AssetInterface;
	
	import events.SelectionEvent;
	
	import scenes.BaseComponent;
	import scenes.game.display.TutorialLevelManager;
	
	import starling.display.DisplayObject;
	import starling.display.Image;
	import starling.display.Quad;
	import starling.display.Sprite;
	import starling.events.Event;
	import starling.events.TouchEvent;
	import starling.events.TouchPhase;
	import starling.textures.Texture;
	import starling.textures.TextureAtlas;
	
	public class SideControlPanel extends BaseComponent
	{
		protected var WIDTH:Number;
		protected var HEIGHT:Number;
		
		protected var m_solverBrush:Sprite;
		protected var m_widenBrush:Sprite;
		protected var m_narrowBrush:Sprite;
		
		public function SideControlPanel( _width:Number, _height:Number)
		{
			WIDTH = _width;
			HEIGHT = _height;

			var backgroundQuad:Quad = new Quad(40, HEIGHT, 0x785201);
			addChild(backgroundQuad);
			x = WIDTH - 40;
			
			m_solverBrush = createPaintBrush(GridViewPanel.SOLVER_BRUSH);
			m_widenBrush = createPaintBrush(GridViewPanel.WIDEN_BRUSH);
			m_narrowBrush = createPaintBrush(GridViewPanel.NARROW_BRUSH);
			
			m_solverBrush.addEventListener(TouchEvent.TOUCH, changeCurrentBrush);
			m_widenBrush.addEventListener(TouchEvent.TOUCH, changeCurrentBrush);
			m_narrowBrush.addEventListener(TouchEvent.TOUCH, changeCurrentBrush);


			//set all to visible == false so that they don't flash on, before being turned off
			m_solverBrush.scaleX = m_solverBrush.scaleY = .2;
			m_solverBrush.x = (WIDTH - m_solverBrush.width)/2;
			m_solverBrush.y = 120;
			m_solverBrush.visible = false;
			addChild(m_solverBrush);
			m_widenBrush.x = m_solverBrush.x;
			m_widenBrush.y = 160;
			m_widenBrush.scaleX = m_widenBrush.scaleY = .2;
			m_widenBrush.visible = false;
			addChild(m_widenBrush);
			m_narrowBrush.x = m_solverBrush.x;
			m_narrowBrush.y = 200;
			m_narrowBrush.scaleX = m_narrowBrush.scaleY = .2;
			m_narrowBrush.visible = false;
			addChild(m_narrowBrush);
		}
		
		private function changeCurrentBrush(evt:starling.events.TouchEvent):void
		{
			if(evt.getTouches(this, TouchPhase.ENDED).length && evt.target is DisplayObject)
			{
				var target:DisplayObject = (evt.target as DisplayObject).parent;
				dispatchEvent(new SelectionEvent(SelectionEvent.BRUSH_CHANGED, target.name, null));
			}
		}
		
		public function showVisibleBrushes(visibleBrushes:int):void
		{
			var count:int = 0;
			m_solverBrush.visible = visibleBrushes & TutorialLevelManager.SOLVER_BRUSH ? true : false;
			if(m_solverBrush.visible) count++;
			m_narrowBrush.visible = visibleBrushes & TutorialLevelManager.WIDEN_BRUSH ? true : false;
			if(m_narrowBrush.visible) count++;
			m_widenBrush.visible = visibleBrushes & TutorialLevelManager.NARROW_BRUSH ? true : false;
			if(m_widenBrush.visible) count++;
			
			//if only one shows, hide them all
			if(count == 1)
				m_solverBrush.visible = m_narrowBrush.visible = m_widenBrush.visible = false;
		}
	}
}