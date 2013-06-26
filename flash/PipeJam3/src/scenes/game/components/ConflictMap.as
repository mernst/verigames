package scenes.game.components
{
	import assets.AssetInterface;
	import assets.AssetsFont;
	
	import flash.geom.Point;
	import flash.utils.Dictionary;
	
	import particle.ErrorParticleSystem;
	
	import scenes.BaseComponent;
	import scenes.game.display.Level;
	
	import starling.display.DisplayObjectContainer;
	import starling.display.Image;
	import starling.display.Quad;
	import starling.display.Sprite;
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
				dispatchEvent(new Event(Level.MOVE_TO_POINT, true, currentPoint));
			}
		}
		
		public function updateLevel(level:Level):void
		{
			currentLevel = level;
			removeChildren(1);
			var list:Dictionary = ErrorParticleSystem.errorList;
			//if we are just switching between levels (not changing worlds, we need to clear out old errors
			for each(var currentError:ErrorParticleSystem in ErrorParticleSystem.errorList)
			{
				if(currentError != null)
				{
					ErrorParticleSystem.errorList = new Dictionary;
					break;
				}
			}
			
			for each(var error:ErrorParticleSystem in ErrorParticleSystem.errorList)
			{
				if(error != null)
					errorAdded(error, level);
				
			}
		}
		
		public function errorAdded(errorData:Object, level:Level):void
		{
			var errorObj:Object = new Object;
			errorObj.particle = errorData;
			errorObj.quad = new Quad(3, 3, 0xff0000);
			conflictList.push(errorObj);

			var errorParticle:ErrorParticleSystem = errorData as ErrorParticleSystem;
			
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
		
		public function errorRemoved(errorData:Object):void
		{
			for(var i:int = 0; i<conflictList.length; i++)
			{
				var errorObj:Object = conflictList[i];
				if(errorObj.particle.id == errorData.id)
				{
					removeChild(errorObj.quad);
					conflictList.splice(i,1);
				}
			}
		}
		
		public function errorMoved(errorData:Sprite):void
		{
			if(errorData.numChildren > 0)
			{
				var error:ErrorParticleSystem = errorData.getChildAt(0) as ErrorParticleSystem;
				for(var i:int = 0; i<conflictList.length; i++)
				{
					var errorObj:Object = conflictList[i];
					if(errorObj.particle.id == error.id)
					{
						errorRemoved(error);
						errorAdded(error, currentLevel);
					}
				}
			}
		}
	}
}