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
	import utils.XMath;
	
	public class MiniMap extends BaseComponent
	{
		private static const BORDER_PCT:Number = 0.05; // allows empty border around map edges
		
		protected var conflictList:Vector.<ErrorPair>;
		protected var currentLevel:Level;

		protected var backgroundImage:Image;
		protected var gameNodeLayer:Sprite;
		protected var errorLayer:Sprite;
		
		private var m_contentX:Number;
		private var m_contentY:Number;
		private var m_contentScale:Number;
		public var isDirty:Boolean;
		
		public function MiniMap()
		{
			var background:Texture = AssetInterface.getTexture("Game", "ConflictMapBackgroundImageClass");
			backgroundImage = new Image(background);
			addChild(backgroundImage);
			
			this.addEventListener(starling.events.Event.ADDED_TO_STAGE, addedToStage);
			this.addEventListener(starling.events.Event.REMOVED_FROM_STAGE, removedFromStage);
			conflictList = new Vector.<ErrorPair>;
			
			gameNodeLayer = new Sprite();
			addChild(gameNodeLayer);
			errorLayer = new Sprite();
			addChild(errorLayer);
			
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
				currentPoint.x -= BORDER_PCT * width;
				currentPoint.y -= BORDER_PCT * height;
				//switch point to percentages
				currentPoint.x /= (1.0 - 2.0 * BORDER_PCT) * width;
				currentPoint.y /= (1.0 - 2.0 * BORDER_PCT) * height;
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
			
			isDirty = true;
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
			isDirty = false;
		}
		
		public function errorAdded(errorParticle:ErrorParticleSystem):void
		{
			if (!errorLayer) return;
			if (!currentLevel) return;
			if (isNaN(m_contentX)) return;
			if (isNaN(m_contentY)) return;
			if (isNaN(m_contentScale)) return;
			
			// TODO: make an internal class and new instance here containing particle, quad
			var errImage:Image = new Image(ErrorParticleSystem.errorTexture);
			errImage.width = errImage.height = 30;
			errImage.alpha = 0.4;
			errImage.color = 0xFF0000;
			var errorPair:ErrorPair = new ErrorPair(errImage, errorParticle);
			conflictList.push(errorPair);
			if (!errorParticle.parent) return;
			
			//find percent location in level panel, then set error quad to that percent in conflict map
			var errorPt:Point = errorParticle.parent.localToGlobal(new Point(errorParticle.x, errorParticle.y));
			
			var levelPoint:Point = currentLevel.globalToLocal(errorPt);
			var boundingBoxMin:Point = currentLevel.localToGlobal(currentLevel.m_boundingBox.topLeft);
			var boundingBoxMax:Point = currentLevel.localToGlobal(currentLevel.m_boundingBox.bottomRight);
			
			var percentX:Number = (levelPoint.x - currentLevel.x) * m_contentScale / (boundingBoxMax.x - boundingBoxMin.x);
			var percentY:Number = (levelPoint.y - currentLevel.y) * m_contentScale / (boundingBoxMax.y - boundingBoxMin.y);
			
			var xVal:Number = XMath.clamp(percentX, 0.0, 1.0) * ((1.0 - 2.0 * BORDER_PCT) * width / scaleX) + BORDER_PCT * width / scaleX;
			var yVal:Number = XMath.clamp(percentY, 0.0, 1.0) * ((1.0 - 2.0 * BORDER_PCT) * height / scaleY) + BORDER_PCT * height / scaleY;
			
			errorPair.image.x = xVal - 0.5 * errorPair.image.width;
			errorPair.image.y = yVal - 0.5 * errorPair.image.height; 
			
			errorLayer.addChild(errorPair.image);
			errorLayer.flatten();
		}
		
		public function errorRemoved(errorParticle:ErrorParticleSystem):void
		{
			for (var i:int = 0; i<conflictList.length; i++)
			{
				var errorPair:ErrorPair = conflictList[i];
				if(errorPair.particle.id == errorParticle.id)
				{
					removeChild(errorPair.image);
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