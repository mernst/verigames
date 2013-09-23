package dialogs
{
	import display.NineSliceBatch;
	import display.NineSliceButton;
	
	import events.MenuEvent;
	
	import feathers.controls.List;
	import feathers.controls.TextInput;
	import feathers.data.ListCollection;
	
	import flash.events.Event;
	import flash.utils.ByteArray;
	
	import networking.LoginHelper;
	
	import scenes.BaseComponent;
	
	import starling.events.Event;
	
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
		
		protected var parentDialog:InGameMenuDialog;
		
		public function SelectLayoutDialog(_parentDialog:InGameMenuDialog)
		{
			super();
			parentDialog = _parentDialog;
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
			if(_layoutList)
			{
				for(var i:int = 0; i<_layoutList.length; i++)
				{
					var layout:Object = _layoutList[i];
					var layoutName:String = decodeURIComponent(layout.name);
					layoutNameArray.push(layoutName);
				}
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
			parentDialog.hideSecondaryDialog(this, false);
		}
		
		private function onSelectButtonTriggered(e:starling.events.Event):void
		{
			parentDialog.hideAllDialogs();
			if(layoutObjectVector != null)
			{
				var selectedIndex:int = layoutList.selectedIndex;
				var layoutID:String = layoutObjectVector[selectedIndex].layoutID;
				
				LoginHelper.getLoginHelper().getNewLayout(layoutID, setNewLayout);
			}
			else if(PipeJam3.RELEASE_BUILD == false)
			{
				//reload layout file??. Useful if testing setNewLayout, and changing layouts during runs
				
			}
		}
		
		private function setNewLayout(byteArray:ByteArray):void
		{
			if (!LoginHelper.getLoginHelper().levelObject) return;
			var name:String = LoginHelper.getLoginHelper().levelObject.layoutName;
			var layoutFile:XML = new XML(byteArray);
			var data:Object = new Object;
			data.name = name;
			data.layoutFile = layoutFile;
			dispatchEvent(new MenuEvent(MenuEvent.SET_NEW_LAYOUT, data));
		}
	}
}