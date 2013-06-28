package scenes.game.components.dialogs
{
	import scenes.BaseComponent;
	import scenes.game.display.Level;
	
	import assets.AssetInterface;
	import assets.AssetsFont;
	
	import feathers.controls.TextInput;
	import feathers.events.FeathersEventType;
	
	import starling.display.Image;
	import starling.events.Event;
	import starling.textures.Texture;
	import feathers.controls.text.StageTextTextEditor;
	import feathers.core.ITextEditor;
	import starling.display.Button;
	
	import display.NineSliceButton;
	import display.NineSliceBatch;
	import feathers.controls.Label;
	import flash.text.TextFormat;
	import feathers.controls.List;
	
	public class SelectLayoutDialog extends BaseComponent
	{
		protected var input:TextInput;
		
		/** Button to save the current layout */
		public var submit_button:NineSliceButton;
		
		/** Button to close the dialog */
		public var cancel_button:NineSliceButton;
		
		private var background:NineSliceBatch;
		
		protected var levelList:List = null;
		
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
			
			submit_button = ButtonFactory.getInstance().createButton("Submit", buttonWidth, buttonHeight, buttonHeight / 2.0, buttonHeight / 2.0);
			submit_button.addEventListener(starling.events.Event.TRIGGERED, onSelectButtonTriggered);
			submit_button.x = background.width - buttonPaddingWidth - buttonWidth;
			submit_button.y = background.height - buttonPaddingHeight - buttonHeight;
			addChild(submit_button);	
			
			cancel_button = ButtonFactory.getInstance().createButton("Cancel", buttonWidth, buttonHeight, buttonHeight / 2.0, buttonHeight / 2.0);
			cancel_button.addEventListener(starling.events.Event.TRIGGERED, onCancelButtonTriggered);
			cancel_button.x = background.width - 2*buttonPaddingWidth - 2*buttonWidth;
			cancel_button.y = background.height - buttonPaddingHeight - buttonHeight;
			addChild(cancel_button);
			
			addEventListener(Event.ADDED_TO_STAGE, onAddedToStage);	
		}
		
		protected function onAddedToStage(event:starling.events.Event):void
		{
			levelList = new List;
			levelList.y = 75;
			levelList.width = 125;
			levelList.x = (width - levelList.width)/2;
			levelList.itemRendererProperties.height = 10;
			
			addChild(levelList);
			levelList.addEventListener( starling.events.Event.CHANGE, onSelectButtonTriggered);
			levelList.validate();
		}
		
		private function onCancelButtonTriggered(e:starling.events.Event):void
		{
			visible = false;
		}
		
		private function onSelectButtonTriggered(e:starling.events.Event):void
		{
			visible = false;
			//dispatchEvent(new starling.events.Event(Level.SAVE_LAYOUT, true, input.text));		
		}
	}
}