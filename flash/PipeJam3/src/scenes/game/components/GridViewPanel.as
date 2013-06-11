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
	
	import flash.display.NativeMenu;
	import flash.display.NativeMenuItem;
	import flash.events.ContextMenuEvent;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.ui.Keyboard;
	
	import scenes.BaseComponent;
	import scenes.game.display.GameComponent;
	import scenes.game.display.GameNode;
	import scenes.game.display.Level;
	import scenes.game.display.World;
	
	import starling.core.Starling;
	import starling.display.BlendMode;
	import starling.display.DisplayObjectContainer;
	import starling.display.Image;
	import starling.display.Quad;
	import starling.display.Sprite;
	import starling.events.Event;
	import starling.events.KeyboardEvent;
	import starling.events.Touch;
	import starling.events.TouchEvent;
	import starling.events.TouchPhase;
	import starling.textures.Texture;
	
	import utils.XMath;
	
	//GamePanel is the main game play area, with a central sprite and right and bottom scrollbars. 
	public class GridViewPanel extends BaseComponent
	{
		private static const WIDTH:Number = 384;
		private static const HEIGHT:Number = Constants.GameHeight;
		
		protected var m_currentLevel:Level;
		
		protected var content:BaseComponent;
		
		protected var quad:Quad;
		
		protected var currentMode:int;
		protected static const NORMAL_MODE:int = 0;
		protected static const MOVING_MODE:int = 1;
		protected static const SELECTING_MODE:int = 2;
		private static const MIN_SCALE:Number = 5.0 / Constants.GAME_SCALE;
		private static const MAX_SCALE:Number = 50.0 / Constants.GAME_SCALE;
		
		public static const MOUSE_WHEEL:String = "mouse_wheel";
		public static const MOUSE_DRAG:String = "mouse_drag";
		public static const CENTER:String = "center";
		
		public function GridViewPanel()
		{
			currentMode = NORMAL_MODE;
			var background:Texture = AssetInterface.getTexture("Game", "BoxesGamePanelBackgroundImageClass");
			var backgroundImage:Image = new Image(background);
			backgroundImage.width = WIDTH;
			backgroundImage.height = HEIGHT;
			backgroundImage.blendMode = BlendMode.NONE;
			addChild(backgroundImage);
			content = new BaseComponent;
			addChild(content);
			
			quad = new Quad(10, 10, 0xff0000);
			
			addEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
			addEventListener(Event.REMOVED_FROM_STAGE, onRemovedFromStage);
		}
		
		private function onAddedToStage():void
		{
			//create a clip rect for the window
			clipRect = new Rectangle(x, y, width, height);
			
			removeEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
			content.addEventListener(Event.ENTER_FRAME, onEnterFrame);
			addEventListener(TouchEvent.TOUCH, onTouch);
			stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
			Starling.current.nativeStage.addEventListener(MouseEvent.MOUSE_WHEEL, onMouseWheel);
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
				else if(currentMode == MOVING_MODE)
				{
					var undoData:Object = new Object();
					undoData.target = this;
					undoData.component = this;
					undoData.startPoint = startingPoint.clone();
					undoData.endPoint = new Point(content.x, content.y);
					var undoEvent:Event = new Event(MOUSE_DRAG,false,undoData);
					dispatchEvent(new Event(World.UNDO_EVENT, true, undoEvent));
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
						var globalStartingPt:Point = localToGlobal(startingPoint);
						var globalCurrentPt:Point = localToGlobal(currentPoint);
						m_currentLevel.handleMarquee(globalStartingPt, globalCurrentPt);
					}
				}
				else
				{
					if(currentMode != MOVING_MODE)
					{
						currentMode = MOVING_MODE;
						startingPoint = new Point(content.x, content.y);
					}
					if (touches.length == 1)
					{
						// one finger touching -> move
						if(touches[0].target is starling.display.Image || touches[0].target is starling.display.Image)
						{
							var delta:Point = touches[0].getMovement(parent);
							var viewRect:Rectangle = getViewInContentSpace();
							var newX:Number = viewRect.x + viewRect.width / 2 - delta.x / content.scaleX;
							var newY:Number = viewRect.y + viewRect.height / 2 - delta.y / content.scaleY;
							moveContent(newX, newY);
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
						
						scaleContent(sizeDiff);
						
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

		private function onMouseWheel(evt:MouseEvent):void
		{
			//scaleContent(1.0/content.scaleX);
			var delta:Number = evt.delta;
			
			var localMouse:Point = this.globalToLocal(new Point(evt.stageX, evt.stageY));
			
			handleMouseWheel(delta, localMouse);
			
		}
		
		private function handleMouseWheel(delta:Number, localMouse:Point, createUndoEvent:Boolean = true)
		{
			var mousePoint:Point = localMouse.clone();
			
			const native2Starling:Point = new Point(Starling.current.stage.stageWidth / Starling.current.nativeStage.stageWidth, 
					Starling.current.stage.stageHeight / Starling.current.nativeStage.stageHeight);
			
			localMouse.x *= native2Starling.x;
			localMouse.y *= native2Starling.y;
			
			// Now localSpace is in local coordinates (relative to this instance of GridViewPanel).
			// Next, we'll convert to content space
			var prevMouse:Point = new Point(localMouse.x - content.x, localMouse.y - content.y);
			prevMouse.x /= content.scaleX;
			prevMouse.y /= content.scaleY;
			
			// Now we have the mouse location in current content space.
			// We want this location to not move after scaling
			
			// Scale content
			scaleContent(1.00 + 2 * delta / 100.0);
			
			// Calculate new location of previous mouse
			var newMouse:Point = new Point(localMouse.x - content.x, localMouse.y - content.y);
			newMouse.x /= content.scaleX;
			newMouse.y /= content.scaleY;
			
			// Move by offset so that the point the mouse is centered on remains in same place
			// (scaling is performed relative to this location)
			var viewRect:Rectangle = getViewInContentSpace();
			var newX:Number = viewRect.x + viewRect.width / 2 + (prevMouse.x - newMouse.x);// / content.scaleX;
			var newY:Number = viewRect.y + viewRect.height / 2 + (prevMouse.y - newMouse.y);// / content.scaleY;
			moveContent(newX, newY);
			
			
			//turn this off if in an undo event
			if(createUndoEvent)
			{
				var endPoint:Point = new Point(content.x, content.y);
				var moveData:Object = new Object();
				moveData.target = this;
				moveData.mousePoint = mousePoint;
				moveData.delta = delta;
				moveData.time = new Date().time;
				var undoEvent:Event = new Event(MOUSE_WHEEL,false,moveData);
				dispatchEvent(new Event(World.UNDO_EVENT, true, undoEvent));
			}
		}
		
		private function moveContent(newX:Number, newY:Number):void
		{
			var moveBounds:Rectangle = content.getBounds(this);
			moveBounds.x -= content.x;
			moveBounds.y -= content.y;
			
			newX = XMath.clamp(newX, moveBounds.x / content.scaleX, (moveBounds.x + moveBounds.width) / content.scaleX);
			newY = XMath.clamp(newY, moveBounds.y / content.scaleY, (moveBounds.y + moveBounds.height) / content.scaleY);
			
			panTo(newX, newY);
		}
		
		/**
		 * Scale the content by the given scale factor (sizeDiff of 1.5 = 150% the original size)
		 * @param	sizeDiff Size difference factor, 1.5 = 150% of original size
		 */
		private function scaleContent(sizeDiff:Number):void
		{
			var oldScaleX:Number = content.scaleX;
			var oldScaleY:Number = content.scaleY;
			var newScaleX:Number = XMath.clamp(content.scaleX * sizeDiff, MIN_SCALE, MAX_SCALE);
			var newScaleY:Number = XMath.clamp(content.scaleY * sizeDiff, MIN_SCALE, MAX_SCALE);
			
			if(newScaleX > newScaleY)
			{
				sizeDiff = newScaleX/content.scaleX;
				newScaleY = content.scaleY*sizeDiff;
			} else {
				sizeDiff = newScaleX/content.scaleX;
				newScaleY = content.scaleY*sizeDiff;
			}
			
			var origViewCoords:Rectangle = getViewInContentSpace();
			// Perform scaling
			content.scaleX = newScaleX;
			content.scaleY = newScaleY;
			var newViewCoords:Rectangle = getViewInContentSpace();
			
			// Adjust so that original centered point is still in the middle
			var dX:Number = origViewCoords.x + origViewCoords.width / 2 - (newViewCoords.x + newViewCoords.width / 2);
			var dY:Number = origViewCoords.y + origViewCoords.height / 2 - (newViewCoords.y + newViewCoords.height / 2);
			
			content.x -= dX * content.scaleX;
			content.y -= dY * content.scaleY;
		}
		
		private function getViewInContentSpace():Rectangle
		{
			return new Rectangle(-content.x / content.scaleX, -content.y / content.scaleY, clipRect.width / content.scaleX, clipRect.height / content.scaleY);
		}
		
		private function makeQuad(qx:Number, qy:Number, color:Number = 0xFFFF00, size:Number = 5):void
		{
			var myQuad:Quad = new Quad(size, size, color);
			myQuad.x = qx;
			myQuad.y = qy;
			content.addChild(myQuad);
		}
		
		private function onRemovedFromStage():void
		{
			//
		}
		
		override public function dispose():void
		{
			if (m_disposed) {
				return;
			}
			if (Starling.current && Starling.current.nativeStage) {
				Starling.current.nativeStage.removeEventListener(MouseEvent.MOUSE_WHEEL, onMouseWheel);
			}
			removeEventListener(Event.ENTER_FRAME, onEnterFrame);
			if (content) {
				content.removeEventListener(TouchEvent.TOUCH, onTouch);
			}
			if (stage) {
				stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
			}
			super.dispose();
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
				content.removeChild(m_currentLevel);
			}
			m_currentLevel = level;
			m_currentLevel.addEventListener(TouchEvent.TOUCH, onTouch);
			content.x = 0;
			content.y = 0;

			content.scaleX = content.scaleY = 24.0 / Constants.GAME_SCALE;
			content.addChild(m_currentLevel);
			var nodes:Vector.<GameNode> = level.getNodes();
			if (nodes.length > 0) {
				centerOnComponent(nodes[0]);
			}
		}
		
		public function onEnterFrame(event:Event):void
		{
			
		}
		
		public function displayTextMetadata(textParent:XML):void
		{
		
		}
		
		/**
		 * Pans the current view to the given point (point is in content-space)
		 * @param	panX
		 * @param	panY
		 */
		public function panTo(panX:Number, panY:Number, createUndoEvent:Boolean = true):void
		{
			var startPoint:Point = new Point(content.x, content.y);
			content.x = (-panX* content.scaleX + clipRect.width/2) ;
			content.y = (-panY* content.scaleY + clipRect.height/2) ;
		}
		
		/**
		 * Centers the current view on the input component
		 * @param	component
		 */
		public function centerOnComponent(component:GameComponent):void
		{
			startingPoint = new Point(content.x, content.y);
			
			var centerPt:Point = new Point(component.width / 2, component.height / 2);
			var globPt:Point = component.localToGlobal(centerPt);
			var localPt:Point = content.globalToLocal(globPt);
			panTo(localPt.x, localPt.y);
			
			var undoData:Object = new Object();
			undoData.target = this;
			undoData.component = this;
			undoData.startPoint = startingPoint.clone();
			undoData.endPoint = new Point(content.x, content.y);
			var undoEvent:Event = new Event(MOUSE_DRAG,false,undoData);
			dispatchEvent(new Event(World.UNDO_EVENT, true, undoEvent));

		}
		
		public override function handleUndoEvent(undoEvent:Event, isUndo:Boolean = true):void
		{
			var undoData:Object = undoEvent.data;
			if(undoEvent.type == GridViewPanel.MOUSE_WHEEL)
			{
				var delta:Number = undoData.delta;
				var localMouse:Point = undoData.mousePoint;
				if(!isUndo)
					handleMouseWheel(delta, localMouse, false);
				else
					handleMouseWheel(-delta, localMouse, false);

			}
			else if(undoEvent.type == GridViewPanel.MOUSE_DRAG)
			{
				var startPoint:Point = undoData.startPoint;
				var endPoint:Point = undoData.endPoint;
				if(isUndo)
				{
					content.x = startPoint.x;
					content.y = startPoint.y;
				}
				else
				{
					content.x = endPoint.x;
					content.y = endPoint.y;
				}
				
			}
		}
	}
}