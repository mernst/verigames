package scenes.game.components.dialogs
{
	import scenes.BaseComponent;
	
	import assets.AssetInterface;
	
	import feathers.controls.TextInput;
	import feathers.events.FeathersEventType;
	
	import starling.display.Image;
	import starling.events.Event;
	import starling.textures.Texture;
	
	public class SubmitLayoutDialog extends BaseComponent
	{
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
			var input:TextInput = new TextInput();
			this.addChild( input );
			input.x = 6;
			input.y = 20;
			input.width = 127;
			input.height = 18;
			input.text = "Enter Layout Name Here";
			input.setFocus();
			input.selectRange(0, input.text.length);
			input.addEventListener( FeathersEventType.ENTER, submitLayoutHandler );
		}
		
		private function submitLayoutHandler(e:starling.events.Event):void
		{
			// TODO Auto Generated method stub
			
		}
	}
}