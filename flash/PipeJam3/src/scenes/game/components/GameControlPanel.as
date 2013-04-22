package scenes.game.components
{
	import assets.AssetInterface;
	import assets.AssetsFont;
	import com.greensock.TweenLite;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import scenes.game.display.GameComponent;
	import utilities.XMath;
	
	import scenes.BaseComponent;
	import scenes.game.display.GameEdgeContainer;
	import scenes.game.display.GameNode;
	import scenes.game.display.Level;
	import scenes.game.display.ScoreBlock;
	import scenes.game.display.World;
	
	import starling.display.Button;
	import starling.display.Image;
	import starling.display.Quad;
	import starling.display.Sprite;
	import starling.events.Event;
	import starling.events.TouchEvent;
	import starling.text.TextField;
	import starling.textures.Texture;
	
	public class GameControlPanel extends BaseComponent
	{	
		private static const WIDTH:Number = 96;
		private static const HEIGHT:Number = Constants.GameHeight;
		private static const SCORE_PANEL_AREA:Rectangle = new Rectangle(3, 65, WIDTH - 3, 266.5 - 65);
		private static const PAD:Number = 2.0;
		private static const SCORE_PANEL_MAX_SCALEY:Number = 1.5;
		
		/** Graphical object showing user's score */
		protected var scorePanel:BaseComponent;
		
		/** Graphical object, child of scorePanel to hold all scoreBlocks */
		protected var scoreBlockContainer:Sprite;
		
		/** Dashed line indicated the score starting point (score = 0), 
		 *  the current level of score (score blocks minus error blocks) 
		 *  and associated textLabel showing the zero/current score, respectively */
		private var m_scoreBaseline:Sprite;
		private var m_scoreCurrentLine:Sprite;
		private var m_scoreBlockBaselineLabel:TextFieldWrapper;
		private var m_scoreBlockCurrentLabel:TextFieldWrapper;
		
		/** Text showing current score on score_pane */
		protected var scoreTextfield:TextFieldWrapper;
		
		/** Button allowing user to place a buzzsaw on the current board */
		public var buzzsaw_button:Image;
		
		/** Button to bring the user back to the previous board */
		public var back_button:Image;
		
		/** Button to bring the up the menu */
		public var menu_button:Button;
		
		/** Button to save to XML */
		protected var exit_button:Image;
		
		/** Button to replay last level */
		protected var replay_button:Image;
		
		/** Button to save to XML */
		protected var save_button:Image;
		
		/** Button to save XML and return to end to end system */
		protected var submit_button:Image;
		
		/** Score of the player */
		protected var current_score:int = 0;
		
		/** Most recent score of the player (could be used to animate between the two, but currently is not) */
		protected var prev_score:int = 0;
		
		/** All the score blocks visible in the scoring pane used to show current/potential scoring for certain nodes/edges */
		private var m_scoreBlocks:Vector.<ScoreBlock> = new Vector.<ScoreBlock>();
		
		protected var m_initialized:Boolean = false;
		
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
			
			scoreTextfield = TextFactory.getInstance().createTextField("0", AssetsFont.FONT_NUMERIC, width, 40, 25, GameComponent.SCORE_COLOR);
			scoreTextfield.x = -5; 
			TextFactory.getInstance().updateAlign(scoreTextfield, 1, 1);
			addChild(scoreTextfield);
			
			scorePanel = new BaseComponent();
			scorePanel.x = SCORE_PANEL_AREA.x + PAD;
			scorePanel.y = SCORE_PANEL_AREA.y + PAD; 
			var quad:Quad = new Quad(SCORE_PANEL_AREA.width - 2*PAD, SCORE_PANEL_AREA.height - 2*PAD, 0x000000);
			scorePanel.addChild(quad);
			addChild(scorePanel);
			
			scoreBlockContainer = new Sprite();
			scorePanel.addChild(scoreBlockContainer);
			var topLeftScorePanel:Point = scorePanel.localToGlobal(new Point(0, 0));
			scorePanel.clipRect = new Rectangle(topLeftScorePanel.x, topLeftScorePanel.y, scorePanel.width, scorePanel.height);
			
			m_scoreBaseline = new Sprite();
			m_scoreCurrentLine = new Sprite();
			const DOTTED_LINE_SEGS:int = 5;
			const BASELINE_TOTAL_WIDTH:Number = 2.5 * ScoreBlock.WIDTH;
			const SEG_WIDTH:Number = BASELINE_TOTAL_WIDTH / (2.0 * DOTTED_LINE_SEGS - 1);
			const SEG_HEIGHT:Number = 1.0;
			const START_X:Number = 2 * ScoreBlock.WIDTH;
			for (var i:int = 0; i < DOTTED_LINE_SEGS; i++)
			{
				// Baseline
				var line:Quad = new Quad(SEG_WIDTH, SEG_HEIGHT, 0xFFFFFF);
				line.x = START_X + 2 * i * SEG_WIDTH;
				line.y = SCORE_PANEL_AREA.height - 2 * PAD - SEG_HEIGHT / 2.0;
				m_scoreBaseline.addChild(line);
				// Current line
				var line2:Quad = new Quad(SEG_WIDTH, SEG_HEIGHT, GameComponent.SCORE_COLOR);
				line2.x = START_X + 2 * i * SEG_WIDTH;
				line2.y = SCORE_PANEL_AREA.height - 2 * PAD - SEG_HEIGHT / 2.0;
				m_scoreCurrentLine.addChild(line2);
			}
			const TEXT_SIZE:Number = 8.0;
			m_scoreBlockBaselineLabel = TextFactory.getInstance().createTextField("0", AssetsFont.FONT_NUMERIC, ScoreBlock.WIDTH, TEXT_SIZE, TEXT_SIZE, 0xFFFFFF);
			m_scoreBlockBaselineLabel.x = START_X + BASELINE_TOTAL_WIDTH + 1.0;
			m_scoreBlockBaselineLabel.y = SCORE_PANEL_AREA.height - 2 * PAD - TEXT_SIZE / 2.0;
			TextFactory.getInstance().updateAlign(m_scoreBlockBaselineLabel, 0, 1);
			m_scoreBaseline.addChild(m_scoreBlockBaselineLabel);
			
			m_scoreBlockCurrentLabel = TextFactory.getInstance().createTextField("0", AssetsFont.FONT_NUMERIC, ScoreBlock.WIDTH, TEXT_SIZE, TEXT_SIZE, GameComponent.SCORE_COLOR);
			m_scoreBlockCurrentLabel.x = START_X + BASELINE_TOTAL_WIDTH + 1.0;
			m_scoreBlockCurrentLabel.y = SCORE_PANEL_AREA.height - 2 * PAD - TEXT_SIZE / 2.0;
			TextFactory.getInstance().updateAlign(m_scoreBlockCurrentLabel, 0, 1);
			m_scoreCurrentLine.addChild(m_scoreBlockCurrentLabel);
			
			scoreBlockContainer.addChild(m_scoreBaseline);
			scoreBlockContainer.addChild(m_scoreCurrentLine);
			
			var menuButtonUp:Texture = AssetInterface.getTexture("Menu", "MenuButtonClass");
			var menuButtonClick:Texture = AssetInterface.getTexture("Menu", "MenuButtonClass");
			
			menu_button = new Button(menuButtonUp, "", menuButtonClick);
			menu_button.addEventListener(Event.TRIGGERED, onMenuButtonTriggered);
			menu_button.x = 15;
			menu_button.y = 275;
			addChild(menu_button);
		}
		
		private function onMenuButtonTriggered():void
		{
			dispatchEvent(new Event(World.SHOW_GAME_MENU, true));
		}
		
		public function removedFromStage(event:starling.events.Event):void
		{
			//TODO what? dispose of things?
		}
		
		public function isInitialized():Boolean
		{
			return m_initialized;
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
			 *
			 * +25 for wide inputs
			 * +25 for narrow outputs
			 * -75 for errors
			*/
			
			prev_score = current_score;
			var wideInputs:int = 0;
			var narrowOutputs:int = 0;
			var errors:int = 0;
			var scoringNodes:Vector.<GameNode> = new Vector.<GameNode>();
			var potentialScoringNodes:Vector.<GameNode> = new Vector.<GameNode>();
			var errorEdges:Vector.<GameEdgeContainer> = new Vector.<GameEdgeContainer>();
			// Pass over all nodes, find nodes involved in scoring
			for each(var nodeSet:GameNode in level.m_nodeList)
			{
				if (nodeSet.isEditable()) { // Decision: don't score nodes that you can't change unless they have errors
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
			
			trace("wideInputs:" + wideInputs + " narrowOutputs:" + narrowOutputs + " errors:" + errors);
			current_score = Constants.WIDE_INPUT_POINTS * wideInputs + Constants.NARROW_OUTPUT_POINTS * narrowOutputs + Constants.ERROR_POINTS * errors;
			TextFactory.getInstance().updateText(scoreTextfield, current_score.toString());
			TextFactory.getInstance().updateText(m_scoreBlockCurrentLabel, current_score.toString());
			
			for each (var block:ScoreBlock in m_scoreBlocks) {
				block.removeFromParent(true);
			}
			m_scoreBlocks = new Vector.<ScoreBlock>();
			
			var currentY:Number = SCORE_PANEL_AREA.height - 2 * PAD;
			var currentX:Number = 0.5 * ScoreBlock.WIDTH;
			// Pass over nodes involved in scoring and create scoring blocks for them
			var maxBlockHeight:Number = (SCORE_PANEL_AREA.height - 5) / Math.max(scoringNodes.length, 1);
			maxBlockHeight = XMath.clamp(maxBlockHeight, 3, 10);
			var scoreNode:GameNode, scoreBlock:ScoreBlock;
			for each (scoreNode in potentialScoringNodes) {
				scoreBlock = new ScoreBlock(scoreNode);
				scoreBlock.x = currentX;
				scoreBlock.y = currentY - scoreBlock.height;
				currentY -= scoreBlock.height + ScoreBlock.VERTICAL_GAP;
				m_scoreBlocks.push(scoreBlock);
				scoreBlockContainer.addChildAt(scoreBlock, 0);
			}
			currentY = SCORE_PANEL_AREA.height - 2 * PAD;
			currentX += 1.5 * ScoreBlock.WIDTH;
			for each (scoreNode in scoringNodes) {
				scoreBlock = new ScoreBlock(scoreNode);
				scoreBlock.x = currentX;
				scoreBlock.y = currentY - scoreBlock.height;
				currentY -= scoreBlock.height + ScoreBlock.VERTICAL_GAP;
				m_scoreBlocks.push(scoreBlock);
				scoreBlockContainer.addChildAt(scoreBlock, 0);
			}
			currentY += ScoreBlock.VERTICAL_GAP;
			currentX += 1.5 * ScoreBlock.WIDTH;
			for each (var scoreEdge:GameEdgeContainer in errorEdges) {
				scoreBlock = new ScoreBlock(scoreEdge);
				scoreBlock.x = currentX;
				scoreBlock.y = currentY;
				currentY += scoreBlock.height + ScoreBlock.VERTICAL_GAP;
				m_scoreBlocks.push(scoreBlock);
				scoreBlockContainer.addChildAt(scoreBlock, 0);
			}
			m_scoreCurrentLine.y = (currentY - ScoreBlock.VERTICAL_GAP) - (SCORE_PANEL_AREA.height - 2 * PAD);
			
			var blocksBounds:Rectangle = scoreBlockContainer.getBounds(scorePanel);
			// Adjust bounds to be relative to top left=(0,0) and unscaled (scaleX,Y=1)
			var adjustedBounds:Rectangle = blocksBounds.clone();
			adjustedBounds.x -= scoreBlockContainer.x;
			adjustedBounds.x /= scoreBlockContainer.scaleX;
			adjustedBounds.y -= scoreBlockContainer.y;
			adjustedBounds.y /= scoreBlockContainer.scaleY;
			adjustedBounds.width /= scoreBlockContainer.scaleX;
			adjustedBounds.height /= scoreBlockContainer.scaleY;
			
			// Tween to make this fit the area we want it to, ONLY IF OFF SCREEN
			TweenLite.killTweensOf(scoreBlockContainer);
			//var newScaleX:Number = (SCORE_PANEL_AREA.width - 2 * PAD) / blocksBounds.width;
			var newScaleY:Number = Math.min(SCORE_PANEL_MAX_SCALEY, (SCORE_PANEL_AREA.height - 2 * PAD) / adjustedBounds.height);
			//var newX:Number = -blocksBounds.x * newScaleX; // left-adjusted
			var newY:Number = SCORE_PANEL_AREA.height - 2 * PAD - adjustedBounds.bottom * newScaleY; // sits on the bottom
			// Only move the score blocks around/scale if some of the blocks are offscreen (out of score panel area)
			if (blocksBounds.top < 0 || blocksBounds.bottom > SCORE_PANEL_AREA.height - 2 * PAD) {
				TweenLite.to(scoreBlockContainer, 1.5, {/*x:newX,*/ y:newY, /*scaleX:newScaleX,*/ scaleY: newScaleY, delay: 0.5 } );
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