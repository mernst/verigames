package scenes.game.components
{
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import assets.AssetInterface;
	import assets.AssetsFont;
	
	import display.BasicButton;
	import display.NineSliceButton;
	import display.RecenterButton;
	import display.TextBubble;
	import display.ZoomInButton;
	import display.ZoomOutButton;
	
	import events.MenuEvent;
	import events.NavigationEvent;
	
	import particle.ErrorParticleSystem;
	
	import scenes.BaseComponent;
	import scenes.game.PipeJamGameScene;
	import scenes.game.display.GameComponent;
	import scenes.game.display.GameEdgeContainer;
	import scenes.game.display.World;
	import scenes.game.display.Level;
	
	import starling.animation.Transitions;
	import starling.core.Starling;
	import starling.display.Image;
	import starling.display.Quad;
	import starling.display.Sprite;
	import starling.events.Event;
	import starling.events.TouchEvent;
	import starling.events.TouchPhase;
	import starling.textures.Texture;
	import starling.textures.TextureAtlas;
	
	import utils.XSprite;
	
	public class GameControlPanel extends BaseComponent
	{
		private static const WIDTH:Number = Constants.GameWidth;
		public static const HEIGHT:Number = 82 - 20;
		
		public static const OVERLAP:Number = 44 - 10;
		public static const SCORE_PANEL_AREA:Rectangle = new Rectangle(108, 18, 284 - 10, 34);
		private static const SCORE_PANEL_MAX_SCALEY:Number = 1.5;
		
		/** Graphical object showing user's score */
		private var m_scorePanel:BaseComponent;
		
		/** Graphical object, child of scorePanel to hold scorebar */
		private var m_scoreBarContainer:Sprite;
		
		/** Indicate the current score */
		private var m_scoreBar:Quad;
		
		/** Text showing current score on score_pane */
		private var m_scoreTextfield:TextFieldWrapper;
		
		/** Text showing current score on score_pane */
		private var m_levelNameTextfield:TextFieldWrapper;
		
		/** Button to bring the up the menu */
		private var m_menuButton:NineSliceButton;
		
		/** Button to solve the selected nodes */
		private var m_solveButton:NineSliceButton;
		
		/** Button to start the level over */
		private var m_resetButton:NineSliceButton;
		
		/** Button to save the level */
		private var m_saveButton:NineSliceButton;
		
		/** Button to share the level */
		private var m_shareButton:NineSliceButton;

		/** Navigation buttons */
		private var m_zoomInButton:BasicButton;
		private var m_zoomOutButton:BasicButton;
		private var m_recenterButton:BasicButton;
		
		private var menuShowing:Boolean = false;
		
		/** Goes over the scorebar but under the menu, transparent in scorebar area */
		private var m_scorebarForeground:Image;
		
		/** Display the target score the player is looking to beat for the level */
		private var m_targetScoreLine:TargetScoreDisplay;
		
		/** Display the best score the player has achieved this session for the level */
		private var m_bestPlayerScoreLine:TargetScoreDisplay;
		
		/** Display the last saved score by this player for this level */
		private var m_lastSavedScoreLine:TargetScoreDisplay;
		
		/** Display the current best score for this level */
		private var m_bestScoreLine:TargetScoreDisplay;
		
		public function GameControlPanel()
		{
			this.addEventListener(Event.ADDED_TO_STAGE, addedToStage);
			this.addEventListener(Event.REMOVED_FROM_STAGE, removedFromStage);
		}
		
		public function addedToStage(event:Event):void
		{
			var atlas:TextureAtlas = AssetInterface.getTextureAtlas("Game", "PipeJamSpriteSheetPNG", "PipeJamSpriteSheetXML");
			var foregroundTexture:Texture = atlas.getTexture(AssetInterface.PipeJamSubTexture_ScoreBarForeground);
			m_scorebarForeground = new Image(foregroundTexture);
			m_scorebarForeground.touchable = false;
			m_scorebarForeground.width = WIDTH;
			m_scorebarForeground.height = HEIGHT;
			addChild(m_scorebarForeground);
			
			m_scorePanel = new BaseComponent();
			m_scorePanel.x = SCORE_PANEL_AREA.x;
			m_scorePanel.y = SCORE_PANEL_AREA.y; 
			var quad:Quad = new Quad(SCORE_PANEL_AREA.width + 10, SCORE_PANEL_AREA.height, 0x231F20);
			m_scorePanel.addChild(quad);
			addChildAt(m_scorePanel, 0);
			
			m_scoreBarContainer = new Sprite();
			m_scorePanel.addChild(m_scoreBarContainer);
			var topLeftScorePanel:Point = m_scorePanel.localToGlobal(new Point(0, 0));
			m_scorePanel.clipRect = new Rectangle(topLeftScorePanel.x, topLeftScorePanel.y, m_scorePanel.width, m_scorePanel.height);
			
			m_scoreTextfield = TextFactory.getInstance().createTextField("0", AssetsFont.FONT_UBUNTU, SCORE_PANEL_AREA.width, 2.0 * SCORE_PANEL_AREA.height / 3.0, 2.0 * SCORE_PANEL_AREA.height / 3.0, GameComponent.SCORE_COLOR);
			m_scoreTextfield.touchable = false;
			m_scoreTextfield.x = (SCORE_PANEL_AREA.width - m_scoreTextfield.width) / 2 ;
			m_scoreTextfield.y = SCORE_PANEL_AREA.height / 6.0;
			TextFactory.getInstance().updateAlign(m_scoreTextfield, 2, 1);
			m_scorePanel.addChild(m_scoreTextfield);
			
			// Top shadow over score panel
			var shadowOverlay:Quad = new Quad(SCORE_PANEL_AREA.width, 10, 0x0);
			shadowOverlay.setVertexAlpha(2, 0);
			shadowOverlay.setVertexAlpha(3, 0);
			shadowOverlay.touchable = false;
			m_scorePanel.addChild(shadowOverlay);
			
			m_levelNameTextfield = TextFactory.getInstance().createTextField("", AssetsFont.FONT_UBUNTU, WIDTH - 2, 10, 10, GameComponent.WIDE_COLOR);
			m_levelNameTextfield.touchable = false;
			m_levelNameTextfield.x = 0;
			m_levelNameTextfield.y = -10;
			TextFactory.getInstance().updateAlign(m_levelNameTextfield, 2, 0);
			addChild(m_levelNameTextfield);
			
			m_menuButton = ButtonFactory.getInstance().createButton("New Level", 44, 14, 8, 8, "Start a new level");
			m_menuButton.addEventListener(Event.TRIGGERED, onMenuButtonTriggered);
			m_menuButton.x = (SCORE_PANEL_AREA.x - m_menuButton.width) / 2 - 2;
			m_menuButton.y = HEIGHT/2 - m_menuButton.height/2;
			addChild(m_menuButton);
			
			m_resetButton = ButtonFactory.getInstance().createButton("Reset", 35, 14, 8, 8, "Reset the board to\nits starting condition");
			m_resetButton.addEventListener(Event.TRIGGERED, onStartOverButtonTriggered);
			m_resetButton.x = m_menuButton.x + (m_menuButton.width - m_resetButton.width);
			m_resetButton.y = m_menuButton.y + m_menuButton.height + 3;
			addChild(m_resetButton);
			
			m_zoomInButton = new ZoomInButton();
			m_zoomInButton.addEventListener(Event.TRIGGERED, onZoomInButtonTriggered);
			m_zoomInButton.scaleX = m_zoomInButton.scaleY = 0.5;
			XSprite.setPivotCenter(m_zoomInButton);
			m_zoomInButton.x = WIDTH - 61;
			m_zoomInButton.y = 10;
			addChild(m_zoomInButton);
			
			m_zoomOutButton = new ZoomOutButton();
			m_zoomOutButton.addEventListener(Event.TRIGGERED, onZoomOutButtonTriggered);
			m_zoomOutButton.scaleX = m_zoomOutButton.scaleY = 0.5;
			XSprite.setPivotCenter(m_zoomOutButton);
			m_zoomOutButton.x = m_zoomInButton.x + m_zoomInButton.width + 4;
			m_zoomOutButton.y = m_zoomInButton.y;
			addChild(m_zoomOutButton);
			
			m_recenterButton = new RecenterButton();
			m_recenterButton.addEventListener(Event.TRIGGERED, onRecenterButtonTriggered);
			m_recenterButton.scaleX = m_recenterButton.scaleY = 0.5;
			XSprite.setPivotCenter(m_recenterButton);
			m_recenterButton.x = m_zoomOutButton.x + m_zoomOutButton.width + 4;
			m_recenterButton.y = m_zoomOutButton.y
			addChild(m_recenterButton);
			
			m_solveButton = ButtonFactory.getInstance().createButton("Solve Selection", 54, 14, 8, 8, "Autosolve the current selection");
			m_solveButton.addEventListener(Event.TRIGGERED, onSolveSelection);
			m_solveButton.x = m_zoomOutButton.x + m_zoomOutButton.width*0.5 - m_solveButton.width*0.5 - 3; //center around zoomOut center
			m_solveButton.y = 25;
			addChild(m_solveButton);
		}
		
		private function onMenuButtonTriggered():void
		{
			dispatchEvent(new NavigationEvent(NavigationEvent.GET_RANDOM_LEVEL));
		}
		
		private function onStartOverButtonTriggered():void
		{
			dispatchEvent(new NavigationEvent(NavigationEvent.START_OVER));
		}

		private function onZoomInButtonTriggered():void
		{
			dispatchEvent(new MenuEvent(MenuEvent.ZOOM_IN));
		}
		
		private function onZoomOutButtonTriggered():void
		{
			dispatchEvent(new MenuEvent(MenuEvent.ZOOM_OUT));
		}
		
		private function onRecenterButtonTriggered():void
		{
			dispatchEvent(new MenuEvent(MenuEvent.RECENTER));
		}
		
		private function onShareButtonTriggered():void
		{
			dispatchEvent(new MenuEvent(MenuEvent.POST_SUBMIT_DIALOG));
		}
		
		private function onSaveButtonTriggered():void
		{
			dispatchEvent(new MenuEvent(MenuEvent.POST_SAVE_DIALOG));
			
		}
		
		public function onMaxZoomReached():void
		{
			if (m_zoomInButton) m_zoomInButton.enabled = false;
			if (m_zoomOutButton) m_zoomOutButton.enabled = true;
		}
		
		public function onMinZoomReached():void
		{
			if (m_zoomInButton) m_zoomInButton.enabled = true;
			if (m_zoomOutButton) m_zoomOutButton.enabled = false;
		}
		
		public function onZoomReset():void
		{
			if (m_zoomInButton) m_zoomInButton.enabled = true;
			if (m_zoomOutButton) m_zoomOutButton.enabled = true;
		}
		
		private function onSolveSelection():void
		{
			dispatchEvent(new MenuEvent(MenuEvent.SOLVE_SELECTION));
		}
		
		public function removedFromStage(event:Event):void
		{
			//TODO what? dispose of things?
		}
		
		public function newLevelSelected(level:Level):void 
		{
			updateScore(level, true);
			TextFactory.getInstance().updateText(m_levelNameTextfield, level.original_level_name);
			TextFactory.getInstance().updateAlign(m_levelNameTextfield, 2, 0);
			setNavigationButtonVisibility(level.getPanZoomAllowed());
		//	setSharingButtonVisibility(!PipeJamGameScene.inTutorial);
		}

		private function setNavigationButtonVisibility(viz:Boolean):void
		{
			m_zoomInButton.visible = viz;
			m_zoomOutButton.visible = viz;
			m_recenterButton.visible = viz;
		}
		
		private function setSharingButtonVisibility(viz:Boolean):void
		{
		//	m_saveButton.visible = viz;
		//	m_shareButton.visible = viz;
		}
		
		/**
		 * Updates the score on the screen
		 */
		public function updateScore(level:Level, skipAnimatons:Boolean):void 
		{
			var currentScore:int = level.currentScore;
			var bestScore:int = level.bestScore;
			var targetScore:int = level.getTargetScore();
			var maxScoreShown:Number = Math.max(currentScore, bestScore);
			maxScoreShown = Math.max(1, maxScoreShown); // avoid divide by zero
			if (targetScore < int.MAX_VALUE) maxScoreShown = Math.max(maxScoreShown, targetScore);
			
			TextFactory.getInstance().updateText(m_scoreTextfield, currentScore.toString());
			TextFactory.getInstance().updateAlign(m_scoreTextfield, 2, 1);
			
			// Aim for max score shown to be 2/3 of the width of the scorebar area
			var newBarWidth:Number = (SCORE_PANEL_AREA.width * 2 / 3) * Math.max(0, currentScore) / maxScoreShown;
			var bestScoreX:Number = (SCORE_PANEL_AREA.width * 2 / 3) * Math.max(0, bestScore) / maxScoreShown;
			var newScoreX:Number = newBarWidth - m_scoreTextfield.width;
			if (!m_scoreBar) {
				m_scoreBar = new Quad(Math.max(1, newBarWidth), 2.0 * SCORE_PANEL_AREA.height / 3.0, GameComponent.NARROW_COLOR);
				m_scoreBar.setVertexColor(2, GameComponent.WIDE_COLOR);
				m_scoreBar.setVertexColor(3, GameComponent.WIDE_COLOR);
				m_scoreBar.y = SCORE_PANEL_AREA.height / 6.0;
				m_scoreTextfield.x = newScoreX;
			}
			m_scoreBarContainer.addChild(m_scoreBar);
			
			if (targetScore < int.MAX_VALUE) {
				if (!m_targetScoreLine) {
					m_targetScoreLine = new TargetScoreDisplay(targetScore.toString(), 0.65 * GameControlPanel.SCORE_PANEL_AREA.height, TextBubble.GOLD, TextBubble.GOLD, "Target Score");
				} else {
					m_targetScoreLine.update(targetScore.toString());
				}
				m_targetScoreLine.x = (SCORE_PANEL_AREA.width * 2.0 / 3.0) * targetScore / maxScoreShown;
				m_scoreBarContainer.addChild(m_targetScoreLine);
				m_scoreBarContainer.visible = true;
				m_scoreTextfield.visible = true;
			} else {
				if (m_targetScoreLine) m_targetScoreLine.removeFromParent();
				if (m_scoreBarContainer) m_scoreBarContainer.visible = false;
				m_scoreTextfield.visible = false;
			}
			
			if (!m_bestPlayerScoreLine) {
				m_bestPlayerScoreLine = new TargetScoreDisplay(bestScore.toString(), 0.35 * GameControlPanel.SCORE_PANEL_AREA.height, GameComponent.WIDE_COLOR, GameComponent.WIDE_COLOR, "Best Score\nClick to Load");
				m_bestPlayerScoreLine.addEventListener(TouchEvent.TOUCH, onTouchBestScore);
				m_bestPlayerScoreLine.useHandCursor = true;
				m_bestPlayerScoreLine.x = bestScoreX;
			} else {
				m_bestPlayerScoreLine.update(bestScore.toString());
			}
			m_bestPlayerScoreLine.alpha = 0.8;
			m_scoreBarContainer.addChild(m_bestPlayerScoreLine);
			
			if (newBarWidth < SCORE_PANEL_AREA.width / 10) {
				// If bar is not wide enough, put the text to the right of it instead of inside the bar
				TextFactory.getInstance().updateColor(m_scoreTextfield, 0xFFFFFF);
				newScoreX = -m_scoreTextfield.width + SCORE_PANEL_AREA.width / 10;
			} else {
				TextFactory.getInstance().updateColor(m_scoreTextfield, 0x0);
			}
			
			var FLASHING_ANIM_SEC:Number = 0; // TODO: make this nonzero when animation is in place
			var DELAY:Number = 0.5;
			var BAR_SLIDING_ANIM_SEC:Number = 1.0;
			if (skipAnimatons) {
				Starling.juggler.removeTweens(m_scoreBar);
				m_scoreBar.width = newBarWidth;
				Starling.juggler.removeTweens(m_scoreTextfield);
				m_scoreTextfield.x = newScoreX;
				Starling.juggler.removeTweens(m_bestPlayerScoreLine);
				m_bestPlayerScoreLine.x = bestScoreX;
			} else if (newBarWidth < m_scoreBar.width) {
				// If we're shrinking, shrink right away - then show flash showing the difference
				Starling.juggler.removeTweens(m_scoreBar);
				Starling.juggler.tween(m_scoreBar, BAR_SLIDING_ANIM_SEC, {
				   transition: Transitions.EASE_OUT,
				   width: newBarWidth
				});
				Starling.juggler.removeTweens(m_scoreTextfield);
				Starling.juggler.tween(m_scoreTextfield, BAR_SLIDING_ANIM_SEC, {
				   transition: Transitions.EASE_OUT,
				   x: newScoreX
				});
				Starling.juggler.removeTweens(m_bestPlayerScoreLine);
				Starling.juggler.tween(m_bestPlayerScoreLine, BAR_SLIDING_ANIM_SEC, {
				   transition: Transitions.EASE_OUT,
				   x: bestScoreX
				});
			} else if (newBarWidth > m_scoreBar.width) {
				// If we're growing, flash the difference first then grow
				Starling.juggler.removeTweens(m_scoreBar);
				Starling.juggler.tween(m_scoreBar, BAR_SLIDING_ANIM_SEC, {
				   transition: Transitions.EASE_OUT,
				   delay: FLASHING_ANIM_SEC,
				   width: newBarWidth
				});
				Starling.juggler.removeTweens(m_scoreTextfield);
				Starling.juggler.tween(m_scoreTextfield, BAR_SLIDING_ANIM_SEC, {
				   transition: Transitions.EASE_OUT,
				   delay: FLASHING_ANIM_SEC,
				   x: newScoreX
				});
				Starling.juggler.removeTweens(m_bestPlayerScoreLine);
				Starling.juggler.tween(m_bestPlayerScoreLine, BAR_SLIDING_ANIM_SEC, {
				   transition: Transitions.EASE_OUT,
				   x: bestScoreX
				});
			} else {
				return;
			}
			
			// If we've spilled off to the right, shrink it down after we've animated showing the difference
			
			var barBounds:Rectangle = m_scoreBar.getBounds(m_scorePanel);
			// Adjust bounds to be relative to top left=(0,0) and unscaled (scaleX,Y=1)
			var adjustedBounds:Rectangle = barBounds.clone();
			adjustedBounds.x -= m_scoreBarContainer.x;
			adjustedBounds.x /= m_scoreBarContainer.scaleX;
			adjustedBounds.y -= m_scoreBarContainer.y;
			adjustedBounds.y /= m_scoreBarContainer.scaleY;
			adjustedBounds.width /= m_scoreBarContainer.scaleX;
			adjustedBounds.height /= m_scoreBarContainer.scaleY;
			
			// Tween to make this fit the area we want it to, ONLY IF OFF SCREEN
			var newScaleX:Number = SCORE_PANEL_AREA.width / barBounds.width;
			//var newScaleY:Number = Math.min(SCORE_PANEL_MAX_SCALEY, SCORE_PANEL_AREA.height / adjustedBounds.height);
			var newX:Number = -barBounds.x * newScaleX; // left-adjusted
			//var newY:Number = SCORE_PANEL_AREA.height - adjustedBounds.bottom * newScaleY; // sits on the bottom
			// Only move the score blocks around/scale if some of the blocks are offscreen (out of score panel area)
			// OR if was shrunk below 100% and doesn't need to be
			if (barBounds.left < 0 || barBounds.right > SCORE_PANEL_AREA.width
				|| ((m_scoreBarContainer.scaleX < 1.0) && (newScaleX > m_scoreBarContainer.scaleX))) {
				Starling.juggler.removeTweens(m_scoreBarContainer);
				Starling.juggler.tween(m_scoreTextfield, 1.5, {
				   transition: Transitions.EASE_OUT,
				   delay: (FLASHING_ANIM_SEC + BAR_SLIDING_ANIM_SEC + 2 * DELAY),
				   scaleX: newScaleX
				});
			}
		}
		
		private function onTouchBestScore(evt:TouchEvent):void
		{
			if (!m_bestPlayerScoreLine) return;
			if (evt.getTouches(m_bestPlayerScoreLine, TouchPhase.ENDED).length) {
				// Clicked, load best score!
				dispatchEvent(new MenuEvent(MenuEvent.LOAD_BEST_SCORE));
			} else if (evt.getTouches(m_bestPlayerScoreLine, TouchPhase.HOVER).length) {
				// Hover over
				m_bestPlayerScoreLine.alpha = 1;
			} else {
				// Hover out
				m_bestPlayerScoreLine.alpha = 0.8;
			}
		}
		
		private function onTouchHighScore(evt:TouchEvent):void
		{
			if (!m_bestScoreLine) return;
			if (evt.getTouches(m_bestScoreLine, TouchPhase.ENDED).length) {
				// Clicked, load best score!
				dispatchEvent(new MenuEvent(MenuEvent.LOAD_HIGH_SCORE));
			} else if (evt.getTouches(m_bestScoreLine, TouchPhase.HOVER).length) {
				// Hover over
				m_bestScoreLine.alpha = 1;
			} else {
				// Hover out
				m_bestScoreLine.alpha = 0.8;
			}
		}
		
		public function setHighScores(highScoreArray:Array):void
		{
			var level:Level = World.m_world.active_level;
			if(level != null && highScoreArray != null)
			{
				var currentScore:int = level.currentScore;
				var bestScore:int = level.bestScore;
				var targetScore:int = level.getTargetScore();
				var maxScoreShown:Number = Math.max(currentScore, targetScore);
				var score:String =  highScoreArray[0].current_score;
				
				if (!m_bestScoreLine) {
					m_bestScoreLine = new TargetScoreDisplay(score, 0.05 * GameControlPanel.SCORE_PANEL_AREA.height, TextBubble.RED, TextBubble.RED, "High Score");
					m_bestScoreLine.addEventListener(TouchEvent.TOUCH, onTouchHighScore);
				} else {
					m_bestScoreLine.update(score);
				}
				m_bestScoreLine.x = (SCORE_PANEL_AREA.width * 2.0 / 3.0) * parseInt(score) / maxScoreShown;
				m_scoreBarContainer.addChild(m_bestScoreLine);
			}
		}
	}
}

