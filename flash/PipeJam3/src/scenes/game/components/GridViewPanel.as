package scenes.game.components
{
//	import Events.CGSServerLocal;
//	
//	import System.VerigameServerConstants;
//	
//	import Utilities.Fonts;
//	
//	import VisualWorld.Board;
//	import VisualWorld.VerigameSystem;
//	import VisualWorld.World;
//	
//	import cgs.server.logging.actions.ClientAction;
	
	
	import assets.AssetInterface;
	
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.ui.Keyboard;
	
	import scenes.BaseComponent;
	import scenes.game.display.GameNode;
	import scenes.game.display.Level;
	
	import starling.display.Image;
	import starling.display.Quad;
	import starling.display.Sprite;
	import starling.events.Event;
	import starling.events.KeyboardEvent;
	import starling.events.Touch;
	import starling.events.TouchEvent;
	import starling.events.TouchPhase;
	import starling.textures.Texture;
	
	//GamePanel is the main game play area, with a central sprite and right and bottom scrollbars. 
	public class GridViewPanel extends BaseComponent
	{
		protected var m_currentLevel:Level;
		
		public var m_gameSurface:Sprite;
		protected var m_gameSurfaceBorder:uint = 25;
		
		protected var nextButtonBottomOffset:int;
		protected var backButtonBottomOffset:int;
		protected var buttomBottomBorder:int = 60;

		protected var content:BaseComponent;
		
		protected var m_currentTouchObject:GameNode;
		
		protected var quad:Quad;
		protected var minScaleX:Number;
		protected var minScaleY:Number;
		
		protected var currentMode:int;
		protected var NORMAL_MODE:int = 0;
		protected var MOVING_MODE:int = 1;
		protected var SELECTING_MODE:int = 2;
		
		public function GridViewPanel()
		{
			addEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
			addEventListener(Event.REMOVED_FROM_STAGE, onRemovedFromStage);			
		}
		
	
		private function onAddedToStage():void
		{
			currentMode = NORMAL_MODE;
			var background:Texture = AssetInterface.getTexture("Game", "BoxesGamePanelBackgroundImageClass");
			var backgroundImage:Image = new Image(background);
			backgroundImage.height = 320;
			addChild(backgroundImage);
			content = new BaseComponent;
			addChild(content);
			
			//create a clip rect for the window
			clipRect = new Rectangle(0, 0, width, height);
			
			quad = new Quad(10, 10, 0xff0000);
			minScaleX = minScaleY = 0.25;
			
			content.addEventListener(Event.ENTER_FRAME, onEnterFrame);
			addEventListener(TouchEvent.TOUCH, onTouch);
			stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
		}
		
		protected var startingPoint:Point;
		private function onTouch(event:TouchEvent):void
		{
			if(event.getTouches(this, TouchPhase.ENDED).length)
			{
				if(currentMode == SELECTING_MODE)
				{
					if(m_currentLevel)
					{
						m_currentLevel.handleMarquee(null, null);
					}
				}
				if(currentMode != NORMAL_MODE)
					currentMode = NORMAL_MODE;
				else
				{
					if(this.m_currentLevel && event.target is starling.display.Image)
						this.m_currentLevel.unselectAll();
				}
			}
			else if(event.getTouches(this, TouchPhase.MOVED).length)
			{
				var touches:Vector.<Touch> = event.getTouches(this, TouchPhase.MOVED);
				if(event.shiftKey)
				{
					if(currentMode != SELECTING_MODE)
					{
						currentMode = SELECTING_MODE;
						startingPoint = touches[0].getPreviousLocation(this);
					}
					if(m_currentLevel)
					{
						var currentPoint:Point = touches[0].getLocation(this);
						m_currentLevel.handleMarquee(startingPoint, currentPoint);
					}
				}
				else
				{
					currentMode = MOVING_MODE;
					if (touches.length == 1)
					{
						// one finger touching -> move
						if(touches[0].target is starling.display.Image || touches[0].target is starling.display.Image)
						{
							var delta:Point = touches[0].getMovement(parent);
							var newX:Number = content.x + delta.x;
							var newY:Number = content.y + delta.y;
	
							if(newX > clipRect.width*0.75)
								newX = clipRect.width*0.75;
							else if(newX < -.5*content.width)
								newX = -.5*content.width;
									
							if(newY > clipRect.height*0.75)
								newY = clipRect.height*0.75;
							else if(newY < -(content.height - .5*clipRect.height))
								newY = -(content.height - .5*clipRect.height);

							content.x = newX;
							content.y = newY;
						}
					}
					else if (touches.length == 2)
					{
						// two fingers touching -> rotate and scale
						var touchA:Touch = touches[0];
						var touchB:Touch = touches[1];
						
						var currentPosA:Point  = touchA.getLocation(parent);
						var previousPosA:Point = touchA.getPreviousLocation(parent);
						var currentPosB:Point  = touchB.getLocation(parent);
						var previousPosB:Point = touchB.getPreviousLocation(parent);
						
						var currentVector:Point  = currentPosA.subtract(currentPosB);
						var previousVector:Point = previousPosA.subtract(previousPosB);
						
						var currentAngle:Number  = Math.atan2(currentVector.y, currentVector.x);
						var previousAngle:Number = Math.atan2(previousVector.y, previousVector.x);
						var deltaAngle:Number = currentAngle - previousAngle;
						
						// update pivot point based on previous center
						var previousLocalA:Point  = touchA.getPreviousLocation(this);
						var previousLocalB:Point  = touchB.getPreviousLocation(this);
						pivotX = (previousLocalA.x + previousLocalB.x) * 0.5;
						pivotY = (previousLocalA.y + previousLocalB.y) * 0.5;
						
						// update location based on the current center
						x = (currentPosA.x + currentPosB.x) * 0.5;
						y = (currentPosA.y + currentPosB.y) * 0.5;
						
						// rotate
					//	rotation += deltaAngle;
						
						// scale
						var sizeDiff:Number = currentVector.length / previousVector.length;
	
						var newScaleX:Number = content.scaleX*sizeDiff;
						var newScaleY:Number = content.scaleY*sizeDiff;
						if(newScaleX > 2.5 &&  newScaleX > newScaleY)
						{
							newScaleX = 2.5;
							sizeDiff = newScaleX/content.scaleX;
							newScaleY = content.scaleY*sizeDiff;
						}
						else if(newScaleY > 2.5)
						{
							newScaleY = 2.5;
							sizeDiff = newScaleY/content.scaleY;
							newScaleX = content.scaleX*sizeDiff;
						}
						else if(newScaleX < minScaleX &&  newScaleX < newScaleY)
						{
							newScaleX = minScaleX;
							sizeDiff = newScaleX/content.scaleX;
							newScaleY = content.scaleY*sizeDiff;
						}
						else if(newScaleY < minScaleY)
						{
							newScaleY = minScaleY;
							sizeDiff = newScaleY/content.scaleY;
							newScaleX = content.scaleX*sizeDiff;
						}
						content.scaleX = newScaleX;
						content.scaleY = newScaleY;
						
	//					var currentCenterPt:Point = new Point((currentPosA.x+currentPosB.x)/2 +content.x, (currentPosA.y+currentPosB.y)/2+content.y);
	//					content.x = currentCenterPt.x - previousCenterPt.x;
	//					content.y = currentCenterPt.y - previousCenterPt.y;
					}
				}
			}
			
//			var touch:Touch = event.getTouch(this, TouchPhase.ENDED);
//			
//			if (touch && touch.tapCount == 2)
//				parent.addChild(this); // bring self to front
			
			// enable this code to see when you're hovering over the object
			// touch = event.getTouch(this, TouchPhase.HOVER);
			// alpha = touch ? 0.8 : 1.0;
		}

		
		private function onRemovedFromStage():void
		{
			removeEventListener(Event.ENTER_FRAME, onEnterFrame);
			content.removeEventListener(TouchEvent.TOUCH, onTouch);
			stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
		}
		
		private function onKeyDown(event:KeyboardEvent):void
		{
			switch(event.keyCode)
			{
				case Keyboard.UP:
					content.y +=  5;
					break;
				case Keyboard.DOWN:
					content.y -= 5;
					break;
				case Keyboard.LEFT:
					content.x += 5;
					break;
				case Keyboard.RIGHT:
					content.x -= 5;
					break;
			}
		}
		
		public function loadLevel(level:Level):void
		{
			if(m_currentLevel == level)
				return;
			if(m_currentLevel)
			{
				m_currentLevel.removeEventListener(TouchEvent.TOUCH, onTouch);
				m_currentLevel.removeFromParent(true);
			}
			m_currentLevel = level;
			m_currentLevel.addEventListener(TouchEvent.TOUCH, onTouch);
			content.x = 0;
			content.y = 0;

			content.scaleX = content.scaleY = 1;
			content.addChild(m_currentLevel);

			//use larger value
			if(this.clipRect.height/content.height > this.clipRect.width/ content.width)
			{
				content.scaleX = content.scaleY = (this.clipRect.width)/content.width;
				if(content.scaleX > 3)
					content.scaleX = content.scaleY = 3; //just limit it from being really big
			}
			else
			{
				content.scaleX = content.scaleY = (this.clipRect.height)/content.height;
				if(content.scaleX > 3)
					content.scaleX = content.scaleY = 3; //just limit it from being really big
			}
			
			if(content.scaleX < minScaleX)
				minScaleX = content.scaleX;
			if(content.scaleY < minScaleY)
				minScaleY = content.scaleY;

		}
		
		protected var updateCount:uint = 0;
		private var nodePlacedCount:int = -50;
		public function onEnterFrame(event:Event):void
		{

		}
		
		public function displayTextMetadata(textParent:XML):void
		{
		
		}
		
		public function centerOnNode(component:GameNode):void
		{
			content.scaleX = content.scaleY = 1;

			content.x = -component.x + clipRect.width/2;
			content.y = -component.y + clipRect.height/2;
			
		}
	}
}