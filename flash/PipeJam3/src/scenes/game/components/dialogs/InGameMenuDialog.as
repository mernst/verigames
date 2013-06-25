package scenes.game.components.dialogs
{
	import flash.geom.Point;
	import starling.display.Button;
	import starling.display.Image;
	import starling.events.Event;
	import starling.events.Touch;
	import starling.events.TouchEvent;
	import starling.events.TouchPhase;
	import starling.textures.Texture;
	
	import assets.AssetInterface;
	import events.NavigationEvent;
	import scenes.BaseComponent;
	import scenes.game.display.Level;
	import scenes.game.display.World;
	import scenes.login.LoginHelper;
	
	public class InGameMenuDialog extends BaseComponent
	{
		
		/** Button to save the current game */
		public var save_button:Button;
		
		/** Button to submit the current game */
		public var submitScore_button:Button;
		
		/** Button to submit the current layout */
		public var submitLayout_button:Button;
		
		/** Button to submit the current layout */
		public var selectLayout_button:Button;
		
		/** Button to go back to the current game */
		public var backToGame_button:Button;
		
		/** Button to exit to the splash screen */
		public var exit_button:Button;
		
		/** Button to switch to the next level */
		public var nextLevel_button:Button;
		
		private var backgroundImage:Image;
		
		private var selectLayoutDialog:SelectLayoutDialog;
		private var submitLayoutDialog:SubmitLayoutDialog;
		
		protected var loginHelper:LoginHelper;
		
		public function InGameMenuDialog()
		{
			super();
			
			
			var background:Texture = AssetInterface.getTexture("Menu", "InGameMenuBackgroundClass");
			backgroundImage = new Image(background);

			addChild(backgroundImage);
			
//			var saveButtonUp:Texture = AssetInterface.getTexture("Menu", "SaveButtonClass");
//			var saveButtonClick:Texture = AssetInterface.getTexture("Menu", "SaveButtonClickClass");
//			
//			save_button = new Button(saveButtonUp, "", saveButtonClick);
//			save_button.addEventListener(Event.TRIGGERED, onSaveButtonTriggered);
//			save_button.x = 2;
//			save_button.y = 2;
//			save_button.width *= .5;
//			save_button.height *= .5;
//			addChild(save_button);
//			
//			var submitScoreButtonUp:Texture = AssetInterface.getTexture("Menu", "SubmitScoreButtonClass");
//			var submitScoreBButtonClick:Texture = AssetInterface.getTexture("Menu", "SubmitScoreButtonClickClass");
//			
//			submitScore_button = new Button(submitScoreButtonUp, "", submitScoreBButtonClick);
//			submitScore_button.addEventListener(Event.TRIGGERED, onSubmitScoreButtonTriggered);
//			submitScore_button.x = 2;
//			submitScore_button.y = 52;
//			submitScore_button.width *= .5;
//			submitScore_button.height *= .5;
//			addChild(submitScore_button);
//			
//			var submitLayoutButtonUp:Texture = AssetInterface.getTexture("Menu", "SubmitLayoutButtonClass");
//			var submitLayoutButtonClick:Texture = AssetInterface.getTexture("Menu", "SubmitLayoutButtonClickClass");
//			
//			submitLayout_button = new Button(submitLayoutButtonUp, "", submitLayoutButtonClick);
//			submitLayout_button.addEventListener(Event.TRIGGERED, onSubmitLayoutButtonTriggered);
//			submitLayout_button.x = 2;
//			submitLayout_button.y = 102;
//			submitLayout_button.width *= .5;
//			submitLayout_button.height *= .25;
//			addChild(submitLayout_button);
//			
//			var selectLayoutButtonUp:Texture = AssetInterface.getTexture("Menu", "SubmitLayoutButtonClass");
//			var selectLayoutButtonClick:Texture = AssetInterface.getTexture("Menu", "SubmitLayoutButtonClickClass");
//			
//			submitLayout_button = new Button(selectLayoutButtonUp, "", selectLayoutButtonClick);
//			submitLayout_button.addEventListener(Event.TRIGGERED, onSelectLayoutButtonTriggered);
//			submitLayout_button.x = 2;
//			submitLayout_button.y = 125;
//			submitLayout_button.width *= .5;
//			submitLayout_button.height *= .25;
//			addChild(submitLayout_button);
//			
//			var backToGameButtonUp:Texture = AssetInterface.getTexture("Menu", "BackToGameButtonClass");
//			var backToGameButtonClick:Texture = AssetInterface.getTexture("Menu", "BackToGameButtonClickClass");
//			
//			backToGame_button = new Button(backToGameButtonUp, "", backToGameButtonClick);
//			backToGame_button.addEventListener(Event.TRIGGERED, onBackToGameButtonTriggered);
//			backToGame_button.x = 2;
//			backToGame_button.y = 152;
//			backToGame_button.width *= .5;
//			backToGame_button.height *= .5;
//			addChild(backToGame_button);
//			
//			var exitButtonUp:Texture = AssetInterface.getTexture("Menu", "ExitButtonClass");
//			var exitButtonClick:Texture = AssetInterface.getTexture("Menu", "ExitButtonClickClass");
//			
//			exit_button = new Button(exitButtonUp, "", exitButtonClick);
//			exit_button.addEventListener(Event.TRIGGERED, onExitButtonTriggered);
//			exit_button.x = 2;
//			exit_button.y = 202;
//			exit_button.width *= .5;
//			exit_button.height *= .5;
//			addChild(exit_button);
//			
//			if(!PipeJamGame.RELEASE_BUILD)
//			{
//				var nextLevelButtonUp:Texture = AssetInterface.getTexture("Menu", "NextLevelButtonClass");
//				var nextLevelButtonClick:Texture = AssetInterface.getTexture("Menu", "NextLevelButtonClickClass");
//				
//				nextLevel_button = new Button(nextLevelButtonUp, "", nextLevelButtonClick);
//				nextLevel_button.addEventListener(Event.TRIGGERED, onNextLevelButtonTriggered);
//				nextLevel_button.x = 2;
//				nextLevel_button.y = 252;
//				nextLevel_button.width *= .5;
//				nextLevel_button.height *= .5;
//				addChild(nextLevel_button);
//			}
			
			addEventListener(TouchEvent.TOUCH, onTouch);
			
			loginHelper = LoginHelper.getLoginHelper();
		}
		
		private function onTouch(event:TouchEvent):void
		{
			var touches:Vector.<Touch> = event.touches;
			if(event.getTouches(this, TouchPhase.ENDED).length){
				var currentPoint:Point = touches[0].getLocation(this);
				if(currentPoint.x < backgroundImage.width)
				{
					if(currentPoint.y < backgroundImage.height/5)
						onNextLevelButtonTriggered();
					else if(currentPoint.y < (backgroundImage.height/5)*2)
						onSelectLayoutButtonTriggered();
					else if(currentPoint.y < (backgroundImage.height/5)*3)
						onSubmitLayoutButtonTriggered();
					else if(currentPoint.y < (backgroundImage.height/5)*4)
						onSubmitScoreButtonTriggered();
					else
						onExitButtonTriggered();
				}
				
			}
		}
		
		private function onSaveButtonTriggered():void
		{
			dispatchEvent(new Event(Level.SAVE_LOCALLY, true, this));
			
		}
		
		private function onSubmitScoreButtonTriggered():void
		{
			dispatchEvent(new Event(Level.SUBMIT_SCORE, true, this));
		}
		
		private function onSubmitLayoutButtonTriggered():void
		{
			//get the name
			if(submitLayoutDialog == null)
			{
				submitLayoutDialog = new SubmitLayoutDialog();
				parent.addChild(submitLayoutDialog);
				submitLayoutDialog.x = backgroundImage.width;
				submitLayoutDialog.y = y + (height - submitLayoutDialog.height);
				submitLayoutDialog.visible = true;
			}
			else
				submitLayoutDialog.visible = !submitLayoutDialog.visible;
		}
		
		private function onSelectLayoutButtonTriggered():void
		{
			dispatchEvent(new Event(Game.START_BUSY_ANIMATION,true));
			loginHelper.onRequestLayoutList(onRequestLayoutList);
		}
		
		protected function onRequestLayoutList(result:int, layoutList:Vector.<Object>):void
		{
			if(selectLayoutDialog == null)
				selectLayoutDialog = new SelectLayoutDialog();
			
			selectLayoutDialog.setLayouts(layoutList);
			addChild(selectLayoutDialog);
		}
		
		private function onBackToGameButtonTriggered():void
		{
			//hide other dialogs
			hideAllDialogs();			
		}
		
		private function onExitButtonTriggered():void
		{
			hideAllDialogs();
			dispatchEvent(new NavigationEvent(NavigationEvent.CHANGE_SCREEN, "SplashScreen", true));
			this.removeFromParent();
			
		}
		
		private function hideAllDialogs():void
		{
			if(submitLayoutDialog)
				submitLayoutDialog.visible = false;
			
			visible = false;
		}
		
		private function onNextLevelButtonTriggered():void
		{
			dispatchEvent(new Event(World.SWITCH_TO_NEXT_LEVEL, true));
		}
	}
}