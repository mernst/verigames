package scenes.layoutselectscene
{
	import assets.AssetInterface;
	import assets.AssetsFont;
	
	import display.BasicButton;
	import display.NineSliceBatch;
	import display.NineSliceButton;
	import display.NineSliceToggleButton;
	
	import events.MenuEvent;
	import events.NavigationEvent;
	
	import feathers.controls.List;
	
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.PixelSnapping;
	import flash.utils.ByteArray;
	
	import networking.*;
	
	import particle.ErrorParticleSystem;
	
	import scenes.Scene;
	import scenes.game.PipeJamGameScene;
	
	import starling.display.BlendMode;
	import starling.display.Image;
	import starling.display.Sprite;
	import starling.events.Event;
	import starling.textures.Texture;
	
	import utils.Base64Decoder;
	
	public class LayoutSelectScene extends Scene
	{		
		protected var background:Image;
		
		protected var levelSelectBackground:NineSliceBatch;
		protected var levelSelectInfoPanel:NineSliceBatch;
		
		protected var loginHelper:LoginHelper;
		
		protected var levelList:List = null;

		
		protected var tutorial_levels_button:NineSliceToggleButton;
		protected var new_levels_button:NineSliceToggleButton;
		protected var saved_levels_button:NineSliceToggleButton;
		
		protected var select_button:NineSliceButton;
		protected var cancel_button:NineSliceButton;
		
		protected var allLayoutslListBox:SelectLayoutList;
		protected var currentVisibleListBox:SelectLayoutList;
		
		//for the info panel
		protected var infoLabel:TextFieldWrapper;
		protected var nameText:TextFieldWrapper;
		protected var descriptionText:TextFieldWrapper;

		protected var thumbnailViewer:Sprite;
		protected var thumbActualWidth:int;
		protected var thumbActualHeight:int;
		
		private var m_layouts:Array;
		
		protected var labelHeight:Number;

		
		public function LayoutSelectScene(game:PipeJamGame = null)
		{
			super(game);
			
			loginHelper = LoginHelper.getLoginHelper();
			
		}
		
		protected override function addedToStage(event:starling.events.Event):void
		{
			super.addedToStage(event);
			
			background = new Image(AssetInterface.getTexture("Game", "StationaryBackgroundClass"));
			background.scaleX = stage.stageWidth/background.width;
			background.scaleY = stage.stageHeight/background.height;
			background.blendMode = BlendMode.NONE;
			addChild(background);
			
			var levelSelectWidth:Number = 305;
			var levelSelectHeight:Number =  300;
			levelSelectBackground = new NineSliceBatch(levelSelectWidth, levelSelectHeight, levelSelectWidth /6.0, levelSelectHeight / 6.0, "Game", "PipeJamLevelSelectSpriteSheetPNG", "PipeJamLevelSelectSpriteSheetXML", "LevelSelectWindow");
			levelSelectBackground.x = 10;
			levelSelectBackground.y = 10;
			addChild(levelSelectBackground);
			
			//select side widgets
			var buttonPadding:int = 7;
			var buttonWidth:Number = (levelSelectWidth - 2*buttonPadding)/3 - buttonPadding;
			var buttonHeight:Number = 25;
			var buttonY:Number = 30;
			
			var label:TextFieldWrapper = TextFactory.getInstance().createTextField("Select Layout", AssetsFont.FONT_UBUNTU, 120, 30, 24, 0x0077FF);
			TextFactory.getInstance().updateAlign(label, 1, 1);
			addChild(label);
			label.x = (levelSelectWidth - label.width)/2 + levelSelectBackground.x;
			label.y = 10;
			
//			tutorial_levels_button = ButtonFactory.getInstance().createTabButton("Intro", buttonWidth, buttonHeight, 6, 6);
//			tutorial_levels_button.addEventListener(starling.events.Event.TRIGGERED, onTutorialButtonTriggered);
//			addChild(tutorial_levels_button);
//			tutorial_levels_button.x = buttonPadding+12;
//			tutorial_levels_button.y = buttonY + label.y;
//			
//			new_levels_button = ButtonFactory.getInstance().createTabButton("Current", buttonWidth, buttonHeight, 6, 6);
//			new_levels_button.addEventListener(starling.events.Event.TRIGGERED, onNewButtonTriggered);
//			addChild(new_levels_button);
//			new_levels_button.x = tutorial_levels_button.x+buttonWidth+buttonPadding;
//			new_levels_button.y = buttonY + label.y;
//			
//			saved_levels_button = ButtonFactory.getInstance().createTabButton("Saved", buttonWidth, buttonHeight, 6, 6);
//			saved_levels_button.addEventListener(starling.events.Event.TRIGGERED, onSavedButtonTriggered);
//			addChild(saved_levels_button);
//			saved_levels_button.x = new_levels_button.x+buttonWidth+buttonPadding;
//			saved_levels_button.y = buttonY + label.y;
			
			select_button = ButtonFactory.getInstance().createDefaultButton("Select", 60, 24);
			select_button.addEventListener(starling.events.Event.TRIGGERED, onSelectButtonTriggered);
			addChild(select_button);
			select_button.x = levelSelectWidth-60-buttonPadding;
			select_button.y = levelSelectHeight - select_button.height - 3;	
			
			cancel_button = ButtonFactory.getInstance().createDefaultButton("Cancel", 60, 24);
			cancel_button.addEventListener(starling.events.Event.TRIGGERED, onCancelButtonTriggered);
			addChild(cancel_button);
			cancel_button.x = select_button.x - cancel_button.width - buttonPadding;
			cancel_button.y = levelSelectHeight - cancel_button.height - 3;
			
			allLayoutslListBox = new SelectLayoutList(levelSelectWidth - 2*buttonPadding, 193);
			allLayoutslListBox.y = buttonY + label.y + buttonHeight + buttonPadding - 4;
			allLayoutslListBox.x = (levelSelectWidth - allLayoutslListBox.width)/2+levelSelectBackground.x;
			addChild(allLayoutslListBox);
			
			labelHeight = buttonY + label.y;
			
			drawInfoPanel();

			initialize();
		}
		
		protected function drawInfoPanel():void
		{
			var levelSelectInfoWidth:Number = 150;
			var levelSelectInfoHeight:Number =  300;
			levelSelectInfoPanel = new NineSliceBatch(levelSelectInfoWidth, levelSelectInfoHeight, levelSelectInfoWidth /6.0, levelSelectInfoHeight / 6.0, "Game", "PipeJamLevelSelectSpriteSheetPNG", "PipeJamLevelSelectSpriteSheetXML", "LevelSelectWindow");
			levelSelectInfoPanel.x = width - levelSelectInfoWidth - 10;
			levelSelectInfoPanel.y = 10;
			addChild(levelSelectInfoPanel);
			
			infoLabel = TextFactory.getInstance().createTextField("Layout Info", AssetsFont.FONT_UBUNTU, 80, 24, 18, 0x0077FF);
			TextFactory.getInstance().updateAlign(infoLabel, 1, 1);
			addChild(infoLabel);
			infoLabel.x = (levelSelectInfoWidth - infoLabel.width)/2 + levelSelectInfoPanel.x;
			infoLabel.y = labelHeight;
		}
		
		protected  override function removedFromStage(event:Event):void
		{
			removeEventListener(Event.TRIGGERED, updateSelectedLevelInfo);
		}
		
		public function initialize():void
		{
			allLayoutslListBox.setClipRect();
			
			if(m_layouts)
				allLayoutslListBox.setButtonArray(m_layouts, false);
			
			onAllButtonTriggered(null);
			
			addEventListener(Event.TRIGGERED, updateSelectedLevelInfo);
		}
		
		private function onAllButtonTriggered(e:Event):void
		{
			allLayoutslListBox.visible = true;

			currentVisibleListBox = allLayoutslListBox;
			updateSelectedLevelInfo();
		}
		

		
		public function updateSelectedLevelInfo(e:Event = null, drawThumbnail:Boolean = true):void
		{
			var nextTextBoxYPos:Number = allLayoutslListBox.y;
			if(currentVisibleListBox.currentSelection && currentVisibleListBox.currentSelection.data)
			{
				var currentSelectedLayout:Object = currentVisibleListBox.currentSelection.data;				
				
				removeChild(nameText);
				if(currentSelectedLayout.hasOwnProperty("name"))
				{
					nameText = TextFactory.getInstance().createTextField("Name: " + currentSelectedLayout.name, AssetsFont.FONT_UBUNTU, 140, 18, 12, 0x0077FF);
					TextFactory.getInstance().updateAlign(nameText, 0, 1);
					addChild(nameText);
					nameText.x = levelSelectInfoPanel.x+ 10;
					nameText.y = nextTextBoxYPos; //line up with list box
					nextTextBoxYPos += 20;
				}
				
				removeChild(descriptionText);
//				removeChild(numEdgesText);
//				removeChild(numConflictsText);
//				removeChild(scoreText);
//				
				if(currentSelectedLayout.hasOwnProperty("description"))
				{
					if(currentSelectedLayout.description.length > 0)
					{
						descriptionText = TextFactory.getInstance().createTextField("Description:\r\t" + currentSelectedLayout.description, AssetsFont.FONT_UBUNTU, 140, 60, 12, 0x0077FF);
						TextFactory.getInstance().updateAlign(descriptionText, 0, 1);
						addChild(descriptionText);
						descriptionText.x = levelSelectInfoPanel.x+ 10;
						descriptionText.y = nextTextBoxYPos; 
						nextTextBoxYPos += 68;
					}
				}
				
				if(drawThumbnail)
				{
					thumbnailViewer = new Sprite;
					thumbnailViewer.x = levelSelectInfoPanel.x;
					thumbnailViewer.y = nextTextBoxYPos;
					addChild(thumbnailViewer);
					
					if(!currentSelectedLayout.hasOwnProperty("layoutFile"))
						LoginHelper.getLoginHelper().getNewLayout(currentSelectedLayout.layoutID, getNewLayout);
					else
						showThumbnail();
				}
			}
		}
		
		//get layout and display thumbnail. Also attach xml to object so I don't have to get again if choosen
		private function getNewLayout(byteArray:ByteArray):void
		{
			//unpack xml, find correct object, attach to it, and if object == current selection, show thumb
			var layoutFile:XML = new XML(byteArray);
			var currentSelectedLayout:Object = currentVisibleListBox.currentSelection.data;	
			
			for each(var obj:Object in m_layouts)
			{
				if(obj.name == layoutFile.@id)
				{
					obj.layoutFile = layoutFile;
					if(obj == currentSelectedLayout)
						showThumbnail();
					break;
				}
			}
		}
		
		private function onCancelButtonTriggered(e:Event):void
		{
			this.parent.removeChild(this);
		}
		
		private function onSelectButtonTriggered(ev:Event):void
		{
			var dataObj:Object = currentVisibleListBox.currentSelection.data;
			if(dataObj != null)
			{
				var layoutID:String = dataObj.layoutID;
				
				var data:Object = new Object;
				data.name = dataObj.name;
				data.layoutFile = dataObj.layoutFile;
				dispatchEvent(new MenuEvent(MenuEvent.SET_NEW_LAYOUT, data));
			}
			this.parent.removeChild(this);
			
		}
		
		private function setNewLayout(byteArray:ByteArray):void
		{
			var name:String = LoginHelper.getLoginHelper().levelObject.layoutName;
			var layoutFile:XML = new XML(byteArray);
			var data:Object = new Object;
			data.name = name;
			data.layoutFile = layoutFile;
			dispatchEvent(new MenuEvent(MenuEvent.SET_NEW_LAYOUT, data));
		}

		public function setLayouts(layoutList:Vector.<Object>):void
		{
			m_layouts = new Array;
			for each(var obj:Object in layoutList)
			{
				m_layouts.push(obj);
				obj.unlocked = true;
				var namePlusDescription:String = decodeURIComponent(obj.name);
				var index:int = namePlusDescription.indexOf("::");
				if(index != -1)
				{
					obj.name = namePlusDescription.substring(0,index);
					obj.description = namePlusDescription.substring(index+2);
				}
				else
				{
					obj.name = namePlusDescription;
					obj.description = "No Description";
				}
			}
			
			if(allLayoutslListBox)
				allLayoutslListBox.setButtonArray(m_layouts, false);
		}
		
		public function showThumbnail():void
		{
			var currentSelectedLayout:Object = currentVisibleListBox.currentSelection.data;	
			if(currentSelectedLayout.hasOwnProperty("layoutFile"))
			{		
				//should be only one
				var foundThumb:Boolean = false;
				for each(var thumb:XML in currentSelectedLayout.layoutFile.thumb)
				{
					foundThumb = true;
					var thumbByteArray:ByteArray = new ByteArray();
					var dec:Base64Decoder = new Base64Decoder();
					dec.decode(thumb.*);
					thumbByteArray = dec.toByteArray();
				
					thumbByteArray.uncompress();
					var thumbActualWidth:int = thumbByteArray.readUnsignedInt();
					var thumbActualHeight:int = ((thumbByteArray.length - 4) / 4) / thumbActualWidth;
					var smallBMD:BitmapData = new BitmapData(thumbActualWidth,thumbActualHeight);
					smallBMD.setPixels(smallBMD.rect, thumbByteArray);
					var bmp:Bitmap = new Bitmap(smallBMD, PixelSnapping.ALWAYS, true);
					var texture:Texture = Texture.fromBitmap(bmp, false);
					var im:Image = new Image(texture);
					//now want the image with a max width of 130, and the height proportional, but not over 130.
					var imageWidth:Number, imageHeight:Number;
					var scale:Number;
					if(thumbActualWidth > thumbActualHeight)
					{
						imageWidth = 130;
						scale = 130/thumbActualWidth;
						imageHeight = thumbActualHeight*scale;
					}
					else
					{
						imageHeight = 130;
						scale = 130/thumbActualHeight;
						imageWidth = thumbActualWidth*scale;
					}
					im.width = imageWidth;
					im.height = imageHeight;
					im.x = (150 - imageWidth)/2;
					thumbnailViewer.addChild(im);
					addChild(thumbnailViewer);
				}
				
				if(!foundThumb)
				{
					thumbnailViewer.removeChildren();
					removeChild(levelSelectInfoPanel);
					drawInfoPanel();
					updateSelectedLevelInfo(null, false);
				}

			}
		}
	}
}