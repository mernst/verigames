package scenes.game.components
{
	import assets.AssetInterface;
	
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
		
		/** Text label for SCORE */
		protected var score_title_textfield:TextField;
		
		/** Text showing current score on score_pane */
		protected var scoreTextfield:TextField;
		
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
			
			
			scoreTextfield = new TextField(width, width, "0", "Verdana", 45);
			scoreTextfield.color = 0xff0000;
			scoreTextfield.x = 0; 
			scoreTextfield.y = -35;
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
			
			/* Current scoring:
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
			
			for each(var nodeSet:GameNode in level.m_nodeList)
			{
				var scoreBlock:ScoreBlock = new ScoreBlock(nodeSet);
				scoreBlock.x = scoreBlock.x + blockXPos + Math.random()*2;
				

				
				scoreBlock.y = currentPosition - scoreBlock.height;
				currentPosition -= scoreBlock.height;
				scorePanel.addChild(scoreBlock);
				
				
			}
//			prev_score = current_score;
//			var my_score:int = 0;
//			for each (var my_level:Level in m_world.levels) {
//				if (!my_level.failed) {
//					my_score += 100;
//				}
//				for each (var my_board:Board in my_level.boards) {
//					if (my_board.trouble_points.length == 0) {
//						my_score += 30;
//					}
////					for each (var my_pipe:Pipe in my_board.pipes) {
////						if (my_pipe.has_buzzsaw) {
////							my_score -= 50;
////						}
////						if (!my_pipe.failed) {
////							my_score += 1;
////							
////							var is_input:Boolean = false;
////							if (my_pipe.associated_edge.from_node.kind == NodeTypes.INCOMING) {
////								is_input = true;
////							}
////							
////							var is_output:Boolean = false;
////							if (my_pipe.associated_edge.to_node.kind == NodeTypes.OUTGOING) {
////								is_output = true;
////							}
////							
////							if (is_input && (my_pipe.is_wide)) {
////								my_score += 10;
////							} else if (is_input && (!my_pipe.is_wide)) {
////								my_score += 5;
////							}
////							
////							if (is_output && (my_pipe.is_wide)) {
////								my_score += 5;
////							} else if (is_output && (!my_pipe.is_wide)) {
////								my_score += 10;
////							}
////						}
////					}
//				}
//			}
			
//			current_score = my_score;
			
			scoreTextfield.text = current_score.toString();
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