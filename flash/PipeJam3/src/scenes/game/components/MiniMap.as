package scenes.game.components
{
	import assets.AssetInterface;
	import events.MiniMapEvent;
	import events.MoveEvent;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.Dictionary;
	import particle.ErrorParticleSystem;
	import scenes.BaseComponent;
	import scenes.game.display.Level;
	import starling.display.Image;
	import starling.display.Quad;
	import starling.display.Sprite;
	import starling.events.EnterFrameEvent;
	import starling.events.Event;
	import starling.events.Touch;
	import starling.events.TouchEvent;
	import starling.events.TouchPhase;
	import starling.textures.Texture;
	import starling.textures.TextureAtlas;
	import utils.XMath;
	
	public class MiniMap extends BaseComponent
	{
		public static const WIDTH:Number = 0.8 * 140;
		public static const HEIGHT:Number = 0.8 * 134;
		
		public static const LEFT_BUFFER_PCT:Number = (44.0 + 15.0) / 280.0;  // extra +15 to avoid bottom left corner (diagonal border)
		public static const BOTTOM_BUFFER_PCT:Number = (62.0 + 15.0) / 268.0;// extra +15 to avoid bottom left corner (diagonal border)
		
		private static const BORDER_PCT:Number = 0.05; // allows empty border around map edges
		
		protected var conflictList:Vector.<ErrorPair>;
		protected var currentLevel:Level;
		
		protected var backgroundImage:Image;
		protected var gameNodeLayer:Sprite;
		protected var errorLayer:Sprite;
		protected var viewRectLayer:Sprite;
		
		private var m_viewSpaceIndicator:Sprite;
		
		private var m_contentX:Number;
		private var m_contentY:Number;
		private var m_contentScale:Number;
		public var isDirty:Boolean;
		
		public function MiniMap()
		{
			var atlas:TextureAtlas = AssetInterface.getTextureAtlas("Game", "PipeJamLevelSelectSpriteSheetPNG", "PipeJamLevelSelectSpriteSheetXML");
			var background:Texture = atlas.getTexture("MapMaximized");
			backgroundImage = new Image(background);
			addChild(backgroundImage);
			
			this.addEventListener(starling.events.Event.ADDED_TO_STAGE, addedToStage);
			this.addEventListener(starling.events.Event.REMOVED_FROM_STAGE, removedFromStage);
			conflictList = new Vector.<ErrorPair>;
			
			gameNodeLayer = new Sprite();
			addChild(gameNodeLayer);
			errorLayer = new Sprite();
			addChild(errorLayer);
			viewRectLayer = new Sprite();
			addChild(viewRectLayer);
			
			isDirty = true;
		}
		
		public function addedToStage(event:starling.events.Event):void
		{				
			addEventListener(TouchEvent.TOUCH, onTouch);
			addEventListener(EnterFrameEvent.ENTER_FRAME, onEnterFrame);
		}
		
		private function onEnterFrame(event:EnterFrameEvent):void
		{
			if (isDirty) draw();
		}
		
		public function removedFromStage(event:starling.events.Event):void
		{
			if (gameNodeLayer) gameNodeLayer.removeChildren(0, -1, true);
			if (errorLayer) errorLayer.removeChildren(0, -1, true);
			if (viewRectLayer) viewRectLayer.removeChildren(0, -1, true);
			ErrorParticleSystem.errorList = new Dictionary;
			removeEventListener(TouchEvent.TOUCH, onTouch);
			removeEventListener(EnterFrameEvent.ENTER_FRAME, onEnterFrame);
		}
		
		override protected function onTouch(event:TouchEvent):void
		{
			var touches:Vector.<Touch> = event.touches;
			if(event.getTouches(this, TouchPhase.ENDED).length)
			{
				var currentPoint:Point = touches[0].getLocation(this);
				//factor in scale
				currentPoint.x *= scaleX;
				currentPoint.y *= scaleY;
				// adjust for borders
				currentPoint.x -= LEFT_BUFFER_PCT * WIDTH;
				currentPoint.y -= 0*BOTTOM_BUFFER_PCT * HEIGHT;
				//switch point to percentages
				currentPoint.x /= (1.0 - LEFT_BUFFER_PCT) * WIDTH;
				currentPoint.y /= (1.0 - BOTTOM_BUFFER_PCT) * HEIGHT;
				// clamp to 0->1
				currentPoint.x = XMath.clamp(currentPoint.x, 0.0, 1.0);
				currentPoint.y = XMath.clamp(currentPoint.y, 0.0, 1.0);
				trace("currentPoint:" + currentPoint);
				dispatchEvent(new MoveEvent(MoveEvent.MOVE_TO_POINT, null, currentPoint, null));
			}
		}
		
		public function onViewspaceChanged(event:MiniMapEvent):void
		{
			m_contentX = event.contentX;
			m_contentY = event.contentY;
			m_contentScale = event.contentScale;
			currentLevel = event.level;
			
			drawViewSpaceIndicator();
		}
		
		
		private function draw():void
		{
			if (gameNodeLayer) gameNodeLayer.removeChildren(0, -1, true);
			if (errorLayer) errorLayer.removeChildren(0, -1, true);
			for (var errorId:String in ErrorParticleSystem.errorList)
			{
				var error:ErrorParticleSystem = ErrorParticleSystem.errorList[errorId];
				if(error != null && error.parent != null)
					errorAdded(error);
			}
			drawViewSpaceIndicator();
			isDirty = false;
		}
		
		private function drawViewSpaceIndicator():void
		{
			if (m_viewSpaceIndicator == null) {
				m_viewSpaceIndicator = new Sprite();
				
				var q1:Quad = new Quad(80, 80, 0xFFFF00);
				q1.alpha = 0.5;
				m_viewSpaceIndicator.addChild(q1);
				
				viewRectLayer.addChild(m_viewSpaceIndicator);
			}
			m_viewSpaceIndicator.width = (1.0 - LEFT_BUFFER_PCT) * (WIDTH / scaleX) * (GridViewPanel.WIDTH / m_contentScale) / visibleBB.width;
			m_viewSpaceIndicator.height = (1.0 - BOTTOM_BUFFER_PCT) * (HEIGHT / scaleY) * ((GridViewPanel.HEIGHT /*- GameControlPanel.OVERLAP*/) / m_contentScale) / visibleBB.height;
			
			var viewTopLeftInLevelSpace:Point = new Point(-m_contentX / m_contentScale, -m_contentY / m_contentScale);
			var viewTopLeftInMapSpace:Point = level2map(viewTopLeftInLevelSpace);
			m_viewSpaceIndicator.x = viewTopLeftInMapSpace.x;
			m_viewSpaceIndicator.y = viewTopLeftInMapSpace.y;
		}
		
		private function get visibleBB():Rectangle
		{
			var levelBB:Rectangle = currentLevel ? currentLevel.m_boundingBox.clone() : new Rectangle();
			levelBB.inflate(0.5 * GridViewPanel.WIDTH / GridViewPanel.MIN_SCALE, 0.5 * GridViewPanel.HEIGHT / GridViewPanel.MIN_SCALE);
			return levelBB;
		}
		
		public function errorAdded(errorParticle:ErrorParticleSystem):void
		{
			if (!errorLayer) return;
			if (!currentLevel) return;
			
			var errImage:Image = new Image(ErrorParticleSystem.errorTexture);
			errImage.width = errImage.height = 30;
			errImage.alpha = 0.4;
			errImage.color = 0xFF0000;
			var errorPair:ErrorPair = new ErrorPair(errImage, errorParticle);
			conflictList.push(errorPair);
			if (!errorParticle.parent) return;
			
			var errPt:Point = level2map(currentLevel.globalToLocal(errorParticle.localToGlobal(new Point())));
			
			errorPair.image.x = errPt.x - 0.5 * errorPair.image.width;
			errorPair.image.y = errPt.y - 0.5 * errorPair.image.height; 
			
			errorLayer.addChild(errorPair.image);
			errorLayer.flatten();
		}
		
		private function level2pct(pt:Point):Point
		{
			var pct:Point = new Point((pt.x - visibleBB.x) / visibleBB.width,
			                          (pt.y - visibleBB.y) / visibleBB.height);
			trace("level pct:" + pct);
			//pct.x = XMath.clamp(pct.x, 0.0, 1.0);
			//pct.y = XMath.clamp(pct.y, 0.0, 1.0);
			return pct;
		}
		
		private function map2pct(pt:Point):Point
		{
			var pct:Point = new Point((pt.x - LEFT_BUFFER_PCT * WIDTH / scaleX) / ((1.0 - LEFT_BUFFER_PCT) * WIDTH / scaleX),
			                          (pt.y - 0*BOTTOM_BUFFER_PCT * HEIGHT / scaleY) / ((1.0 - BOTTOM_BUFFER_PCT) * HEIGHT / scaleY));
			trace("map pct:" + pct);
			//pct.x = XMath.clamp(pct.x, 0.0, 1.0);
			//pct.y = XMath.clamp(pct.y, 0.0, 1.0);
			return pct;
		}
		
		private function pct2level(pct:Point):Point
		{
			var pt:Point = new Point(visibleBB.width * pct.x + visibleBB.x,
			                         visibleBB.height * pct.y + visibleBB.y);
			trace("level pt:" + pt);
			return pt;
		}
		
		private function pct2map(pct:Point):Point
		{
			var pt:Point = new Point(pct.x * ((1.0 - LEFT_BUFFER_PCT) * WIDTH / scaleX) + LEFT_BUFFER_PCT * WIDTH / scaleX,
			                         pct.y * ((1.0 - BOTTOM_BUFFER_PCT) * HEIGHT / scaleY) + 0*BOTTOM_BUFFER_PCT * HEIGHT / scaleY);
			trace("map pt:" + pt);
			return pt;
		}
		
		private function level2map(pt:Point):Point
		{
			var pct:Point = level2pct(pt);
			return pct2map(pct);
		}
		
		public function errorRemoved(errorParticle:ErrorParticleSystem):void
		{
			for (var i:int = 0; i<conflictList.length; i++)
			{
				var errorPair:ErrorPair = conflictList[i];
				if(errorPair.particle.id == errorParticle.id)
				{
					errorPair.image.removeFromParent();
					conflictList.splice(i,1);
				}
			}
		}
		
	}
}


import particle.ErrorParticleSystem;
import starling.display.Image;
internal class ErrorPair
{
	public var image:Image;
	public var particle:ErrorParticleSystem;
	
	public function ErrorPair(_image:Image, _particle:ErrorParticleSystem)
	{
		image = _image;
		particle = _particle;
	}
}