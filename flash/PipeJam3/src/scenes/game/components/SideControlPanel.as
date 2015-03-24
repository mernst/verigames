package scenes.game.components
{
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import assets.AssetInterface;
	import assets.AssetsFont;
	
	import display.BasicButton;
	import display.NineSliceButton;
	import display.RadioButton;
	import display.RadioButtonGroup;
	import display.RecenterButton;
	import display.SoundButton;
	import display.ZoomInButton;
	import display.ZoomOutButton;
	
	import events.MenuEvent;
	import events.NavigationEvent;
	import events.SelectionEvent;
	
	import scenes.BaseComponent;
	import scenes.game.display.Level;
	import scenes.game.display.NodeSkin;
	import scenes.game.display.TutorialLevelManager;
	
	import starling.animation.Transitions;
	import starling.core.Starling;
	import starling.display.DisplayObject;
	import starling.display.Image;
	import starling.display.Quad;
	import starling.display.Sprite;
	import starling.events.Event;
	import starling.events.Touch;
	import starling.events.TouchEvent;
	import starling.events.TouchPhase;
	import starling.textures.Texture;
	import starling.textures.TextureAtlas;
	
	import utils.XSprite;
	
	public class SideControlPanel extends BaseComponent
	{
		protected var WIDTH:Number;
		protected var HEIGHT:Number;
		
		public static const OVERLAP:Number = 2;
		
		/** Button to bring the up the menu */
		private var m_menuButton:NineSliceButton;
		
		protected var scoreCircleMiddleImage:Image;
		protected var scoreCircleFrontImage:Image;
		protected var scoreImageCenter:Point;
		/** Navigation buttons */
		private var m_zoomInButton:BasicButton;
		private var m_zoomOutButton:BasicButton;
		
		protected var m_solver1Brush:RadioButton;
		protected var m_solver2Brush:RadioButton;
		protected var m_widenBrush:RadioButton;
		protected var m_narrowBrush:RadioButton;
		protected var m_brushButtonGroup:RadioButtonGroup;
		
		/** Text showing current score */
		private var m_scoreTextfield:TextFieldWrapper;

		/** Text showing best score */
		private var m_bestTextfield:TextFieldWrapper;
		
		private var addSolverArray:Array = [1,0,1,1];

		
		public function SideControlPanel( _width:Number, _height:Number)
		{
			WIDTH = _width;
			HEIGHT = _height;
			
			var atlas:TextureAtlas = AssetInterface.getTextureAtlas("Game", "ParadoxSpriteSheetPNG", "ParadoxSpriteSheetXML");
			
			var scoreCircleBackTexture:Texture = atlas.getTexture(AssetInterface.ParadoxSubTexture_ScoreCircleBack);
			var scoreCircleMiddleTexture:Texture = atlas.getTexture(AssetInterface.ParadoxSubTexture_ScoreCircleMiddle);
			var scoreCircleFrontTexture:Texture = atlas.getTexture(AssetInterface.ParadoxSubTexture_ScoreCircleFront);
			
			var scoreCircleBackImage:Image = new Image(scoreCircleBackTexture);
			scoreCircleBackImage.scaleX = scoreCircleBackImage.scaleY = 0.5;
			scoreCircleBackImage.x = 6.25;
			scoreCircleBackImage.y = 18.75;
			addChild(scoreCircleBackImage);
			
			scoreCircleMiddleImage = new Image(scoreCircleMiddleTexture);
			scoreCircleMiddleImage.x = 6.25;
			scoreCircleMiddleImage.y = 18.75;
			scoreCircleMiddleImage.scaleX = scoreCircleMiddleImage.scaleY = 0.5;
			addChild(scoreCircleMiddleImage);
			
			scoreCircleFrontImage = new Image(scoreCircleFrontTexture);
			scoreCircleFrontImage.x = 19;
			scoreCircleFrontImage.y = 32.5;
			scoreCircleFrontImage.scaleX = scoreCircleFrontImage.scaleY = 0.5;
			addChild(scoreCircleFrontImage);
			
			scoreImageCenter = new Point(scoreCircleFrontImage.x + scoreCircleFrontImage.width/2, 
												scoreCircleFrontImage.y + scoreCircleFrontImage.height/2)
			
			var background:Texture = atlas.getTexture(AssetInterface.ParadoxSubTexture_Sidebar);
			var backgroundImage:Image = new Image(background);
			backgroundImage.scaleX = backgroundImage.scaleY = 0.5;
			addChild(backgroundImage);
			
			m_menuButton = ButtonFactory.getInstance().createButton(PipeJam3.TUTORIAL_DEMO ? "Level Select" : "Menu", 44, 14, 8, 8, "Return to the main menu");
			m_menuButton.addEventListener(starling.events.Event.TRIGGERED, onMenuButtonTriggered);
			m_menuButton.x = 59;
			m_menuButton.y = 23;
			m_menuButton.scaleX = .8;
			//m_menuButton.scaleY = .8;
			
			var logo:Texture = atlas.getTexture(AssetInterface.ParadoxSubTexture_ParadoxLogoWhiteSmall);
			var logoImage:Image = new Image(logo);
			logoImage.x = m_menuButton.x;
			logoImage.y = 5;
			logoImage.width = m_menuButton.width;
			logoImage.scaleY = logoImage.scaleX;
			addChild(logoImage);
			
			m_scoreTextfield = TextFactory.getInstance().createTextField("0%", AssetsFont.FONT_UBUNTU, 50, 2.0 * 20, 30, 0xFFFFFF);
			m_scoreTextfield.touchable = false;
			m_scoreTextfield.x = 44;
			m_scoreTextfield.y = 44;
			TextFactory.getInstance().updateAlign(m_scoreTextfield, 2, 1);
			addChild(m_scoreTextfield);
			
			m_zoomInButton = new ZoomInButton();
			m_zoomInButton.addEventListener(starling.events.Event.TRIGGERED, onZoomInButtonTriggered);
			m_zoomInButton.scaleX = m_zoomInButton.scaleY = 0.6;
			XSprite.setPivotCenter(m_zoomInButton);
			m_zoomInButton.x = 24;
			m_zoomInButton.y = MiniMap.TOP_Y + 4.5;
			
			m_zoomOutButton = new ZoomOutButton();
			m_zoomOutButton.addEventListener(starling.events.Event.TRIGGERED, onZoomOutButtonTriggered);
			m_zoomOutButton.scaleX = m_zoomOutButton.scaleY = m_zoomInButton.scaleX;
			XSprite.setPivotCenter(m_zoomOutButton);
			m_zoomOutButton.x = m_zoomInButton.x;
			m_zoomOutButton.y = m_zoomInButton.y + m_zoomInButton.height + 7;
			
			m_brushButtonGroup = new RadioButtonGroup();
			addChild(m_brushButtonGroup);
			m_brushButtonGroup.y = 115;
			m_brushButtonGroup.x = 40;
			m_solver1Brush = createPaintBrushButton(GridViewPanel.SOLVER1_BRUSH, changeCurrentBrush, false, "Optimize") as RadioButton;
			m_solver2Brush = createPaintBrushButton(GridViewPanel.SOLVER2_BRUSH, changeCurrentBrush, false, "Optimize") as RadioButton;
			m_widenBrush = createPaintBrushButton(GridViewPanel.WIDEN_BRUSH, changeCurrentBrush, false, "Make Wide") as RadioButton;
			m_narrowBrush = createPaintBrushButton(GridViewPanel.NARROW_BRUSH, changeCurrentBrush, false, "Make Narrow") as RadioButton;

			
			//set all to visible == false so that they don't flash on, before being turned off
			var currentY:Number = 0;
			m_solver1Brush.scaleX = m_solver1Brush.scaleY = .5;
			m_solver1Brush.x = 25;
			m_solver1Brush.y = currentY;
			
			m_solver1Brush.visible = false;
			if(addSolverArray[0] == 1)
			{
				currentY += 30;
				m_brushButtonGroup.addChild(m_solver1Brush);
				GridViewPanel.FIRST_SOLVER_BRUSH = GridViewPanel.SOLVER1_BRUSH;
				m_brushButtonGroup.makeActive(m_solver1Brush);
			}
			else
				GridViewPanel.FIRST_SOLVER_BRUSH = GridViewPanel.SOLVER2_BRUSH;
			
			//brush icons are different widths, so line up centers
			var brushCenter:Number = m_solver1Brush.x + m_solver1Brush.width/2;
			m_solver2Brush.scaleX = m_solver2Brush.scaleY = m_solver1Brush.scaleX;
			m_solver2Brush.x = brushCenter - m_solver2Brush.width/2;
			m_solver2Brush.y = currentY;
			m_solver2Brush.visible = false;
			if(addSolverArray[1] == 1)
			{
				m_brushButtonGroup.addChild(m_solver2Brush);
				currentY += 30;
			}
			m_widenBrush.scaleX = m_widenBrush.scaleY = m_solver1Brush.scaleX;
			m_widenBrush.x = brushCenter - m_widenBrush.width/2;
			m_widenBrush.y = currentY;
			m_widenBrush.visible = false;
			if(addSolverArray[2] == 1)
			{
				m_brushButtonGroup.addChild(m_widenBrush);
				currentY += 30;
			}
			m_narrowBrush.scaleX = m_narrowBrush.scaleY = m_solver1Brush.scaleX;
			m_narrowBrush.x = brushCenter - m_narrowBrush.width/2;
			m_narrowBrush.y = currentY;
			m_narrowBrush.visible = false;
			if(addSolverArray[3] == 1)
				m_brushButtonGroup.addChild(m_narrowBrush);
			
			this.addEventListener(starling.events.Event.ADDED_TO_STAGE, addedToStage);
			//
		}
		
		public function addedToStage(event:starling.events.Event):void
		{
			addChild(m_menuButton);
			addChild(m_zoomInButton);
			addChild(m_zoomOutButton);
			addEventListener(TouchEvent.TOUCH, onTouch);
			this.removeEventListener(starling.events.Event.ADDED_TO_STAGE, addedToStage);
			this.addEventListener(starling.events.Event.REMOVED_FROM_STAGE, removedFromStage);
		}
		
		public function addSoundButton(m_sfxButton:SoundButton):void
		{
			m_sfxButton.scaleX = m_sfxButton.scaleY = m_zoomInButton.scaleX;
			m_sfxButton.x = m_zoomInButton.x - 3.5;
			m_sfxButton.y = m_zoomOutButton.y + m_zoomOutButton.height + 3.5;
			var test:Point = localToGlobal(new Point(m_sfxButton.x, m_sfxButton.y));
			addChild(m_sfxButton);
			
		}
		
		//min scale == max zoom
		public function onMaxZoomReached():void
		{
			if (m_zoomInButton) m_zoomInButton.enabled = true;
			if (m_zoomOutButton) m_zoomOutButton.enabled = false;
		}
		
		public function onMinZoomReached():void
		{
			if (m_zoomInButton) m_zoomInButton.enabled = false;
			if (m_zoomOutButton) m_zoomOutButton.enabled = true;
		}
		
		public function onZoomReset():void
		{
			if (m_zoomInButton) m_zoomInButton.enabled = true;
			if (m_zoomOutButton) m_zoomOutButton.enabled = true;
		}
		
		public function newLevelSelected(level:Level):void 
		{
//			m_currentLevel = level;
//			updateScore(level, true);
//			TextFactory.getInstance().updateText(m_levelNameTextfield, level.level_name);
//			TextFactory.getInstance().updateAlign(m_levelNameTextfield, 1, 1);
//			setNavigationButtonVisibility(level.getPanZoomAllowed());
//			setSolveButtonsVisibility(level.getAutoSolveAllowed());
//			updateNumNodesSelectedDisplay();
			
			m_brushButtonGroup.resetGroup();
		}
		
		public function removedFromStage(event:starling.events.Event):void
		{
			removeEventListener(starling.events.Event.REMOVED_FROM_STAGE, removedFromStage);
		}
		
		protected var inTransparentArea:Boolean = false;
		override protected function onTouch(event:TouchEvent):void
		{
			//handle touches in transparent part, since starling doesn't
			var touch:Touch;
			var loc:Point;
			var eventType:String;
			if (event.getTouches(this, TouchPhase.HOVER).length)
			{
				touch = event.getTouches(this, TouchPhase.HOVER)[0];
				eventType = MouseEvent.MOUSE_MOVE;
			}
			else if(event.getTouches(this, TouchPhase.BEGAN).length)
			{
				touch = event.getTouches(this, TouchPhase.BEGAN)[0];
				eventType =TouchPhase.BEGAN;
			}
			else if(event.getTouches(this, TouchPhase.MOVED).length)
			{
				touch = event.getTouches(this, TouchPhase.MOVED)[0];
				eventType = TouchPhase.MOVED;
			}
			else if(event.getTouches(this, TouchPhase.ENDED).length)
			{
				touch = event.getTouches(this, TouchPhase.ENDED)[0];
				eventType = TouchPhase.ENDED;
			}
			
			if(touch)
				loc = new Point(touch.globalX, touch.globalY);
			
			if(touch && loc && (loc.x < 398 || (loc.x < 431 && loc.y < 250)))
			{
				inTransparentArea = true;
				dispatchEvent(new starling.events.Event(eventType,  true,  loc));
			}
			else
				inTransparentArea = false;
			
		}
		
		private function onMenuButtonTriggered():void
		{
			if (PipeJam3.TUTORIAL_DEMO) {
				dispatchEvent(new NavigationEvent(NavigationEvent.SHOW_GAME_MENU));
			} else {
				dispatchEvent(new NavigationEvent(NavigationEvent.CHANGE_SCREEN, "SplashScreen"));
			}
		}
		
		private function onZoomInButtonTriggered():void
		{
			dispatchEvent(new MenuEvent(MenuEvent.ZOOM_IN));
		}
		
		private function onZoomOutButtonTriggered():void
		{
			dispatchEvent(new MenuEvent(MenuEvent.ZOOM_OUT));
		}
		
		/**
		 * Updates the score on the screen
		 */
		public function updateScore(level:Level, skipAnimatons:Boolean):void 
		{
			var maxConflicts:int = level.maxScore;
			var currentConflicts:int = MiniMap.numConflicts;
			var score:Number = ((maxConflicts-currentConflicts)/maxConflicts)*100;
			var integerPart:int = Math.floor(score);
			var decimalPart:int = (score - integerPart) * 100;
			
			var currentScore:String = score.toFixed(2) + '%';
			trace("conflict count", maxConflicts, currentConflicts, currentScore);
			
			TextFactory.getInstance().updateText(m_scoreTextfield, currentScore);
			TextFactory.getInstance().updateAlign(m_scoreTextfield, 2, 1);
			
			var integerRotation:Number = -(100-integerPart)*1.8; //180/100
			var decimalRotation:Number = -(100-decimalPart)*1.8;
			rotateAroundCenter(scoreCircleMiddleImage, integerRotation);
			rotateAroundCenter(scoreCircleFrontImage, decimalRotation);
			
			
		}
		
		protected var degConversion:Number = (Math.PI/180);
		public function rotateAroundCenter (image:Image, angleDegrees:Number):void 
		{
			image.rotation = degConversion*angleDegrees;
			var newXCenter:Number = image.bounds.left + (image.bounds.right - image.bounds.left)/2;
			var newYCenter:Number = image.bounds.top + (image.bounds.bottom - image.bounds.top)/2;
			image.x += scoreImageCenter.x - newXCenter;
			image.y += scoreImageCenter.y - newYCenter;
		}
		
		private function changeCurrentBrush(evt:starling.events.Event):void
		{
			dispatchEvent(new SelectionEvent(SelectionEvent.BRUSH_CHANGED, evt.target, null));
		}
		
		public function showVisibleBrushes(visibleBrushes:int):void
		{
			var count:int = 0;
			m_solver1Brush.visible = visibleBrushes & TutorialLevelManager.SOLVER_BRUSH ? true : false;
			if(m_solver1Brush.visible) count++;
			m_solver2Brush.visible = visibleBrushes & TutorialLevelManager.SOLVER_BRUSH ? true : false;
			if(m_solver2Brush.visible) count++;
			m_narrowBrush.visible = visibleBrushes & TutorialLevelManager.WIDEN_BRUSH ? true : false;
			if(m_narrowBrush.visible) count++;
			m_widenBrush.visible = visibleBrushes & TutorialLevelManager.NARROW_BRUSH ? true : false;
			if(m_widenBrush.visible) count++;
			
			//if only one shows, hide them all
			if(count == 1)
				m_solver1Brush.visible = m_solver2Brush.visible = m_narrowBrush.visible = m_widenBrush.visible = false;
		}
	}
}