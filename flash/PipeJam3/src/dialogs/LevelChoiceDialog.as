package dialogs 
{
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

	public class LevelChoiceDialog extends BaseDialog 
	{
		private var m_callback:Function;
		
		protected var easy_button:NineSliceButton;
		protected var rec_button:NineSliceButton;
		protected var hard_button:NineSliceButton;
		protected var exit_button:NineSliceButton;
		protected var label:TextFieldWrapper;
		
		public function LevelChoiceDialog(text:String, playerRating:Number, easyRating:Number, recRating:Number, hardRating:Number, _width:Number, _height:Number, callback:Function = null, numLinesInText:int = 1, cancelButton:Boolean = false) 
		{
			super(_width, _height);
			
			m_callback = callback;
			
			background.x -= 48;
			background.y += 20;
			
			buttonHeight *= 4;
			buttonWidth *= 3;
			
			if (World.m_world.allLevelsSeen())
			{
				var dialog:ExitGameDialog = new ExitGameDialog(380, 200);
				this.addChild(dialog);
				return;
				/*
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
				return;
				*/
			}
			
			playerRating = Math.round(playerRating);
			easyRating = Math.round(easyRating);
			recRating = Math.round(recRating);
			hardRating = Math.round(hardRating);
			
			label = TextFactory.getInstance().createTextField(text, AssetsFont.FONT_UBUNTU, 120, 14*numLinesInText, 20, 0xFFFFFF);
			TextFactory.getInstance().updateAlign(label, 1, 1);
			addChild(label);
			label.x = (_width - label.width)/2;
			label.y = background.y + 15;
			
			if (World.RatingsDisplayMode == 3)
			{
			var ratingText:String = "Your Rating: " + playerRating.toString();
			var playerRatingLabel:TextFieldWrapper = TextFactory.getInstance().createTextField(ratingText, AssetsFont.FONT_UBUNTU, 120, 14*numLinesInText, 12, 0xFFFFFF);
			TextFactory.getInstance().updateAlign(playerRatingLabel, 1, 1);
			addChild(playerRatingLabel);
			playerRatingLabel.x = (_width - playerRatingLabel.width)/2;
			playerRatingLabel.y = label.y + 20;
			}
			if (!World.noEasyLevels)
			{
				easy_button = ButtonFactory.getInstance().createButton("Easy", buttonWidth - 10, buttonHeight, buttonHeight / 2.0, buttonHeight / 2.0, "", 0.5);
				easy_button.addEventListener(Event.TRIGGERED, onEasyButtonTriggered);
			}
			else
			{
				easy_button = ButtonFactory.getInstance().createButton("None left", buttonWidth - 10, buttonHeight, buttonHeight / 2.0, buttonHeight / 2.0, "", 0.6);
			}
			
			if(!World.noRecLevels)
			{
				rec_button = ButtonFactory.getInstance().createButton("Recommended", buttonWidth + 10, buttonHeight, buttonHeight / 2.0, buttonHeight / 2.0, "", 0.8);
				rec_button.addEventListener(Event.TRIGGERED, onRecButtonTriggered);
			}
			else
			{
				//rec_button = ButtonFactory.getInstance().createButton("None left", buttonWidth + 10, buttonHeight, buttonHeight / 2.0, buttonHeight / 2.0, "", 0.6);
				rec_button = ButtonFactory.getInstance().createButton("None left", buttonWidth - 10, buttonHeight, buttonHeight / 2.0, buttonHeight / 2.0, "", 0.6);
			}
				
			if(!World.noHardLevels)	
			{
				hard_button = ButtonFactory.getInstance().createButton("Hard", buttonWidth - 10, buttonHeight, buttonHeight / 2.0, buttonHeight / 2.0, "", 0.5);
				hard_button.addEventListener(Event.TRIGGERED, onHardButtonTriggered);
			}
			else
			{
				hard_button = ButtonFactory.getInstance().createButton("None left", buttonWidth - 10, buttonHeight, buttonHeight / 2.0, buttonHeight / 2.0, "", 0.6);
				//hard_button = ButtonFactory.getInstance().createButton("None left", buttonWidth + 10, buttonHeight, buttonHeight / 2.0, buttonHeight / 2.0, "", 0.9);
			
			}
			
			
			addChild(easy_button);
			addChild(rec_button);
			addChild(hard_button);
			
			easy_button.x = background.x + (_width - easy_button.width)/2 - 120;
			easy_button.y = background.y + _height / 3;
			
			rec_button.x = background.x + (_width - rec_button.width)/2;
			rec_button.y = background.y + _height / 3;
			
			hard_button.x = background.x + (_width - hard_button.width)/2 + 120;
			hard_button.y = background.y + _height / 3;
			
			if (World.RatingsDisplayMode == 3)
			{
			var easyRatingText:String = World.noEasyLevels ? "Rating: N/A" : "Rating: " + easyRating.toString();
			var easyRatingLabel:TextFieldWrapper = TextFactory.getInstance().createTextField(easyRatingText, AssetsFont.FONT_UBUNTU, 120, 14*numLinesInText, 12, 0xFFFFFF);
			TextFactory.getInstance().updateAlign(easyRatingLabel, 1, 1);
			addChild(easyRatingLabel);
			easyRatingLabel.x = easy_button.x - 10;
			easyRatingLabel.y = easy_button.y + easy_button.height + 10;
			
			var recRatingText:String = World.noRecLevels ? "Rating: N/A" :  "Rating: " + recRating.toString();
			var recRatingLabel:TextFieldWrapper = TextFactory.getInstance().createTextField(recRatingText, AssetsFont.FONT_UBUNTU, 120, 14*numLinesInText, 12, 0xFFFFFF);
			TextFactory.getInstance().updateAlign(recRatingLabel, 1, 1);
			addChild(recRatingLabel);
			recRatingLabel.x = rec_button.x;
			recRatingLabel.y = rec_button.y + rec_button.height + 10;
			
			var hardRatingText:String = World.noHardLevels ? "Rating: N/A" : "Rating: " + hardRating.toString();
			var hardRatingLabel:TextFieldWrapper = TextFactory.getInstance().createTextField(hardRatingText, AssetsFont.FONT_UBUNTU, 120, 14*numLinesInText, 12, 0xFFFFFF);
			TextFactory.getInstance().updateAlign(hardRatingLabel, 1, 1);
			addChild(hardRatingLabel);
			hardRatingLabel.x = hard_button.x - 10;
			hardRatingLabel.y = hard_button.y + hard_button.height + 10;
			
			var easyWinExp:Number = (World.m_world.getWinningExpectancy(playerRating, easyRating) * 100.00);
			var recWinExp:Number = (World.m_world.getWinningExpectancy(playerRating, recRating) * 100.00);
			var hardWinExp:Number = (World.m_world.getWinningExpectancy(playerRating, hardRating) * 100.00);
			
			easyWinExp = easyWinExp < 1 ? easyWinExp : Math.round(easyWinExp);
			recWinExp = recWinExp < 1 ? recWinExp : Math.round(recWinExp);
			hardWinExp = hardWinExp < 1 ? (Math.round(hardWinExp * 100)) / 100 : Math.round(hardWinExp);
			
			var easyWinText:String = "Win Estimate: ";
			var easyWinTextLabel:TextFieldWrapper = TextFactory.getInstance().createTextField(easyWinText, AssetsFont.FONT_UBUNTU, 120, 14*numLinesInText, 12, 0xFFFFFF);
			TextFactory.getInstance().updateAlign(easyWinTextLabel, 1, 1);
			easyWinTextLabel.x = easyRatingLabel.x;
			easyWinTextLabel.y = easyRatingLabel.y + 20;
			addChild(easyWinTextLabel);
			
			var recWinText:String = "Win Estimate: ";
			var recWinTextLabel:TextFieldWrapper = TextFactory.getInstance().createTextField(recWinText, AssetsFont.FONT_UBUNTU, 120, 14*numLinesInText, 12, 0xFFFFFF);
			TextFactory.getInstance().updateAlign(recWinTextLabel, 1, 1);
			recWinTextLabel.x = rec_button.x;
			recWinTextLabel.y = recRatingLabel.y + 20;
			addChild(recWinTextLabel);
			
			var hardWinText:String = "Win Estimate: ";
			var hardWinTextLabel:TextFieldWrapper = TextFactory.getInstance().createTextField(hardWinText, AssetsFont.FONT_UBUNTU, 120, 14*numLinesInText, 12, 0xFFFFFF);
			TextFactory.getInstance().updateAlign(hardWinTextLabel, 1, 1);
			hardWinTextLabel.x = hardRatingLabel.x;
			hardWinTextLabel.y = hardRatingLabel.y + 20;
			addChild(hardWinTextLabel);
			
			var easyWinExpText:String = easyWinExp.toString() + "%";
			var easyWinExpLabel:TextFieldWrapper = TextFactory.getInstance().createTextField(World.noEasyLevels ? "N/A" : easyWinExpText, AssetsFont.FONT_UBUNTU, 120, 14*numLinesInText, 12, 0xFFFFFF);
			TextFactory.getInstance().updateAlign(easyWinExpLabel, 1, 1);
			addChild(easyWinExpLabel);
			easyWinExpLabel.x = easyRatingLabel.x;
			easyWinExpLabel.y = easyWinTextLabel.y + 10;
			
			var recWinExpText:String = recWinExp.toString() + "%";
			var recWinExpLabel:TextFieldWrapper = TextFactory.getInstance().createTextField(World.noRecLevels ? "N/A" : recWinExpText, AssetsFont.FONT_UBUNTU, 120, 14*numLinesInText, 12, 0xFFFFFF);
			TextFactory.getInstance().updateAlign(recWinExpLabel, 1, 1);
			addChild(recWinExpLabel);
			recWinExpLabel.x = rec_button.x;
			recWinExpLabel.y = recWinTextLabel.y + 10;
			
			var hardWinExpText:String = hardWinExp.toString() + "%";
			var hardWinExpLabel:TextFieldWrapper = TextFactory.getInstance().createTextField(World.noHardLevels ? "N/A" : hardWinExpText, AssetsFont.FONT_UBUNTU, 120, 14*numLinesInText, 12, 0xFFFFFF);
			TextFactory.getInstance().updateAlign(hardWinExpLabel, 1, 1);
			addChild(hardWinExpLabel);
			hardWinExpLabel.x = hardRatingLabel.x;
			hardWinExpLabel.y = hardWinTextLabel.y + 10;
			}
		}
		
		private function onEasyButtonTriggered(evt:Event):void
		{
			//World.m_world.clearSplashDisplay();
			if (!World.noEasyLevels)
			{
			visible = false;
			parent.removeChild(this);
			var target:NineSliceButton = NineSliceButton(evt.target);
			trace("Event Target: " + target.GetText());
			var button:String = target.GetText();
			if(m_callback != null)
				m_callback(button);
			}
		}
		
		private function onRecButtonTriggered(evt:Event):void
		{
		//	World.m_world.clearSplashDisplay();
			if (!World.noRecLevels)
			{
			visible = false;
			this.removeChildren();
			parent.removeChild(this);
			var target:NineSliceButton = NineSliceButton(evt.target);
			trace("Event Target: " + target.GetText());
			var button:String = target.GetText();
			if(m_callback != null)
				m_callback(button);
			}
		}
		
		private function onHardButtonTriggered(evt:Event):void
		{
			//World.m_world.clearSplashDisplay();
			if (!World.noHardLevels)
			{
			visible = false;
			parent.removeChild(this);
			var target:NineSliceButton = NineSliceButton(evt.target);
			trace("Event Target: " + target.GetText());
			var button:String = target.GetText();
			if(m_callback != null)
				m_callback(button);
			}
		}
		
		private function onExitButtonTriggered(evt:Event):void
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