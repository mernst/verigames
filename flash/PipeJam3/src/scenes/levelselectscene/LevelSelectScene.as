package scenes.levelselectscene
{
	import assets.AssetInterface;
	import assets.AssetsFont;
	
	import display.BasicButton;
	import display.NineSliceBatch;
	import display.NineSliceButton;
	import display.NineSliceToggleButton;
	
	import events.NavigationEvent;
	import events.MenuEvent;
	
	import feathers.controls.List;
	
	import networking.*;
	
	import particle.ErrorParticleSystem;
	
	import scenes.Scene;
	import scenes.game.PipeJamGameScene;
	
	import starling.core.Starling;
	import starling.display.BlendMode;
	import starling.display.Image;
	import starling.events.Event;
	import events.MouseWheelEvent;
	import flash.events.MouseEvent;
	
	public class LevelSelectScene extends Scene
	{		
		protected var background:Image;
		
		protected var levelSelectBackground:NineSliceBatch;
		protected var levelSelectInfoPanel:NineSliceBatch;
		
		protected var loginHelper:LoginHelper;
		
		protected var levelList:List = null;
		protected var matchArrayObjects:Array = null;
		protected var matchArrayMetadata:Array = null;
		protected var savedLevelsArrayMetadata:Array = null;
		
		protected var tutorial_levels_button:NineSliceToggleButton;
		protected var new_levels_button:NineSliceToggleButton;
		protected var saved_levels_button:NineSliceToggleButton;
		
		protected var select_button:NineSliceButton;
		protected var cancel_button:NineSliceButton;
		
		protected var tutorialListBox:SelectLevelList;
		protected var newLevelListBox:SelectLevelList;
		protected var savedLevelsListBox:SelectLevelList;
		protected var currentVisibleListBox:SelectLevelList;
		
		//for the info panel
		protected var infoLabel:TextFieldWrapper;
		protected var nameText:TextFieldWrapper;
		protected var numNodesText:TextFieldWrapper;
		protected var numEdgesText:TextFieldWrapper;
		protected var numConflictsText:TextFieldWrapper;
		protected var scoreText:TextFieldWrapper;
		
		public function LevelSelectScene(game:PipeJamGame)
		{
			super(game);
			
			loginHelper = LoginHelper.getLoginHelper();
		}
		
		protected override function addedToStage(event:starling.events.Event):void
		{
			super.addedToStage(event);
			
			background = new Image(AssetInterface.getTexture("Game", "Background0Class"));
			background.scaleX = stage.stageWidth/background.width;
			background.scaleY = stage.stageHeight/background.height;
			background.blendMode = BlendMode.NONE;
			addChild(background);
			
			var levelSelectWidth:Number = 305;
			var levelSelectHeight:Number =  320;
			levelSelectBackground = new NineSliceBatch(levelSelectWidth, levelSelectHeight, levelSelectWidth /6.0, levelSelectHeight / 6.0, "Game", "PipeJamLevelSelectSpriteSheetPNG", "PipeJamLevelSelectSpriteSheetXML", "LevelSelectWindow");
			levelSelectBackground.x = 10;
			levelSelectBackground.y = 5;
			addChild(levelSelectBackground);
			
			var levelSelectInfoWidth:Number = 150;
			var levelSelectInfoHeight:Number =  320;
			levelSelectInfoPanel = new NineSliceBatch(levelSelectInfoWidth, levelSelectInfoHeight, levelSelectInfoWidth /6.0, levelSelectInfoHeight / 6.0, "Game", "PipeJamLevelSelectSpriteSheetPNG", "PipeJamLevelSelectSpriteSheetXML", "LevelSelectWindow");
			levelSelectInfoPanel.x = width - levelSelectInfoWidth - 10;
			levelSelectInfoPanel.y = 5;
			addChild(levelSelectInfoPanel);
			
			//select side widgets
			var buttonPadding:int = 7;
			var buttonWidth:Number = (levelSelectWidth - 2*buttonPadding)/3 - buttonPadding;
			var buttonHeight:Number = 25;
			var buttonY:Number = 30;
			
			var label:TextFieldWrapper = TextFactory.getInstance().createTextField("Select Level", AssetsFont.FONT_UBUNTU, 120, 30, 24, 0xFFFFFF);
			TextFactory.getInstance().updateAlign(label, 1, 1);
			addChild(label);
			label.x = (levelSelectWidth - label.width)/2 + levelSelectBackground.x;
			label.y = 10;
			
			infoLabel = TextFactory.getInstance().createTextField("Level Info", AssetsFont.FONT_UBUNTU, 80, 24, 18, 0xFFFFFF);
			TextFactory.getInstance().updateAlign(infoLabel, 1, 1);
			addChild(infoLabel);
			infoLabel.x = (levelSelectInfoWidth - infoLabel.width)/2 + levelSelectInfoPanel.x;
			infoLabel.y = buttonY + label.y;
			
			tutorial_levels_button = ButtonFactory.getInstance().createTabButton("Intro", buttonWidth, buttonHeight, 6, 6);
			tutorial_levels_button.addEventListener(starling.events.Event.TRIGGERED, onTutorialButtonTriggered);
			addChild(tutorial_levels_button);
			tutorial_levels_button.x = buttonPadding+12;
			tutorial_levels_button.y = buttonY + label.y;
			
			new_levels_button = ButtonFactory.getInstance().createTabButton("Current", buttonWidth, buttonHeight, 6, 6);
			new_levels_button.addEventListener(starling.events.Event.TRIGGERED, onNewButtonTriggered);
			addChild(new_levels_button);
			new_levels_button.x = tutorial_levels_button.x+buttonWidth+buttonPadding;
			new_levels_button.y = buttonY + label.y;
			
			saved_levels_button = ButtonFactory.getInstance().createTabButton("Saved", buttonWidth, buttonHeight, 6, 6);
			saved_levels_button.addEventListener(starling.events.Event.TRIGGERED, onSavedButtonTriggered);
			addChild(saved_levels_button);
			saved_levels_button.x = new_levels_button.x+buttonWidth+buttonPadding;
			saved_levels_button.y = buttonY + label.y;
			
			select_button = ButtonFactory.getInstance().createDefaultButton("Select", 50, 18);
			select_button.addEventListener(starling.events.Event.TRIGGERED, onSelectButtonTriggered);
			addChild(select_button);
			select_button.x = levelSelectWidth-50-buttonPadding;
			select_button.y = levelSelectHeight - select_button.height - 12;	
			
			cancel_button = ButtonFactory.getInstance().createDefaultButton("Cancel", 50, 18);
			cancel_button.addEventListener(starling.events.Event.TRIGGERED, onCancelButtonTriggered);
			addChild(cancel_button);
			cancel_button.x = select_button.x - cancel_button.width - buttonPadding;
			cancel_button.y = levelSelectHeight - cancel_button.height - 12;
			
			tutorialListBox = new SelectLevelList(levelSelectWidth - 3*buttonPadding - 4, levelSelectHeight - label.height - tutorial_levels_button.height - cancel_button.height - 4*buttonPadding - 2);
			tutorialListBox.y = tutorial_levels_button.y + tutorial_levels_button.height + buttonPadding - 2;
			tutorialListBox.x = (levelSelectWidth - tutorialListBox.width)/2+levelSelectBackground.x+2;
			addChild(tutorialListBox);
			
			newLevelListBox = new SelectLevelList(levelSelectWidth - 3*buttonPadding - 4, levelSelectHeight - label.height - tutorial_levels_button.height - cancel_button.height - 4*buttonPadding - 2);
			newLevelListBox.y = tutorialListBox.y;
			newLevelListBox.x = tutorialListBox.x;
			addChild(newLevelListBox);
			
			savedLevelsListBox = new SelectLevelList(levelSelectWidth - 3*buttonPadding - 4, levelSelectHeight - label.height - tutorial_levels_button.height - cancel_button.height - 4*buttonPadding - 2);
			savedLevelsListBox.y = tutorialListBox.y;
			savedLevelsListBox.x = tutorialListBox.x;
			addChild(savedLevelsListBox);
			
			initialize();
		}
		
		protected  override function removedFromStage(event:Event):void
		{
			removeEventListener(Event.TRIGGERED, updateSelectedLevelInfo);
		}
		
		public function initialize():void
		{
			tutorialListBox.setClipRect();
			savedLevelsListBox.setClipRect();
			newLevelListBox.setClipRect();
			
			savedLevelsListBox.startBusyAnimation(savedLevelsListBox);
			newLevelListBox.startBusyAnimation(newLevelListBox);
			
			loginHelper.levelInfoVector = null;
			loginHelper.matchArrayObjects = null;
			loginHelper.savedMatchArrayObjects = null;
			loginHelper.requestLevels(onRequestLevels);
			loginHelper.getLevelMetadata(onRequestLevels);
			loginHelper.getSavedLevels(onRequestSavedLevels);
						
			setTutorialXMLFile(TutorialController.tutorialXML);
			
			if(!TutorialController.getTutorialController().isTutorialDone())
				onTutorialButtonTriggered(null);
			else
				onNewButtonTriggered(null);
			
			addEventListener(Event.TRIGGERED, updateSelectedLevelInfo);
			Starling.current.nativeStage.addEventListener(MouseEvent.MOUSE_WHEEL, onMouseWheel);
			dispatchEventWith(MenuEvent.TOGGLE_SOUND_CONTROL, true, false);
		}
		
		private function onTutorialButtonTriggered(e:Event):void
		{
			tutorialListBox.visible = true;
			savedLevelsListBox.visible = false;
			newLevelListBox.visible = false;
			
			tutorial_levels_button.setToggleState(true);
			new_levels_button.setToggleState(false);
			saved_levels_button.setToggleState(false);
			
			currentVisibleListBox = tutorialListBox;
			updateSelectedLevelInfo();
		}
		
		private function onNewButtonTriggered(e:Event):void
		{
			tutorialListBox.visible = false;
			savedLevelsListBox.visible = false;
			newLevelListBox.visible = true;
			
			tutorial_levels_button.setToggleState(false);
			new_levels_button.setToggleState(true);
			saved_levels_button.setToggleState(false);	
			
			currentVisibleListBox = newLevelListBox;
			updateSelectedLevelInfo();
		}
		
		private function onSavedButtonTriggered(e:Event):void
		{
			tutorialListBox.visible = false;
			savedLevelsListBox.visible = true;
			newLevelListBox.visible = false;
			
			tutorial_levels_button.setToggleState(false);
			new_levels_button.setToggleState(false);
			saved_levels_button.setToggleState(true);
			
			currentVisibleListBox = savedLevelsListBox;
			updateSelectedLevelInfo();
		}
		
		public function updateSelectedLevelInfo(e:Event = null):void
		{
			var nextTextBoxYPos:Number = tutorialListBox.y;
			if(currentVisibleListBox.currentSelection && currentVisibleListBox.currentSelection.data)
			{
				var currentSelectedLevel:Object = currentVisibleListBox.currentSelection.data;
				
				removeChild(nameText);
				if(currentSelectedLevel.hasOwnProperty("name"))
				{
					nameText = TextFactory.getInstance().createTextField("Name: " + currentSelectedLevel.name, AssetsFont.FONT_UBUNTU, 140, 18, 12, 0xFFFFFF);
					TextFactory.getInstance().updateAlign(nameText, 0, 1);
					addChild(nameText);
					nameText.x = levelSelectInfoPanel.x+ 10;
					nameText.y = nextTextBoxYPos; //line up with list box
					nextTextBoxYPos += 20;
				}
					
				removeChild(numNodesText);
				removeChild(numEdgesText);
				removeChild(numConflictsText);
				removeChild(scoreText);
				
				if(currentSelectedLevel.hasOwnProperty("metadata"))
				{
					numNodesText = TextFactory.getInstance().createTextField("Widgets: " + currentSelectedLevel.metadata.properties.visibleboxes, AssetsFont.FONT_UBUNTU, 140, 18, 12, 0xFFFFFF);
					TextFactory.getInstance().updateAlign(numNodesText, 0, 1);
					addChild(numNodesText);
					numNodesText.x = levelSelectInfoPanel.x + 10;
					numNodesText.y = nextTextBoxYPos; //line up with list box
					nextTextBoxYPos += 20;
				
					numEdgesText = TextFactory.getInstance().createTextField("Links: " + currentSelectedLevel.metadata.properties.visiblelines, AssetsFont.FONT_UBUNTU, 140, 18, 12, 0xFFFFFF);
					TextFactory.getInstance().updateAlign(numEdgesText, 0, 1);
					addChild(numEdgesText);
					numEdgesText.x = levelSelectInfoPanel.x + 10;
					numEdgesText.y = nextTextBoxYPos; //line up with list box
					nextTextBoxYPos += 20;
	
					numConflictsText = TextFactory.getInstance().createTextField("Jams: " + currentSelectedLevel.metadata.properties.conflicts, AssetsFont.FONT_UBUNTU, 140, 18, 12, 0xFFFFFF);
					TextFactory.getInstance().updateAlign(numConflictsText, 0, 1);
					addChild(numConflictsText);
					numConflictsText.x = levelSelectInfoPanel.x + 10;
					numConflictsText.y = nextTextBoxYPos; //line up with list box
					nextTextBoxYPos += 20;
	
					if(currentSelectedLevel.hasOwnProperty("score"))
					{
						scoreText = TextFactory.getInstance().createTextField("Score: " + currentSelectedLevel.score, AssetsFont.FONT_UBUNTU, 140, 18, 12, 0xFFFFFF);
						TextFactory.getInstance().updateAlign(scoreText, 0, 1);
						addChild(scoreText);
						scoreText.x = levelSelectInfoPanel.x + 10;
						scoreText.y = nextTextBoxYPos; //line up with list box
						nextTextBoxYPos += 20;
					}
				}
				if(e && e.data && e.data.tapCount == 2)
					onSelectButtonTriggered(e);
			}
		}
		
		protected function onMouseWheel(event:MouseEvent):void
		{
			var delta:Number = event.delta;
			currentVisibleListBox.scrollPanel(delta);
		}
		
		private function onCancelButtonTriggered(e:Event):void
		{
			loginHelper.refuseLevels();
			dispatchEventWith(MenuEvent.TOGGLE_SOUND_CONTROL, true, true);
			dispatchEvent(new NavigationEvent(NavigationEvent.CHANGE_SCREEN, "SplashScreen"));
			
		}
		
		private function onSelectButtonTriggered(ev:Event):void
		{
			var dataObj:Object = currentVisibleListBox.currentSelection.data;
			dispatchEventWith(MenuEvent.TOGGLE_SOUND_CONTROL, true, true);
			
			if(currentVisibleListBox == tutorialListBox)
			{
				TutorialController.getTutorialController().fromLevelSelectList = true;
				PipeJamGameScene.inTutorial = true;
			}
			else
				PipeJamGameScene.inTutorial = false;
			
			if (dataObj) {
				if (dataObj.hasOwnProperty("levelId")) {
					PipeJamGameScene.inDemo = false;
					LoginHelper.getLoginHelper().levelObject = dataObj;
					dispatchEvent(new NavigationEvent(NavigationEvent.CHANGE_SCREEN, "PipeJamGame"));
				}
			}
		}
		
		protected function onRequestLevels(result:int):void
		{
			try{
				if(result == LoginHelper.EVENT_COMPLETE)
				{
					if(loginHelper.levelInfoVector != null && loginHelper.matchArrayObjects != null)
						onGetLevelMetadataComplete();
				}
			}
			catch(err:Error) //probably a parse error in trying to decode the RA response
			{
				trace("ERROR: failure in loading levels " + err);
				newLevelListBox.stopBusyAnimation();
			}
		}
		
		protected function onRequestSavedLevels(result:int):void
		{
			try{
				if(result == LoginHelper.EVENT_COMPLETE)
				{
					if(loginHelper.savedMatchArrayObjects != null)
						onGetSavedLevelsComplete();
				}
			}
			catch(err:Error) //probably a parse error in trying to decode the RA response
			{
				trace("ERROR: failure in loading levels " + err);
				savedLevelsListBox.stopBusyAnimation();
			}
		}
		
		protected function onGetLevelMetadataComplete():void
		{
			matchArrayMetadata = new Array;
			for(var i:int = 0; i<loginHelper.matchArrayObjects.length; i++)
			{
				var match:Object = loginHelper.matchArrayObjects[i];
				var savedObj:Object = fileLevelNameFromMatch(match, loginHelper.levelInfoVector, matchArrayMetadata);
				if(savedObj)
					savedObj.unlocked = true;
			}
			
			setNewLevelInfo(matchArrayMetadata);
			
			onRequestLevelsComplete();
		}
		
		protected function onGetSavedLevelsComplete():void
		{		
			savedLevelsArrayMetadata = new Array;
			for(var i:int = 0; i<loginHelper.savedMatchArrayObjects.length; i++)
			{
				var match:Object = loginHelper.savedMatchArrayObjects[i];
				savedLevelsArrayMetadata.push(match);
				match.unlocked = true;
			}
			
			setSavedLevelsInfo(savedLevelsArrayMetadata);
			
			onRequestLevelsComplete();
		}
		
		protected function onRequestLevelsComplete():void
		{
			if(loginHelper.levelInfoVector != null && loginHelper.matchArrayObjects != null && newLevelListBox != null)
				newLevelListBox.stopBusyAnimation();
			
			if(loginHelper.savedMatchArrayObjects != null && savedLevelsListBox != null)
				savedLevelsListBox.stopBusyAnimation();
		}
		
		protected static var levelCount:int = 1;
		protected function fileLevelNameFromMatch(match:Object, levelMetadataVector:Vector.<Object>, savedObjArray:Array):Object
		{
			//find the level record based on id, and then find the levelID match
			var levelNotFound:Boolean = true;
			var index:int = 0;
			var foundObj:Object;
			
			var objID:String;
			var matchID:String;
			if(match.levelId is String)
				matchID = match.levelId;
			else if(match.emptorId is String) //work around for hopefully temporary bug in RA
				matchID = match.emptorId;
			else
				matchID = match.levelId.$oid;
			
			while(levelNotFound)
			{
				if(index >= levelMetadataVector.length)
					break;
				
				foundObj = levelMetadataVector[index];
				if(foundObj.levelId is String)
					objID = foundObj.levelId;
				else
					objID = foundObj.levelId.$oid;
				
				if(matchID == objID)
				{
					levelNotFound = false;
					break;
				}
				index++;
			}
			if(levelNotFound)
			{
				//TODO -report error? or just skip?
				return null;
			}
			
			if(foundObj.levelId is String)
				objID = foundObj.levelId;
			else
				objID = foundObj.levelId.$oid;
			
			for(var i:int=0; i<levelMetadataVector.length;i++)
			{
				var levelObj:Object = levelMetadataVector[i];
				//we don't want ourselves
				//	if(levelObj == foundObj) there was a time when the RA info was stored here too, and as such we needed to skip this
				//		continue;
				var levelObjID:String;
				if(levelObj.levelId is String)
					levelObjID = levelObj.levelId;
				else
					levelObjID = levelObj.levelId.$oid;
				
				if(objID == levelObjID)
				{
					savedObjArray.push(levelObj);
					return levelObj;
				}
			}
			
			return null;
		}
		
		protected function onLevelSelected(e:starling.events.Event):void
		{
			LoginHelper.getLoginHelper().levelObject = matchArrayMetadata[levelList.selectedIndex];
			
			dispatchEvent(new NavigationEvent(NavigationEvent.CHANGE_SCREEN, "PipeJamGame"));
		}
		
		public function setNewLevelInfo(_newLevelInfo:Array):void
		{
			this.newLevelListBox.setButtonArray(_newLevelInfo, false);
		}
		
		public function setSavedLevelsInfo(_savedLevelInfo:Array):void
		{
			this.savedLevelsListBox.setButtonArray(_savedLevelInfo, true);
		}
		
		public function setTutorialXMLFile(tutorialXML:XML):void
		{
			var tutorialLevels:XMLList = tutorialXML["level"];
			var tutorialController:TutorialController = TutorialController.getTutorialController();
			
				
			var tutorialArray:Array = new Array;
			for each(var levelXML:XML in tutorialLevels)
			{
				var obj:Object = new Object;
				obj.levelId = levelXML.@qid.toString();
				obj.name = levelXML.@name.toString();
				
				//unlock all that user should be able play, check the ones they have played
				if(PipeJam3.RELEASE_BUILD)
				{
					obj.unlocked = tutorialController.tutorialShouldBeUnlocked(obj.levelId);
					obj.checked = tutorialController.isTutorialLevelCompleted(obj.levelId);
				}
				else
				{
					obj.unlocked = true;
					obj.checked = true;
					
				}
				tutorialArray.push(obj);
			}
			tutorialListBox.setButtonArray(tutorialArray, false);
		}
	}
}