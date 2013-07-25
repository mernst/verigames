package scenes.game.components.dialogs
{
	import assets.AssetInterface;
	import assets.AssetsFont;
	
	import display.NineSliceBatch;
	import display.NineSliceButton;
	import display.NineSliceToggleButton;
	
	import events.NavigationEvent;
	
	import feathers.controls.Label;
	import feathers.controls.List;
	import feathers.controls.TabBar;
	import feathers.controls.text.TextFieldTextRenderer;
	import feathers.core.ITextRenderer;
	import feathers.data.HierarchicalCollection;
	import feathers.data.ListCollection;
	import feathers.display.Scale9Image;
	
	import flash.text.TextFormat;
	
	import networking.LoginHelper;
	
	import scenes.BaseComponent;
	import scenes.game.PipeJamGameScene;
	import scenes.splashscreen.SplashScreenMenuBox;
	
	import starling.display.DisplayObjectContainer;
	import starling.display.Quad;
	import starling.display.Sprite;
	import starling.events.Event;
	import starling.textures.Texture;
	import starling.textures.TextureAtlas;
	
	public class SelectLevelDialog extends BaseComponent
	{
		protected var dialogParent:SplashScreenMenuBox;
		private var background:NineSliceBatch;
		
		protected var tutorial_levels_button:NineSliceToggleButton;
		protected var new_levels_button:NineSliceToggleButton;
		protected var submitted_levels_button:NineSliceToggleButton;
		
		protected var cancel_button:NineSliceButton;
		
		protected var tutorialListBox:SelectLevelList;
		protected var newLevelListBox:SelectLevelList;
		protected var submittedLevelListBox:SelectLevelList;
		protected var currentVisibleListBox:SelectLevelList;
				
		public function SelectLevelDialog(_dialogParent:SplashScreenMenuBox, width:Number, height:Number)
		{
			super();
			
			background = new NineSliceBatch(width, height, width /6.0, height / 6.0, "Game", "PipeJamLevelSelectSpriteSheetPNG", "PipeJamLevelSelectSpriteSheetXML", "LevelSelectWindow");
			addChild(background);

			dialogParent = _dialogParent;
			
			addEventListener(starling.events.Event.ADDED_TO_STAGE, onAddedToStage);	
		}
		
		//runs once when screen is first added to the stage.
		//a good place to add children and things.
		protected function onAddedToStage(event:starling.events.Event):void
		{
			var buttonPadding:int = 7;
			var buttonWidth:Number = (width - 2*buttonPadding)/3 - buttonPadding;
			var buttonY:Number = 30;
			
			var label:TextFieldWrapper = TextFactory.getInstance().createTextField("Select Level", AssetsFont.FONT_UBUNTU, 120, 30, 24, 0x0077FF);
			TextFactory.getInstance().updateAlign(label, 1, 1);
			addChild(label);
			label.x = (width - label.width)/2;
			
			tutorial_levels_button = ButtonFactory.getInstance().createTabButton("Intro", buttonWidth, 27, 6, 6);
			tutorial_levels_button.addEventListener(starling.events.Event.TRIGGERED, onTutorialButtonTriggered);
			addChild(tutorial_levels_button);
			tutorial_levels_button.x = buttonPadding;
			tutorial_levels_button.y = buttonY;
			
			new_levels_button = ButtonFactory.getInstance().createTabButton("Current", buttonWidth, 27, 6, 6);
			new_levels_button.addEventListener(starling.events.Event.TRIGGERED, onNewButtonTriggered);
			addChild(new_levels_button);
			new_levels_button.x = tutorial_levels_button.x+buttonWidth+buttonPadding;
			new_levels_button.y = buttonY;
			
			submitted_levels_button = ButtonFactory.getInstance().createTabButton("Saved", buttonWidth, 27, 6, 6);
			submitted_levels_button.addEventListener(starling.events.Event.TRIGGERED, onSubmittedButtonTriggered);
			addChild(submitted_levels_button);
			submitted_levels_button.x = new_levels_button.x+buttonWidth+buttonPadding;
			submitted_levels_button.y = buttonY;
			
			cancel_button = ButtonFactory.getInstance().createDefaultButton("Cancel", 60, 24);
			cancel_button.addEventListener(starling.events.Event.TRIGGERED, onCancelButtonTriggered);
			addChild(cancel_button);
			cancel_button.x = width-60-2*buttonPadding;
			cancel_button.y = height - cancel_button.height - 6;
			
			tutorialListBox = new SelectLevelList(width - 2*buttonPadding, height - label.height - tutorial_levels_button.height - cancel_button.height - 4*buttonPadding);
			tutorialListBox.y = label.height + tutorial_levels_button.height + buttonPadding;
			tutorialListBox.x = (width - tutorialListBox.width)/2;
			addChild(tutorialListBox);
			
			newLevelListBox = new SelectLevelList(width - 2*buttonPadding, height - label.height - tutorial_levels_button.height - cancel_button.height - 4*buttonPadding);
			newLevelListBox.y = label.height + tutorial_levels_button.height + buttonPadding;
			newLevelListBox.x = (width - newLevelListBox.width)/2;
			addChild(newLevelListBox);
			newLevelListBox.visible = false;
			
			submittedLevelListBox = new SelectLevelList(width - 2*buttonPadding, height - label.height - tutorial_levels_button.height - cancel_button.height - 4*buttonPadding);
			submittedLevelListBox.y = label.height + tutorial_levels_button.height + buttonPadding;
			submittedLevelListBox.x = (width - submittedLevelListBox.width)/2+1;
			addChild(submittedLevelListBox);
			submittedLevelListBox.visible = false;
			
			tutorial_levels_button.setToggleState(true);
			currentVisibleListBox = tutorialListBox;
			addEventListener(Event.TRIGGERED, onButtonTriggered);
		}
		
		public function initialize():void
		{
			tutorialListBox.setClipRect();
			submittedLevelListBox.setClipRect();
			newLevelListBox.setClipRect();
		}
		
		private function onTutorialButtonTriggered(e:Event):void
		{
			// TODO Auto Generated method stub
			
		}
		
		private function onNewButtonTriggered(e:Event):void
		{
			// TODO Auto Generated method stub
			
		}
		
		private function onSubmittedButtonTriggered(e:Event):void
		{
			// TODO Auto Generated method stub
			
		}
		
		private function onCancelButtonTriggered(e:Event):void
		{
			parent.removeChild(this);
			dialogParent.showMainMenu(true);
			
		}
		
		private function onButtonTriggered(ev:Event):void
		{
			var levelObj:Object = ev.data;
			
			if (levelObj) {
				if (levelObj.levelId != undefined) {
					LoginHelper.getLoginHelper().levelObject = levelObj.levelId;
				} else {
					LoginHelper.getLoginHelper().levelObject = levelObj;
				}
				
				dispatchEvent(new NavigationEvent(NavigationEvent.CHANGE_SCREEN, "PipeJamGame"));
			}
		}

		public function setNewLevelInfo(_newLevelInfo:Array):void
		{			
			this.newLevelListBox.setButtonArray(_newLevelInfo);
		}
		
		public function setSavedLevelsInfo(_savedLevelInfo:Array):void
		{			
			this.submittedLevelListBox.setButtonArray(_savedLevelInfo);
		}
		
		public function setTutorialXMLFile(tutorialXML:XML):void
		{
			var tutorialLevels:XMLList = tutorialXML["level"];
			
			var tutorialArray:Array = new Array;
			var count:int = 0;
			for each(var level:XML in tutorialLevels)
			{
				var obj:Object = new Object;
				obj.levelId = count;
				obj.name = level.@name.toString();
				if(count <= PipeJamGameScene.maxTutorialLevelCompleted)
					obj.unlocked = true;
				else
					obj.unlocked = false;
				tutorialArray.push(obj);
				count++;
			}
			tutorialListBox.setButtonArray(tutorialArray);
		}
	}
}
