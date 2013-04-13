package scenes.game.components
{
	import assets.AssetInterface;
	import assets.AssetsFont;
	import scenes.game.display.GameEdgeContainer;
	
	import scenes.BaseComponent;
	import scenes.game.display.GameNode;
	import scenes.game.display.Level;
	import scenes.game.display.ScoreBlock;
	
	import starling.display.Image;
	import starling.display.Quad;
	import starling.display.Sprite;
	import starling.events.Event;
	import starling.events.TouchEvent;
	import starling.text.TextField;
	import starling.textures.Texture;
	
	public class GameControlPanel extends BaseComponent
	{	
		/** Graphical object showing user's score */
		protected var scorePanel:Sprite;
		
		/** Text showing current score on score_pane */
		protected var scoreTextfield:TextFieldWrapper;
		
		/** Button allowing user to place a buzzsaw on the current board */
		public var buzzsaw_button:Image;
		
		/** Button to bring the user back to the previous board */
		public var back_button:Image;
		
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
			backgroundImage.height = 320;
			addChild(backgroundImage);
			
			scoreTextfield = TextFactory.getInstance().createTextField("0", AssetsFont.FONT_NUMERIC, width, 40, 25, 0xFF0000);
			scoreTextfield.x = -5; 
			TextFactory.getInstance().updateAlign(scoreTextfield, 1, 1);
			addChild(scoreTextfield);
			
			scorePanel = new Sprite();
			scorePanel.x = 5; 
			scorePanel.y = 77.8; 
			var quad:Quad = new Quad(width-scorePanel.x*2, 190, 0x000000);
			scorePanel.addChild(quad);
			addChild(scorePanel);
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
			
			//Quad(width-scorePanel.x*2, 200, 0xfff000)
			scorePanel.removeChildren(1);
			var currentPosition:Number = scorePanel.height;
			var maxBlockHeight:Number = (scorePanel.height - 5)/level.m_nodeList.length;
			if(maxBlockHeight > 10)
				maxBlockHeight = 10;
			if(maxBlockHeight < 3)
				maxBlockHeight = 3;
			
			ScoreBlock.wideHeight = maxBlockHeight;
			ScoreBlock.narrowHeight = maxBlockHeight*2/3;
			ScoreBlock.maxWidth = scorePanel.width - 30;
			var blockXPos:Number = scorePanel.width/2 - 10;
			
			prev_score = current_score;
			var wideInputs:int = 0;
			var narrowOutputs:int = 0;
			var errors:int = 0;
			for each(var nodeSet:GameNode in level.m_nodeList)
			{
				var scoreBlock:ScoreBlock = new ScoreBlock(nodeSet);
				scoreBlock.x = scoreBlock.x + blockXPos + Math.random()*2;
				scoreBlock.y = currentPosition - scoreBlock.height;
				currentPosition -= scoreBlock.height;
				scorePanel.addChild(scoreBlock);
				if (nodeSet.isWide()) {
					wideInputs += nodeSet.m_numIncomingNodeEdges;
				} else {
					narrowOutputs += nodeSet.m_numOutgoingNodeEdges;
				}
				for each (var incomingEdge:GameEdgeContainer in nodeSet.m_incomingEdges) {
					if (incomingEdge.hasError()) {
						errors++;
					}
				}
			}
			trace("wideInputs:" + wideInputs + " narrowOutputs:" + narrowOutputs + " errors:" + errors);
			current_score = Constants.WIDE_INPUT_POINTS * wideInputs + Constants.NARROW_OUTPUT_POINTS * narrowOutputs + Constants.ERROR_POINTS * errors;
			TextFactory.getInstance().updateText(scoreTextfield, current_score.toString());
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