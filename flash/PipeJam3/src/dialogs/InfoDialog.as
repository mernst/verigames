package dialogs
{
	import assets.AssetsFont;
	
	import dialogs.InfoDialogInfo;
	
	import display.NineSliceButton;
	
	import scenes.game.components.TutorialText;
	import scenes.game.display.Level;
	
	import starling.animation.Transitions;
	import starling.core.Starling;
	import starling.events.Event;
	import starling.events.Touch;
	import starling.events.TouchEvent;
	import starling.events.TouchPhase;
	
	//this is all hacked to support one dialog. If we want to extend its usage we need to use metrics to generalize stuff. Imagine that!
	public class InfoDialog extends TutorialText
	{
		protected var dialogInfo:InfoDialogInfo;
		
		public function InfoDialog(level:Level, info:InfoDialogInfo)
		{
			super(level, info);
			dialogInfo = info;
			if(info.button1String)
			{
				var button1:NineSliceButton = ButtonFactory.getInstance().createButton(info.button1String, 25, 15, 8, 8);
				if(info.button1Callback != null)
					button1.addEventListener(starling.events.Event.TRIGGERED, info.button1Callback);

				addChild(button1);
				button1.x = -3;
				button1.y = 8;
			}
			
			if(info.button2String)
			{
				var button2:NineSliceButton = ButtonFactory.getInstance().createButton(info.button2String, 25, 15, 8, 8);
				if(info.button2Callback != null)
					button2.addEventListener(starling.events.Event.TRIGGERED, info.button2Callback);

				addChild(button2);
				button2.x = 25;
				button2.y = 8;
			}
			
			touchable = true;
			
			addEventListener(starling.events.Event.ADDED_TO_STAGE, onAddedToStage); 
		}
		
		public function closeDialog():void
		{
			removeFromParent();
		}
		
		protected function onAddedToStage(event:starling.events.Event):void
		{
			removeEventListener(starling.events.Event.ADDED_TO_STAGE, onAddedToStage);
			Starling.juggler.tween(this, 2, { delay:dialogInfo.fadeTimeSeconds, alpha:0, transition:Transitions.EASE_IN } );
		}
		
		//keep this, or else dialog placement changes
		protected override function onEnterFrame(evt:Event):void
		{
			
		}
	}
}