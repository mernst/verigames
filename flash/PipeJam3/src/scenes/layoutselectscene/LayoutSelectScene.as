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
		
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.PixelSnapping;
	import flash.geom.Matrix;
	import flash.geom.Point;
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

		}
		
		protected override function addedToStage(event:starling.events.Event):void
		{
		}
		
		protected function drawInfoPanel():void
		{
	
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
			
			dispatchEventWith(MenuEvent.TOGGLE_SOUND_CONTROL, true, false);
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
					nameText = TextFactory.getInstance().createTextField("Name: " + currentSelectedLayout.name, AssetsFont.FONT_UBUNTU, 140, 18, 12, 0xFFFFFF);
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
						descriptionText = TextFactory.getInstance().createTextField("Description:\r\t" + currentSelectedLayout.description, AssetsFont.FONT_UBUNTU, 140, 60, 12, 0xFFFFFF, true);
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
						GameFileHandler.getFileByID(currentSelectedLayout.layoutID, getNewLayout);
					else
						showThumbnail();
				}
			}
		}
		
		//get layout and display thumbnail. Also attach xml to object so I don't have to get again if choosen
		private function getNewLayout(layoutFile:XML):void
		{
			//unpack xml, find correct object, attach to it, and if object == current selection, show thumb
			var currentSelectedLayout:Object = currentVisibleListBox.currentSelection.data;	
			
			for each(var obj:Object in m_layouts)
			{
				if(obj.name == layoutFile.@id)
				{
					obj.layoutFile = layoutFile;
					if(obj == currentSelectedLayout)
					{
						showThumbnail();
						break;
					}
				}
			}
		}
		
		private function onCancelButtonTriggered(e:Event):void
		{
			dispatchEventWith(MenuEvent.TOGGLE_SOUND_CONTROL, true, true);
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
			dispatchEventWith(MenuEvent.TOGGLE_SOUND_CONTROL, true, true);
			this.parent.removeChild(this);
			
			
		}
		
		private function setNewLayout(byteArray:ByteArray):void
		{
			var name:String = PipeJamGame.levelInfo.layoutName;
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
			if (currentSelectedLayout.hasOwnProperty("layoutFile"))
			{
				if (currentSelectedLayout.layoutFile["thumb"])
				{
					var thumbByteArray:ByteArray = new ByteArray();
					var dec:Base64Decoder = new Base64Decoder();
					dec.decode(currentSelectedLayout.layoutFile["thumb"] as String);
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
					if (thumbActualWidth > thumbActualHeight)
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
				else
				{
					thumbnailViewer.removeChildren();
					removeChild(levelSelectInfoPanel);
					drawInfoPanel();
					updateSelectedLevelInfo(null, false);
				}
			}
		}
		
		public function rotateAroundCenter (ob:*, angleDegrees:Number):void
		{
			var point:Point = new Point(ob.x, ob.y);
			var m:Matrix=ob.transform.matrix;
			m.tx -= point.x;
			m.ty -= point.y;
			m.rotate(angleDegrees*(Math.PI/180));
			m.tx += point.x;
			m.ty += point.y;
			ob.transform.matrix=m;
		}
	}
}