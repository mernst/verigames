package dialogs
{
	import display.NineSliceBatch;
	import display.NineSliceButton;
	
	import events.MenuEvent;
	import events.NavigationEvent;
	
	import flash.geom.Rectangle;
	
	import networking.LoginHelper;
	
	import scenes.BaseComponent;
	import scenes.game.PipeJamGameScene;
	import scenes.layoutselectscene.LayoutSelectScene;
	
	import starling.animation.Juggler;
	import starling.animation.Transitions;
	import starling.core.Starling;
	import starling.display.Sprite;
	import starling.events.Event;

	public class InGameMenuDialog extends BaseComponent
	{
		/** Button to share the current game */
		protected var submit_score_button:NineSliceButton;
		
		/** Button to save the current game */
		protected var save_score_button:NineSliceButton;
		
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
		
		private var submitLevelDialog:SubmitLevelDialog;
		
		protected var loginHelper:LoginHelper;	
		
		protected var shapeWidth:int = 96;
		protected var buttonPaddingWidth:int = 8;
		protected var buttonPaddingHeight:int = 8;
		protected var buttonHeight:int = 24;
		protected var buttonWidth:int = shapeWidth - 2*buttonPaddingWidth;
		
		protected var numButtons:int = 5;
		
		protected var hideMainDialog:Boolean = true;
		
		public function InGameMenuDialog()
		{
			super();
			
			if(!PipeJam3.RELEASE_BUILD)
				numButtons ++;
			
			var backgroundHeight:int = numButtons*buttonHeight + (numButtons+1)*buttonPaddingHeight;
			background = new NineSliceBatch(shapeWidth, backgroundHeight, backgroundHeight / 3.0, backgroundHeight / 3.0, "Game", "PipeJamSpriteSheetPNG", "PipeJamSpriteSheetXML", "MenuBoxAttached");
			addChild(background);
			
			exit_button = ButtonFactory.getInstance().createButton("Exit", buttonWidth, buttonHeight, buttonHeight / 2.0, buttonHeight / 2.0, "Return to\nLevel Select");
			exit_button.addEventListener(starling.events.Event.TRIGGERED, onExitButtonTriggered);
			exit_button.x = buttonPaddingWidth;
			exit_button.y = background.height - buttonPaddingHeight - exit_button.height;
			addChild(exit_button);
			
			submit_layout_button = ButtonFactory.getInstance().createButton("Share Layout", buttonWidth, buttonHeight, buttonHeight / 2.0, buttonHeight / 2.0, "Share your\nlayout with\nother players");
			submit_layout_button.addEventListener(starling.events.Event.TRIGGERED, onSubmitLayoutButtonTriggered);
			submit_layout_button.x = buttonPaddingWidth;
			submit_layout_button.y = exit_button.y - buttonPaddingHeight - submit_layout_button.height;
			if (PipeJam3.TUTORIAL_DEMO || PipeJamGameScene.inTutorial) submit_layout_button.enabled = false;
			addChild(submit_layout_button);
			
			select_layout_button = ButtonFactory.getInstance().createButton("Select Layout", buttonWidth, buttonHeight, buttonHeight / 2.0, buttonHeight / 2.0, "Load a\nsaved layout,\nscoring will\nnot change");
			select_layout_button.addEventListener(starling.events.Event.TRIGGERED, onSelectLayoutButtonTriggered);
			select_layout_button.x = buttonPaddingWidth;
			select_layout_button.y = submit_layout_button.y - buttonPaddingHeight - select_layout_button.height;
			if (PipeJam3.TUTORIAL_DEMO || PipeJamGameScene.inTutorial) select_layout_button.enabled = false;
			addChild(select_layout_button);
			
			save_score_button = ButtonFactory.getInstance().createButton("Save Level", buttonWidth, buttonHeight, buttonHeight / 2.0, buttonHeight / 2.0, "Save or share\nyour progress");
			save_score_button.addEventListener(starling.events.Event.TRIGGERED, onSaveScoreButtonTriggered);
			save_score_button.x = buttonPaddingWidth;
			save_score_button.y = select_layout_button.y - buttonPaddingHeight - save_score_button.height;
			if (PipeJam3.TUTORIAL_DEMO || PipeJamGameScene.inTutorial) save_score_button.enabled = false;
			addChild(save_score_button);
			
			submit_score_button = ButtonFactory.getInstance().createButton("Submit Level", buttonWidth, buttonHeight, buttonHeight / 2.0, buttonHeight / 2.0, "Submit your\nsolution for\ncredit");
			submit_score_button.addEventListener(starling.events.Event.TRIGGERED, onSubmitScoreButtonTriggered);
			submit_score_button.x = buttonPaddingWidth;
			submit_score_button.y = save_score_button.y - buttonPaddingHeight - submit_score_button.height;
			
			if (PipeJam3.TUTORIAL_DEMO || PipeJamGameScene.inTutorial) submit_score_button.enabled = false;
			addChild(submit_score_button);
			
			if(!PipeJam3.RELEASE_BUILD)
			{
				next_level_button = ButtonFactory.getInstance().createButton("Next Level", buttonWidth, buttonHeight, buttonHeight / 2.0, buttonHeight / 2.0);
				next_level_button.addEventListener(starling.events.Event.TRIGGERED, onNextLevelButtonTriggered);
				next_level_button.x = buttonPaddingWidth;
				next_level_button.y = submit_score_button.y - buttonPaddingHeight - next_level_button.height;
				addChild(next_level_button);
			}
			
			loginHelper = LoginHelper.getLoginHelper();
		}
		
		private function onSaveScoreButtonTriggered():void
		{
			dispatchEvent(new MenuEvent(MenuEvent.SAVE_LEVEL));
		}
		
		private function onSubmitScoreButtonTriggered():void
		{
			if(submitLevelDialog == null)
			{
				submitLevelDialog = new SubmitLevelDialog(200, 200);
				parent.addChild(submitLevelDialog);
				
				submitLevelDialog.x = (480 - submitLevelDialog.width)/2;
				submitLevelDialog.y = (320 - submitLevelDialog.height)/2;
				submitLevelDialog.visible = true;
				//add clip rect so box seems to slide up out of the gameControlPanel
			}
			else
				submitLevelDialog.visible = !submitLevelDialog.visible;
		}
		
		private function onSubmitLayoutButtonTriggered():void
		{			
			//get the name
			if(submitLayoutDialog == null)
			{
				submitLayoutDialog = new SubmitLayoutDialog();
				parent.addChild(submitLayoutDialog);
				submitLayoutDialog.x = background.width - submitLayoutDialog.width;
				submitLayoutDialog.y = y + (height - submitLayoutDialog.height);
				submitLayoutDialog.visible = true;
				submitLayoutDialog.clipRect = new Rectangle(background.width, y + (height - submitLayoutDialog.height), 
										submitLayoutDialog.width, submitLayoutDialog.height);

				Starling.juggler.tween(submitLayoutDialog, 1.0, {
					transition: Transitions.EASE_IN_OUT,
					x: background.width 
				});	
			}
			else if(submitLayoutDialog.visible)
			{
				hideSecondaryDialog(submitLayoutDialog, false);
			}
			else
			{
				submitLayoutDialog.resetText();
				submitLayoutDialog.x = background.width - submitLayoutDialog.width;
				submitLayoutDialog.y = y + (height - submitLayoutDialog.height);
				submitLayoutDialog.visible = true;
				submitLayoutDialog.clipRect = new Rectangle(background.width, y + (height - submitLayoutDialog.height), 
					submitLayoutDialog.width, submitLayoutDialog.height);
				
				Starling.juggler.tween(submitLayoutDialog, 1.0, {
					transition: Transitions.EASE_IN_OUT,
					x: background.width 
				});	
			}
		}
		
		private function onSelectLayoutButtonTriggered():void
		{
			var loginHelper:LoginHelper = LoginHelper.getLoginHelper();
			onBackToGameButtonTriggered();//close menu
			if(loginHelper != null && loginHelper.levelObject != null)
			{
				dispatchEvent(new Event(Game.START_BUSY_ANIMATION,true));
				loginHelper.getLayoutList(onRequestLayoutList);
			}
			else
				onRequestLayoutList(0, null);  //just for testing, as it leads nowhere...
		}
		
		protected function onRequestLayoutList(result:int, layoutList:Vector.<Object>):void
		{
			dispatchEvent(new Event(Game.STOP_BUSY_ANIMATION,true));
			var layoutSelectScene:LayoutSelectScene = new LayoutSelectScene();
			layoutSelectScene.setLayouts(layoutList);
			parent.addChild(layoutSelectScene);
		}
		
		public function onBackToGameButtonTriggered():void
		{
			//hide other dialogs
			hideAllDialogs();			
		}
		
		private function onExitButtonTriggered():void
		{
			hideAllDialogs();
			loginHelper.stopLevel();
			dispatchEvent(new NavigationEvent(NavigationEvent.CHANGE_SCREEN, "LevelSelectScene"));
		}
		
		public function hideAllDialogs():void
		{
			if(submitLayoutDialog && submitLayoutDialog.visible == true)
			{
				hideSecondaryDialog(submitLayoutDialog, true);
			}
			else if (selectLayoutDialog && selectLayoutDialog.visible == true)
			{
				hideSecondaryDialog(selectLayoutDialog, true);
			}
			else
				hideSelf();
		}
		
		protected function hideSelf():void
		{
			var juggler:Juggler = Starling.juggler;
			juggler.tween(this, 1.0, {
				transition: Transitions.EASE_IN_OUT,
				onComplete: onHideSelfComplete,
				y: y + height 
			});			
		}
		
		protected function onHideSelfComplete():void
		{
			visible = false;
		}
		
		public function hideSecondaryDialog(dialog:BaseComponent, _hideMainDialog:Boolean):void
		{
			hideMainDialog = _hideMainDialog;
			
			var juggler:Juggler = Starling.juggler;

			juggler.tween(dialog, 1.0, {
				transition: Transitions.EASE_IN_OUT,
				onComplete: onHideSecondaryDialogComplete,
				x: dialog.x - dialog.width
			});			
		}
		
		protected function onHideSecondaryDialogComplete():void
		{
			submitLayoutDialog = null;
			selectLayoutDialog = null;
			if(hideMainDialog)
				hideSelf();
		}
		


		
		private function onNextLevelButtonTriggered():void
		{
			dispatchEvent(new NavigationEvent(NavigationEvent.SWITCH_TO_NEXT_LEVEL, "", true));
		}
	}
}