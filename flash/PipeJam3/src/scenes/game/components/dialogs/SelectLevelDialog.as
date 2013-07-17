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
	
	import scenes.BaseComponent;
	import scenes.game.PipeJamGameScene;
	import scenes.login.LoginHelper;
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
		protected var select_button:NineSliceButton;
		
		protected var tutorialListBox:SelectLevelList;
		protected var newLevelListBox:SelectLevelList;
		protected var submittedLevelListBox:SelectLevelList;
		protected var currentVisibleListBox:SelectLevelList;
				
		public function SelectLevelDialog(_dialogParent:SplashScreenMenuBox, width:Number, height:Number)
		{
			super();
			
			background = new NineSliceBatch(width, height, width /6.0, height / 6.0, "Game", "PipeJamSpriteSheetPNG", "PipeJamSpriteSheetXML", "MenuBoxFree");
			addChild(background);

			dialogParent = _dialogParent;
			
			addEventListener(starling.events.Event.ADDED_TO_STAGE, onAddedToStage);	
		}
		
		//runs once when screen is first added to the stage.
		//a good place to add children and things.
		protected function onAddedToStage(event:starling.events.Event):void
		{
			var buttonPadding:int = 7;
			var buttonWidth:Number = (width - 2*buttonPadding)/3 - 1;
			var buttonY:Number = 30;
			
			var label:TextFieldWrapper = TextFactory.getInstance().createTextField("Select Level", AssetsFont.FONT_UBUNTU, 120, 30, 24, 0x0077FF);
			TextFactory.getInstance().updateAlign(label, 1, 1);
			addChild(label);
			label.x = (width - label.width)/2;
			
			tutorial_levels_button = ButtonFactory.getInstance().createToggleButton("Tutorials", buttonWidth, 20, 0, 0);
			tutorial_levels_button.addEventListener(starling.events.Event.TRIGGERED, onTutorialButtonTriggered);
			addChild(tutorial_levels_button);
			tutorial_levels_button.x = buttonPadding;
			tutorial_levels_button.y = buttonY;
			
			new_levels_button = ButtonFactory.getInstance().createToggleButton("New", buttonWidth, 20, 0, 0);
			new_levels_button.addEventListener(starling.events.Event.TRIGGERED, onNewButtonTriggered);
			addChild(new_levels_button);
			new_levels_button.x = tutorial_levels_button.x+buttonWidth;
			new_levels_button.y = buttonY;
			
			submitted_levels_button = ButtonFactory.getInstance().createToggleButton("Submitted", buttonWidth, 20, 0, 0);
			submitted_levels_button.addEventListener(starling.events.Event.TRIGGERED, onSubmittedButtonTriggered);
			addChild(submitted_levels_button);
			submitted_levels_button.x = new_levels_button.x+buttonWidth;
			submitted_levels_button.y = buttonY;
			
			cancel_button = ButtonFactory.getInstance().createDefaultButton("Cancel", 60, 20);
			cancel_button.addEventListener(starling.events.Event.TRIGGERED, onCancelButtonTriggered);
			addChild(cancel_button);
			cancel_button.x = width-2*60-2*buttonPadding;
			cancel_button.y = height - cancel_button.height - buttonPadding;
			
			select_button = ButtonFactory.getInstance().createDefaultButton("Select", 60, 20);
			select_button.addEventListener(starling.events.Event.TRIGGERED, onSelectButtonTriggered);
			addChild(select_button);
			select_button.x = width-60-buttonPadding;
			select_button.y = height - select_button.height - buttonPadding;
			//disable to begin with
			select_button.enabled = false;
			
			tutorialListBox = new SelectLevelList(width - 2*buttonPadding, height - label.height - tutorial_levels_button.height - select_button.height - 3*buttonPadding);
			tutorialListBox.y = label.height + tutorial_levels_button.height + buttonPadding;
			tutorialListBox.x = (width - tutorialListBox.width)/2;
			addChild(tutorialListBox);
			
			newLevelListBox = new SelectLevelList(width - 2*buttonPadding, height - label.height - tutorial_levels_button.height - select_button.height - 3*buttonPadding);
			newLevelListBox.y = label.height + tutorial_levels_button.height + buttonPadding;
			newLevelListBox.x = (width - newLevelListBox.width)/2;
			addChild(newLevelListBox);
			newLevelListBox.visible = false;
			
			submittedLevelListBox = new SelectLevelList(width - 2*buttonPadding, height - label.height - tutorial_levels_button.height - select_button.height - 3*buttonPadding);
			submittedLevelListBox.y = label.height + tutorial_levels_button.height + buttonPadding;
			submittedLevelListBox.x = (width - submittedLevelListBox.width)/2;
			addChild(submittedLevelListBox);
			submittedLevelListBox.visible = false;
			
			tutorial_levels_button.setToggleState(true);
			currentVisibleListBox = tutorialListBox;
			addEventListener(Event.TRIGGERED, onButtonToggle);
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
		
		private function onSelectButtonTriggered(e:Event):void
		{
			if(currentVisibleListBox == this.tutorialListBox)
				LoginHelper.levelObject = currentVisibleListBox.getSelectedLevelObject().levelId;
			else
			{
				LoginHelper.levelObject = currentVisibleListBox.getSelectedLevelObject();
			}
			
			dispatchEvent(new NavigationEvent(NavigationEvent.CHANGE_SCREEN, "PipeJamGame"));
			
		}
		
		private function onButtonToggle(e:Event):void
		{
			if(e.target is NineSliceToggleButton)
			{
				var target:NineSliceToggleButton = (e.target as NineSliceToggleButton);
				if(target.icon == null) //TODO fix this somehow...
				{
					if(target != tutorial_levels_button)
					{
						tutorial_levels_button.setToggleState(false);
						tutorialListBox.visible = false;
					}
					else
					{
						tutorial_levels_button.setToggleState(true);
						tutorialListBox.visible = true;
						currentVisibleListBox = tutorialListBox;
					}
					
					if(target != new_levels_button)
					{
						new_levels_button.setToggleState(false);
						newLevelListBox.visible = false;
					}
					else
					{
						new_levels_button.setToggleState(true);
						newLevelListBox.visible = true;
						currentVisibleListBox = newLevelListBox;
						
					}
					
					if(target != submitted_levels_button)
					{
						submitted_levels_button.setToggleState(false);
						submittedLevelListBox.visible = false;
					}
					else
					{
						submitted_levels_button.setToggleState(true);
						submittedLevelListBox.visible = true;
						currentVisibleListBox = submittedLevelListBox;
					}
				}
				else
				{
					currentVisibleListBox.setCurrentSelection(e.target as NineSliceToggleButton);
				}
				
				if(currentVisibleListBox.getElementCount() > 0)
					this.select_button.enabled = true;
				else
					this.select_button.enabled = false;
			}
		}
		
		public function setNewLevelInfo(_newLevelInfo:Array):void
		{			
			this.newLevelListBox.setButtonArray(_newLevelInfo);
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
				if(count <= PipeJamGameScene.numTutorialLevelsCompleted)
					obj.unlocked = true;
				else
					obj.unlocked = false;
				tutorialArray.push(obj);
				count++;
			}
			tutorialListBox.setButtonArray(tutorialArray);
			
			if(currentVisibleListBox.getElementCount() > 0)
				this.select_button.enabled = true;
			else
				this.select_button.enabled = false;
		}
	}
}