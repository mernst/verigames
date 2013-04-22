package scenes.login
{
	import assets.AssetInterface;
	
	import events.NavigationEvent;
	
	import flash.events.*;
	import flash.external.ExternalInterface;
	import flash.net.*;
	import flash.system.Security;
	import flash.text.*;
	import flash.utils.*;
	
	import mx.collections.ArrayList;
	import mx.controls.List;
	import mx.messaging.messages.HTTPRequestMessage;
	import mx.rpc.events.FaultEvent;
	import mx.rpc.events.ResultEvent;
	import mx.rpc.http.HTTPService;
	
	import scenes.Scene
	
	import starling.core.Starling;
	import starling.display.Button;
	import starling.display.Sprite;
	import starling.events.Event;
	import starling.textures.Texture;

	public class LoginScene extends Scene
	{
		/** Start button image */
		protected var new_player_button:starling.display.Button;
		protected var login_button:Button;
		protected var activate_player_button:Button;
		protected var deactivate_player_button:Button;
		protected var delete_player_button:Button;
		protected var get_levels_button:Button;
		private var stop_level_button:Button;
		private var start_level_button:Button;
		private var create_random_level_button:Button;
		private var advanced_button:Button;
		
		private var activate_level_button:Button;
		private var deactivate_level_button:Button;
		private var activate_levels_button:Button;
		private var deactivate_levels_button:Button;
		
		private var random_request_button:Button;
		
		protected var playerNumber:TextField;
		protected var dataGrid:Sprite;
		
		protected var texture:Texture;
			
		protected var GAME_ID:int = 1;
		
		public var CREATE_PLAYER:int = 0;
		public var ACTIVATE_PLAYER:int = 1;
		public var DEACTIVATE_PLAYER:int = 71;
		public var DELETE_PLAYER:int = 2;
		public var CREATE_RANDOM_LEVEL:int = 3;
		public var REQUEST_LEVELS:int = 4;
		public var START_LEVEL:int = 5;
		public var STOP_LEVEL:int = 6;
		public var ACTIVATE_LEVEL:int = 7;
		public var DEACTIVATE_LEVEL:int = 8;
		public var ACTIVATE_ALL_LEVELS:int = 9;
		public var DEACTIVATE_ALL_LEVELS:int = 10;
		public var RANDOM_REQUEST:int = 11;
		protected var m_currentRequestType:int = 0;
		
		private var newPlayer:Boolean = false;
		private var getLevels:Boolean = false;
		private var chooseLevel:Boolean = false;
		private var storedPlayerNumber:String;
		
		public function LoginScene(game:PipeJamGame)
		{
			super(game);
		}
		
		protected override function addedToStage(event:starling.events.Event):void
		{
			Security.loadPolicyFile(PROXY_URL + "/crossdomain.xml");
			
			super.addedToStage(event);
//			var background:Image = new Image(AssetInterface.getTexture("Game", "BoxesStartScreenImageClass"));
//			background.scaleX = stage.stageWidth/background.width;
//			background.scaleY = stage.stageHeight/background.height;
//			background.blendMode = BlendMode.NONE;
//			addChild(background);
			
			texture = AssetInterface.getTexture("Login", "LoginButtonImageClass");
			
			new_player_button = new Button(texture, "New Random Player");
			new_player_button.addEventListener(starling.events.Event.TRIGGERED, onCreateNewPlayer);
			new_player_button.x = 20;
			new_player_button.y = 20;			
			addChild(new_player_button);
			
			activate_player_button = new Button(texture, "Activate Player");
			activate_player_button.addEventListener(starling.events.Event.TRIGGERED, onActivatePlayer);
			activate_player_button.x = 20;
			activate_player_button.y = 40;
			addChild(activate_player_button);
			
			deactivate_player_button = new Button(texture, "Deactivate Player");
			deactivate_player_button.addEventListener(starling.events.Event.TRIGGERED, onDeactivatePlayer);
			deactivate_player_button.x = 20;
			deactivate_player_button.y = 60;
			addChild(deactivate_player_button);
			
			delete_player_button = new Button(texture, "Delete Player");
			delete_player_button.addEventListener(starling.events.Event.TRIGGERED, onDeletePlayer);
			delete_player_button.x = 20;
			delete_player_button.y = 80;
			addChild(delete_player_button);
			
			get_levels_button = new Button(texture, "Request Levels");
			get_levels_button.addEventListener(starling.events.Event.TRIGGERED, onRequestLevels);
			get_levels_button.x = 20;
			get_levels_button.y = 100;
			addChild(get_levels_button);
			
			advanced_button = new Button(texture, "Advanced");
			advanced_button.addEventListener(starling.events.Event.TRIGGERED, onAdvancedButton);
			advanced_button.x = 20;
			advanced_button.y = 200;
			addChild(advanced_button);
			
			playerNumber = new flash.text.TextField();
			// Create default text format
			var playerNumberTextFormat:TextFormat = new TextFormat("Arial", 12, 0x000000);
			playerNumberTextFormat.align = TextFormatAlign.LEFT;
			playerNumber.defaultTextFormat = playerNumberTextFormat;
			// Set text input type
			playerNumber.type = TextFieldType.INPUT;
			playerNumber.autoSize = TextFieldAutoSize.LEFT;
			playerNumber.x = 100;
			playerNumber.y = 20;
			// Set background just for testing needs
			playerNumber.background = true;
			playerNumber.backgroundColor = 0xffffff;
			playerNumber.text = "Input Player Number Here";
			
			Starling.current.nativeOverlay.addChild(playerNumber);
			
			dataGrid = new Sprite();
			var colButton:Button = new Button(texture, "Levels");
			colButton.enabled = false;
			dataGrid.addChild(colButton);
			dataGrid.width = 300; 
			dataGrid.x = 100;
			dataGrid.y = 60;
			
			addChild(dataGrid);
			
			m_currentRequestType = 0;
		}
		
		
		protected  override function removedFromStage(event:starling.events.Event):void
		{
			removeChildren();
			Starling.current.nativeOverlay.removeChildren();
		}
		
		protected function onCreateNewPlayer(e:starling.events.Event):void
		{
			sendMessage(CREATE_PLAYER);
		}
		
		
		protected function onActivatePlayer(e:starling.events.Event):void
		{
			sendMessage(ACTIVATE_PLAYER);
		}
		
		protected function onDeactivatePlayer(e:starling.events.Event):void
		{
			sendMessage(DEACTIVATE_PLAYER);
		}
		
		protected function onDeletePlayer(e:starling.events.Event):void
		{
			sendMessage(DELETE_PLAYER);
		}
		
		protected function onRequestLevels(e:starling.events.Event):void
		{
			sendMessage(REQUEST_LEVELS);
		}
		
		private function onCreateRandomLevel(e:starling.events.Event):void
		{
			sendMessage(CREATE_RANDOM_LEVEL);	
		}
		
		private function onStartLevel(e:starling.events.Event):void
		{
			sendMessage(START_LEVEL);	
		}	
		
		private function onStopLevel(e:starling.events.Event):void
		{
			sendMessage(STOP_LEVEL);
			
		}
		
		protected function onActivateLevel(e:starling.events.Event):void
		{
			sendMessage(ACTIVATE_LEVEL);
		}
		
		private function onDeactivateLevel(e:starling.events.Event):void
		{
			sendMessage(DEACTIVATE_LEVEL);	
		}
		
		private function onActivateAllLevels(e:starling.events.Event):void
		{
			sendMessage(ACTIVATE_ALL_LEVELS);	
		}	
		
		private function onDeactivateAllLevels(e:starling.events.Event):void
		{
			sendMessage(DEACTIVATE_ALL_LEVELS);
		}
		
		private function onSpecificRequest(e:starling.events.Event):void
		{
			sendMessage(RANDOM_REQUEST);
		}
		
		private function onChooseLevel(e:starling.events.Event):void
		{
			levelNumberString = (e.currentTarget as Button).text;
			useCurrentLevelNumber = true;
			sendMessage(START_LEVEL);	
		}	

		public static function log(msg:String, caller:Object = null):void{
			var str:String = "";
			if(caller){
				str = getQualifiedClassName(caller);
				str += ":: ";
			}
			str += msg;
			trace(str);
//			if(ExternalInterface.available){
//				ExternalInterface.call("console.log", str);
//			}
		}

		private function onAdvancedButton(e:starling.events.Event):void
		{
			dispatchEvent(new NavigationEvent(NavigationEvent.CHANGE_SCREEN, "LoginTestScene"));
		}
		
		protected function sendMessage(type:int, info:String = ""):void
		{
			var request:String;
			var method:String;
			//are we busy?
			if(m_currentRequestType != 0)
				return;
			
			newPlayer = false;
			getLevels = false;
			chooseLevel = false;
			
			log(Security.sandboxType);
			
			m_currentRequestType = type;
			
			switch(type)
			{
				case CREATE_PLAYER:
					request = "/ra/games/"+GAME_ID+"/players/random";
					method = URLRequestMethod.POST; 
					newPlayer = true;
					break;
				case ACTIVATE_PLAYER:
					request = "/ra/games/"+GAME_ID+"/players/"+playerNumber.text+"/activate&method=PUT"; 
					method = URLRequestMethod.POST; 
					break;
				case DEACTIVATE_PLAYER:
					request = "/ra/games/"+GAME_ID+"/players/"+playerNumber.text+"/deactivate&method=PUT"; 
					method = URLRequestMethod.PUT; 
					break;
				case DELETE_PLAYER:
					request = "/ra/games/"+GAME_ID+"/players/"+playerNumber.text+"&method=DELETE"; 
					method = URLRequestMethod.DELETE; 
					break;

				case REQUEST_LEVELS:
					request = "/ra/games/"+GAME_ID+"/players/"+playerNumber.text+"/count/5/match";
					method = URLRequestMethod.POST; 
					getLevels = true;
					break;
				case START_LEVEL:
				request = "/ra/games/"+GAME_ID+"/players/"+playerNumber.text+"/levels/"+levelNumberString+"/started&method=PUT";
					method = URLRequestMethod.POST; 
					chooseLevel = true;
					break;
				case STOP_LEVEL:
					request = "/ra/games/"+GAME_ID+"/players/"+playerNumber.text+"/stopped&method=PUT";
					method = URLRequestMethod.POST; 
					break;
			}

			var urlRequest:URLRequest = new URLRequest(PROXY_URL+request);
			
			if(method == URLRequestMethod.GET)
				urlRequest.method = method;
			else
				urlRequest.method = URLRequestMethod.POST;


			var loader:URLLoader = new URLLoader();
			configureListeners(loader);
			
			try
			{
				loader.load(urlRequest);
			}
			catch(error:Error)
			{
				trace("Unable to load requested document.");
			}
		}
		
		private function configureListeners(dispatcher:flash.events.IEventDispatcher):void
		{
			dispatcher.addEventListener(flash.events.Event.COMPLETE, completeHandler);
			dispatcher.addEventListener(SecurityErrorEvent.SECURITY_ERROR, securityErrorHandler);
			dispatcher.addEventListener(HTTPStatusEvent.HTTP_STATUS, httpStatusHandler);
			dispatcher.addEventListener(IOErrorEvent.IO_ERROR, ioErrorHandler);
		}
		
		private function securityErrorHandler(ev:flash.events.SecurityErrorEvent):void
		{
			trace("security error " + ev.text);
//			inputInfo.text = ev.text;
		}
		
		private function httpStatusHandler(ev:flash.events.HTTPStatusEvent):void
		{
			trace(ev.status);
	//		outputInfo.text = ev.status.toString();
		}
		
		private function ioErrorHandler(ev:flash.events.IOErrorEvent):void
		{
			trace(ev.text);
			m_currentRequestType = 0;
//			outputInfo.text = ev.text;
		}
		
		private function completeHandler(e:flash.events.Event):void
		{
			trace(e.target.data);
			if(newPlayer)
			{
				var playerInfo:Object = JSON.parse(e.target.data);
				playerNumber.text = playerInfo.id;
				storedPlayerNumber = playerInfo.id;
			}
			else if(getLevels)
			{
				//parse level info
				dataGrid.removeChildren(1); //don't remove column header
				var levels:Object = JSON.parse(e.target.data);
				var yPos:int = 20;
				for each(var level:Object in levels.matches)
				{
					var colButton:Button = new Button(texture, level.levelId);
					colButton.addEventListener(starling.events.Event.TRIGGERED, onChooseLevel);
					colButton.y = yPos;
					yPos += 20;
					dataGrid.addChild(colButton);
				}
			}
			else if(chooseLevel)
			{
				dispatchEvent(new NavigationEvent(NavigationEvent.CHANGE_SCREEN, "PipeJamGame"));
			}
				
			m_currentRequestType = 0;
		}
		
		private function resultHandler(ev :mx.rpc.events.ResultEvent):void
		{
			var x:mx.rpc.events.ResultEvent = ev;
			trace("in result");
		}
	}
}