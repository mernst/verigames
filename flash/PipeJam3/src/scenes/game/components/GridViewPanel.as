package scenes.game.components
{
	import feathers.display.TiledImage;
	import flash.display.BitmapData;
	import flash.events.ContextMenuEvent;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.events.TimerEvent;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.system.System;
	import flash.ui.ContextMenu;
	import flash.ui.Keyboard;
	import flash.utils.ByteArray;
	import flash.utils.Dictionary;
	import flash.utils.Timer;
	
	import assets.AssetInterface;
	import assets.AssetsFont;
	
	import display.NineSliceButton;
	import display.ToolTipText;
	
	import events.MenuEvent;
	import events.MiniMapEvent;
	import events.MouseWheelEvent;
	import events.MoveEvent;
	import events.NavigationEvent;
	import events.PropertyModeChangeEvent;
	import events.SelectionEvent;
	import events.TutorialEvent;
	import events.UndoEvent;
	
	import networking.TutorialController;
	
	import particle.FanfareParticleSystem;
	
	import scenes.BaseComponent;
	import scenes.game.PipeJamGameScene;
	import scenes.game.display.Level;
	import scenes.game.display.OutlineFilter;
	import scenes.game.display.TutorialLevelManager;
	import scenes.game.display.TutorialManagerTextInfo;
	import scenes.game.display.World;
	
	import starling.animation.DelayedCall;
	import starling.animation.Transitions;
	import starling.core.RenderSupport;
	import starling.core.Starling;
	import starling.display.DisplayObject;
	import starling.display.Image;
	import starling.display.Quad;
	import starling.display.Sprite;
	import starling.events.EnterFrameEvent;
	import starling.events.Event;
	import starling.events.KeyboardEvent;
	import starling.events.Touch;
	import starling.events.TouchEvent;
	import starling.events.TouchPhase;
	import starling.textures.Texture;
	import starling.textures.TextureAtlas;
	
	import system.MaxSatSolver;
	
	import utils.PropDictionary;
	import utils.XMath;
	
	//GamePanel is the main game play area, with a central sprite and right and bottom scrollbars. 
	public class GridViewPanel extends BaseComponent
	{
		public static var WIDTH:Number = Constants.GameWidth;
		public static var HEIGHT:Number = Constants.GameHeight;
		
		private var m_currentLevel:Level;
		private var inactiveContent:Sprite;
		private var contentBarrier:Quad;
		private var content:BaseComponent;
		private var errorBubbleContainer:Sprite;
		private var currentMode:int;
		private var endingMoveMode:Boolean;
		private var continueButton:NineSliceButton;
		private var m_border:Image;
		private var m_tutorialText:TutorialText;
		private var m_persistentToolTips:Vector.<ToolTipText> = new Vector.<ToolTipText>();
		private var m_continueButtonForced:Boolean = false; //true to force the continue button to display, ignoring score
		private var m_errorTextBubbles:Dictionary = new Dictionary();
		private var m_nodeLayoutQueue:Vector.<Object> = new Vector.<Object>();
		private var m_edgeLayoutQueue:Vector.<Object> = new Vector.<Object>();
		
		private var m_tutorialTextLayer:Sprite = new Sprite();
		
		private var m_paintBrushLayer:Sprite = new Sprite();
		protected var m_paintBrushInfoSprite:Sprite = new Sprite();
		protected var m_paintBrush:Sprite = new Sprite();
		protected var m_selectionCount:Sprite = new Sprite();
		protected var m_selectedText:TextFieldWrapper;
		protected var m_selectionLimitText:TextFieldWrapper;
		static public var PAINT_RADIUS:int = 60;
		
		private var m_fanfareLayer:Sprite = new Sprite();
		private var m_buttonLayer:Sprite = new Sprite();
		
		private var m_selectionUpdated:Boolean = false;
		private var m_startingTouchPoint:Point;
		private var m_currentTouchPoint:Point;
		private var m_inBounds:Boolean = true;
		private var m_wasOutOfBounds:Boolean = true;
		private var m_rightMouseDown:Boolean = false;
		private var m_MouseMoveListenerInstalled:Boolean = false;
		
		private static const VISIBLE_BUFFER_PIXELS:Number = 60.0; // make objects within this many pixels visible, only refresh visible list when we've moved outside of this buffer
		protected static const NORMAL_MODE:int = 0;
		protected static const MOVING_MODE:int = 1;
		protected static const SELECTING_MODE:int = 2;
		protected static const HOVER_MODE:int = 3;
		protected static const RELEASE_SHIFT_MODE:int = 4;
		
		//brush details
		protected var m_solver1Brush:Sprite;
		protected var m_solver2Brush:Sprite;
		protected var m_widenBrush:Sprite;
		protected var m_narrowBrush:Sprite;
	
		public static const SOLVER1_BRUSH:String = "BrushCircle";
		public static const SOLVER2_BRUSH:String = "BrushDiamond";
		public static const WIDEN_BRUSH:String = "BrushHexagon";
		public static const NARROW_BRUSH:String = "BrushSquare";
		public static var FIRST_SOLVER_BRUSH:String;
		
		public static const CHANGE_BRUSH:String = "change_brush";
		
		public static const MIN_SCALE:Number = 2.0 / Constants.GAME_SCALE;
		private static var MAX_SCALE:Number = 25.0 / Constants.GAME_SCALE;
		private static const STARTING_SCALE:Number = 12.0 / Constants.GAME_SCALE;
		// At scales less than this value (zoomed out), error text is hidden - but arrows remain
		private static const MIN_ERROR_TEXT_DISPLAY_SCALE:Number = 15.0 / Constants.GAME_SCALE;
		private static var m_gridTexture:Texture;
		
		private var m_gridTileImg:TiledImage;
		private var m_gridContainer:Sprite;
		private var m_zoomPanTimer:Timer;
		private static const ZOOM_PAN_TIME_SEC:Number = 0.6;
		
		public function GridViewPanel(world:World)
		{
			this.alpha = .999;

			currentMode = NORMAL_MODE;
			
			inactiveContent = new Sprite();
			addChild(inactiveContent);
			
			content = new BaseComponent();
			addChild(content);
			
			errorBubbleContainer = new Sprite();
			addChild(errorBubbleContainer);
			
			addChild(m_tutorialTextLayer);
			
			addChild(m_paintBrushLayer);
			
			var borderTexture:Texture = AssetInterface.getTexture("Game", "BorderVignetteClass");
			m_border = new Image(borderTexture);
			m_border.width = WIDTH - 40;
			m_border.height = HEIGHT + 10;
			m_border.x = m_border.y = -5;
			m_border.touchable = false;
			addChild(m_border);
			
			contentBarrier = new Quad(width,height, 0x00);
			contentBarrier.alpha = 0.01;
			contentBarrier.visible = true;
			addChildAt(contentBarrier,0);
			
			// Create paintbrushes for menu, and for mouse cursor
			m_solver1Brush = createPaintBrush(SOLVER1_BRUSH, true);
			m_solver2Brush = createPaintBrush(SOLVER2_BRUSH, true);
			m_widenBrush = createPaintBrush(WIDEN_BRUSH, true);
			m_narrowBrush = createPaintBrush(NARROW_BRUSH, true);
			
			m_paintBrush = m_solver1Brush;
			
			var atlas:TextureAtlas = AssetInterface.getTextureAtlas("Game", "PipeJamSpriteSheetPNG", "PipeJamSpriteSheetXML");
			var scoreBoxTexture:Texture = atlas.getTexture(AssetInterface.PipeJamSubTexture_TutorialBoxPrefix);
			var scoreBoxImage:Image = new Image(scoreBoxTexture);
			scoreBoxImage.width = scoreBoxImage.height = .6 * PAINT_RADIUS;
			m_selectionCount.addChild(scoreBoxImage);
			m_selectionCount.x = m_paintBrushInfoSprite.bounds.left;
			m_selectionCount.y = m_paintBrushInfoSprite.bounds.left;
			
			m_paintBrushInfoSprite.addChild(m_selectionCount);
			
			m_selectedText = TextFactory.getInstance().createTextField("000", AssetsFont.FONT_UBUNTU, m_selectionCount.width - 4, m_selectionCount.height/2, 10, 0xc1a06d);
			m_selectedText.touchable = false;
			m_selectedText.x = m_selectionCount.x + 2;
			m_selectedText.y = m_selectionCount.y + 1;
			TextFactory.getInstance().updateAlign(m_selectedText, 1, 1);
			
			m_paintBrushInfoSprite.addChild(m_selectedText);
			
			var divisionLineQuad:Quad = new Quad(m_selectedText.width - 6, 2, 0xc1a06d);
			divisionLineQuad.touchable = false;
			divisionLineQuad.x = m_selectedText.x + 3;
			divisionLineQuad.y = m_selectedText.y + m_selectedText.height - 3;
			m_paintBrushInfoSprite.addChild(divisionLineQuad);
			
			m_selectionLimitText = TextFactory.getInstance().createTextField("1000", AssetsFont.FONT_UBUNTU, m_selectionCount.width - 4, m_selectionCount.height/2, 10, 0xc1a06d);
			m_selectionLimitText.touchable = false;
			m_selectionLimitText.x = m_selectedText.x;
			m_selectionLimitText.y = divisionLineQuad.y;
			TextFactory.getInstance().updateAlign(m_selectionLimitText, 1, 1);
			
			m_paintBrushInfoSprite.addChild(m_selectionLimitText);
			m_paintBrushInfoSprite.flatten();

			addChild(m_buttonLayer);
			addChild(m_fanfareLayer);
			
			addEventListener(starling.events.Event.ADDED_TO_STAGE, onAddedToStage);
			addEventListener(starling.events.Event.REMOVED_FROM_STAGE, onRemovedFromStage);
		}
		
		private function onAddedToStage():void
		{
			addEventListener(EnterFrameEvent.ENTER_FRAME, onEnterFrame);
				
			//create a clip rect for the window
			clipRect = new Rectangle(x, y, m_border.width, m_border.height - 10);
			
			removeEventListener(starling.events.Event.ADDED_TO_STAGE, onAddedToStage);
			addEventListener(TouchEvent.TOUCH, onTouch);
			addEventListener(PropertyModeChangeEvent.PROPERTY_MODE_CHANGE, onPropertyModeChange);
			if (!PipeJam3.REPLAY_DQID) {
				stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
				stage.addEventListener(KeyboardEvent.KEY_UP, onKeyUp);
			}
			Starling.current.nativeStage.addEventListener(MouseEvent.MOUSE_WHEEL, onMouseWheel);
			
			var myContextMenu:ContextMenu = new ContextMenu();
			myContextMenu.clipboardMenu = true;
			myContextMenu.addEventListener(ContextMenuEvent.MENU_SELECT, menuSelectHandler);
			PipeJam3.pipeJam3.contextMenu = myContextMenu;		
			
			installPaintBrush(true);
			m_nextPaintbrushLocation = new Point(width/2, height/2);

			addEventListener(MaxSatSolver.SOLVER_STARTED, onSolverStarted);
			addEventListener(MaxSatSolver.SOLVER_STOPPED, onSolverStopped);

			Starling.current.nativeStage.addEventListener(MouseEvent.RIGHT_CLICK, function(e:MouseEvent):void{});
			Starling.current.nativeStage.addEventListener(MouseEvent.RIGHT_MOUSE_DOWN, mouseRightClickDownEventHandler);
			Starling.current.nativeStage.addEventListener(MouseEvent.RIGHT_MOUSE_UP, mouseRightClickUpEventHandler);
			Starling.current.nativeStage.addEventListener(flash.events.Event.MOUSE_LEAVE, mouseLeaveHandler);
		}
		
		protected function mouseLeaveHandler(event:flash.events.Event):void
		{
			m_inBounds = false;
			m_wasOutOfBounds = true;
			if(!m_MouseMoveListenerInstalled)
			{
				Starling.current.nativeStage.addEventListener(MouseEvent.MOUSE_MOVE, mouseMoveEventHandler);
				m_MouseMoveListenerInstalled = true;
			}
		}
		
		protected var currentLocation:Point = null;
		protected function mouseMoveEventHandler(event:MouseEvent):void
		{
			if(event.stageX > 0 &&
				event.stageX < 960 &&
				event.stageY > 0 &&
				event.stageY < 640)
					m_inBounds = true;

			if(m_rightMouseDown && currentLocation)
			{
				var deltaX:Number = event.stageX - currentLocation.x;
				var deltaY:Number = event.stageY - currentLocation.y;
				var viewRect:Rectangle = getViewInContentSpace();
				var newX:Number = viewRect.x + viewRect.width / 2 - (deltaX / content.scaleX/2);
				var newY:Number = viewRect.y + viewRect.height / 2 - (deltaY / content.scaleY/2);
				moveContent(newX, newY);
				currentLocation.x = event.stageX;
				currentLocation.y = event.stageY;
			}
			else if(m_inBounds && m_wasOutOfBounds)
			{
				if(m_MouseMoveListenerInstalled)
				{
					Starling.current.nativeStage.removeEventListener(MouseEvent.MOUSE_MOVE, mouseMoveEventHandler);
					m_MouseMoveListenerInstalled = false;
				}
				m_wasOutOfBounds = false;
			}
		}
		
		private function mouseRightClickDownEventHandler(event:MouseEvent):void
		{
			if(getPanZoomAllowed())
			{
				if(!m_MouseMoveListenerInstalled)
				{
					Starling.current.nativeStage.addEventListener(MouseEvent.MOUSE_MOVE, mouseMoveEventHandler);
					m_MouseMoveListenerInstalled = true;
				}
				m_paintBrush.visible = false;
				m_paintBrushInfoSprite.visible = false;
				m_rightMouseDown = true;
				currentLocation = new Point(event.stageX, event.stageY);
			}
		}
		
		private function mouseRightClickUpEventHandler(event:MouseEvent):void
		{
			if(getPanZoomAllowed())
			{
				if(m_MouseMoveListenerInstalled)
				{
					Starling.current.nativeStage.removeEventListener(MouseEvent.MOUSE_MOVE, mouseMoveEventHandler);
					m_MouseMoveListenerInstalled = false;
				}
				m_paintBrush.visible = true;
				m_paintBrushInfoSprite.visible = true;
				m_rightMouseDown = false;
				currentLocation = null;
			}
		}
		
		protected function menuSelectHandler(event:flash.events.Event):void
		{
			PipeJam3.pipeJam3.contextMenu.clipboardItems.paste = true;
		}
		
		private var oldViewRect:Rectangle;
		public function onEnterFrame(evt:EnterFrameEvent):void
		{
			if (!m_currentLevel) return;
			
			if (m_nextPaintbrushLocationUpdated && m_nextPaintbrushLocation) {
				
				m_paintBrush.x = m_nextPaintbrushLocation.x;
				m_paintBrush.y =  m_nextPaintbrushLocation.y; 
				m_paintBrushInfoSprite.x = m_nextPaintbrushLocation.x - m_paintBrush.width/2;
				m_paintBrushInfoSprite.y =  m_nextPaintbrushLocation.y - m_paintBrush.height/2; 
				var num:int = m_currentLevel.selectedNodes.length;
				if (m_selectedText) {
					TextFactory.getInstance().updateText(m_selectedText, String(num));
					TextFactory.getInstance().updateAlign(m_selectedText, 1, 1);
					m_paintBrushInfoSprite.flatten();
				}
				m_nextPaintbrushLocationUpdated = false;
			}
			
			if (m_selectionUpdated && m_currentLevel && m_currentTouchPoint && currentMode == SELECTING_MODE) {
				m_selectionUpdated = false;
				var globalCurrentPt:Point = localToGlobal(m_currentTouchPoint);
				handlePaint(globalCurrentPt);
			}
			
			if(endingMoveMode) //force gc after dragging
			{
				System.gc();
				endingMoveMode = false;
			}
		}
		
		public function outsideEventHandler(event:starling.events.Event):void
		{
			m_inBounds = true;
			if(event.type == MouseEvent.MOUSE_MOVE)
			{
				movePaintBrush(event.data as Point);
				onEnterFrame(null);
			}
			else if(event.type == TouchPhase.BEGAN)
				currentMode = GridViewPanel.SELECTING_MODE;
			else if(event.type == TouchPhase.MOVED)
			{
				movePaintBrush(event.data as Point);
				handlePaint(event.data as Point);
				onEnterFrame(null);
			}
			else if(event.type == TouchPhase.ENDED)
				endSelectMode();
		}
		
		public function onGameComponentsCreated():void
		{
			var toolTips:Vector.<TutorialManagerTextInfo> = m_currentLevel.getLevelToolTipsInfo();
			for (var i:int = 0; i < toolTips.length; i++) {
				var tip:ToolTipText = new ToolTipText(toolTips[i].text, m_currentLevel, true, toolTips[i].pointAtFn, toolTips[i].pointFrom, toolTips[i].pointTo);
				m_tutorialTextLayer.addChildAt(tip, 0);
				m_persistentToolTips.push(tip);
			}
			
			var levelTextInfo:TutorialManagerTextInfo = m_currentLevel.getLevelTextInfo();
			if (levelTextInfo) {
				m_tutorialText = new TutorialText(m_currentLevel, levelTextInfo);
				m_tutorialTextLayer.addChild(m_tutorialText);
			}
			
			recenter();
			var currentViewRect:Rectangle = getViewInContentSpace();
			m_currentLevel.updateLevelDisplay(currentViewRect);
			
			if (DEBUG_BOUNDING_BOX) {
				if (!m_boundingBoxDebug) {
					m_boundingBoxDebug = new Quad(m_currentLevel.m_boundingBox.width, m_currentLevel.m_boundingBox.height, 0xFFFF00);
					m_boundingBoxDebug.alpha = 0.2;
					m_boundingBoxDebug.touchable = false;
					content.addChildAt(m_boundingBoxDebug,0);
				} else {
					m_boundingBoxDebug.width = m_currentLevel.m_boundingBox.width;
					m_boundingBoxDebug.height = m_currentLevel.m_boundingBox.height;
				}
				m_boundingBoxDebug.x = m_currentLevel.m_boundingBox.x;
				m_boundingBoxDebug.y = m_currentLevel.m_boundingBox.y;
			} else if (m_boundingBoxDebug) {
				m_boundingBoxDebug.removeFromParent(true);
			}
		}
		
		private static function isOnScreen(bb:Rectangle, view:Rectangle):Boolean
		{
			if (bb.right < view.left - VISIBLE_BUFFER_PIXELS) return false;
			if (bb.left > view.right + VISIBLE_BUFFER_PIXELS) return false;
			if (bb.bottom < view.top - VISIBLE_BUFFER_PIXELS) return false;
			if (bb.top > view.bottom + VISIBLE_BUFFER_PIXELS) return false;
			return true;
		}
		
		private function onPropertyModeChange(evt:PropertyModeChangeEvent):void
		{
			//if (evt.prop == PropDictionary.PROP_NARROW) {
				//contentBarrier.visible = false;
			//} else {
				//contentBarrier.visible = true;
			//}
		}
		
		public function endSelectMode():void
		{
			if(m_currentLevel)
			{
				if(!m_currentLevel.m_inSolver)
					dispatchEvent(new MenuEvent(MenuEvent.SOLVE_SELECTION, m_paintBrush.name));
				else
					dispatchEvent(new MenuEvent(MenuEvent.STOP_SOLVER));
				endPaint();
			}
		}
		
		private function beginMoveMode():void
		{
			m_startingTouchPoint = new Point(content.x, content.y);
			currentMode = MOVING_MODE;
		}
		
		private function endMoveMode():void
		{
			//did we really move?
			if(content.x != m_startingTouchPoint.x || content.y != m_startingTouchPoint.y)
			{
				var startPoint:Point = m_startingTouchPoint.clone();
				var endPoint:Point = new Point(content.x, content.y);
				var eventToUndo:starling.events.Event = new MoveEvent(MoveEvent.MOUSE_DRAG, null, startPoint, endPoint);
				var eventToDispatch:UndoEvent = new UndoEvent(eventToUndo, this);
				eventToDispatch.addToSimilar = true;
				dispatchEvent(eventToDispatch);
				endingMoveMode = true;
			}
		}
		
		override protected function onTouch(event:TouchEvent):void
		{
			//trace("Mode:" + event.type);
			var touches:Vector.<Touch>;
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
				if (currentMode != NORMAL_MODE)
				{
					currentMode = NORMAL_MODE;
				}
				else
				{
					if (m_currentLevel && event.target == contentBarrier && World.changingFullScreenState == false) {
						m_currentLevel.unselectAll();
						var evt:PropertyModeChangeEvent = new PropertyModeChangeEvent(PropertyModeChangeEvent.PROPERTY_MODE_CHANGE, PropDictionary.PROP_NARROW);
						m_currentLevel.onPropertyModeChange(evt);
					}
					else
						World.changingFullScreenState = false;
				}
			}
			else if (event.getTouches(this, TouchPhase.BEGAN).length || event.getTouches(this, TouchPhase.MOVED).length)
			{
				touches = event.getTouches(this, TouchPhase.BEGAN);
				if (!touches.length) touches = event.getTouches(this, TouchPhase.MOVED);
				if(!event.shiftKey)
				{
					if (m_currentLevel && m_currentLevel.getAutoSolveAllowed())
					{
						// Only allow painting/selecting if autosolve is enabled
						if(currentMode != SELECTING_MODE)
						{
							if (currentMode == MOVING_MODE) endMoveMode();
							currentMode = SELECTING_MODE;
							m_startingTouchPoint = touches[0].getPreviousLocation(this);
							if (m_currentLevel) beginPaint();
						}
						m_currentTouchPoint = touches[0].getLocation(this);
						m_selectionUpdated = true;
					}
				}
				else
				{
					hidePaintBrush();
					if (currentMode != SELECTING_MODE)
					{
						// Don't allow user to go straight from painting to moving with shift, if 
						if(currentMode != MOVING_MODE) beginMoveMode();
						if (touches[0].target == contentBarrier && currentMode == MOVING_MODE)
						{
							var loc:Point = touches[0].getLocation(m_currentLevel);
							if (getPanZoomAllowed())
							{
								var delta:Point = touches[0].getMovement(parent);
								var viewRect:Rectangle = getViewInContentSpace();
								var newX:Number = viewRect.x + viewRect.width / 2 - delta.x / content.scaleX;
								var newY:Number = viewRect.y + viewRect.height / 2 - delta.y / content.scaleY;
								moveContent(newX, newY);
							}
						}
					}
				}
			}
			
			// see if the mouse has moved
			var touch:Touch = event.getTouch(this, TouchPhase.HOVER);
			if(touch || touches)
			{
				var location:Point;
				if(touch)
				{
					 currentMode = HOVER_MODE;
				location = touch.getLocation(this.stage);
				if(location.x > WIDTH)
					hidePaintBrush();
				else
					if(!event.shiftKey && !m_rightMouseDown)
						showPaintBrush();
				}
				else
					location = touches[0].getLocation(this.stage);
				movePaintBrush(location);
			}
		}

		private function onMouseWheel(evt:MouseEvent):void
		{
			var delta:Number = evt.delta;
			var localMouse:Point = this.globalToLocal(new Point(evt.stageX, evt.stageY));
			handleMouseWheel(delta, localMouse);			
		}
		
		private var lastScaleChanged:Boolean = false;
		private function handleMouseWheel(delta:Number, localMouse:Point = null):void
		{
			if (!getPanZoomAllowed())
			{
				return;
			}
			showZoomPanGrid();
			if (localMouse == null) {
				localMouse = new Point((WIDTH - Constants.RightPanelWidth) / 2, HEIGHT / 2);
			} else {
				var mousePoint:Point = localMouse.clone();
				
				const native2Starling:Point = new Point(Starling.current.stage.stageWidth / Starling.current.nativeStage.stageWidth, 
						Starling.current.stage.stageHeight / Starling.current.nativeStage.stageHeight);
				
				localMouse.x *= native2Starling.x;
				localMouse.y *= native2Starling.y;
			}
			// Now localMouse is in local coordinates (relative to this instance of GridViewPanel).
			// Next, we'll convert to content space
			var contentToScale:DisplayObject = m_gridContainer;
			var prevMouse:Point = contentToScale.globalToLocal(localMouse);
			// Now we have the mouse location in current content space.
			// We want this location to not move after scaling
			
			// Calculate what new scale would be
			var sizeDiff:Number = 1.00 + 2 * delta / 100.0;
			
			var newScaleX:Number = XMath.clamp(contentToScale.scaleX * sizeDiff, MIN_SCALE, MAX_SCALE);
			var newScaleY:Number = XMath.clamp(contentToScale.scaleY * sizeDiff, MIN_SCALE, MAX_SCALE);
			
			var scaleChanged:Boolean = (newScaleX != contentToScale.scaleX && newScaleY != contentToScale.scaleY);
			
			if(scaleChanged)
			{
				scaleContent(sizeDiff, sizeDiff, contentToScale);
				//find the difference between the location of the clicked point previous and current in global space
				var newGlobalPrevMouse:Point = contentToScale.localToGlobal(prevMouse);
				//offset by the differences
				contentToScale.x -= newGlobalPrevMouse.x - localMouse.x;
				contentToScale.y -= newGlobalPrevMouse.y - localMouse.y;
				if (contentToScale == content)
				{
					inactiveContent.x = content.x;
					inactiveContent.y = content.y;
					dispatchEvent(new MiniMapEvent(MiniMapEvent.VIEWSPACE_CHANGED, content.x, content.y, content.scaleX, m_currentLevel));
					var currentViewRect:Rectangle = getViewInContentSpace();
					m_currentLevel.updateLevelDisplay(currentViewRect);
				}
				checkGridSize();
					
			}
			
			if(lastScaleChanged == false || scaleChanged == false)
			{
				if(lastScaleChanged == false && scaleChanged != false)
					dispatchEvent(new MenuEvent(MenuEvent.RESET_ZOOM, null));
				else if(newScaleX == MIN_SCALE || newScaleY == MIN_SCALE)
				{
					dispatchEvent(new MenuEvent(MenuEvent.MAX_ZOOM_REACHED, null));
				}
				else
				{
					dispatchEvent(new MenuEvent(MenuEvent.MIN_ZOOM_REACHED, null));
				}
			}
			
			lastScaleChanged = scaleChanged;
		}
		
		private function moveContent(newX:Number, newY:Number, useGrid:Boolean = true):void
		{
			var contentToMove:DisplayObject = content;
			if (useGrid)
			{
				showZoomPanGrid();
				contentToMove = m_gridContainer;
			}
			newX = XMath.clamp(newX, m_currentLevel.m_boundingBox.x, m_currentLevel.m_boundingBox.x + m_currentLevel.m_boundingBox.width);
			newY = XMath.clamp(newY, m_currentLevel.m_boundingBox.y, m_currentLevel.m_boundingBox.y + m_currentLevel.m_boundingBox.height);
		//	trace("PAN ", newX, newY);
			panTo(newX, newY, contentToMove);
			var currentViewRect:Rectangle = getViewInContentSpace(contentToMove);
			if (contentToMove == content) m_currentLevel.updateLevelDisplay(currentViewRect);
			checkGridSize();
		}
		
		//max scale == min zoom
		public function atMinZoom(scale:Point = null):Boolean
		{
			if (!scale) scale = new Point(content.scaleX, content.scaleY);
			return ((scale.x >= MAX_SCALE) || (scale.y >= MAX_SCALE));
		}
		
		//min scale == max zoom
		public function atMaxZoom(scale:Point = null):Boolean
		{
			if (!scale) scale = new Point(content.scaleX, content.scaleY);
			return ((scale.x <= MIN_SCALE) || (scale.y <= MIN_SCALE));
		}
		
		private function isGridUp():Boolean { return (m_gridContainer && m_gridContainer.parent); }
		
		private function checkGridSize():void
		{
			if (!isGridUp()) return;
			var viewSpace:Rectangle = getViewInContentSpace(m_gridContainer);
			if (m_gridTileImg.x > viewSpace.x || 
				m_gridTileImg.x + m_gridTileImg.width < viewSpace.right ||
				m_gridTileImg.y > viewSpace.y || 
				m_gridTileImg.y + m_gridTileImg.height < viewSpace.bottom)
			{
				m_gridTileImg.x = viewSpace.x - 2 * viewSpace.width;
				m_gridTileImg.y = viewSpace.y - 2 * viewSpace.height;
				m_gridTileImg.width = 5 * viewSpace.width;
				m_gridTileImg.height = 5 * viewSpace.height;
				m_gridTileImg.textureScale = 1.0 / m_gridContainer.scaleX;
			}
		}
		
		private function showZoomPanGrid():void
		{
			if (!m_gridTexture) m_gridTexture = AssetInterface.getTexture("Game", "GridClass");
			if (!m_gridTileImg) m_gridTileImg = new TiledImage(m_gridTexture);
			if (!m_gridContainer)
			{
				m_gridContainer = new Sprite();
				m_gridContainer.addChild(m_gridTileImg);
			}
			if (!isGridUp()) // if not showing grid, show now and start the timer
			{
				var viewSpace:Rectangle = getViewInContentSpace();
				m_gridTileImg.x = viewSpace.x - 2 * viewSpace.width;
				m_gridTileImg.y = viewSpace.y - 2 * viewSpace.height;
				m_gridTileImg.width = 5 * viewSpace.width;
				m_gridTileImg.height = 5 * viewSpace.height;
				m_gridTileImg.textureScale = 1.0 / content.scaleX;
				m_gridContainer.scaleX = content.scaleX;
				m_gridContainer.scaleY = content.scaleY;
				m_gridContainer.x = content.x;
				m_gridContainer.y = content.y;
				addChildAt(m_gridContainer, getChildIndex(content) + 1);
				if (!m_zoomPanTimer) m_zoomPanTimer = new Timer(ZOOM_PAN_TIME_SEC * 1000.0, 1);
				m_zoomPanTimer.addEventListener(TimerEvent.TIMER_COMPLETE, hideZoomPanGridAndApplyChanges);
			}
			m_zoomPanTimer.reset(); // reset the timer (even if grid was already being shown)
			m_zoomPanTimer.start();
		}
		
		private function hideZoomPanGridAndApplyChanges(evt:TimerEvent):void
		{
			m_zoomPanTimer.removeEventListener(TimerEvent.TIMER_COMPLETE, hideZoomPanGridAndApplyChanges);
			content.scaleX = inactiveContent.scaleX = m_gridContainer.scaleX;
			content.scaleY = inactiveContent.scaleY = m_gridContainer.scaleY;
			content.x = inactiveContent.x = m_gridContainer.x;
			content.y = inactiveContent.y = m_gridContainer.y;
			
			dispatchEvent(new MiniMapEvent(MiniMapEvent.VIEWSPACE_CHANGED, content.x, content.y, content.scaleX, m_currentLevel));
			if (m_currentLevel)
			{
				var currentViewRect:Rectangle = getViewInContentSpace();
				m_currentLevel.updateLevelDisplay(currentViewRect);
			}
			m_gridContainer.removeFromParent();
		}
		
		/**
		 * Scale the content by the given scale factor (sizeDiff of 1.5 = 150% the original size)
		 * @param	sizeDiff Size difference factor, 1.5 = 150% of original size
		 */
		private function scaleContent(sizeDiffX:Number, sizeDiffY:Number, contentToScale:DisplayObject = null):void
		{
			if (contentToScale == null) contentToScale = content;
			m_selectionUpdated = (currentMode == SELECTING_MODE);
			var newScaleX:Number = XMath.clamp(contentToScale.scaleX * sizeDiffX, MIN_SCALE, MAX_SCALE);
			var newScaleY:Number = XMath.clamp(contentToScale.scaleY * sizeDiffY, MIN_SCALE, MAX_SCALE);
			
			if(newScaleX == contentToScale.scaleX || newScaleY == contentToScale.scaleY)
				return;
			
			//if we fit inside the current view, don't scale any more
			//var levelBounds:Rectangle = m_currentLevel.m_boundingBox;
			//if(newScaleX < oldScaleX && levelBounds.width*contentToScale.scaleX < clipRect.width 
					//&& levelBounds.height*contentToScale.scaleY < clipRect.height - 90)
				//return false;
			
			//if one of these got capped, scale the other proportionally
			if(newScaleX == MAX_SCALE || newScaleY == MAX_SCALE)
				if(newScaleX > newScaleY)
				{
					sizeDiffX = newScaleX/contentToScale.scaleX;
					newScaleY = contentToScale.scaleY*sizeDiffX;
				} else {
					sizeDiffX = newScaleX/contentToScale.scaleX;
					newScaleY = contentToScale.scaleY*sizeDiffX;
				}
			
			var origViewCoords:Rectangle = getViewInContentSpace(contentToScale);
			// Perform scaling
			var oldScale:Point = new Point(contentToScale.scaleX, contentToScale.scaleY);
			contentToScale.scaleX = newScaleX;
			contentToScale.scaleY = newScaleY;
			if (contentToScale == content)
			{
				inactiveContent.scaleX = contentToScale.scaleX;
				inactiveContent.scaleY = contentToScale.scaleY;
				onContentScaleChanged(oldScale);
			}
			
			var newViewCoords:Rectangle = getViewInContentSpace(contentToScale);
			// Adjust so that original centered point is still in the middle
			var dX:Number = origViewCoords.x + origViewCoords.width / 2 - (newViewCoords.x + newViewCoords.width / 2);
			var dY:Number = origViewCoords.y + origViewCoords.height / 2 - (newViewCoords.y + newViewCoords.height / 2);
			
			contentToScale.x -= dX * contentToScale.scaleX;
			contentToScale.y -= dY * contentToScale.scaleY;
			if (contentToScale == content)
			{
				inactiveContent.x = content.x;
				inactiveContent.y = content.y;
			}
			//trace("newscale:" + contentToScale.scaleX + "new xy:" + contentToScale.x + " " + contentToScale.y);
		}
		
		private function onContentScaleChanged(prevScale:Point):void
		{
			if (atMaxZoom()) {
				if (!atMaxZoom(prevScale))
					dispatchEvent(new MenuEvent(MenuEvent.MAX_ZOOM_REACHED));
			} else if (atMinZoom()) {
				if (!atMinZoom(prevScale))
					dispatchEvent(new MenuEvent(MenuEvent.MIN_ZOOM_REACHED));
			} else {
				if (atMaxZoom(prevScale) || atMinZoom(prevScale))
					dispatchEvent(new MenuEvent(MenuEvent.RESET_ZOOM));
			}
			
			if (m_currentLevel == null) return;
 			if ((content.scaleX < MIN_ERROR_TEXT_DISPLAY_SCALE) || (content.scaleY < MIN_ERROR_TEXT_DISPLAY_SCALE)) {
				m_currentLevel.hideErrorText();
 			} else {
				m_currentLevel.showErrorText();
 			}
		}
		
		private function getViewInContentSpace(contentToUse:DisplayObject = null):Rectangle
		{
			if (contentToUse == null) contentToUse = content;
			return new Rectangle(-contentToUse.x / contentToUse.scaleX, -contentToUse.y / contentToUse.scaleY, clipRect.width / contentToUse.scaleX, clipRect.height / contentToUse.scaleY);
		}
		
		private function onRemovedFromStage():void
		{
			removeEventListener(EnterFrameEvent.ENTER_FRAME, onEnterFrame);
			removeEventListener(MaxSatSolver.SOLVER_STARTED, onSolverStarted);
			removeEventListener(MaxSatSolver.SOLVER_STOPPED, onSolverStopped);
		}
		
		override public function dispose():void
		{
			if (m_disposed) {
				return;
			}
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
		}
		
		public function zoomOutDiscrete():void
		{
			handleMouseWheel(-5);
		}
		
		private function onKeyDown(event:KeyboardEvent):void
		{
			var viewRect:Rectangle, newX:Number, newY:Number;
			const MOVE_PX:Number = 5.0; // pixels to move when arrow keys pressed
			var contentToUse:DisplayObject = isGridUp() ? m_gridContainer : content;
			switch(event.keyCode)
			{
				case Keyboard.SHIFT:
					hidePaintBrush();
					break;
				case Keyboard.TAB:
					if (getPanZoomAllowed() && m_currentLevel) {
						var conflictLoc:Point = m_currentLevel.getNextConflictLocation(!event.shiftKey);
						if (conflictLoc != null) moveContent(conflictLoc.x, conflictLoc.y, false);
					}
					break;
				case Keyboard.UP:
				case Keyboard.W:
				case Keyboard.NUMPAD_8:
					if (getPanZoomAllowed()) {
						viewRect = getViewInContentSpace(contentToUse);
						newX = viewRect.x + viewRect.width / 2;
						newY = viewRect.y + viewRect.height / 2 - MOVE_PX / contentToUse.scaleY;
						moveContent(newX, newY);
					}
					break;
				case Keyboard.DOWN:
				case Keyboard.NUMPAD_2:
					if (getPanZoomAllowed()) {
						viewRect = getViewInContentSpace(contentToUse);
						newX = viewRect.x + viewRect.width / 2;
						newY = viewRect.y + viewRect.height / 2 + MOVE_PX / contentToUse.scaleY;
						moveContent(newX, newY);
					}
					break;
				case Keyboard.LEFT:
				case Keyboard.A:
				case Keyboard.NUMPAD_4:
					if (getPanZoomAllowed()) {
						viewRect = getViewInContentSpace(contentToUse);
						newX = viewRect.x + viewRect.width / 2 - MOVE_PX / contentToUse.scaleX;
						newY = viewRect.y + viewRect.height / 2;
						moveContent(newX, newY);
					}
					break;
				case Keyboard.RIGHT:
				case Keyboard.D:
				case Keyboard.NUMPAD_6:
					if (getPanZoomAllowed()) {
						viewRect = getViewInContentSpace(contentToUse);
						newX = viewRect.x + viewRect.width / 2 + MOVE_PX / contentToUse.scaleX;
						newY = viewRect.y + viewRect.height / 2;
						moveContent(newX, newY);
					}
					break;
				case Keyboard.C:
					if (event.ctrlKey) {
						World.m_world.solverDoneCallback("");
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
				case Keyboard.DELETE:
					if (m_currentLevel) m_currentLevel.onDeletePressed();
					break;
				case Keyboard.QUOTE:
					if (m_currentLevel)
						if(event.shiftKey)
							m_currentLevel.onUseSelectionPressed(MenuEvent.MAKE_SELECTION_WIDE);
						else
							m_currentLevel.onUseSelectionPressed(MenuEvent.MAKE_SELECTION_NARROW);
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
			switch(event.keyCode)
			{
				case Keyboard.SHIFT:
					showPaintBrush();
					break;
				case Keyboard.NUMBER_1:
				case Keyboard.NUMBER_2:
				case Keyboard.NUMBER_3:
				case Keyboard.NUMBER_4:
				case Keyboard.NUMBER_5:
					setPaintBrushSize(event.keyCode - Keyboard.NUMBER_1 + 1);
					break;
			}
		}
		
		private var m_boundingBoxDebug:Quad;
		private static const DEBUG_BOUNDING_BOX:Boolean = false;
		public function setupLevel(level:Level):void
		{
			m_continueButtonForced = false;
			removeFanfare();
			hideContinueButton();
			if (m_gridContainer) m_gridContainer.removeFromParent();
			if (m_zoomPanTimer) m_zoomPanTimer.stop();
			if(m_currentLevel != level)
			{
				if(m_currentLevel)
				{
					m_currentLevel.removeEventListener(TouchEvent.TOUCH, onTouch);
					m_currentLevel.removeEventListener(MiniMapEvent.VIEWSPACE_CHANGED, onLevelViewChanged);
					content.removeChild(m_currentLevel);
					if (m_currentLevel.tutorialManager) {
						m_currentLevel.tutorialManager.removeEventListener(TutorialEvent.SHOW_CONTINUE, displayContinueButton);
						m_currentLevel.tutorialManager.removeEventListener(TutorialEvent.NEW_TUTORIAL_TEXT, onTutorialTextChange);
						m_currentLevel.tutorialManager.removeEventListener(TutorialEvent.NEW_TOOLTIP_TEXT, onPersistentToolTipTextChange);
					}
				}
				m_currentLevel = level;
				
				var max:int = m_currentLevel.getMaxSelectableWidgets();
				TextFactory.getInstance().updateText(m_selectionLimitText, String(max));
				TextFactory.getInstance().updateAlign(m_selectionLimitText, 1, 1);
			}
			
			inactiveContent.removeChildren();
			//inactiveContent.addChild(m_currentLevel.inactiveLayer); // deprecated
			
			// Remove old error text containers and place new ones
			for (var errorEdgeId:String in m_errorTextBubbles) {
				var errorSprite:Sprite = m_errorTextBubbles[errorEdgeId];
				errorSprite.removeFromParent();
			}
			m_errorTextBubbles = new Dictionary();
			
			if (m_tutorialText) {
				m_tutorialText.removeFromParent(true);
				m_tutorialText = null;
			}
			for (var i:int = 0; i < m_persistentToolTips.length; i++) m_persistentToolTips[i].removeFromParent(true);
			m_persistentToolTips = new Vector.<ToolTipText>();
			
			content.addChild(m_currentLevel);
		}
		
		public function loadLevel():void
		{
			m_currentLevel.addEventListener(TouchEvent.TOUCH, onTouch);
			m_currentLevel.addEventListener(MiniMapEvent.VIEWSPACE_CHANGED, onLevelViewChanged);
			if (m_currentLevel.tutorialManager) {
				m_currentLevel.tutorialManager.addEventListener(TutorialEvent.SHOW_CONTINUE, displayContinueButton);
				m_currentLevel.tutorialManager.addEventListener(TutorialEvent.NEW_TUTORIAL_TEXT, onTutorialTextChange);
				m_currentLevel.tutorialManager.addEventListener(TutorialEvent.NEW_TOOLTIP_TEXT, onPersistentToolTipTextChange);
			}
			
			// Queue all nodes/edges to add (later we can refine to only on-screen
			//for (var nodeId:String in m_currentLevel.nodeLayoutObjs) {
				//var nodeLayoutObj:Object = m_currentLevel.nodeLayoutObjs[nodeId];
				//m_nodeLayoutQueue.push(nodeLayoutObj);
			//}
			//var edgeId:String;
			//for (edgeId in m_currentLevel.edgeLayoutObjs) {
				//var edgeLayoutObj:Object = m_currentLevel.edgeLayoutObjs[edgeId];
				//m_edgeLayoutQueue.push(edgeLayoutObj);
			//}
			onGameComponentsCreated();
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
				m_tutorialTextLayer.addChild(m_tutorialText);
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
				m_tutorialTextLayer.addChildAt(tip, 0);
				m_persistentToolTips.push(tip);
			}
		}
		
		private function onLevelViewChanged(evt:MiniMapEvent):void
		{
			// TODO: grid?
			dispatchEvent(new MiniMapEvent(MiniMapEvent.VIEWSPACE_CHANGED, content.x, content.y, content.scaleX, m_currentLevel));
		}
		
		public function recenter():void
		{
			// TODO: grid?
			m_selectionUpdated = (currentMode == SELECTING_MODE);
			content.x = 0;
			content.y = 0;
			inactiveContent.x = inactiveContent.y = 0;
			var oldScale:Point = new Point(content.scaleX, content.scaleY);
			content.scaleX = content.scaleY = STARTING_SCALE;
			inactiveContent.scaleX = inactiveContent.scaleY = STARTING_SCALE;
			onContentScaleChanged(oldScale);
			content.addChild(m_currentLevel);
			
			if (DEBUG_BOUNDING_BOX) {
				if (!m_boundingBoxDebug) {
					m_boundingBoxDebug = new Quad(m_currentLevel.m_boundingBox.width, m_currentLevel.m_boundingBox.height, 0xFFFF00);
					m_boundingBoxDebug.alpha = 0.2;
					m_boundingBoxDebug.touchable = false;
					content.addChildAt(m_boundingBoxDebug,0);
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
			const VIEW_HEIGHT:Number = HEIGHT - GameControlPanel.OVERLAP;
			
			centerPt = new Point(m_currentLevel.m_boundingBox.left + m_currentLevel.m_boundingBox.width / 2, m_currentLevel.m_boundingBox.top + m_currentLevel.m_boundingBox.height / 2);
			globPt = m_currentLevel.localToGlobal(centerPt);
			localPt = content.globalToLocal(globPt);
			moveContent(localPt.x, localPt.y, false);
			trace("center to: " + localPt);
			
			const BUFFER:Number = 1.5;
			var newScale:Number = Math.min((WIDTH - Constants.RightPanelWidth) / (BUFFER * m_currentLevel.m_boundingBox.width * content.scaleX),
				VIEW_HEIGHT / (BUFFER * m_currentLevel.m_boundingBox.height * content.scaleY));
			scaleContent(newScale, newScale, content);
			if (m_currentLevel && m_currentLevel.tutorialManager) {
				var startPtOffset:Point = m_currentLevel.tutorialManager.getStartPanOffset();
				content.x += startPtOffset.x;
				content.y += startPtOffset.y;
				inactiveContent.x = content.x;
				inactiveContent.y = content.y;
				newScale = STARTING_SCALE * m_currentLevel.tutorialManager.getStartScaleFactor();
				scaleContent(newScale, newScale);
			}
			dispatchEvent(new MiniMapEvent(MiniMapEvent.VIEWSPACE_CHANGED, content.x, content.y, content.scaleX, m_currentLevel));
		}
		
		private var m_fanfareContainer:Sprite = new Sprite();
		private var m_fanfare:Vector.<FanfareParticleSystem> = new Vector.<FanfareParticleSystem>();
		private var m_fanfareTextContainer:Sprite = new Sprite();
		private var m_stopFanfareDelayedCall:DelayedCall;
		public function displayContinueButton(permanently:Boolean = false, showFanfare:Boolean = true):void
		{
			if (permanently) m_continueButtonForced = true;
			if (!continueButton) {
				continueButton = ButtonFactory.getInstance().createDefaultButton("Next Level", 128, 32);
				continueButton.addEventListener(starling.events.Event.TRIGGERED, onNextLevelButtonTriggered);
				continueButton.x = WIDTH - continueButton.width - 50 - Constants.RightPanelWidth;
				continueButton.y = HEIGHT - continueButton.height - 2;
			}
			
			if(PipeJamGameScene.inTutorial)
				m_buttonLayer.addChild(continueButton);
			
			// Fanfare
			removeFanfare();
			if (showFanfare) {
				m_fanfareLayer.addChild(m_fanfareContainer);
				m_fanfareContainer.x = m_fanfareTextContainer.x = WIDTH / 2 - continueButton.width;
				m_fanfareContainer.y = m_fanfareTextContainer.y = continueButton.y - continueButton.height;
				
				var levelCompleteText:String = PipeJamGameScene.inTutorial ? "Level Complete!" : "Great work!\nBut keep playing to further improve your score."
				var textWidth:Number = PipeJamGameScene.inTutorial ? continueButton.width : 208;
				
				for (var i:int = 5; i <= textWidth - 5; i += 10) {
					var fanfare:FanfareParticleSystem = new FanfareParticleSystem();
					fanfare.x = i;
					fanfare.y = continueButton.height / 2;
					fanfare.scaleX = fanfare.scaleY = 0.4;
					m_fanfare.push(fanfare);
					m_fanfareContainer.addChild(fanfare);
				}
				
				startFanfare();
				const LEVEL_COMPLETE_TEXT_MOVE_SEC:Number = PipeJamGameScene.inTutorial ? 2.0 : 0.0;
				const LEVEL_COMPLETE_TEXT_FADE_SEC:Number = PipeJamGameScene.inTutorial ? 0.0 : 1.0;
				const LEVEL_COMPLETE_TEXT_PAUSE_SEC:Number = PipeJamGameScene.inTutorial ? 1.0 : 5.0;
				var textField:TextFieldWrapper = TextFactory.getInstance().createTextField(levelCompleteText, AssetsFont.FONT_UBUNTU, textWidth, continueButton.height, 16, Constants.BROWN);
				if (!PipeJam3.DISABLE_FILTERS) TextFactory.getInstance().updateFilter(textField, OutlineFilter.getOutlineFilter());
				m_fanfareTextContainer.addChild(textField);
				m_fanfareTextContainer.alpha = 1;
				m_fanfareLayer.addChild(m_fanfareTextContainer);
				
				if (PipeJamGameScene.inTutorial) {
					// For tutorial, move text and button off to the side
					var origX:Number = m_fanfareTextContainer.x;
					var origY:Number = m_fanfareTextContainer.y;
					for (i = 0; i < m_fanfare.length; i++) {
						Starling.juggler.tween(m_fanfare[i], LEVEL_COMPLETE_TEXT_MOVE_SEC, { delay:LEVEL_COMPLETE_TEXT_PAUSE_SEC, particleX:(continueButton.x - origX), particleY:(continueButton.y - continueButton.height - origY), transition:Transitions.EASE_OUT } );
					}
					Starling.juggler.tween(m_fanfareTextContainer, LEVEL_COMPLETE_TEXT_MOVE_SEC, { delay:LEVEL_COMPLETE_TEXT_PAUSE_SEC, x:continueButton.x, y:continueButton.y - continueButton.height, transition:Transitions.EASE_OUT } );
				} else {
					// For real levels, gradually fade out text
					Starling.juggler.tween(m_fanfareTextContainer, LEVEL_COMPLETE_TEXT_FADE_SEC, { delay:LEVEL_COMPLETE_TEXT_PAUSE_SEC, alpha: 0, transition:Transitions.EASE_IN } );
				}
				m_stopFanfareDelayedCall = Starling.juggler.delayCall(stopFanfare, LEVEL_COMPLETE_TEXT_PAUSE_SEC + LEVEL_COMPLETE_TEXT_MOVE_SEC + LEVEL_COMPLETE_TEXT_FADE_SEC - 0.5);
			} // end if showing fanfare
			
			if(PipeJamGameScene.inTutorial)
				TutorialController.getTutorialController().addCompletedTutorial(m_currentLevel.m_tutorialTag, true);
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
		
		public function removeFanfare():void
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
		
		public function hideContinueButton(forceOff:Boolean = false):void
		{
			if (forceOff) m_continueButtonForced = false;
			if (continueButton && !m_continueButtonForced) {
				continueButton.removeFromParent();
			}
		}
		
		private function onNextLevelButtonTriggered(evt:starling.events.Event):void
		{
			dispatchEvent(new NavigationEvent(NavigationEvent.SWITCH_TO_NEXT_LEVEL));
		}
		
		//calculates the relative point of the level's content and centers it
		public function moveToPoint(percentPoint:Point):void
		{
			var contentX:Number = m_currentLevel.m_boundingBox.x / scaleX + percentPoint.x * m_currentLevel.m_boundingBox.width / scaleX;
			var contentY:Number = m_currentLevel.m_boundingBox.y / scaleY + percentPoint.y * m_currentLevel.m_boundingBox.height / scaleY;

			moveContent(contentX, contentY);
		}
		
		/**
		 * Centers the current view on the given point (point is in content-space)
		 * @param	panX
		 * @param	panY
		 */
		public function panTo(panX:Number, panY:Number, contentToMove:DisplayObject):void
		{
			contentToMove.x = clipRect.width / 2 - panX * contentToMove.scaleX;
			contentToMove.y = clipRect.height / 2 - panY * contentToMove.scaleY;
			if (contentToMove == content)
			{
				inactiveContent.x = content.x;
				inactiveContent.y = content.y;
				dispatchEvent(new MiniMapEvent(MiniMapEvent.VIEWSPACE_CHANGED, content.x, content.y, content.scaleX, m_currentLevel));
			}
		}
		
		/**
		 * Centers the current view on the input component
		 * @param	component
		 */
		public function centerOnComponent(component:Object):void
		{
			m_startingTouchPoint = new Point(content.x, content.y);
			
			var centerPt:Point = new Point(component.width / 2, component.height / 2);
			var globPt:Point = component.localToGlobal(centerPt);
			var localPt:Point = content.globalToLocal(globPt);
			moveContent(localPt.x, localPt.y);
			
			var startPoint:Point = m_startingTouchPoint.clone();
			var endPoint:Point = new Point(content.x, content.y);
			var eventToUndo:MoveEvent = new MoveEvent(MoveEvent.MOUSE_DRAG, null, startPoint, endPoint);
			var eventToDispatch:UndoEvent = new UndoEvent(eventToUndo, this);
			dispatchEvent(eventToDispatch);
		}
		
		public override function handleUndoEvent(undoEvent:starling.events.Event, isUndo:Boolean = true):void
		{
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
			m_border.removeFromParent();
			
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
			addChildAt(this.m_border, 0);
			
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
		
		
		public function adjustSize(newWidth:Number, newHeight:Number):void
		{
			// TODO grid?
			clipRect = new Rectangle(x, y, newWidth, newHeight);
		
			if(contentBarrier)
				contentBarrier.removeFromParent()
			
			contentBarrier = new Quad(newWidth,newHeight, 0x00);
			contentBarrier.alpha = 0.01;
			contentBarrier.visible = true;
			addChildAt(contentBarrier, 0);
		}
		
		public function beginPaint():void
		{
			//trace("beginPaint()");
			m_currentLevel.unselectAll();
		}
		
		public function setFirstBrush(visibleBrushes:int):void
		{
			if(visibleBrushes & TutorialLevelManager.SOLVER_BRUSH)
			{
				changeBrush(GridViewPanel.FIRST_SOLVER_BRUSH);
				return;
			}
			
			if(visibleBrushes & TutorialLevelManager.WIDEN_BRUSH)
			{
				changeBrush(GridViewPanel.WIDEN_BRUSH);
				return;
			}
			
			if(visibleBrushes & TutorialLevelManager.NARROW_BRUSH)
			{
				changeBrush(GridViewPanel.NARROW_BRUSH);
				return;
			}
		}
		
		public function changeBrush(brushName:String):void
		{
			var brush:Sprite;
			
			if(brushName == GridViewPanel.SOLVER1_BRUSH)
			{
				brush = m_solver1Brush;
			}
			
			if(brushName == GridViewPanel.SOLVER2_BRUSH)
			{
				brush = m_solver2Brush;
			}
			else if(brushName == GridViewPanel.NARROW_BRUSH)
			{
				brush = m_narrowBrush;
			}
			else if(brushName == GridViewPanel.WIDEN_BRUSH)
			{
				brush = m_widenBrush;
			}
			
			if(brush == m_paintBrush || brush == null)
				return;
			
			var currentVisibility:Boolean = m_paintBrush.visible;
			if(m_paintBrush.parent)
				m_paintBrush.removeFromParent();
			m_paintBrush = brush;
			installPaintBrush(currentVisibility);
		}
		
		public function installPaintBrush(currentVisibility:Boolean):void
		{
			//trace("handlePaint(", globPt, ")");
			if (!parent) return;
			m_paintBrush.scaleX = m_paintBrushInfoSprite.scaleX = .5;
			m_paintBrush.scaleY = m_paintBrushInfoSprite.scaleY = .5;
			m_paintBrushLayer.addChild(m_paintBrush);
			m_paintBrushLayer.addChild(m_paintBrushInfoSprite);
			m_paintBrush.flatten();
			m_paintBrushInfoSprite.flatten();
			m_paintBrush.visible = currentVisibility;
			m_paintBrushInfoSprite.visible = currentVisibility;
			m_nextPaintbrushLocationUpdated = true;
		}
		
		private function setPaintBrushSize(size:int):void
		{
			m_paintBrush.scaleX = m_paintBrush.scaleY = size * .20;
			m_paintBrushInfoSprite.scaleX = m_paintBrushInfoSprite.scaleY = size*.20;
			m_paintBrush.flatten();
			m_paintBrushInfoSprite.flatten();
		}
		
		
		private var m_nextPaintbrushLocation:Point;
		private var m_nextPaintbrushLocationUpdated:Boolean = false;
		protected function movePaintBrush(pt:Point):void
		{
			m_nextPaintbrushLocation = globalToLocal(pt);
			m_nextPaintbrushLocationUpdated = true;
		}
		
		protected function showPaintBrush():void
		{
			m_paintBrush.visible = true;
			m_paintBrushInfoSprite.visible = true;
		}
		
		public function hidePaintBrush():void
		{
			m_paintBrush.visible = false;
			m_paintBrushInfoSprite.visible = false;
		}
		
		protected function handlePaint(globPt:Point):void
		{
			// TODO grid?
			var localPt:Point = m_currentLevel.globalToLocal(globPt);
			const dX:Number = PAINT_RADIUS * m_paintBrushInfoSprite.scaleX/content.scaleX;
			const dY:Number = PAINT_RADIUS * m_paintBrushInfoSprite.scaleY/content.scaleY;
			
			m_currentLevel.selectNodes(localPt, dX, dY);
		}
		
		protected function endPaint():void
		{
			//trace("endPaint()");
			//m_paintBrush.removeFromParent();
		}
		
		
		private function onSolverStarted():void
		{
			//start rotating
			var reverse:Boolean = false; //(Math.random() > .7) ? true : false; //just for variation..?
			Starling.juggler.tween(m_paintBrush, 4, {
				repeatCount: 0,
				reverse: reverse,
				rotation: 2*Math.PI
			});
		}
		
		private function onSolverStopped():void
		{
			Starling.juggler.removeTweens(m_paintBrush);
			Starling.juggler.tween(m_paintBrush, 0.2, {
				repeatCount: 1,
				reverse: false,
				rotation: 2*Math.PI,
				delay: .2
			});
		}
	}
}
