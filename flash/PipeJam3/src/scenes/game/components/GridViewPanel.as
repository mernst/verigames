package scenes.game.components
{
	import assets.AssetInterface;
	import assets.AssetsFont;
	import display.NineSliceButton;
	import display.ToolTipText;
	import events.MouseWheelEvent;
	import events.MoveEvent;
	import events.NavigationEvent;
	import events.PropertyModeChangeEvent;
	import events.TutorialEvent;
	import events.UndoEvent;
	import flash.display.BitmapData;
	import flash.events.MouseEvent;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.ui.Keyboard;
	import flash.utils.ByteArray;
	import graph.PropDictionary;
	import particle.FanfareParticleSystem;
	import scenes.BaseComponent;
	import scenes.game.display.GameComponent;
	import scenes.game.display.GameEdgeContainer;
	import scenes.game.display.GameNode;
	import scenes.game.display.Level;
	import scenes.game.display.OutlineFilter;
	import scenes.game.display.TutorialManagerTextInfo;
	import scenes.game.display.World;
	import scenes.game.PipeJamGameScene;
	import starling.animation.DelayedCall;
	import starling.animation.Transitions;
	import starling.core.RenderSupport;
	import starling.core.Starling;
	import starling.display.BlendMode;
	import starling.display.DisplayObject;
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
		public static const WIDTH:Number = Constants.GameWidth;
		public static const HEIGHT:Number = 262;
		
		private var m_currentLevel:Level;
		private var inactiveContent:Sprite;
		private var contentBarrier:Quad;
		private var content:BaseComponent;
		private var errorBubbleContainer:Sprite;
		private var currentMode:int;
		private var continueButton:NineSliceButton;
		private var m_backgroundLayer:Sprite = new Sprite();
		private var m_backgroundImage:Image;
		private var m_border:Image;
		private var m_tutorialText:TutorialText;
		private var m_persistentToolTips:Vector.<ToolTipText> = new Vector.<ToolTipText>();
		private var m_continueButtonForced:Boolean = false; //true to force the continue button to display, ignoring score
		private var m_spotlight:Image;
		private var m_errorTextBubbles:Vector.<Sprite> = new Vector.<Sprite>();
		
		private var m_world:World;

		
		protected static const NORMAL_MODE:int = 0;
		protected static const MOVING_MODE:int = 1;
		protected static const SELECTING_MODE:int = 2;
		protected static const RELEASE_SHIFT_MODE:int = 3;
		private static const MIN_SCALE:Number = 5.0 / Constants.GAME_SCALE;
		private static const MAX_SCALE:Number = 250.0 / Constants.GAME_SCALE;
		private static const STARTING_SCALE:Number = 22.0 / Constants.GAME_SCALE;
		// At scales less than this value (zoomed out), error text is hidden - but arrows remain
		private static const MIN_ERROR_TEXT_DISPLAY_SCALE:Number = 15.0 / Constants.GAME_SCALE;
		
		public function GridViewPanel(world:World)
		{
			m_world = world;
			currentMode = NORMAL_MODE;
			
			addChild(m_backgroundLayer);
			swapBackgroundImage();
			
			inactiveContent = new Sprite();
			addChild(inactiveContent);
			
			contentBarrier = new Quad(m_backgroundImage.width, m_backgroundImage.height, 0x0);
			contentBarrier.alpha = 0.8;
			contentBarrier.visible = false;
			addChild(contentBarrier);
			
			content = new BaseComponent();
			addChild(content);
			
			errorBubbleContainer = new Sprite();
			addChild(errorBubbleContainer);
			
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
			clipRect = new Rectangle(x, y, WIDTH, HEIGHT);
			
			removeEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
			addEventListener(TouchEvent.TOUCH, onTouch);
			addEventListener(PropertyModeChangeEvent.PROPERTY_MODE_CHANGE, onPropertyModeChange);
			stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
			stage.addEventListener(KeyboardEvent.KEY_UP, onKeyUp);
			Starling.current.nativeStage.addEventListener(MouseEvent.MOUSE_WHEEL, onMouseWheel);
		}
		
		private function onPropertyModeChange(evt:PropertyModeChangeEvent):void
		{
			if (evt.prop == PropDictionary.PROP_NARROW) {
				contentBarrier.visible = false;
			} else {
				contentBarrier.visible = true;
			}
		}
		
		private function endSelectMode():void
		{
			if(m_currentLevel)
			{
				m_currentLevel.handleMarquee(null, null);
			}
		}
		
		private function endMoveMode():void
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
		
		protected var startingPoint:Point;
		override protected function onTouch(event:TouchEvent):void
		{
			//trace("Mode:" + currentMode);
			if(event.getTouches(this, TouchPhase.ENDED).length)
			{
				if(currentMode == SELECTING_MODE)
				{
					endSelectMode();
				}
				else if(currentMode == MOVING_MODE)
				{
					endMoveMode();
				}
				if(currentMode != NORMAL_MODE)
					currentMode = NORMAL_MODE;
				else
				{
					if (m_currentLevel && ((event.target == m_backgroundImage) || (event.target == contentBarrier))) {
						m_currentLevel.unselectAll();
						var evt:PropertyModeChangeEvent = new PropertyModeChangeEvent(PropertyModeChangeEvent.PROPERTY_MODE_CHANGE, PropDictionary.PROP_NARROW);
						m_currentLevel.onPropertyModeChange(evt);
						onPropertyModeChange(evt);
					}
				}
			}
			else if(event.getTouches(this, TouchPhase.MOVED).length)
			{
				var touches:Vector.<Touch> = event.getTouches(this, TouchPhase.MOVED);
				if(event.shiftKey)
				{
					if(currentMode != SELECTING_MODE)
					{
						if (currentMode == MOVING_MODE) endMoveMode();
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
						if (currentMode == SELECTING_MODE) endSelectMode();
						currentMode = MOVING_MODE;
						startingPoint = new Point(content.x, content.y);
					}
					if (touches.length == 1)
					{
						// one finger touching -> move
						if ((touches[0].target == m_backgroundImage) || (touches[0].target == contentBarrier))
						{
							if (getPanZoomAllowed())
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
					}
					else if (touches.length == 2)
					{
						/*
						// TODO: Need to take a look at this if we reactivate multitouch - hasn't been touched in a while 
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
						*/
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
			if (!getPanZoomAllowed())
			{
				return;
			}
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
			newY = XMath.clamp(newY, m_currentLevel.m_boundingBox.y, m_currentLevel.m_boundingBox.y + m_currentLevel.m_boundingBox.height);
			
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
			inactiveContent.scaleX = content.scaleX;
			inactiveContent.scaleY = content.scaleY;
			onContentScaleChanged();
			
			var newViewCoords:Rectangle = getViewInContentSpace();
			
			// Adjust so that original centered point is still in the middle
			var dX:Number = origViewCoords.x + origViewCoords.width / 2 - (newViewCoords.x + newViewCoords.width / 2);
			var dY:Number = origViewCoords.y + origViewCoords.height / 2 - (newViewCoords.y + newViewCoords.height / 2);
			
			content.x -= dX * content.scaleX;
			content.y -= dY * content.scaleY;
			inactiveContent.x = content.x;
			inactiveContent.y = content.y;
			//trace("newscale:" + content.scaleX + "new xy:" + content.x + " " + content.y);
		}
		
		private function onContentScaleChanged():void
		{
			if (m_currentLevel == null) return;
 			if ((content.scaleX < MIN_ERROR_TEXT_DISPLAY_SCALE) || (content.scaleY < MIN_ERROR_TEXT_DISPLAY_SCALE)) {
				m_currentLevel.hideErrorText();
 			} else {
				m_currentLevel.showErrorText();
 			}
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
			if (m_backgroundImage) m_backgroundImage.removeFromParent(true);
			if (m_tutorialText) {
				m_tutorialText.removeFromParent(true);
				m_tutorialText = null;
			}
			for (var i:int = 0; i < m_persistentToolTips.length; i++) m_persistentToolTips[i].removeFromParent(true);
			m_persistentToolTips = new Vector.<ToolTipText>();
			if (Starling.current && Starling.current.nativeStage) {
				Starling.current.nativeStage.removeEventListener(MouseEvent.MOUSE_WHEEL, onMouseWheel);
			}
			content.removeEventListener(TouchEvent.TOUCH, onTouch);
			removeEventListener(PropertyModeChangeEvent.PROPERTY_MODE_CHANGE, onPropertyModeChange);
			if (stage) {
				stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
				stage.removeEventListener(KeyboardEvent.KEY_UP, onKeyUp);
			}
			super.dispose();
		}
		
		public function zoomInDiscrete():void
		{
			handleMouseWheel(5);
			m_currentLevel.updateVisibleList();
		}
		
		public function zoomOutDiscrete():void
		{
			handleMouseWheel(-5);
			m_currentLevel.updateVisibleList();
		}
		
		private function onKeyDown(event:KeyboardEvent):void
		{
			if(m_world.hasDialogOpen())
					return;
			
			switch(event.keyCode)
			{
				case Keyboard.UP:
				case Keyboard.W:
				case Keyboard.NUMPAD_8:
					if (getPanZoomAllowed()) {
						content.y += 5;
						inactiveContent.y = content.y;
					}
					break;
				case Keyboard.DOWN:
				case Keyboard.S:
				case Keyboard.NUMPAD_2:
					if (getPanZoomAllowed()) {
						content.y -= 5;
						inactiveContent.y = content.y;
					}
					break;
				case Keyboard.LEFT:
				case Keyboard.A:
				case Keyboard.NUMPAD_4:
					if (getPanZoomAllowed()) {
						content.x += 5;
						inactiveContent.x = content.x;
					}
					break;
				case Keyboard.RIGHT:
				case Keyboard.D:
				case Keyboard.NUMPAD_6:
					if (getPanZoomAllowed()) {
						content.x -= 5;
						inactiveContent.x = content.x;
					}
					break;
				case Keyboard.EQUAL:
				case Keyboard.NUMPAD_ADD:
					zoomInDiscrete();
					break;
				case Keyboard.MINUS:
				case Keyboard.NUMPAD_SUBTRACT:
					zoomOutDiscrete();
					break;
				case Keyboard.SPACE:
					recenter();
					break;
			}
		}
		
		private function onKeyUp(event:KeyboardEvent):void
		{
			// Release shift, temporarily enter this mode until next touch
			// (this prevents the user from un-selecting when they perform
			// a shift + click + drag + unshift + unclick sequence
			if(currentMode == SELECTING_MODE && !event.shiftKey)
			{
				endSelectMode();
				currentMode = RELEASE_SHIFT_MODE; // this will reset on next touch event
			}
		}
		
		private var m_boundingBoxDebug:Quad;
		private static const DEBUG_BOUNDING_BOX:Boolean = false;
		public function loadLevel(level:Level):void
		{
			m_continueButtonForced = false;
			removeFanfare();
			hideContinueButton();
			removeSpotlight();
			if(m_currentLevel != level)
			{
				if(m_currentLevel)
				{
					m_currentLevel.removeEventListener(TouchEvent.TOUCH, onTouch);
					content.removeChild(m_currentLevel);
					if (m_currentLevel.tutorialManager) {
						m_currentLevel.tutorialManager.removeEventListener(TutorialEvent.SHOW_CONTINUE, displayContinueButton);
						m_currentLevel.tutorialManager.removeEventListener(TutorialEvent.HIGHLIGHT_BOX, onHighlightTutorialEvent);
						m_currentLevel.tutorialManager.removeEventListener(TutorialEvent.HIGHLIGHT_EDGE, onHighlightTutorialEvent);
						m_currentLevel.tutorialManager.removeEventListener(TutorialEvent.HIGHLIGHT_PASSAGE, onHighlightTutorialEvent);
						m_currentLevel.tutorialManager.removeEventListener(TutorialEvent.HIGHLIGHT_CLASH, onHighlightTutorialEvent);
						m_currentLevel.tutorialManager.removeEventListener(TutorialEvent.HIGHLIGHT_SCOREBLOCK, onHighlightTutorialEvent);
						m_currentLevel.tutorialManager.removeEventListener(TutorialEvent.NEW_TUTORIAL_TEXT, onTutorialTextChange);
						m_currentLevel.tutorialManager.removeEventListener(TutorialEvent.NEW_TOOLTIP_TEXT, onPersistentToolTipTextChange);
					}
				}
				m_currentLevel = level;
				var seed:int = m_currentLevel.levelNodes.qid;
				if (seed < 0) {
					seed = 0;
					for (var c:int = 0; c < m_currentLevel.level_name.length; c++) {
						var code:Number = m_currentLevel.level_name.charCodeAt(c);
						if (isNaN(code)) {
							seed += c;
						} else {
							seed += Math.max(Math.round(code), 1);
						}
					}
				}
				swapBackgroundImage(seed);
				m_currentLevel.addEventListener(TouchEvent.TOUCH, onTouch);
				if (m_currentLevel.tutorialManager) {
					m_currentLevel.tutorialManager.addEventListener(TutorialEvent.SHOW_CONTINUE, displayContinueButton);
					m_currentLevel.tutorialManager.addEventListener(TutorialEvent.HIGHLIGHT_BOX, onHighlightTutorialEvent);
					m_currentLevel.tutorialManager.addEventListener(TutorialEvent.HIGHLIGHT_EDGE, onHighlightTutorialEvent);
					m_currentLevel.tutorialManager.addEventListener(TutorialEvent.HIGHLIGHT_PASSAGE, onHighlightTutorialEvent);
					m_currentLevel.tutorialManager.addEventListener(TutorialEvent.HIGHLIGHT_CLASH, onHighlightTutorialEvent);
					m_currentLevel.tutorialManager.addEventListener(TutorialEvent.HIGHLIGHT_SCOREBLOCK, onHighlightTutorialEvent);
					m_currentLevel.tutorialManager.addEventListener(TutorialEvent.NEW_TUTORIAL_TEXT, onTutorialTextChange);
					m_currentLevel.tutorialManager.addEventListener(TutorialEvent.NEW_TOOLTIP_TEXT, onPersistentToolTipTextChange);
				}
			}
			
			inactiveContent.removeChildren();
			inactiveContent.addChild(m_currentLevel.inactiveLayer);
			
			// Remove old error text containers and place new ones
			for (var i:int = 0; i < m_errorTextBubbles.length; i++) m_errorTextBubbles[i].removeFromParent();
			m_errorTextBubbles = new Vector.<Sprite>();
			for (i = 0; i < m_currentLevel.m_edgeList.length; i++) {
				m_errorTextBubbles.push(m_currentLevel.m_edgeList[i].errorTextBubbleContainer);
				errorBubbleContainer.addChild(m_currentLevel.m_edgeList[i].errorTextBubbleContainer);
			}
			
			if (m_tutorialText) {
				m_tutorialText.removeFromParent(true);
				m_tutorialText = null;
			}
			for (i = 0; i < m_persistentToolTips.length; i++) m_persistentToolTips[i].removeFromParent(true);
			m_persistentToolTips = new Vector.<ToolTipText>();
			
			var toolTips:Vector.<TutorialManagerTextInfo> = m_currentLevel.getLevelToolTipsInfo();
			for (i = 0; i < toolTips.length; i++) {
				var tip:ToolTipText = new ToolTipText(toolTips[i].text, m_currentLevel, true, toolTips[i].pointAtFn, toolTips[i].pointFrom, toolTips[i].pointTo);
				addChild(tip);
				m_persistentToolTips.push(tip);
			}
			
			var levelTextInfo:TutorialManagerTextInfo = m_currentLevel.getLevelTextInfo();
			if (levelTextInfo) {
				m_tutorialText = new TutorialText(m_currentLevel, levelTextInfo);
				addChild(m_tutorialText);
			}
			
			recenter();
		}
		
		public function onTutorialTextChange(evt:TutorialEvent):void
		{
			if (m_tutorialText) {
				m_tutorialText.removeFromParent(true);
				m_tutorialText = null;
			}
			
			var levelTextInfo:TutorialManagerTextInfo = (evt.newTextInfo.length == 1) ? evt.newTextInfo[0] : null;
			if (levelTextInfo) {
				m_tutorialText = new TutorialText(m_currentLevel, levelTextInfo);
				addChild(m_tutorialText);
			}
		}
		
		public function onPersistentToolTipTextChange(evt:TutorialEvent):void
		{
			var i:int;
			for (i = 0; i < m_persistentToolTips.length; i++) m_persistentToolTips[i].removeFromParent(true);
			m_persistentToolTips = new Vector.<ToolTipText>();
			
			var toolTips:Vector.<TutorialManagerTextInfo> = m_currentLevel.getLevelToolTipsInfo();
			for (i = 0; i < toolTips.length; i++) {
				var tip:ToolTipText = new ToolTipText(toolTips[i].text, m_currentLevel, true, toolTips[i].pointAtFn, toolTips[i].pointFrom, toolTips[i].pointTo);
				addChild(tip);
				m_persistentToolTips.push(tip);
			}
		}
		
		public function recenter():void
		{
			content.x = 0;
			content.y = 0;
			inactiveContent.x = inactiveContent.y = 0;
			
			content.scaleX = content.scaleY = STARTING_SCALE;
			inactiveContent.scaleX = inactiveContent.scaleY = STARTING_SCALE;
			onContentScaleChanged();
			content.addChild(m_currentLevel);
			
			if (DEBUG_BOUNDING_BOX) {
				if (!m_boundingBoxDebug) {
					m_boundingBoxDebug = new Quad(m_currentLevel.m_boundingBox.width, m_currentLevel.m_boundingBox.height, 0xFFFF00);
					m_boundingBoxDebug.alpha = 0.2;
					m_boundingBoxDebug.touchable = false;
					content.addChild(m_boundingBoxDebug);
				} else {
					m_boundingBoxDebug.width = m_currentLevel.m_boundingBox.width;
					m_boundingBoxDebug.height = m_currentLevel.m_boundingBox.height;
				}
				m_boundingBoxDebug.x = m_currentLevel.m_boundingBox.x;
				m_boundingBoxDebug.y = m_currentLevel.m_boundingBox.y;
			} else if (m_boundingBoxDebug) {
				m_boundingBoxDebug.removeFromParent(true);
			}
			
			var i:int;
			var centerPt:Point, globPt:Point, localPt:Point;
			if ((m_currentLevel.m_boundingBox.width * content.scaleX < MAX_SCALE * WIDTH) && (m_currentLevel.m_boundingBox.height * content.scaleX  < MAX_SCALE * HEIGHT)) {
				// If about the size of the window, just center the level
				centerPt = new Point(m_currentLevel.m_boundingBox.left + m_currentLevel.m_boundingBox.width / 2, m_currentLevel.m_boundingBox.top + m_currentLevel.m_boundingBox.height / 2);
				globPt = m_currentLevel.localToGlobal(centerPt);
				localPt = content.globalToLocal(globPt);
				moveContent(localPt.x, localPt.y);
				const BUFFER:Number = 1.5;
				scaleContent(Math.min(WIDTH  / (BUFFER * m_currentLevel.m_boundingBox.width * content.scaleX),
					HEIGHT / (BUFFER * m_currentLevel.m_boundingBox.height * content.scaleY)));
			} else {
				// Otherwise center on the first visible box
				var nodes:Vector.<GameNode> = m_currentLevel.getNodes();
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
			
			if (m_currentLevel && m_currentLevel.tutorialManager) {
				var startPtOffset:Point = m_currentLevel.tutorialManager.getStartPanOffset();
				content.x += startPtOffset.x * content.scaleX;
				content.y += startPtOffset.y * content.scaleY;
				inactiveContent.x = content.x;
				inactiveContent.y = content.y;
				scaleContent(m_currentLevel.tutorialManager.getStartScaleFactor());
			}
		}
		
		private var m_fanfareContainer:Sprite = new Sprite();
		private var m_fanfare:Vector.<FanfareParticleSystem> = new Vector.<FanfareParticleSystem>();
		private var m_fanfareTextContainer:Sprite = new Sprite();
		private var m_stopFanfareDelayedCall:DelayedCall;
		public function displayContinueButton(permenantly:Boolean = true):void
		{
			if (permenantly) m_continueButtonForced = true;
			if (!continueButton) {
				continueButton = ButtonFactory.getInstance().createDefaultButton("Next Level", 128, 32);
				continueButton.addEventListener(Event.TRIGGERED, onNextLevelButtonTriggered);
				continueButton.x = WIDTH - continueButton.width - 5;
				continueButton.y = HEIGHT - continueButton.height - 5;
			}
			
			if (continueButton.parent == null) {
				addChild(continueButton);
				
				// Fanfare
				removeFanfare();
				addChild(m_fanfareContainer);
				m_fanfareContainer.x = m_fanfareTextContainer.x = WIDTH / 2 - continueButton.width / 2;
				m_fanfareContainer.y = m_fanfareTextContainer.y = continueButton.y - continueButton.height;
				
				for (var i:int = 5; i <= continueButton.width - 5; i += 10) {
					var fanfare:FanfareParticleSystem = new FanfareParticleSystem();
					fanfare.x = i;
					fanfare.y = continueButton.height / 2;
					fanfare.scaleX = fanfare.scaleY = 0.4;
					m_fanfare.push(fanfare);
					m_fanfareContainer.addChild(fanfare);
				}
				
				var textField:TextFieldWrapper = TextFactory.getInstance().createTextField("Level Complete!", AssetsFont.FONT_UBUNTU, continueButton.width, continueButton.height, 16, 0xFFEC00);
				TextFactory.getInstance().updateFilter(textField, OutlineFilter.getOutlineFilter());
				m_fanfareTextContainer.addChild(textField);
				addChild(m_fanfareTextContainer);
				
				var origX:Number = m_fanfareTextContainer.x;
				var origY:Number = m_fanfareTextContainer.y;
				const LEVEL_COMPLETE_TEXT_PAUSE_SEC:Number = 1.0;
				const LEVEL_COMPLETE_TEXT_MOVE_SEC:Number = 2.0;
				startFanfare();
				for (i = 0; i < m_fanfare.length; i++) {
					Starling.juggler.tween(m_fanfare[i], LEVEL_COMPLETE_TEXT_MOVE_SEC, { delay:LEVEL_COMPLETE_TEXT_PAUSE_SEC, particleX:(continueButton.x - origX), particleY:(continueButton.y - continueButton.height - origY), transition:Transitions.EASE_OUT } );
				}
				m_stopFanfareDelayedCall = Starling.juggler.delayCall(stopFanfare, LEVEL_COMPLETE_TEXT_PAUSE_SEC + LEVEL_COMPLETE_TEXT_MOVE_SEC - 0.5);
				Starling.juggler.tween(m_fanfareTextContainer, LEVEL_COMPLETE_TEXT_MOVE_SEC, { delay:LEVEL_COMPLETE_TEXT_PAUSE_SEC, x:continueButton.x, y:continueButton.y - continueButton.height, transition:Transitions.EASE_OUT } );
			}
			
			//assume we are in the tutorial, and we just finished a level
			PipeJamGameScene.solvedTutorialLevel(m_currentLevel.m_tutorialTag);
		}
		
		private function startFanfare():void
		{
			for (var i:int = 0; i < m_fanfare.length; i++) {
				m_fanfare[i].start();
			}
		}
		
		private function stopFanfare():void
		{
			for (var i:int = 0; i < m_fanfare.length; i++) {
				m_fanfare[i].stop();
			}
		}
		
		private function removeFanfare():void
		{
			if (m_stopFanfareDelayedCall) Starling.juggler.remove(m_stopFanfareDelayedCall);
			for (var i:int = 0; i < m_fanfare.length; i++) {
				m_fanfare[i].removeFromParent(true);
			}
			m_fanfare = new Vector.<FanfareParticleSystem>();
			if (m_fanfareContainer) m_fanfareContainer.removeFromParent();
			if (m_fanfareTextContainer) {
				Starling.juggler.removeTweens(m_fanfareTextContainer);
				m_fanfareTextContainer.removeFromParent();
			}
		}
		
		public function hideContinueButton():void
		{
			if (continueButton && !m_continueButtonForced) {
				continueButton.removeFromParent();
			}
		}
		
		private function onNextLevelButtonTriggered(evt:Event):void
		{
			dispatchEvent(new NavigationEvent(NavigationEvent.SWITCH_TO_NEXT_LEVEL));
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
			content.x = ( -panX * content.scaleX + clipRect.width / 2);
			inactiveContent.x = content.x;
			content.y = ( -panY * content.scaleY + clipRect.height / 2);
			inactiveContent.y = content.y;
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
			moveContent(localPt.x, localPt.y);
			
			var startPoint:Point = startingPoint.clone();
			var endPoint:Point = new Point(content.x, content.y);
			var eventToUndo:MoveEvent = new MoveEvent(MoveEvent.MOUSE_DRAG, null, startPoint, endPoint);
			var eventToDispatch:UndoEvent = new UndoEvent(eventToUndo, this);
			dispatchEvent(eventToDispatch);
		}
		
		public function onHighlightTutorialEvent(evt:TutorialEvent):void
		{
			if (!evt.highlightOn) {
				removeSpotlight();
				return;
			}
			if (!m_currentLevel) return;
			var edge:GameEdgeContainer;
			switch (evt.type) {
				case TutorialEvent.HIGHLIGHT_BOX:
					var node:GameNode = m_currentLevel.getNode(evt.componentId);
					if (node) spotlightComponent(node);
					break;
				case TutorialEvent.HIGHLIGHT_EDGE:
					edge = m_currentLevel.getEdgeContainer(evt.componentId);
					if (edge) spotlightComponent(edge, 3.0, 1.75, 1.2);
					break;
				case TutorialEvent.HIGHLIGHT_PASSAGE:
					edge = m_currentLevel.getEdgeContainer(evt.componentId);
					if (edge && edge.m_innerBoxSegment) spotlightComponent(edge.m_innerBoxSegment, 3.0, 3, 2);
					break;
				case TutorialEvent.HIGHLIGHT_CLASH:
					edge = m_currentLevel.getEdgeContainer(evt.componentId);
					if (edge && edge.errorContainer) spotlightComponent(edge.errorContainer, 3.0, 1.3, 1.3);
					break;
			}
		}
		
		private function removeSpotlight():void
		{
			if (m_spotlight) m_spotlight.removeFromParent();
		}
		
		public function spotlightComponent(component:DisplayObject, timeSec:Number = 3.0, widthScale:Number = 1.75, heightScale:Number = 1.75):void
		{
			if (!m_currentLevel) return;
			startingPoint = new Point(content.x, content.y);
			var bounds:Rectangle = component.getBounds(component);
			var centerPt:Point = new Point(bounds.x + bounds.width / 2, bounds.y + bounds.height / 2);
			var globPt:Point = component.localToGlobal(centerPt);
			var localPt:Point = content.globalToLocal(globPt);
			
			if (!m_spotlight) {
				var spotlightTexture:Texture = AssetInterface.getTexture("Game", "SpotlightClass");
				m_spotlight = new Image(spotlightTexture);
				m_spotlight.touchable = false;
				m_spotlight.alpha = 0.3;
			}
			m_spotlight.width = component.width * widthScale;
			m_spotlight.height = component.height * heightScale;
			m_spotlight.x = m_currentLevel.m_boundingBox.x - Constants.GameWidth / 2;
			m_spotlight.y = m_currentLevel.m_boundingBox.y - Constants.GameHeight / 2;
			content.addChild(m_spotlight);
			var destX:Number = localPt.x - m_spotlight.width / 2;
			var destY:Number = localPt.y - m_spotlight.height / 2;
			Starling.juggler.removeTweens(m_spotlight);
			Starling.juggler.tween(m_spotlight, 0.9*timeSec, { delay:0.1*timeSec, x:destX, transition: Transitions.EASE_OUT_ELASTIC } );
			Starling.juggler.tween(m_spotlight, timeSec, { delay:0, y:destY, transition: Transitions.EASE_OUT_ELASTIC } );
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
				inactiveContent.x = content.x;
				inactiveContent.y = content.y;
			}
		}
		
		public function getPanZoomAllowed():Boolean
		{
			if (m_currentLevel) return m_currentLevel.getPanZoomAllowed();
			return true;
		}
		
		//returns ByteArray that contains bitmap that is the same aspect ratio as view, with maxwidth or maxheight (or both, if same as aspect ratio) respected
		//byte array is compressed and contains it's width as as unsigned int at the start of the array
		public function getThumbnail(_maxwidth:Number, _maxheight:Number):ByteArray
		{
			var  backgroundColor:Number = 0x262257;
			//save current state
			var savedClipRect:Rectangle = clipRect;
			var currentX:Number = content.x;
			var currentY:Number = content.y;
			var currentXScale:Number = content.scaleX;
			var currentYScale:Number = content.scaleY;
			recenter();
			this.clipRect = null;
			//remove these to help with compression
			removeChild(m_backgroundImage);
			removeChild(m_border);
			
			var bmpdata:BitmapData = drawToBitmapData(backgroundColor);
	
			var scaleWidth:Number = _maxwidth/bmpdata.width;
			var scaleHeight:Number = _maxheight/bmpdata.height;
			var newWidth:Number, newHeight:Number;
			if(scaleWidth < scaleHeight)
			{
				scaleHeight = scaleWidth;
				newWidth = _maxwidth;
				newHeight = bmpdata.height*scaleHeight;
			}
			else
			{
				scaleWidth = scaleHeight;
				newHeight = _maxheight;
				newWidth = bmpdata.width*scaleWidth;
			}
			
			//crashes on my machine in debug, even though should be supported in 11.3
	//		var byteArray:ByteArray = new ByteArray;
	//		bmpdata.encode(new Rectangle(0,0,640,480), new flash.display.JPEGEncoderOptions(), byteArray);
			
			var m:Matrix = new Matrix();
			m.scale(scaleWidth, scaleHeight);
			var smallBMD:BitmapData = new BitmapData(newWidth, newHeight);
			smallBMD.draw(bmpdata, m);
		
			//restore state
			content.x = currentX;
			content.y = currentY;
			inactiveContent.x = content.x;
			inactiveContent.x = content.y;
			content.scaleX = currentXScale;
			content.scaleY = currentYScale;
			inactiveContent.scaleX = content.scaleX;
			inactiveContent.scaleY = content.scaleY;
			clipRect = savedClipRect;
			addChildAt(this.m_backgroundImage, 0);
			addChildAt(this.m_border, 1);
			
			var bytes:ByteArray = new ByteArray;
			bytes.writeUnsignedInt(smallBMD.width);
			//fix bottom to be above score area
			var fixedRect:Rectangle = smallBMD.rect.clone();
			fixedRect.height = Math.floor(smallBMD.height*(clipRect.height/320));
			bytes.writeBytes(smallBMD.getPixels(fixedRect));
			bytes.compress();
			
			return bytes;
		}
		
		public function drawToBitmapData(_backgroundColor:Number = 0x00000000, destination:BitmapData=null):BitmapData
		{
			var support:RenderSupport = new RenderSupport();
			var star:Starling = Starling.current;

			if (destination == null)
				destination = new BitmapData(480, 320);

			support.renderTarget = null;
			support.setOrthographicProjection(0, 0, 960, 640);
			support.clear(_backgroundColor, 1);
			render(support, 1.0);
			support.finishQuadBatch();

			Starling.current.context.drawToBitmapData(destination);
		//	Starling.current.context.present(); // required on some platforms to avoid flickering

			return destination;
		}
		
		private function swapBackgroundImage(seed:int = 0):void
		{
			if (m_backgroundImage) m_backgroundImage.removeFromParent(true);
			var backMod:int = seed % Constants.NUM_BACKGROUNDS;
			var background:Texture = AssetInterface.getTexture("Game", "Background" + backMod + "Class");
			m_backgroundImage = new Image(background);
			m_backgroundImage.width = Constants.GameWidth;
			m_backgroundImage.height = Constants.GameHeight;
			m_backgroundImage.blendMode = BlendMode.NONE;
			if (m_backgroundLayer) m_backgroundLayer.addChild(m_backgroundImage);
		}
	}
}
