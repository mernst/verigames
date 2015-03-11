package display
{
	import starling.display.DisplayObjectContainer;
	import starling.display.DisplayObject;
	import starling.events.Event;
	
	public class RadioButtonGroup extends DisplayObjectContainer
	{
		
		public function RadioButtonGroup()
		{
			super();
			
			this.addEventListener(starling.events.Event.ADDED_TO_STAGE, addedToStage);
		}
		
		public function addedToStage(event:starling.events.Event):void
		{
			this.removeEventListener(starling.events.Event.ADDED_TO_STAGE, addedToStage);
			this.addEventListener(starling.events.Event.REMOVED_FROM_STAGE, removedFromStage);
			this.addEventListener(Event.TRIGGERED, buttonClicked);
		}
		

		public function removedFromStage(event:starling.events.Event):void
		{
			removeEventListener(starling.events.Event.REMOVED_FROM_STAGE, removedFromStage);
			this.addEventListener(starling.events.Event.ADDED_TO_STAGE, addedToStage);
		}
		
		public override function addChild(_child:DisplayObject):DisplayObject
		{
			super.addChild(_child);
			return _child;
		}
		
		private function buttonClicked(event:Event):void
		{
			var button:RadioButton = event.target as RadioButton;
			makeActive(button);
		}
		
		public function makeActive(button:RadioButton):void
		{
			button.setState(true);
			for(var i:int = 0; i< numChildren; i++)
			{
				var childButton:RadioButton = getChildAt(i) as RadioButton;
				if(childButton && childButton != button)
					childButton.setState(false);
			}
		}
		
		public function resetGroup():void
		{
			//set first visible button to on
			for(var i:int = 0; i< numChildren; i++)
			{
				var button:RadioButton = getChildAt(i) as RadioButton;
				if(button && button.visible)
				{
					makeActive(button);
					return;
				}
			}
		}
	}
}