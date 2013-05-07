package scenes.game.components
{
	import scenes.BaseComponent;
	import assets.AssetInterface;
	import starling.textures.Texture;
	import starling.display.Button;
	import scenes.game.display.World;
	import scenes.game.display.Level;
	import starling.events.Event;
	import events.NavigationEvent;

	public class InGameMenuBox extends BaseComponent
	{
		
		/** Button to save the current game */
		public var save_button:Button;
		
		/** Button to submit the current game */
		public var submitScore_button:Button;
		
		/** Button to submit the current layout */
		public var submitLayout_button:Button;
		
		/** Button to go back to the current game */
		public var backToGame_button:Button;
		
		/** Button to exit to the splash screen */
		public var exit_button:Button;
		
		/** Button to switch to the next level */
		public var nextLevel_button:Button;
		
		public function InGameMenuBox()
		{
			super();
			
			var saveButtonUp:Texture = AssetInterface.getTexture("Menu", "SaveButtonClass");
			var saveButtonClick:Texture = AssetInterface.getTexture("Menu", "SaveButtonClickClass");
			
			save_button = new Button(saveButtonUp, "", saveButtonClick);
			save_button.addEventListener(Event.TRIGGERED, onSaveButtonTriggered);
			save_button.x = 2;
			save_button.y = 2;
			save_button.width *= .5;
			save_button.height *= .5;
			addChild(save_button);
			
			var submitScoreButtonUp:Texture = AssetInterface.getTexture("Menu", "SubmitScoreButtonClass");
			var submitScoreBButtonClick:Texture = AssetInterface.getTexture("Menu", "SubmitScoreButtonClickClass");
			
			submitScore_button = new Button(submitScoreButtonUp, "", submitScoreBButtonClick);
			submitScore_button.addEventListener(Event.TRIGGERED, onSubmitScoreButtonTriggered);
			submitScore_button.x = 2;
			submitScore_button.y = 52;
			submitScore_button.width *= .5;
			submitScore_button.height *= .5;
			addChild(submitScore_button);
			
			var submitLayoutButtonUp:Texture = AssetInterface.getTexture("Menu", "SubmitLayoutButtonClass");
			var submitLayoutButtonClick:Texture = AssetInterface.getTexture("Menu", "SubmitLayoutButtonClickClass");
			
			submitLayout_button = new Button(submitLayoutButtonUp, "", submitLayoutButtonClick);
			submitLayout_button.addEventListener(Event.TRIGGERED, onSubmitLayoutButtonTriggered);
			submitLayout_button.x = 2;
			submitLayout_button.y = 102;
			submitLayout_button.width *= .5;
			submitLayout_button.height *= .5;
			addChild(submitLayout_button);
			
			var backToGameButtonUp:Texture = AssetInterface.getTexture("Menu", "BackToGameButtonClass");
			var backToGameButtonClick:Texture = AssetInterface.getTexture("Menu", "BackToGameButtonClickClass");
			
			backToGame_button = new Button(backToGameButtonUp, "", backToGameButtonClick);
			backToGame_button.addEventListener(Event.TRIGGERED, onBackToGameButtonTriggered);
			backToGame_button.x = 2;
			backToGame_button.y = 152;
			backToGame_button.width *= .5;
			backToGame_button.height *= .5;
			addChild(backToGame_button);
			
			var exitButtonUp:Texture = AssetInterface.getTexture("Menu", "ExitButtonClass");
			var exitButtonClick:Texture = AssetInterface.getTexture("Menu", "ExitButtonClickClass");
			
			exit_button = new Button(exitButtonUp, "", exitButtonClick);
			exit_button.addEventListener(Event.TRIGGERED, onExitButtonTriggered);
			exit_button.x = 2;
			exit_button.y = 202;
			exit_button.width *= .5;
			exit_button.height *= .5;
			addChild(exit_button);
			
			var nextLevelButtonUp:Texture = AssetInterface.getTexture("Menu", "NextLevelButtonClass");
			var nextLevelButtonClick:Texture = AssetInterface.getTexture("Menu", "NextLevelButtonClickClass");
			
			nextLevel_button = new Button(nextLevelButtonUp, "", nextLevelButtonClick);
			nextLevel_button.addEventListener(Event.TRIGGERED, onNextLevelButtonTriggered);
			nextLevel_button.x = 2;
			nextLevel_button.y = 252;
			nextLevel_button.width *= .5;
			nextLevel_button.height *= .5;
			addChild(nextLevel_button);
		}
		
		private function onSaveButtonTriggered():void
		{
			dispatchEvent(new starling.events.Event(Level.SAVE_LOCALLY, true, this));
			
		}
		
		private function onSubmitScoreButtonTriggered():void
		{
			dispatchEvent(new starling.events.Event(Level.SUBMIT_SCORE, true, this));
		}
		
		private function onSubmitLayoutButtonTriggered():void
		{
			dispatchEvent(new starling.events.Event(Level.SAVE_LAYOUT, true, this));
		}
		
		private function onBackToGameButtonTriggered():void
		{
			this.removeFromParent();
			
		}
		
		private function onExitButtonTriggered():void
		{
			dispatchEvent(new NavigationEvent(NavigationEvent.CHANGE_SCREEN, "SplashScreen", true));
			this.removeFromParent();
			
		}
		
		private function onNextLevelButtonTriggered():void
		{
			dispatchEvent(new Event(World.SWITCH_TO_NEXT_LEVEL, true));
			
		}
	}
}