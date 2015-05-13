package dialogs
{	
	import scenes.game.display.TutorialManagerTextInfo;
	
	public class InfoDialogInfo extends TutorialManagerTextInfo
	{
		public var fadeTimeSeconds:Number;
		public var button1String:String;
		public var button1Callback:Function;
		public var button2String:String;
		public var button2Callback:Function;
		
		public function InfoDialogInfo(_text:String , _fadeTimeSeconds:Number, _button1String:String = "", _button1Callback:Function = null, _button2String:String = "", _button2Callback:Function = null)
		{
			super(_text, null, null, null, null);
			
			fadeTimeSeconds = _fadeTimeSeconds;
			button1String = _button1String;
			button1Callback = _button1Callback;
			button2String = _button2String;
			button2Callback = _button2Callback;
		}
	}
}