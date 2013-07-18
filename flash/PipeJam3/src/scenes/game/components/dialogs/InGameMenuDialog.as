package scenes.game.components.dialogs
{
	import display.NineSliceBatch;
	import display.NineSliceButton;
	import events.MenuEvent;
	import display.NineSliceButton;
	import events.NavigationEvent;
	import networking.LoginHelper;
	import starling.display.Sprite;
	import starling.events.Event;
	import scenes.BaseComponent;
	import starling.animation.Juggler;
	import starling.animation.Transitions;
	import starling.core.Starling;
	import flash.geom.Rectangle;

	public class InGameMenuDialog extends BaseComponent
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
		
		private var submitLevelDialog:SubmitLevelDialog;
		
		protected var loginHelper:LoginHelper;	
		
		protected var shapeWidth:int = 96;
		protected var buttonPaddingWidth:int = 8;
		protected var buttonPaddingHeight:int = 8;
		protected var buttonHeight:int = 24;
		protected var buttonWidth:int = shapeWidth - 2*buttonPaddingWidth;
		
		protected var numButtons:int = 4;
		
		protected var hideMainDialog:Boolean = true;
		
		public function InGameMenuDialog()
		{
			super();
			
			if(!PipeJam3.RELEASE_BUILD)
				numButtons = 5;
			
			var backgroundHeight:int = numButtons*buttonHeight + (numButtons+1)*buttonPaddingHeight;
			background = new NineSliceBatch(shapeWidth, backgroundHeight, backgroundHeight / 3.0, backgroundHeight / 3.0, "Game", "PipeJamSpriteSheetPNG", "PipeJamSpriteSheetXML", "MenuBoxAttached");
			addChild(background);
			
			exit_button = ButtonFactory.getInstance().createButton("Exit", buttonWidth, buttonHeight, buttonHeight / 2.0, buttonHeight / 2.0);
			exit_button.addEventListener(starling.events.Event.TRIGGERED, onExitButtonTriggered);
			exit_button.x = buttonPaddingWidth;
			exit_button.y = background.height - buttonPaddingHeight - exit_button.height;
			addChild(exit_button);
			
			submit_layout_button = ButtonFactory.getInstance().createButton("Submit Layout", buttonWidth, buttonHeight, buttonHeight / 2.0, buttonHeight / 2.0);
			submit_layout_button.addEventListener(starling.events.Event.TRIGGERED, onSubmitLayoutButtonTriggered);
			submit_layout_button.x = buttonPaddingWidth;
			submit_layout_button.y = exit_button.y - buttonPaddingHeight - submit_layout_button.height;
			if (PipeJam3.TUTORIAL_DEMO) submit_layout_button.enabled = false;
			addChild(submit_layout_button);
			
			select_layout_button = ButtonFactory.getInstance().createButton("Select Layout", buttonWidth, buttonHeight, buttonHeight / 2.0, buttonHeight / 2.0);
			select_layout_button.addEventListener(starling.events.Event.TRIGGERED, onSelectLayoutButtonTriggered);
			select_layout_button.x = buttonPaddingWidth;
			select_layout_button.y = submit_layout_button.y - buttonPaddingHeight - select_layout_button.height;
			if (PipeJam3.TUTORIAL_DEMO) select_layout_button.enabled = false;
			addChild(select_layout_button);
			
			submit_score_button = ButtonFactory.getInstance().createButton("Submit Score", buttonWidth, buttonHeight, buttonHeight / 2.0, buttonHeight / 2.0);
			submit_score_button.addEventListener(starling.events.Event.TRIGGERED, onSubmitScoreButtonTriggered);
			submit_score_button.x = buttonPaddingWidth;
			submit_score_button.y = select_layout_button.y - buttonPaddingHeight - submit_score_button.height;
			if (PipeJam3.TUTORIAL_DEMO) submit_score_button.enabled = false;
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
		
		private function onSaveButtonTriggered():void
		{
			dispatchEvent(new MenuEvent(MenuEvent.SAVE_LOCALLY));
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

				var juggler:Juggler = Starling.juggler;
				juggler.tween(submitLayoutDialog, 1.0, {
					transition: Transitions.EASE_IN_OUT,
					x: background.width 
				});	
			}
			else
			{
				hideMainDialog = false;
				hideSecondaryDialog(submitLayoutDialog);
			}
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
				
				selectLayoutDialog.x = background.width - selectLayoutDialog.width;
				selectLayoutDialog.y = y + (height - selectLayoutDialog.height);
				selectLayoutDialog.clipRect = new Rectangle(background.width, y + (height - selectLayoutDialog.height), 
					selectLayoutDialog.width, selectLayoutDialog.height);
				
				selectLayoutDialog.setDialogInfo(layoutList);
				var juggler:Juggler = Starling.juggler;
				juggler.tween(selectLayoutDialog, 1.0, {
					transition: Transitions.EASE_IN_OUT,
					x: background.width 
				});	
			}
			else
			{
				hideMainDialog = false;
				hideSecondaryDialog(selectLayoutDialog);
			}
			
		}
		
		public function onBackToGameButtonTriggered():void
		{
			//hide other dialogs
			hideAllDialogs();			
		}
		
		private function onExitButtonTriggered():void
		{
			hideAllDialogs();
			dispatchEvent(new NavigationEvent(NavigationEvent.CHANGE_SCREEN, "SplashScreen"));
			this.removeFromParent();
		}
		
		private function hideAllDialogs():void
		{
			hideMainDialog = true;
			
			if(submitLayoutDialog && submitLayoutDialog.visible == true)
			{
				hideSecondaryDialog(submitLayoutDialog);
			}
			else if (selectLayoutDialog && selectLayoutDialog.visible == true)
			{
				hideSecondaryDialog(selectLayoutDialog);
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
		
		protected function hideSecondaryDialog(dialog:BaseComponent):void
		{
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