package scenes.game.components.dialogs
{
	import assets.AssetInterface;
	import assets.AssetsFont;
	
	import display.NineSliceBatch;
	import display.NineSliceButton;
	
	import feathers.controls.Label;
	import feathers.controls.List;
	import feathers.controls.TextInput;
	import feathers.controls.text.StageTextTextEditor;
	import feathers.core.ITextEditor;
	import feathers.data.ListCollection;
	import feathers.events.FeathersEventType;
	
	import flash.text.TextFormat;
	import flash.events.Event;
	import scenes.BaseComponent;
	import scenes.game.display.Level;
	
	import starling.display.Button;
	import starling.display.Image;
	import starling.events.Event;
	import starling.textures.Texture;
	
	import utils.Base64Decoder;
	import flash.utils.ByteArray;
	import scenes.login.LoginHelper;
	
	public class SelectLayoutDialog extends BaseComponent
	{
		protected var input:TextInput;
		
		/** Button to save the current layout */
		public var submit_button:NineSliceButton;
		
		/** Button to close the dialog */
		public var cancel_button:NineSliceButton;
		
		private var background:NineSliceBatch;
		
		protected var layoutList:List = null;
		
		protected var layoutObjectVector:Vector.<Object> = null;
		protected var layoutNameArray:Array = null;
		protected var layoutNameCollection:ListCollection;
		
		protected var buttonPaddingWidth:int = 8;
		protected var buttonPaddingHeight:int = 8;
		protected var textInputHeight:int = 18;
		protected var labelHeight:int = 12;
		protected var shapeWidth:int = 120;
		protected var buttonHeight:int = 24;
		protected var buttonWidth:int = (shapeWidth - 3*buttonPaddingWidth)/2;
		protected var shapeHeight:int = 3*buttonPaddingHeight + buttonHeight + textInputHeight + labelHeight;
		
		public function SelectLayoutDialog()
		{
			super();
			
			background = new NineSliceBatch(shapeWidth, shapeHeight, shapeHeight / 3.0, shapeHeight / 3.0, "Game", "PipeJamSpriteSheetPNG", "PipeJamSpriteSheetXML", "MenuBoxAttached");
			addChild(background);
			
			submit_button = ButtonFactory.getInstance().createButton("Select", buttonWidth, buttonHeight, buttonHeight / 2.0, buttonHeight / 2.0);
			submit_button.addEventListener(starling.events.Event.TRIGGERED, onSelectButtonTriggered);
			submit_button.x = background.width - buttonPaddingWidth - buttonWidth;
			submit_button.y = background.height - buttonPaddingHeight - buttonHeight;
			addChild(submit_button);	
			
			cancel_button = ButtonFactory.getInstance().createButton("Cancel", buttonWidth, buttonHeight, buttonHeight / 2.0, buttonHeight / 2.0);
			cancel_button.addEventListener(starling.events.Event.TRIGGERED, onCancelButtonTriggered);
			cancel_button.x = background.width - 2*buttonPaddingWidth - 2*buttonWidth;
			cancel_button.y = background.height - buttonPaddingHeight - buttonHeight;
			addChild(cancel_button);
			
			addEventListener(starling.events.Event.ADDED_TO_STAGE, onAddedToStage);	
		}
		
		protected function onAddedToStage(event:starling.events.Event):void
		{
			layoutList = new List;
			layoutList.y = buttonPaddingHeight;
			layoutList.width = width - 2*buttonPaddingWidth;
			layoutList.height = height - buttonHeight - 3*buttonPaddingHeight;
			layoutList.x = (width - layoutList.width)/2;
			layoutList.itemRendererProperties.height = 10;
			
			addChild(layoutList);
	//		layoutList.addEventListener( starling.events.Event.CHANGE, onSelectButtonTriggered);
			layoutList.validate();
			
			if(layoutNameCollection)
			{
				layoutList.dataProvider = layoutNameCollection;
				layoutList.selectedIndex = 0;
			}
		}
		
		public function setDialogInfo(_layoutList:Vector.<Object>):void
		{
			layoutNameArray = new Array;
			for(var i:int = 0; i<_layoutList.length; i++)
			{
				var layout:Object = _layoutList[i];
				var layoutName:String = decodeURIComponent(layout.name);
				layoutNameArray.push(layoutName);
			}
			
			//we are done, show everything
			// Creating the dataprovider
			layoutNameCollection = new ListCollection(layoutNameArray);
			layoutObjectVector = _layoutList;
			if(layoutList)
			{
				layoutList.dataProvider = layoutNameCollection;
				layoutList.selectedIndex = 0;
			}
		}
		
		private function onCancelButtonTriggered(e:starling.events.Event):void
		{
			visible = false;
		}
		
		private function onSelectButtonTriggered(e:starling.events.Event):void
		{
			visible = false;
			var selectedIndex:int = layoutList.selectedIndex;
			var layoutID:String;
			if(layoutObjectVector[selectedIndex]._id is String)
				layoutID = layoutObjectVector[selectedIndex]._id;
			else
			{
				var idObj:Object = layoutID = layoutObjectVector[selectedIndex]._id;
				layoutID = idObj.$oid;
			}
			LoginHelper.getLoginHelper().getNewLayout(layoutID, setNewLayout);
		}
		
		private function setNewLayout(byteArray:ByteArray):void
		{
			var layoutFile:XML = new XML(byteArray);
			dispatchEvent(new starling.events.Event(Level.SET_NEW_LAYOUT, true, layoutFile));		
			
		}
	}
}