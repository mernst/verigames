package dialogs
{
	import assets.AssetsFont;
	import display.NineSliceBatch;
	import display.NineSliceButton;
	import events.MenuEvent;
	import flash.text.TextFormat;
	import scenes.BaseComponent;
	import starling.events.Event;
	
	public class SubmitLayoutDialog extends BaseComponent
	{
		/** Button to save the current layout */
		public var submit_button:NineSliceButton;
		
		/** Button to close the dialog */
		public var cancel_button:NineSliceButton;
		
		private var background:NineSliceBatch;
		
		protected var buttonPaddingWidth:int = 8;
		protected var buttonPaddingHeight:int = 8;
		protected var textInputHeight:int = 18;
		protected var descriptionInputHeight:int = 60;
		protected var labelHeight:int = 12;
		protected var shapeWidth:int = 150;
		protected var buttonHeight:int = 24;
		protected var buttonWidth:int = (shapeWidth - 3*buttonPaddingWidth)/2;
		protected var shapeHeight:int = 4*buttonPaddingHeight + buttonHeight + textInputHeight + descriptionInputHeight + labelHeight;
		protected var m_defaultName:String;
		
		public function SubmitLayoutDialog(defaultName:String = "Layout Name")
		{
	
		}
		
		protected function onAddedToStage(event:starling.events.Event):void
		{
		
		}
		
		private function onFocus(e:starling.events.Event):void
		{
	
		}
		
		private function onCancelButtonTriggered(e:starling.events.Event):void
		{
			visible = false;
		}
		
		private function onSubmitButtonTriggered(e:starling.events.Event):void
		{
	
		}
		
		public function resetText(defaultName:String = "Layout Name"):void
		{
	
		}
	}
}