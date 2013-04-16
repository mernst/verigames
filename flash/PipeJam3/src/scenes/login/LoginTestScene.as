package scenes.login
{
	import starling.core.Starling;
	import starling.display.*;
	import starling.events.Event;
	import starling.textures.Texture;
	import events.NavigationEvent;
	import assets.AssetInterface;
	
	import scenes.Scene;
	import flash.net.*;
	import mx.rpc.events.ResultEvent;
	import flash.events.*;
	import flash.text.*;
	import mx.rpc.http.HTTPService;
	import mx.rpc.events.FaultEvent;
	import mx.messaging.messages.HTTPRequestMessage;
	import flash.system.Security;
	import flash.external.ExternalInterface;
	import flash.utils.*;

	public class LoginTestScene extends Scene
	{
		/** Start button image */
		protected var new_player_button:Button;
		protected var login_button:Button;
		protected var activate_player_button:Button;
		protected var deactivate_player_button:Button;
		protected var delete_player_button:Button;
		protected var get_levels_button:Button;
		private var stop_level_button:Button;
		private var start_level_button:Button;
		private var create_random_level_button:Button;
		
		private var activate_level_button:Button;
		private var deactivate_level_button:Button;
		private var activate_levels_button:Button;
		private var deactivate_levels_button:Button;
		
		private var random_request_button:Button;
		private var back_button:Button;
		
		protected var playerNumber:TextField;
		protected var inputInfo:TextField;
		protected var outputInfo:TextField;
	
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
		
		public function LoginTestScene(game:PipeJamGame)
		{
			super(game);
		}
		
		protected override function addedToStage(event:starling.events.Event):void
		{
			super.addedToStage(event);
//			var background:Image = new Image(AssetInterface.getTexture("Game", "BoxesStartScreenImageClass"));
//			background.scaleX = stage.stageWidth/background.width;
//			background.scaleY = stage.stageHeight/background.height;
//			background.blendMode = BlendMode.NONE;
//			addChild(background);
			
			var texture:Texture = AssetInterface.getTexture("Login", "LoginButtonImageClass");
			
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
			
			create_random_level_button = new Button(texture, "Create Random Level");
			create_random_level_button.addEventListener(starling.events.Event.TRIGGERED, onCreateRandomLevel);
			create_random_level_button.x = 20;
			create_random_level_button.y = 100;
			addChild(create_random_level_button);
			
			get_levels_button = new Button(texture, "Request Levels");
			get_levels_button.addEventListener(starling.events.Event.TRIGGERED, onRequestLevels);
			get_levels_button.x = 20;
			get_levels_button.y = 120;
			addChild(get_levels_button);
			
			start_level_button = new Button(texture, "Start Level");
			start_level_button.addEventListener(starling.events.Event.TRIGGERED, onStartLevel);
			start_level_button.x = 20;
			start_level_button.y = 140;
			addChild(start_level_button);
			
			stop_level_button = new Button(texture, "Stop Level");
			stop_level_button.addEventListener(starling.events.Event.TRIGGERED, onStopLevel);
			stop_level_button.x = 20;
			stop_level_button.y = 160;
			addChild(stop_level_button);
			
			activate_level_button = new Button(texture, "Activate Level");
			activate_level_button.addEventListener(starling.events.Event.TRIGGERED, onActivateLevel);
			activate_level_button.x = 20;
			activate_level_button.y = 180;
			addChild(activate_level_button);
			
			deactivate_level_button = new Button(texture, "Deactivate Level");
			deactivate_level_button.addEventListener(starling.events.Event.TRIGGERED, onDeactivateLevel);
			deactivate_level_button.x = 20;
			deactivate_level_button.y = 200;
			addChild(deactivate_level_button);
			
			activate_levels_button = new Button(texture, "Activate All Levels");
			activate_levels_button.addEventListener(starling.events.Event.TRIGGERED, onActivateAllLevels);
			activate_levels_button.x = 20;
			activate_levels_button.y = 220;
			addChild(activate_levels_button);
			
			deactivate_levels_button = new Button(texture, "Deactivate All Levels");
			deactivate_levels_button.addEventListener(starling.events.Event.TRIGGERED, onDeactivateAllLevels);
			deactivate_levels_button.x = 20;
			deactivate_levels_button.y = 240;
			addChild(deactivate_levels_button);
			
			random_request_button = new Button(texture, "Specific Request");
			random_request_button.addEventListener(starling.events.Event.TRIGGERED, onSpecificRequest);
			random_request_button.x = 20;
			random_request_button.y = 260;
			addChild(random_request_button);
			
			back_button = new Button(texture, "Back to Login");
			back_button.addEventListener(starling.events.Event.TRIGGERED, onBackToLogin);
			back_button.x = 20;
			back_button.y = 280;
			addChild(back_button);
			
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
			
			inputInfo = new flash.text.TextField();
			// Create default text format
			var inputInfoTextFormat:TextFormat = new TextFormat("Arial", 12, 0x000000);
			inputInfoTextFormat.align = TextFormatAlign.LEFT;
			inputInfo.defaultTextFormat = inputInfoTextFormat;
			// Set text input type
			inputInfo.type = TextFieldType.INPUT;
			inputInfo.autoSize = TextFieldAutoSize.LEFT;
			inputInfo.multiline = true;
			inputInfo.wordWrap = true;
			inputInfo.x = 100;
			inputInfo.y = 50;
			inputInfo.height = 100;
			inputInfo.width = 300;
			// Set background just for testing needs
			inputInfo.background = true;
			inputInfo.backgroundColor = 0xffffff;
			inputInfo.text = "input info";
			
			Starling.current.nativeOverlay.addChild(inputInfo);
			
			outputInfo = new flash.text.TextField();
			// Create default text format
			var outputInfoTextFormat:TextFormat = new TextFormat("Arial", 12, 0x000000);
			outputInfoTextFormat.align = TextFormatAlign.LEFT;
			outputInfo.defaultTextFormat = outputInfoTextFormat;
			// Set text input type
			outputInfo.type = TextFieldType.INPUT;
			outputInfo.autoSize = TextFieldAutoSize.LEFT;
			outputInfo.multiline = true;
			outputInfo.wordWrap = true;
			outputInfo.x = 100;
			outputInfo.y = 150;
			outputInfo.height = 100;
			outputInfo.width = 400;
			// Set background just for testing needs
			outputInfo.background = true;
			outputInfo.backgroundColor = 0xffffff;
			outputInfo.text = "output result";
			
			Starling.current.nativeOverlay.addChild(outputInfo);
			
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
		
		private function onBackToLogin(e:starling.events.Event):void
		{
			dispatchEvent(new NavigationEvent(NavigationEvent.CHANGE_SCREEN, "LoginScene"));
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

		
		protected function sendMessage(type:int, info:String = ""):void
		{
			var request:String;
			var method:String;
			//are we busy?
			if(m_currentRequestType != 0)
				return;
			
			log(Security.sandboxType);
			
			m_currentRequestType = type;
			
			switch(type)
			{
				case CREATE_PLAYER:
					request = "/ra/games/"+GAME_ID+"/players/random";
					method = URLRequestMethod.POST; 
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
				case CREATE_RANDOM_LEVEL:
					request = "/ra/games/"+GAME_ID+"/levels/random";
					method = URLRequestMethod.POST; 
					break;
				case REQUEST_LEVELS:
					request = "/ra/games/"+GAME_ID+"/players/"+playerNumber.text+"/count/"+inputInfo.text+"/match";
					method = URLRequestMethod.POST; 
					break; 
				case START_LEVEL:
				request = "/ra/games/"+GAME_ID+"/players/"+playerNumber.text+"/levels/"+inputInfo.text+"/started&method=PUT";
					method = URLRequestMethod.POST; 
					break;
				case STOP_LEVEL:
					request = "/ra/games/"+GAME_ID+"/players/"+playerNumber.text+"/stopped&method=PUT";
					method = URLRequestMethod.POST; 
					break;
				case ACTIVATE_LEVEL:
					request = "/ra/games/"+GAME_ID+"/levels/"+playerNumber.text+"/activate&method=PUT";
					method = URLRequestMethod.POST; 
					break;
				case DEACTIVATE_LEVEL:
					request = "/ra/games/"+GAME_ID+"/levels/"+playerNumber.text+"/deactivate&method=PUT";
					method = URLRequestMethod.POST; 
					break;
				case ACTIVATE_ALL_LEVELS:
					request = "/ra/games/"+GAME_ID+"/activateAllLevels&method=PUT";
					method = URLRequestMethod.POST; 
					break;
				case DEACTIVATE_ALL_LEVELS:
					request = "/ra/games/"+GAME_ID+"/deactivateAllLevels&method=PUT";
					method = URLRequestMethod.POST; 
					break;
				case RANDOM_REQUEST:
					request = playerNumber.text;
					method = URLRequestMethod.POST; 
					break;
			}

//			doRestCall(
//				apiURL+request,
//				function(result: ResultEvent):void
//				{
//					outputInfo.text = result.result.toString();
//				},
//				function(event: FaultEvent) : void
//				{
//					trace("error occured " + event.fault);
//				}
//			);
//			doRestCall1(apiURL+request,method);
			var urlRequest:URLRequest = new URLRequest(PROXY_URL+request);
			
			if(method == URLRequestMethod.GET)
				urlRequest.method = method;
			else
			{
				urlRequest.method = URLRequestMethod.POST;
				urlRequest.requestHeaders.push(new URLRequestHeader("X-HTTP-Method-Override",  method));
			}
			urlRequest.data = new Object();
			urlRequest.data.abc = "abc";
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
		
		protected var httpService:HTTPService;
		public function doRestCall( url : String, resultFunction : Function, faultFunction : Function = null,
									restMethod : String = "GET", parms : Object = null ) : void
		{
			var httpService : HTTPService = new HTTPService( );
			
			if ( restMethod.toUpperCase() != "GET" )
			{
				httpService.method = HTTPRequestMessage.POST_METHOD;
				if( parms == null )
				{
					parms = new Object();
				}
				parms._method = restMethod;
			}
			else
			{
				httpService.method = HTTPRequestMessage.GET_METHOD;
			}
			
			httpService.url =  url;
//			httpService.resultFormat = "e4x";
			httpService.addEventListener( ResultEvent.RESULT, resultFunction );
			if( faultFunction != null )
			{
				httpService.addEventListener( FaultEvent.FAULT, faultFunction );
			}
			httpService.send( parms );
		}
		public function doRestCall1(url:String, method:String):void
		{
			httpService = new HTTPService();
			httpService.url = url;
			httpService.method = method;
			httpService.useProxy = true;
			
			//you need to tell the service who's listening
			httpService.addEventListener(ResultEvent.RESULT, resultHandler1);
			httpService.addEventListener(mx.rpc.events.FaultEvent.FAULT, faultHandler1);
			
			httpService.send();
		}
		
		private function resultHandler1(event:ResultEvent):void
		{
			//don't forget to stop listening. we don't want memory leaks!
			httpService.removeEventListener(ResultEvent.RESULT, resultHandler1);
			outputInfo.text = event.message.toString();
		}
		
		private function faultHandler1(event:FaultEvent):void
		{
			var httpService:EventDispatcher = event.target as EventDispatcher;
			//don't forget to stop listening. we don't want memory leaks!
			httpService.removeEventListener(mx.rpc.events.FaultEvent.FAULT, faultHandler1);
			
			log(event.fault.toString());

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
			log(ev.text);
			inputInfo.text = ev.text;
		}
		
		private function httpStatusHandler(ev:flash.events.HTTPStatusEvent):void
		{
			trace(ev.status);
			outputInfo.text = ev.status.toString();
		}
		
		private function ioErrorHandler(ev:flash.events.IOErrorEvent):void
		{
			log(ev.text);
			m_currentRequestType = 0;
			outputInfo.text = ev.text;
		}
		
		private function completeHandler(e:flash.events.Event):void
		{
			trace("in complete " + e.target.data);
			outputInfo.text = e.target.data;
			m_currentRequestType = 0;
		}
		
		private function resultHandler(ev :mx.rpc.events.ResultEvent):void
		{
			var x:mx.rpc.events.ResultEvent = ev;
			trace("in result");
		}
	}
}