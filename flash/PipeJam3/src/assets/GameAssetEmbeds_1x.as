package assets
{
	public class GameAssetEmbeds_1x
	{
		// Bitmaps
		
		//Splash Screen
		[Embed(source="../lib/assets/TrafficSplashScreen.png")]
		public var TrafficJamTitleScreenImageClass:Class;
		
		[Embed(source="../lib/assets/BoxesStartScreen.jpg")]
		public var BoxesStartScreenImageClass:Class;
		
		[Embed(source="../../lib/assets/BoxesGamePanelBackground.jpg")]
		public var BoxesGamePanelBackgroundImageClass:Class;
		
		[Embed(source="../../lib/assets/GameControlPanelBackground.jpg")]
		public var GameControlPanelBackgroundImageClass:Class;
 
		[Embed(source="../../lib/assets/TrafficStartButtonUp.png")]
		public var StartButtonTrafficImageClass:Class;
		
		[Embed(source="../../lib/assets/TrafficStartButtonOver.png")]
		public var StartButtonTrafficClickImageClass:Class;
		
		[Embed(source="../../lib/assets/TutorialButtonUp.png")]
		public var TutorialButtonTrafficImageClass:Class;
		
		[Embed(source="../../lib/assets/TutorialButtonOver.png")]
		public var TutorialButtonTrafficClickImageClass:Class;
		
		//Game Scene
		//[Embed(source = '../../lib/assets/FireworksSlowMo.swf', symbol = 'FireworksSlowMo')]
		/** Animated fireworks display */
		
		[Embed(source = '../../lib/assets/Fireworks.swf', symbol = 'Fireworks')]
		public var Fireworks:Class;
		
		[Embed(source="../../lib/assets/background.png")]
		public var Art_Background:Class;
		
		[Embed(source="../../lib/assets/test.png")]
		public var Art_Workers:Class;
		
		//Game Panel
		/** The animated buzzsaw asset */
		[Embed(source = '../../lib/assets/NextButtonUp.png')]
		public var NextLevelButtonClass:Class;
		
		[Embed(source = '../../lib/assets/NextButtonOver.png')]
		public var NextLevelClickButtonClass:Class;
		
		/** The animated buzzsaw asset */
		[Embed(source = '../../lib/assets/BackButtonUp.png')]
		public var BackLevelButtonClass:Class;
		
		[Embed(source = '../../lib/assets/BackButtonOver.png')]
		public var BackLevelClickButtonClass:Class;
		
		[Embed(source = '../../lib/assets/ExitButton.png')]
		public var ExitButtonClass:Class;
		
		[Embed(source = '../../lib/assets/ExitButtonClick.png')]
		public var ExitClickButtonClass:Class;
		
		[Embed(source = '../../lib/assets/PipeJamAlternateLarge.jpeg')]
		public var PipeJamGameArt:Class;
		
		[Embed(source = '../../lib/assets/MergeSign.png')]
		public var MergeSignClass:Class;
		
		[Embed(source = '../../lib/assets/SplitSign.png')]
		public var SplitSignClass:Class;
		
		[Embed(source = '../../lib/assets/StreetConnect.png')]
		public var StreetConnectClass:Class;
		
		[Embed(source = '../../lib/assets/StreetEnd.png')]
		public var StreetEndClass:Class;
		
		[Embed(source = "../../lib/assets/Chevron.png")]
		public var ChevronClass:Class;
		
		[Embed(source="../../lib/assets/Star.png")]
		public var StarClass:Class;
		
		// Bitmap Fonts
		
		[Embed(source="../../media/fonts/1x/desyrel.fnt", mimeType="application/octet-stream")]
		public var DesyrelXml:Class;
		
		[Embed(source = "../../media/fonts/1x/desyrel.png")]
		public var DesyrelTexture:Class;
	}
}