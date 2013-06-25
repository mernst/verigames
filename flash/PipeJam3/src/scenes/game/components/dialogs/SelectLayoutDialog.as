package scenes.game.components.dialogs
{
	import assets.AssetInterface;
	import assets.AssetsFont;
	
	import events.NavigationEvent;
	
	import feathers.controls.List;
	import feathers.data.ListCollection;
	import feathers.themes.*;
	
	import flash.events.Event;
	import flash.events.HTTPStatusEvent;
	import flash.net.*;
	import flash.utils.ByteArray;
	
	import scenes.BaseComponent;
	import scenes.Scene;
	import scenes.game.display.Level;
	import scenes.login.LoginHelper;
	
	import starling.core.Starling;
	import starling.display.*;
	import starling.events.Event;
	import starling.events.TouchEvent;
	import starling.text.TextField;
	import starling.textures.Texture;

	public class SelectLayoutDialog extends BaseComponent
	{
		protected var m_layoutMenu:starling.display.Sprite;
				
		protected var loader:URLLoader;
		protected var loginHelper:LoginHelper;
				
		protected var layoutList:List = null;
		protected var layoutArray:Array = null;
		protected var m_layoutVector:Vector.<Object>;
		
		public function SelectLayoutDialog()
		{
			super();
			
			loginHelper = LoginHelper.getLoginHelper();
			buildSelectLayoutMenu();
			
			addEventListener(starling.events.Event.ADDED_TO_STAGE, addedToStage);
			addEventListener(starling.events.Event.REMOVED_FROM_STAGE, removedFromStage);
		}
		
		protected function addedToStage(event:starling.events.Event):void
		{
			addChild(m_layoutMenu);
			m_layoutMenu.visible = true;
			visible = true;
		}
		
		protected function removedFromStage(event:starling.events.Event):void
		{
			
		}
		
		
		protected function buildSelectLayoutMenu():void
		{
			m_layoutMenu = new Sprite();
			var background:Texture = AssetInterface.getTexture("Game", "GameControlPanelBackgroundImageClass");
			var backgroundImage:Image = new Image(background);
			backgroundImage.width = 150;
			backgroundImage.height = 200;
			m_layoutMenu.addChild(backgroundImage);
			
			//create a title
//			var titleTextfield:TextFieldWrapper = TextFactory.getInstance().createTextField("Layouts", AssetsFont.FONT_NUMERIC, width, 40, 25, 0xeeeeee);
//			titleTextfield.x = -5; 
//			TextFactory.getInstance().updateAlign(titleTextfield, 1, 1);
//			m_layoutMenu.addChild(titleTextfield);

			layoutList = new List;
			layoutList.y = 75;
			layoutList.x = 10;
			layoutList.width = 125;
			layoutList.itemRendererProperties.height = 10;
			
			m_layoutMenu.addChild(layoutList);
			layoutList.addEventListener( starling.events.Event.CHANGE, onLayoutSelected);
			layoutList.validate();
			
			var exitButtonUp:Texture = AssetInterface.getTexture("Menu", "ExitButtonClass");
			var exitButtonClick:Texture = AssetInterface.getTexture("Menu", "ExitButtonClass");
			
			var exit_button:Button = new Button(exitButtonUp, "", exitButtonClick);
			exit_button.addEventListener(starling.events.Event.TRIGGERED, onExitButtonTriggered);
			exit_button.x = 10;
			exit_button.y = 150;
			exit_button.width *= .38;
			exit_button.height *= .38;
			m_layoutMenu.addChild(exit_button);
			
			m_layoutMenu.visible = false;
			//use this for testing without any connection
//			onRequestLevels(LoginHelper.EVENT_COMPLETE, null)
		}
		
		public function setLayouts(layoutVector:Vector.<Object>):void
		{
			layoutArray = new Array();
			m_layoutVector = layoutVector;
			for(var i:int = 0; i<layoutVector.length; i++)
			{
				var layout:Object = layoutVector[i];
				var layoutName:String = layout.name;
				layoutArray.push(layoutName);
			}
			
			//we are done, show everything
			// Creating the dataprovider
			var matchCollection:ListCollection = new ListCollection(layoutArray);
			layoutList.dataProvider = matchCollection;			
			dispatchEvent(new starling.events.Event(Game.STOP_BUSY_ANIMATION,true));
		}
		
		protected function onLayoutSelected(e:starling.events.Event):void
		{
			var levelObj:Object = m_layoutVector[layoutList.selectedIndex];
			
			var levelObjID:String;
			if(levelObj._id is String)
				levelObjID = levelObj._id;
			else
				levelObjID = levelObj._id.$oid;
			LoginHelper.getLoginHelper().getNewLayout(levelObjID, onNewLayout);
		}
		
		protected function onNewLayout(byteArray:ByteArray):void
		{
			dispatchEvent(new starling.events.Event(Level.SET_NEW_LAYOUT, true, new XML(byteArray)));
		}
		
		private function onExitButtonTriggered():void
		{
			visible = false;
		}
		
	}
}