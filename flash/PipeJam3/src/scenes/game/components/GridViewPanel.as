package scenes.game.components
{
	import assets.AssetInterface;
	import assets.AssetsFont;
	
	import display.NineSliceButton;
	import display.ShimmeringText;
	
	import events.MouseWheelEvent;
	import events.MoveEvent;
	import events.NavigationEvent;
	import events.UndoEvent;
	
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.text.TextFormat;
	import flash.ui.Keyboard;
	
	import scenes.BaseComponent;
	import scenes.game.PipeJamGameScene;
	import scenes.game.display.GameComponent;
	import scenes.game.display.GameNode;
	import scenes.game.display.Level;
	import scenes.game.display.World;
	
	import starling.animation.Transitions;
	import starling.core.Starling;
	import starling.display.BlendMode;
	import starling.display.Image;
	import starling.display.Quad;
	import starling.events.Event;
	import starling.events.KeyboardEvent;
	import starling.events.Touch;
	import starling.events.TouchEvent;
	import starling.events.TouchPhase;
	import starling.textures.Texture;
	import starling.textures.TextureAtlas;
	
	import utils.XMath;
	
	//GamePanel is the main game play area, with a central sprite and right and bottom scrollbars. 
	public class GridViewPanel extends BaseComponent
	{
		public static const WIDTH:Number = Constants.GameWidth;
		public static const HEIGHT:Number = 262;
		
		protected var m_currentLevel:Level;
		protected var content:BaseComponent;
		protected var currentMode:int;
		protected var nextLevelButton:NineSliceButton;
		protected var m_levelTextFields:Vector.<ShimmeringText> = new Vector.<ShimmeringText>();
		protected var m_backgroundImage:Image;
		protected var m_border:Image;
		
		protected static const NORMAL_MODE:int = 0;
		protected static const MOVING_MODE:int = 1;
		protected static const SELECTING_MODE:int = 2;
		private static const MIN_SCALE:Number = 10.0 / Constants.GAME_SCALE;
		private static const MAX_SCALE:Number = 50.0 / Constants.GAME_SCALE;
		private static const STARTING_SCALE:Number = 24.0 / Constants.GAME_SCALE;
		
		public function GridViewPanel()
		{
			currentMode = NORMAL_MODE;
			
			var background:Texture = AssetInterface.getTexture("Game", "StationaryBackgroundClass");
			m_backgroundImage = new Image(background);
			m_backgroundImage.width = Constants.GameWidth;
			m_backgroundImage.height = Constants.GameHeight;
			m_backgroundImage.blendMode = BlendMode.NONE;
			addChild(m_backgroundImage);
			
			content = new BaseComponent();
			addChild(content);
			
			var borderTexture:Texture = AssetInterface.getTexture("Game", "BorderVignetteClass");
			m_border = new Image(borderTexture);
			m_border.width = WIDTH;
			m_border.height = HEIGHT;
			m_border.touchable = false;
			addChild(m_border);
			
			addEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
			addEventListener(Event.REMOVED_FROM_STAGE, onRemovedFromStage);
		}
		
		private function onAddedToStage():void
		{
			//create a clip rect for the window
			clipRect = new Rectangle(x, y, width, height);
			
			removeEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
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
					//did we really move?
					if(content.x != startingPoint.x || content.y != startingPoint.y)
					{
						var startPoint:Point = startingPoint.clone();
						var endPoint:Point = new Point(content.x, content.y);
						var eventToUndo:Event = new MoveEvent(MoveEvent.MOUSE_DRAG, null, startPoint, endPoint);
						var eventToDispatch:UndoEvent = new UndoEvent(eventToUndo, this);
						eventToDispatch.addToSimilar = true;
						dispatchEvent(eventToDispatch);
					}
				}
				if(currentMode != NORMAL_MODE)
					currentMode = NORMAL_MODE;
				else
				{
					if(this.m_currentLevel && event.target == m_backgroundImage)
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
						if(touches[0].target == m_backgroundImage)
						{
							var delta:Point = touches[0].getMovement(parent);
							var cp:Point = touches[0].getLocation(this.content);
							var viewRect:Rectangle = getViewInContentSpace();
							var newX:Number = viewRect.x + viewRect.width / 2 - delta.x / content.scaleX;
							var newY:Number = viewRect.y + viewRect.height / 2 - delta.y / content.scaleY;
							moveContent(newX, newY);
							m_currentLevel.updateVisibleList();
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
						m_currentLevel.updateVisibleList();
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
			
			m_currentLevel.updateVisibleList();
			
		}
		
		private function handleMouseWheel(delta:Number, localMouse:Point = null, createUndoEvent:Boolean = true):void
		{
			if (localMouse == null) {
				localMouse = new Point(WIDTH / 2, HEIGHT / 2);
			} else {
				var mousePoint:Point = localMouse.clone();
				
				const native2Starling:Point = new Point(Starling.current.stage.stageWidth / Starling.current.nativeStage.stageWidth, 
						Starling.current.stage.stageHeight / Starling.current.nativeStage.stageHeight);
				
				localMouse.x *= native2Starling.x;
				localMouse.y *= native2Starling.y;
			}
			
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
				var eventToUndo:MouseWheelEvent = new MouseWheelEvent(mousePoint, delta, new Date().time);
				var eventToDispatch:UndoEvent = new UndoEvent(eventToUndo, this);
				eventToDispatch.addToSimilar = true;
				dispatchEvent(eventToDispatch);
			}
		}
		
		private function moveContent(newX:Number, newY:Number):void
		{
			newX = XMath.clamp(newX, m_currentLevel.m_boundingBox.x, m_currentLevel.m_boundingBox.x + m_currentLevel.m_boundingBox.width);
			newY = XMath.clamp(newY,m_currentLevel.m_boundingBox.y, m_currentLevel.m_boundingBox.y + m_currentLevel.m_boundingBox.height);
			
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
		
		//returns a point containing the content scale factors
		public function getContentScale():Point
		{
			return new Point(content.scaleX, content.scaleY);
		}
		
		private function getViewInContentSpace():Rectangle
		{
			return new Rectangle(-content.x / content.scaleX, -content.y / content.scaleY, clipRect.width / content.scaleX, clipRect.height / content.scaleY);
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
				case Keyboard.EQUAL:
					handleMouseWheel(5);
					m_currentLevel.updateVisibleList();
					break;
				case Keyboard.MINUS:
					handleMouseWheel(-5);
					m_currentLevel.updateVisibleList();
					break;
			}
		}
		
		public function loadLevel(level:Level):void
		{
			hideNextButton();
			if(m_currentLevel != level)
			{
				if(m_currentLevel)
				{
					m_currentLevel.removeEventListener(TouchEvent.TOUCH, onTouch);
					content.removeChild(m_currentLevel);
				}
				m_currentLevel = level;
				m_currentLevel.addEventListener(TouchEvent.TOUCH, onTouch);
			}
			content.x = 0;
			content.y = 0;
			
			content.scaleX = content.scaleY = STARTING_SCALE;
			content.addChild(m_currentLevel);
			var i:int;
			if ((m_currentLevel.m_boundingBox.width < 2 * WIDTH) && (m_currentLevel.m_boundingBox.height < 2 * HEIGHT)) {
				// If about the size of the window, just center the level
				var centerPt:Point = new Point(m_currentLevel.m_boundingBox.right / 2, m_currentLevel.m_boundingBox.bottom / 2);
				var globPt:Point = m_currentLevel.localToGlobal(centerPt);
				var localPt:Point = content.globalToLocal(globPt);
				panTo(localPt.x, localPt.y);
			} else {
				// Otherwise center on the first visible box
				var nodes:Vector.<GameNode> = level.getNodes();
				if (nodes.length > 0) {
					var foundNode:GameNode = nodes[0];
					for (i = 0; i < nodes.length; i++) {
						if (nodes[i].visible && (nodes[i].alpha > 0) && nodes[i].parent) {
							foundNode = nodes[i];
							break;
						}
					}
					centerOnComponent(foundNode);
				}
			}
			
			for (i = 0; i < m_levelTextFields.length; i++) {
				Starling.juggler.removeTweens(m_levelTextFields[i]);
				m_levelTextFields[i].removeFromParent(true);
			}
			m_levelTextFields = new Vector.<ShimmeringText>();
			var levelText:String = m_currentLevel.getLevelText();
			if (levelText) {
				var textLines:Array = levelText.split("\n\n");
				var totalTime:Number = 0.0;
				var lineHeight:Number = HEIGHT / Math.max(10, textLines.length * 1.5);
				const SEC_PER_CHAR:Number = 0.1; // seconds per character to calculate reading time
				for (i = 0; i < textLines.length; i++) {
					var levelTextLine:String = textLines[i] as String;
					var lineDispTime:Number = levelTextLine.length * SEC_PER_CHAR;
					var shimmerLine:ShimmeringText = new ShimmeringText(levelTextLine, AssetsFont.FONT_DEFAULT, WIDTH, lineHeight, lineHeight, 0xEEEE00);
					shimmerLine.y = i * 1.5 * lineHeight + HEIGHT / 2 - textLines.length * 1.5 * lineHeight / 2;
					shimmerLine.touchable = false;
					shimmerLine.visible = false;
					m_levelTextFields.push(shimmerLine);
					addChild(shimmerLine);
					Starling.juggler.delayCall(shimmerLine.showLineShimmer, totalTime, lineDispTime / 3, lineDispTime / 3, (levelText.length - 2 * textLines.length) * SEC_PER_CHAR - totalTime, 1.0);
					totalTime += lineDispTime;
				}
			}
		}
		
		public function displayNextButton():void
		{
			if (!nextLevelButton) {
				nextLevelButton = ButtonFactory.getInstance().createDefaultButton("Next Level", 128, 42);
				nextLevelButton.addEventListener(Event.TRIGGERED, onNextLevelButtonTriggered);
				nextLevelButton.x = WIDTH - nextLevelButton.width - 5;
				nextLevelButton.y = HEIGHT - nextLevelButton.height - 5;
			}
			addChild(nextLevelButton);
			
			//assume we are in the tutorial, and we just finished a level
			PipeJamGameScene.solvedTutorialLevel(m_currentLevel.m_tutorialTag);
		}
		
		public function hideNextButton():void
		{
			if (nextLevelButton) {
				nextLevelButton.removeFromParent();
			}
		}
		
		private function onNextLevelButtonTriggered(evt:Event):void
		{
			dispatchEvent(new NavigationEvent(NavigationEvent.SWITCH_TO_NEXT_LEVEL));
		}
		
		public function displayTextMetadata(textParent:XML):void
		{
		
		}
		
		public function moveToPoint(percentPoint:Point):void
		{
			moveContent(percentPoint.x* m_currentLevel.m_boundingBox.width/scaleX, percentPoint.y * m_currentLevel.m_boundingBox.height/scaleY);
		}
		
		/**
		 * Pans the current view to the given point (point is in content-space)
		 * @param	panX
		 * @param	panY
		 */
		public function panTo(panX:Number, panY:Number, createUndoEvent:Boolean = true):void
		{
			var startPoint:Point = new Point(content.x, content.y);
			content.x = ( -panX * content.scaleX + clipRect.width / 2) ;
			content.y = ( -panY * content.scaleY + clipRect.height / 2) ;
		}
		
		/**
		 * Centers the current view on the input component
		 * @param	component
		 */
		private var m_spotlight:Image;
		public function centerOnComponent(component:GameComponent, highlightWithSpotlight:Boolean = false):void
		{
			startingPoint = new Point(content.x, content.y);
			
			var centerPt:Point = new Point(component.width / 2, component.height / 2);
			var globPt:Point = component.localToGlobal(centerPt);
			var localPt:Point = content.globalToLocal(globPt);
			panTo(localPt.x, localPt.y);
			
			if (highlightWithSpotlight) {
				if (!m_spotlight) {
					var spotlightTexture:Texture = AssetInterface.getTexture("Game", "SpotlightClass");
					m_spotlight = new Image(spotlightTexture);
					m_spotlight.touchable = false;
					m_spotlight.alpha = 0.5;
				}
				const MIN_SPOTLIGHT_ASPECT:Number = 1.5;
				const SPOTLIGHT_TO_COMPONENT_RATIO:Number = 1.75;
				if (component.width > MIN_SPOTLIGHT_ASPECT * component.height) {
					// Reached out min aspect, use scaled up dimensions
					m_spotlight.width = component.width * SPOTLIGHT_TO_COMPONENT_RATIO;
					m_spotlight.height = component.height * SPOTLIGHT_TO_COMPONENT_RATIO;
				} else {
					// need to expand width to match min aspect
					m_spotlight.width = component.height * MIN_SPOTLIGHT_ASPECT * SPOTLIGHT_TO_COMPONENT_RATIO;
					m_spotlight.height = component.height * SPOTLIGHT_TO_COMPONENT_RATIO;
				}
				m_spotlight.x = content.x;
				m_spotlight.y = content.y;
				content.addChild(m_spotlight);
				var destX:Number = localPt.x - m_spotlight.width / 2;
				var destY:Number = localPt.y - m_spotlight.height / 2;
				Starling.juggler.removeTweens(m_spotlight);
				Starling.juggler.tween(m_spotlight, 2.0, { delay: 0.20, x:destX, transition: Transitions.EASE_OUT_ELASTIC } );
				Starling.juggler.tween(m_spotlight, 1.8, { delay: 0.40, y:destY, transition: Transitions.EASE_OUT_ELASTIC } );
			}
			
			var startPoint:Point = startingPoint.clone();
			var endPoint:Point = new Point(content.x, content.y);
			var eventToUndo:MoveEvent = new MoveEvent(MoveEvent.MOUSE_DRAG, null, startPoint, endPoint);
			var eventToDispatch:UndoEvent = new UndoEvent(eventToUndo, this);
			dispatchEvent(eventToDispatch);
		}
		
		public override function handleUndoEvent(undoEvent:Event, isUndo:Boolean = true):void
		{
			if(undoEvent is MouseWheelEvent)
			{
				var wheelEvt:MouseWheelEvent = undoEvent as MouseWheelEvent;
				var delta:Number = wheelEvt.delta;
				var localMouse:Point = wheelEvt.mousePoint;
				if(isUndo)
					handleMouseWheel(-delta, localMouse, false);
				else
					handleMouseWheel(delta, localMouse, false);
			}
			else if ((undoEvent is MoveEvent) && (undoEvent.type == MoveEvent.MOUSE_DRAG))
			{
				var moveEvt:MoveEvent = undoEvent as MoveEvent;
				var startPoint:Point = moveEvt.startLoc;
				var endPoint:Point = moveEvt.endLoc;
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