import display.ToolTippableSprite;
import events.ToolTipEvent;
import scenes.game.components.GameControlPanel;
import assets.AssetsFont;
import starling.display.Quad;
import starling.display.Sprite;

class TargetScoreDisplay extends ToolTippableSprite
{
	private var m_targetScoreTextfield:TextFieldHack;
	private var m_textHitArea:Quad;
	private var m_toolTipText:String;
	
	public function TargetScoreDisplay(score:String, textY:Number, lineColor:uint, fontColor:uint, toolTipText:String = "")
	{
		m_toolTipText = toolTipText;
		// Add a dotted line effect
		for (var dq:int = 0; dq < 10; dq++) {
			var dottedQ:Quad = new Quad(1, 1, lineColor);
			dottedQ.x = -dottedQ.width / 2;
			dottedQ.y = ((dq + 1.0) / 11.0) * GameControlPanel.SCORE_PANEL_AREA.height;
			addChild(dottedQ);
		}
		m_targetScoreTextfield = TextFactory.getInstance().createTextField(score, AssetsFont.FONT_UBUNTU, GameControlPanel.SCORE_PANEL_AREA.width, GameControlPanel.SCORE_PANEL_AREA.height / 3.0, GameControlPanel.SCORE_PANEL_AREA.height / 3.0, fontColor) as TextFieldHack;
		m_targetScoreTextfield.x = 2.0;
		
		TextFactory.getInstance().updateAlign(m_targetScoreTextfield, 0, 1);
		m_targetScoreTextfield.y = textY;
		addChild(m_targetScoreTextfield);
		// Create hit areas for capturing mouse events
		m_textHitArea = new Quad(m_targetScoreTextfield.textBounds.width, m_targetScoreTextfield.textBounds.height, 0xFFFFFF);
		m_textHitArea.x = m_targetScoreTextfield.x + m_targetScoreTextfield.textBounds.x;
		m_textHitArea.y = m_targetScoreTextfield.y + m_targetScoreTextfield.textBounds.y;
		m_textHitArea.alpha = 0;
		addChild(m_textHitArea);
		var lineHitArea:Quad = new Quad(8, GameControlPanel.SCORE_PANEL_AREA.height, 0xFFFFFF);
		lineHitArea.x = -4;
		lineHitArea.alpha = 0;
		addChild(lineHitArea);
	}
	
	public function update(score:String):void
	{
		TextFactory.getInstance().updateText(m_targetScoreTextfield, score);
		TextFactory.getInstance().updateAlign(m_targetScoreTextfield, 0, 1);
		m_textHitArea.width = m_targetScoreTextfield.textBounds.width;
		m_textHitArea.height = m_targetScoreTextfield.textBounds.height;
		m_textHitArea.x = m_targetScoreTextfield.x + m_targetScoreTextfield.textBounds.x;
		m_textHitArea.y = m_targetScoreTextfield.y + m_targetScoreTextfield.textBounds.y;
	}
	
	protected override function getToolTipEvent():ToolTipEvent
	{
		return new ToolTipEvent(ToolTipEvent.ADD_TOOL_TIP, this, m_toolTipText);
	}
}