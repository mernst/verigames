package dialogs 
{
	/**
	 * ...
	 * @author ...
	 */
	
	import assets.AssetInterface;
	import assets.AssetsFont;
	import display.NineSliceBatch;
	
	import display.BasicButton;
	import display.NineSliceButton;
	
	import starling.display.Quad;
	
	import flash.geom.Rectangle;
	
	import scenes.BaseComponent;
	
	import starling.display.Image;
	import starling.events.Event;
	import starling.textures.Texture;
	
	import scenes.game.display.World;
	
	import server.NULogging;
	
	import networking.TutorialController;
	
	import events.NavigationEvent;
	
	public class ExitGameDialog extends BaseDialog 
	{
		protected var exit_button:NineSliceButton;
		protected var label:TextFieldWrapper;
		
		public function ExitGameDialog(_width:Number, _height:Number, numLinesInText:int = 1) 
		{
			super(_width, _height);
			
			background.x -= 48;
			background.y += 20;
			
			buttonHeight *= 4;
			buttonWidth *= 3;
			
			label = TextFactory.getInstance().createTextField("No more levels left to play! Please click the button to exit.", AssetsFont.FONT_UBUNTU, 280, 28*numLinesInText, 20, 0xFFFFFF);
			TextFactory.getInstance().updateAlign(label, 1, 1);
			addChild(label);
			label.x = (_width - label.width)/2;
			label.y = background.y + 15;
			exit_button = ButtonFactory.getInstance().createButton("Exit", buttonWidth - 10, buttonHeight, buttonHeight / 2.0, buttonHeight / 2.0, "", 0.5);
			addChild(exit_button);
			exit_button.x = background.x + (_width - exit_button.width)/2;
			exit_button.y = background.y + _height / 3; 
			exit_button.addEventListener(Event.TRIGGERED, onExitButtonTriggered);
		}
		
		private function onExitButtonTriggered():void
		{
			var o:Object = new Object();
			o["details"] = "Definitely wanted to skip to survey.";			
			NULogging.action(o, NULogging.ACTION_TYPE_SKIP_TO_SURVEY_CLICKED);
			
			// When skipping to survey, mark it as the end of this run.
			NULogging.runEnd(o);
			
			World.gamePlayDone = true;
			dispatchEvent(new NavigationEvent(NavigationEvent.SHOW_GAME_MENU));
			var attemptedLevel:Boolean = World.movesBrushHexagon + World.movesBrushSquare
								+ World.movesBrushCircle + World.movesBrushDiamond > 0;
			if (TutorialController.tutorialsDone)
			{
				if(attemptedLevel)
					World.totalLevelsAttempted++;
				else
					World.totallevelsAbandoned++;
			}
		}
		
	}

}