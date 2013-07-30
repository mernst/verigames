package scenes.game.components
{
	import assets.AssetInterface;
	import events.MoveEvent;
	import flash.geom.Point;
	import flash.utils.Dictionary;
	import particle.ErrorParticleSystem;
	import scenes.BaseComponent;
	import scenes.game.display.Level;
	import starling.display.Image;
	import starling.display.Quad;
	import starling.events.Event;
	import starling.events.Touch;
	import starling.events.TouchEvent;
	import starling.events.TouchPhase;
	import starling.textures.Texture;
	import utils.XMath;
	
	public class ConflictMap extends BaseComponent
	{
		
		protected var conflictList:Vector.<Object>;
		protected var currentLevel:Level;

		protected var backgroundImage:Image;
		
		public function ConflictMap()
		{
			var background:Texture = AssetInterface.getTexture("Game", "ConflictMapBackgroundImageClass");
			backgroundImage = new Image(background);
			addChild(backgroundImage);
			
			this.addEventListener(starling.events.Event.ADDED_TO_STAGE, addedToStage);
			this.addEventListener(starling.events.Event.REMOVED_FROM_STAGE, removedFromStage);
			conflictList = new Vector.<Object>;
		}
		
		public function addedToStage(event:starling.events.Event):void
		{				
			addEventListener(TouchEvent.TOUCH, onTouch);
		}
		
		public function removedFromStage(event:starling.events.Event):void
		{
			removeChildren();
			ErrorParticleSystem.errorList = new Dictionary;
		}
		
		private function onTouch(event:TouchEvent):void
		{
			var touches:Vector.<Touch> = event.touches;
			//trace(m_id);
			if(event.getTouches(this, TouchPhase.ENDED).length)
			{
				var currentPoint:Point = touches[0].getLocation(this);
				//factor in scale
				currentPoint.x *= scaleX;
				currentPoint.y *= scaleY;
				//switch point to percentages
				currentPoint.x /= width;
				currentPoint.y /= height;
				dispatchEvent(new MoveEvent(MoveEvent.MOVE_TO_POINT, null, currentPoint, null));
			}
		}
		
		public function updateLevel(level:Level):void
		{
			currentLevel = level;
			removeChildren(1);
			var list:Dictionary = ErrorParticleSystem.errorList;
			//if we are just switching between levels (not changing worlds, we need to clear out old errors
			//TO FIX this isn't right. We should do this at the level of actually switching levels
//			for each(var currentError:ErrorParticleSystem in ErrorParticleSystem.errorList)
//			{
//				if(currentError != null)
//				{
//					ErrorParticleSystem.errorList = new Dictionary;
//					break;
//				}
//			}
			
			for each(var error:ErrorParticleSystem in ErrorParticleSystem.errorList)
			{
				if(error != null && error.parent != null)
					errorAdded(error, level);
				
			}
		}
		
		public function errorAdded(errorParticle:ErrorParticleSystem, level:Level):void
		{
			// TODO: make an internal class and new instance here containing particle, quad
			var errorObj:Object = new Object;
			errorObj.particle = errorParticle;
			errorObj.quad = new Quad(3, 3, 0xff0000);
			conflictList.push(errorObj);
			
			//find percent location in level panel, then set error quad to that percent in conflict map
			var errorPt:Point = errorParticle.parent.localToGlobal(new Point(errorParticle.x, errorParticle.y));
			
			var levelPoint:Point = level.globalToLocal(errorPt);
			var boundingBoxMin:Point = level.localToGlobal(new Point(level.m_boundingBox.x, level.m_boundingBox.y));
			var boundingBoxMax:Point = level.localToGlobal(new Point(level.m_boundingBox.width,level.m_boundingBox.height));
			
			var gvp:GridViewPanel = level.parent.parent as GridViewPanel;
			var contentScale:Point = gvp.getContentScale();
			
			var percentX:Number = (levelPoint.x-level.x)*contentScale.x/(boundingBoxMax.x - boundingBoxMin.x);
			var percentY:Number = (levelPoint.y-level.y)*contentScale.y/(boundingBoxMax.y - boundingBoxMin.y);
			
			var xVal:Number = XMath.clamp(percentX*(width/scaleX),0, width/scaleX);
			var yVal:Number = XMath.clamp(percentY*(height/scaleY),0, height/scaleY);
			errorObj.quad.x	= xVal;
			errorObj.quad.y = yVal; 
			
			addChild(errorObj.quad);
		}
		
		public function errorRemoved(errorParticle:ErrorParticleSystem):void
		{
			for(var i:int = 0; i<conflictList.length; i++)
			{
				var errorObj:Object = conflictList[i];
				if(errorObj.particle.id == errorParticle.id)
				{
					removeChild(errorObj.quad);
					conflictList.splice(i,1);
				}
			}
		}
		
		public function errorMoved(errorParticle:ErrorParticleSystem):void
		{
			for(var i:int = 0; i<conflictList.length; i++)
			{
				var errorObj:Object = conflictList[i];
				if(errorObj.particle.id == errorParticle.id)
				{
					errorRemoved(errorParticle);
					errorAdded(errorParticle, currentLevel);
				}
			}
		}
	}
}