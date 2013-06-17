package scenes.game.components.dialogs
{
	import scenes.BaseComponent;
	import scenes.game.display.Level;
	
	import assets.AssetInterface;
	
	import feathers.controls.TextInput;
	import feathers.events.FeathersEventType;
	
	import starling.display.Image;
	import starling.events.Event;
	import starling.textures.Texture;
	import feathers.controls.text.StageTextTextEditor;
	import feathers.core.ITextEditor;
	import starling.display.Button;
	
	public class SubmitLayoutDialog extends BaseComponent
	{
		protected var input:TextInput;
		
		/** Button to save the current layout */
		public var submit_button:Button;
		
		/** Button to close the dialog */
		public var cancel_button:Button;
		
		public function SubmitLayoutDialog()
		{
			super();
			
			
			var background:Texture = AssetInterface.getTexture("Menu", "SubmitLayoutDialogBackgroundClass");
			var backgroundImage:Image = new Image(background);
			
			addChild(backgroundImage);
			addEventListener(Event.ADDED_TO_STAGE, onAddedToStage);	
		}
		
		protected function onAddedToStage(event:starling.events.Event):void
		{
			input = new TextInput();
			
			input.textEditorFactory = function():ITextEditor
			{
				var editor:StageTextTextEditor = new StageTextTextEditor();
				editor.fontSize = 11;
				return editor;
			}
				
			this.addChild( input );
			input.x = 5;
			input.y = 20;
			input.width = 130;
			input.height = 18;
			input.text = "Enter Layout Name Here";
			input.setFocus();
			input.selectRange(0, input.text.length);
			input.addEventListener( FeathersEventType.ENTER, onSubmitButtonTriggered );
			
			var cancelButtonUp:Texture = AssetInterface.getTexture("Menu", "CancelButtonClass");
			var cancelButtonClick:Texture = AssetInterface.getTexture("Menu", "CancelButtonClass");
			
			cancel_button = new Button(cancelButtonUp, "", cancelButtonClick);
			cancel_button.addEventListener(starling.events.Event.TRIGGERED, onCancelButtonTriggered);
			cancel_button.x = 20;
			cancel_button.y = 52;
			addChild(cancel_button);
			
			var submitButtonUp:Texture = AssetInterface.getTexture("Menu", "SubmitButtonClass");
			var submitButtonClick:Texture = AssetInterface.getTexture("Menu", "SubmitButtonClass");
			
			submit_button = new Button(submitButtonUp, "", submitButtonClick);
			submit_button.addEventListener(starling.events.Event.TRIGGERED, onSubmitButtonTriggered);
			submit_button.x = 75;
			submit_button.y = 52;
			addChild(submit_button);
		}
		
		private function onCancelButtonTriggered(e:starling.events.Event):void
		{
			visible = false;
		}
		
		private function onSubmitButtonTriggered(e:starling.events.Event):void
		{
			visible = false;
			dispatchEvent(new starling.events.Event(Level.SAVE_LAYOUT, true, input.text));		
		}
	}
}