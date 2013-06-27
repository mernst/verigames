package scenes.game.components.dialogs
{
	import assets.AssetInterface;
	
	
	import events.NavigationEvent;
	
	import flash.geom.Point;
	
	import scenes.BaseComponent;
	import scenes.game.display.Level;
	import scenes.game.display.World;
	import scenes.login.LoginHelper;
	
	import starling.display.Button;
	import starling.display.Image;
	import starling.display.Sprite;
	import starling.events.Event;
	import starling.events.Touch;
	import starling.events.TouchEvent;
	import starling.events.TouchPhase;
	import starling.textures.Texture;

	import display.NineSliceButton;
	import display.NineSliceBatch;
	
	public class InGameMenuDialog extends Sprite
	{
				
		/** Button to submit the current game */
		protected var submit_score_button:NineSliceButton;
		
		/** Button to submit the current layout */
		protected var submit_layout_button:NineSliceButton;
		
		/** Button to select a new layout */
		protected var select_layout_button:NineSliceButton;
				
		/** Button to exit to the splash screen */
		protected var exit_button:NineSliceButton;

		
		/** Button to switch to the next level only available in debug build */
		protected var next_level_button:NineSliceButton;
		
		private var background:NineSliceBatch;
		
		private var selectLayoutDialog:SelectLayoutDialog;
		
		private var submitLayoutDialog:SubmitLayoutDialog;
		
		protected var loginHelper:LoginHelper;	
		
		protected var shapeWidth:int = 86;
		protected var buttonPaddingWidth:int = 8;
		protected var buttonPaddingHeight:int = 8;
		protected var buttonHeight:int = 20;
		protected var buttonWidth:int = shapeWidth - 2*buttonPaddingWidth;
		
		protected var numButtons:int = 4;
		
		public function InGameMenuDialog()
		{
			super();
			
			if(!PipeJam3.RELEASE_BUILD)
				numButtons = 5;
			
			var backgroundHeight:int = numButtons*buttonHeight + (numButtons+1)*buttonPaddingHeight;
			background = new NineSliceBatch(shapeWidth, backgroundHeight, backgroundHeight / 3.0, backgroundHeight / 3.0, "Game", "PipeJamSpriteSheetPNG", "PipeJamSpriteSheetXML", "MenuBoxAttached");
			addChild(background);
			
			exit_button = ButtonFactory.getInstance().createDefaultButton("Exit", buttonWidth, buttonHeight);
			exit_button.addEventListener(starling.events.Event.TRIGGERED, onExitButtonTriggered);
			exit_button.x = buttonPaddingWidth;
			exit_button.y = background.height - buttonPaddingHeight - exit_button.height;
			addChild(exit_button);
			
			submit_layout_button = ButtonFactory.getInstance().createDefaultButton("Submit Layout", buttonWidth, buttonHeight);
			submit_layout_button.addEventListener(starling.events.Event.TRIGGERED, onSubmitLayoutButtonTriggered);
			submit_layout_button.x = buttonPaddingWidth;
			submit_layout_button.y = exit_button.y - buttonPaddingHeight - submit_layout_button.height;
			addChild(submit_layout_button);
			
			select_layout_button = ButtonFactory.getInstance().createDefaultButton("Select Layout", buttonWidth, buttonHeight);
			select_layout_button.addEventListener(starling.events.Event.TRIGGERED, onSelectLayoutButtonTriggered);
			select_layout_button.x = buttonPaddingWidth;
			select_layout_button.y = submit_layout_button.y - buttonPaddingHeight - select_layout_button.height;
			addChild(select_layout_button);
			
			submit_score_button = ButtonFactory.getInstance().createDefaultButton("Submit Score", buttonWidth, buttonHeight);
			submit_score_button.addEventListener(starling.events.Event.TRIGGERED, onSubmitScoreButtonTriggered);
			submit_score_button.x = buttonPaddingWidth;
			submit_score_button.y = select_layout_button.y - buttonPaddingHeight - submit_score_button.height;
			addChild(submit_score_button);
					
			if(!PipeJam3.RELEASE_BUILD)
			{
				next_level_button = ButtonFactory.getInstance().createDefaultButton("Next Level", buttonWidth, buttonHeight);
				next_level_button.addEventListener(starling.events.Event.TRIGGERED, onNextLevelButtonTriggered);
				next_level_button.x = buttonPaddingWidth;
				next_level_button.y = submit_score_button.y - buttonPaddingHeight - next_level_button.height;
				addChild(next_level_button);
			}
			
			loginHelper = LoginHelper.getLoginHelper();
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
				submitLayoutDialog.x = background.width;
				submitLayoutDialog.y = y + (height - submitLayoutDialog.height);
				submitLayoutDialog.visible = true;
			}
			else
				submitLayoutDialog.visible = !submitLayoutDialog.visible;
		}
		
		private function onSelectLayoutButtonTriggered():void
		{
			if(LoginHelper.levelObject != null)
			{
				dispatchEvent(new Event(Game.START_BUSY_ANIMATION,true));
				loginHelper.onRequestLayoutList(onRequestLayoutList);
			}
			else
				onRequestLayoutList(0, null);
		}
		
		protected function onRequestLayoutList(result:int, layoutList:Vector.<Object>):void
		{
			if(selectLayoutDialog == null)
			{
				selectLayoutDialog = new SelectLayoutDialog();
				parent.addChild(selectLayoutDialog);
				selectLayoutDialog.x = background.width;
				selectLayoutDialog.y = y + (height - selectLayoutDialog.height);
				selectLayoutDialog.visible = true;
			}
			else
				selectLayoutDialog.visible = !selectLayoutDialog.visible;
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