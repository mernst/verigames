package dialogs
{
	import assets.AssetInterface;
	import assets.AssetsFont;
	import display.BasicButton;
	import flash.geom.Rectangle;
	import starling.display.Image;
	import starling.textures.Texture;
	
	import display.NineSliceBatch;
	import display.NineSliceButton;
	
	import scenes.BaseComponent;
	import starling.events.Event;

	public class SimpleAlertDialog extends BaseComponent
	{
		protected var ok_button:NineSliceButton;
		private var m_socialText:String;
		private var m_callback:Function;
		
		public function SimpleAlertDialog(text:String, _width:Number, _height:Number, _socialText:String = "", callback:Function = null)
		{
			super();
			m_socialText = _socialText;
			m_callback = callback;
			
			var background:NineSliceBatch = new NineSliceBatch(_width, _height, _width /6.0, _height / 6.0, "Game", "PipeJamSpriteSheetPNG", "PipeJamSpriteSheetXML", "MenuBoxFree");
			addChild(background);
			
			var label:TextFieldWrapper = TextFactory.getInstance().createTextField(text, AssetsFont.FONT_UBUNTU, 120, 14, 12, 0x0077FF);
			TextFactory.getInstance().updateAlign(label, 1, 1);
			addChild(label);
			label.x = (width - label.width)/2;
			label.y = 10;
			
			ok_button = ButtonFactory.getInstance().createDefaultButton("OK", 40, 20);
			ok_button.addEventListener(starling.events.Event.TRIGGERED, onOKButtonTriggered);
			addChild(ok_button);
			ok_button.x = (_width - ok_button.width)/2;
			ok_button.y = _height - 16 - 12;
			
			if (m_socialText.length > 0) {
				var fbLogoTexture:Texture = AssetInterface.getTexture("Game", "FacebookLogoWhiteClass");
				var fbLogoImage:Image = new Image(fbLogoTexture);
				var fbButton:BasicButton = new BasicButton(fbLogoImage, fbLogoImage, fbLogoImage);
				fbButton.width = fbButton.height = _height / 4.0;
				fbButton.useHandCursor = true;
				fbButton.addEventListener(Event.TRIGGERED, onClickFacebookShareButton);
				var twitterLogoTexture:Texture = AssetInterface.getTexture("Game", "TwitterLogoWhiteClass");
				var twitterLogoImage:Image = new Image(twitterLogoTexture);
				var twitterButton:BasicButton = new BasicButton(twitterLogoImage, twitterLogoImage, twitterLogoImage);
				twitterButton.width = twitterButton.height = _height / 3.0;
				const X_PAD:Number = (_width - fbButton.width - twitterButton.width) / 3.0;
				fbButton.x = X_PAD;
				fbButton.y = (label.y + label.height + ok_button.y - fbButton.height) / 2.0;
				twitterButton.x = _width - X_PAD - twitterButton.width;
				twitterButton.y = (label.y + label.height + ok_button.y - twitterButton.height) / 2.0;
				twitterButton.useHandCursor = true;
				twitterButton.addEventListener(Event.TRIGGERED, onClickTwitterShareButton);
				addChild(fbButton);
				addChild(twitterButton);
			}
		}
		
		private function onClickFacebookShareButton(evt:Event):void
		{
			// TODO: Call Top coder API
			trace("Share on Facebook: " + m_socialText);
		}
		
		private function onClickTwitterShareButton(evt:Event):void
		{
			// TODO: Call Top coder API
			trace("Tweet: " + m_socialText);
		}
		
		private function onOKButtonTriggered(evt:Event):void
		{
			visible = false;
			parent.removeChild(this);
			if(m_callback != null)
				m_callback();
		}
	}
}