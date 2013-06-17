package scenes.game.components
{
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import starling.animation.Transitions;
	import starling.core.Starling;
	import starling.display.Button;
	import starling.display.Image;
	import starling.display.Quad;
	import starling.display.Sprite;
	import starling.events.Event;
	import starling.textures.Texture;
	
	import assets.AssetInterface;
	import assets.AssetsFont;
	import scenes.BaseComponent;
	import scenes.game.display.GameComponent;
	import scenes.game.display.GameEdgeContainer;
	import scenes.game.display.GameJointNode;
	import scenes.game.display.GameNode;
	import scenes.game.display.Level;
	import scenes.game.display.World;
	
	public class GameControlPanel extends BaseComponent
	{
		private static const WIDTH:Number = Constants.GameWidth;
		private static const HEIGHT:Number = 50;
		
		private static const SCORE_PANEL_AREA:Rectangle = new Rectangle(79, 2, 304, 48);
		private static const PAD:Number = 2.0;
		private static const SCORE_PANEL_MAX_SCALEY:Number = 1.5;
		
		/** Graphical object showing user's score */
		private var m_scorePanel:BaseComponent;
		
		/** Graphical object, child of scorePanel to hold scorebar */
		private var m_scoreBarContainer:Sprite;
		
		/** Indicate the current score */
		private var m_scoreBar:Quad;
		
		/** Text showing current score on score_pane */
		private var m_scoreTextfield:TextFieldWrapper;
		
		/** Button to bring the up the menu */
		private var m_menuButton:Button;
		
		private var menuShowing:Boolean = false;
		
		/** Current Score of the player */
		private var m_currentScore:int = 0;
		
		/** Most recent score of the player */
		private var m_prevScore:int = 0;
		
		public function GameControlPanel()
		{			
			this.addEventListener(starling.events.Event.ADDED_TO_STAGE, addedToStage);
			this.addEventListener(starling.events.Event.REMOVED_FROM_STAGE, removedFromStage);
		}
		
		public function addedToStage(event:starling.events.Event):void
		{
			var background:Texture = AssetInterface.getTexture("Game", "GameControlPanelBackgroundImageClass");
			var backgroundImage:Image = new Image(background);
			backgroundImage.width = WIDTH;
			backgroundImage.height = HEIGHT;
			addChild(backgroundImage);
			
			m_scorePanel = new BaseComponent();
			m_scorePanel.x = SCORE_PANEL_AREA.x + PAD;
			m_scorePanel.y = SCORE_PANEL_AREA.y + PAD; 
			var quad:Quad = new Quad(SCORE_PANEL_AREA.width - 2*PAD, SCORE_PANEL_AREA.height - 2*PAD, 0x000000);
			m_scorePanel.addChild(quad);
			addChild(m_scorePanel);
			
			m_scoreBarContainer = new Sprite();
			m_scorePanel.addChild(m_scoreBarContainer);
			var topLeftScorePanel:Point = m_scorePanel.localToGlobal(new Point(0, 0));
			m_scorePanel.clipRect = new Rectangle(topLeftScorePanel.x, topLeftScorePanel.y, m_scorePanel.width, m_scorePanel.height);
			
			m_scoreTextfield = TextFactory.getInstance().createTextField("0", AssetsFont.FONT_NUMERIC, SCORE_PANEL_AREA.width, HEIGHT / 2 - 2*PAD, HEIGHT / 2 - 2*PAD, GameComponent.SCORE_COLOR);
			m_scoreTextfield.x = (SCORE_PANEL_AREA.width- m_scoreTextfield.width) / 2 ;
			m_scoreTextfield.y = HEIGHT/4 + PAD;
			TextFactory.getInstance().updateAlign(m_scoreTextfield, 2, 1);
			m_scorePanel.addChild(m_scoreTextfield);
			
			var menuButtonUp:Texture = AssetInterface.getTexture("Menu", "MenuButtonClass");
			var menuButtonClick:Texture = AssetInterface.getTexture("Menu", "MenuButtonClickClass");
			
			m_menuButton = new Button(menuButtonUp, "", menuButtonClick);
			m_menuButton.addEventListener(Event.TRIGGERED, onMenuButtonTriggered);
//			m_menuButton.width *= .4;
//			m_menuButton.height *= .5;
			m_menuButton.x = 4;
			m_menuButton.y = HEIGHT/2 - m_menuButton.height/2;
			addChild(m_menuButton);
		}
		
		private function onMenuButtonTriggered():void
		{
			menuShowing = !menuShowing;
			dispatchEvent(new Event(World.SHOW_GAME_MENU, true, menuShowing));
		}
		
		public function removedFromStage(event:starling.events.Event):void
		{
			//TODO what? dispose of things?
		}
		
		/**
		 * Re-calculates score and updates the score on the screen
		 */
		
		public function updateScore(level:Level):void 
		{
			
			/* Old scoring:
			* 
			For pipes:
			No points for any red pipe.
			For green pipes:
			10 points for every wide input pipe
			5 points for every narrow input pipe
			10 points for every narrow output pipe
			5 points for every wide output pipe
			1 point for every internal pipe, no matter what its width
			
			For solving the game:
			30 points per board solved
			- Changed this to 30 from 10 = original
			
			100 points per level solved
			1000 points per world solved
			
			For each exception to the laws of physics:
			-50 points
			*/
			
			/*
			 * New Scoring:
			 * +75 for each line going thru/starting/ending @ a box
			 * +25 for wide inputs
			 * +25 for narrow outputs
			 * -75 for errors
			*/
			
			m_prevScore = m_currentScore;
			var wideInputs:int = 0;
			var narrowOutputs:int = 0;
			var errors:int = 0;
			var totalLines:int = 0;
			var scoringNodes:Vector.<GameNode> = new Vector.<GameNode>();
			var potentialScoringNodes:Vector.<GameNode> = new Vector.<GameNode>();
			var errorEdges:Vector.<GameEdgeContainer> = new Vector.<GameEdgeContainer>();
			// Pass over all nodes, find nodes involved in scoring
			for each(var nodeSet:GameNode in level.getNodes())
			{
				if (nodeSet.isEditable()) { // don't count star points for uneditable boxes
					totalLines += nodeSet.getNumLines();
					if (nodeSet.isWide()) {
						if (nodeSet.m_numIncomingNodeEdges - nodeSet.m_numOutgoingNodeEdges > 0) {
							wideInputs += nodeSet.m_numIncomingNodeEdges - nodeSet.m_numOutgoingNodeEdges;
							scoringNodes.push(nodeSet);
						} else if (nodeSet.m_numOutgoingNodeEdges - nodeSet.m_numIncomingNodeEdges > 0) {
							potentialScoringNodes.push(nodeSet);
						}
					} else {
						if (nodeSet.m_numOutgoingNodeEdges - nodeSet.m_numIncomingNodeEdges > 0) {
							narrowOutputs += nodeSet.m_numOutgoingNodeEdges - nodeSet.m_numIncomingNodeEdges;
							scoringNodes.push(nodeSet);
						} else if (nodeSet.m_numIncomingNodeEdges - nodeSet.m_numOutgoingNodeEdges > 0) {
							potentialScoringNodes.push(nodeSet);
						}
					}
				}
				for each (var incomingEdge:GameEdgeContainer in nodeSet.m_incomingEdges) {
					if (incomingEdge.hasError()) {
						errors++;
						if (errorEdges.indexOf(incomingEdge) == -1) {
							errorEdges.push(incomingEdge);
						} else {
							trace("WARNING! Seem to be marking the same GameEdgeContainer as an error twice, this shouldn't be possible (same GameEdgeContainer is listed as 'incoming' for > 1 GameNode")
						}
					}
				}
			}
			
			for each (var myJoint:GameJointNode in level.getJoints()) {
				for each (var injEdge:GameEdgeContainer in myJoint.m_incomingEdges) {
					if (injEdge.hasError()) {
						errors++;
						if (errorEdges.indexOf(injEdge) == -1) {
							errorEdges.push(injEdge);
						} else {
							trace("WARNING! Seem to be marking the same GameEdgeContainer as an error twice, this shouldn't be possible (same GameEdgeContainer is listed as 'incoming' for > 1 GameNode")
						}
					}
				}
			}
			
			//trace("totalLines:" + totalLines + " wideInputs:" + wideInputs + " narrowOutputs:" + narrowOutputs + " errors:" + errors);
			m_currentScore = Constants.POINTS_PER_LINE * totalLines + Constants.WIDE_INPUT_POINTS * wideInputs + Constants.NARROW_OUTPUT_POINTS * narrowOutputs + Constants.ERROR_POINTS * errors;
			var baseScore:Number = Constants.POINTS_PER_LINE * totalLines;
			
			TextFactory.getInstance().updateText(m_scoreTextfield, m_currentScore.toString());
			TextFactory.getInstance().updateAlign(m_scoreTextfield, 2, 1);
			
			// Aim for starting score to be 2/3 of the width of the scorebar area
			var newBarWidth:Number = (SCORE_PANEL_AREA.width * 2 / 3) * m_currentScore / baseScore;
			var newScoreX:Number = newBarWidth - m_scoreTextfield.width;
			if (!m_scoreBar) {
				m_scoreBar = new Quad(newBarWidth, HEIGHT / 2, GameComponent.NARROW_COLOR);
				m_scoreBar.setVertexColor(2, GameComponent.WIDE_COLOR);
				m_scoreBar.setVertexColor(3, GameComponent.WIDE_COLOR);
				m_scoreBar.y = (HEIGHT - m_scoreBar.height) / 2;
				m_scoreBarContainer.addChild(m_scoreBar);
				m_scoreTextfield.x = newScoreX;
			}
			
			var FLASHING_ANIM_SEC:Number = 0; // TODO: make this nonzero when animation is in place
			var DELAY:Number = 0.5;
			var BAR_SLIDING_ANIM_SEC:Number = 1.0;
			if (newBarWidth < m_scoreBar.width) {
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
			} else {
				return;
			}
			
			// If we've spilled off to the right, shrink it down after we've animated showing the difference
			
			var blocksBounds:Rectangle = m_scoreBarContainer.getBounds(m_scorePanel);
			// Adjust bounds to be relative to top left=(0,0) and unscaled (scaleX,Y=1)
			var adjustedBounds:Rectangle = blocksBounds.clone();
			adjustedBounds.x -= m_scoreBarContainer.x;
			adjustedBounds.x /= m_scoreBarContainer.scaleX;
			adjustedBounds.y -= m_scoreBarContainer.y;
			adjustedBounds.y /= m_scoreBarContainer.scaleY;
			adjustedBounds.width /= m_scoreBarContainer.scaleX;
			adjustedBounds.height /= m_scoreBarContainer.scaleY;
			
			// Tween to make this fit the area we want it to, ONLY IF OFF SCREEN
			var newScaleX:Number = (SCORE_PANEL_AREA.width - 2 * PAD) / blocksBounds.width;
			//var newScaleY:Number = Math.min(SCORE_PANEL_MAX_SCALEY, (SCORE_PANEL_AREA.height - 2 * PAD) / adjustedBounds.height);
			var newX:Number = -blocksBounds.x * newScaleX; // left-adjusted
			//var newY:Number = SCORE_PANEL_AREA.height - 2 * PAD - adjustedBounds.bottom * newScaleY; // sits on the bottom
			// Only move the score blocks around/scale if some of the blocks are offscreen (out of score panel area)
			// OR if was shrunk below 100% and doesn't need to be
			if (blocksBounds.top < 0 || blocksBounds.bottom > SCORE_PANEL_AREA.height - 2 * PAD
				|| ((m_scoreBarContainer.scaleX < 1.0) && (newScaleX > m_scoreBarContainer.scaleX))) {
				Starling.juggler.removeTweens(m_scoreBarContainer);
				Starling.juggler.tween(m_scoreTextfield, 1.5, {
				   transition: Transitions.EASE_OUT,
				   delay: (FLASHING_ANIM_SEC + BAR_SLIDING_ANIM_SEC + 2 * DELAY),
				   scaleX: newScaleX
				});
			}
		}
		
//		public function onSaveButtonClick(e:TouchEvent):void {
//			if (m_world) {
//				m_world.outputXmlToJavascript();
//			}
//		}
//		
//		public function onSubmitButtonClick(e:TouchEvent):void {
//			if (m_world) {
//				m_world.outputXmlToJavascript();
//			}
//			//showNextWorldScreen();
//		}

	}
}