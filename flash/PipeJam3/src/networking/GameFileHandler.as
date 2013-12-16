package networking
{
	import deng.fzip.FZip;
	import deng.fzip.FZipFile;
	
	import events.MenuEvent;
	
	import flash.events.*;
	import flash.net.*;
	import flash.net.URLLoader;
	import starling.events.Event;
	import scenes.game.PipeJamGameScene;
	import scenes.Scene;
	import scenes.game.display.World;
	
	import starling.core.Starling;
	
	import utils.Base64Encoder;
	
	/** How to use:
	 * In most cases, there's a static function that will do what you want, and call a callback when done.
	 * 	internally, this creates a GameFileHandler object and carries out the request.
	 *  occasionally, you might need to create your own object
	 *   	but in cases like these, you might just want to add a new static interface.
	 */
	public class GameFileHandler
	{
		public static var REQUEST_LEVELS:int = 1;
		public static var GET_ALL_LEVEL_METADATA:int = 2;
		public static var SAVE_LAYOUT:int = 3;
		public static var REFUSE_LEVELS:int = 4;
		public static var REQUEST_LAYOUT_LIST:int = 5;
		public static var CREATE_RA_LEVEL:int = 6;	
		public static var SAVE_LEVEL:int = 7;
		public static var GET_ALL_SAVED_LEVELS:int = 8;
		public static var GET_SAVED_LEVEL:int = 15;
		public static var DELETE_SAVED_LEVEL:int = 9;
		public static var START_LEVEL:int = 10;
		public static var STOP_LEVEL:int = 11;
		public static var REPORT_PLAYER_RATING:int = 12;
		public static var REPORT_LEADERBOARD_SCORE:int = 13;
				
		public static var USE_LOCAL:int = 1;
		public static var USE_DATABASE:int = 2;
		public static var USE_URL:int = 3;
		
		static public var METADATA_GET_ALL_REQUEST:String = "/level/metadata/get/all";
		static public var LAYOUTS_GET_ALL_REQUEST:String = "/layout/get/all/";
	
		static public var levelInfoVector:Vector.<Object> = null;
		static public var matchArrayObjects:Object = null;
		static public var savedMatchArrayObjects:Vector.<Object> = null;
		
		static public var numLevels:int = 10;

		protected var m_callback:Function;
		protected var fzip:FZip;
		
		protected var m_saveType:String
		protected var m_fileType:int;
		protected var m_levelFilesString:String;
		
		public var m_constraintsSaved:Boolean = false;
		public var m_levelCreated:Boolean = false;
		public var m_levelSubmitted:Boolean = false;

		static public function loadLevelInfoFromObjectID(id:String, callback:Function):void
		{
			var fileHandler:GameFileHandler = new GameFileHandler(callback);
			fileHandler.sendMessage(GET_SAVED_LEVEL, fileHandler.defaultJSONCallback, null, id);
		}
		
		static public function getFileByID(id:String, callback:Function):void
		{
			var fileURL:String = "/file/get/" + id;
			
			var fileHandler:GameFileHandler = new GameFileHandler(callback);
			fileHandler.loadFile(USE_DATABASE, fileURL);
		}
		
		static public function saveLayoutFile(callback:Function, _layoutAsString:String):void
		{
			var layoutDescription:String = PipeJamGame.levelInfo.m_layoutName + "::" + PipeJamGame.levelInfo.m_layoutDescription;
			
			var encodedLayoutDescription:String = encodeURIComponent(layoutDescription);
			var fileHandler:GameFileHandler = new GameFileHandler(callback);
			fileHandler.sendMessage(SAVE_LAYOUT, null, encodedLayoutDescription, _layoutAsString);
		}
		
		static public function deleteSavedLevel(_levelIDString:String):void
		{
			var fileHandler:GameFileHandler = new GameFileHandler();
			fileHandler.sendMessage(DELETE_SAVED_LEVEL, null, _levelIDString);
		}
		
		static public function requestLevels(callback:Function):void
		{
			var fileHandler:GameFileHandler = new GameFileHandler(callback);
			fileHandler.sendMessage(REQUEST_LEVELS, fileHandler.onRequestLevelFinished);
		}
		
		static public function refuseLevels():void
		{
			var fileHandler:GameFileHandler = new GameFileHandler();
			fileHandler.sendMessage(REFUSE_LEVELS, null);
		}
		
		static public function startLevel(levelObj:Object):void
		{
			PipeJamGame.levelInfo = new LevelInformation(levelObj);
			var fileHandler:GameFileHandler = new GameFileHandler();
			fileHandler.sendMessage(START_LEVEL, null);
		}
		
		static public function stopLevel():void
		{
			var fileHandler:GameFileHandler = new GameFileHandler();
			fileHandler.sendMessage(STOP_LEVEL, null);
		}
		
		static public function reportPlayerPreference(preference:String):void
		{
			PipeJamGame.levelInfo.preference = preference;
			var fileHandler:GameFileHandler = new GameFileHandler();
			fileHandler.sendMessage(REPORT_PLAYER_RATING, null, null);
		}
		
		//connect to the db and get a list of all levels
		static public function getLevelMetadata(callback:Function):void
		{
			levelInfoVector = null;
			var fileHandler:GameFileHandler = new GameFileHandler(callback);
			fileHandler.sendMessage(GET_ALL_LEVEL_METADATA, fileHandler.setLevelMetadataFromCurrent);
		}
		
		//connect to the db and get a list of all saved levels
		static public function getSavedLevels(callback:Function):void
		{
			savedMatchArrayObjects = null;
			var fileHandler:GameFileHandler = new GameFileHandler(callback);
			fileHandler.sendMessage(GET_ALL_SAVED_LEVELS, fileHandler.onRequestSavedLevelsFinished);
		}
		
		//request a list of layouts associated with current levelObject xmlID
		static public function getLayoutList(callback:Function):void
		{
			var fileHandler:GameFileHandler = new GameFileHandler(callback);
			fileHandler.sendMessage(REQUEST_LAYOUT_LIST, fileHandler.defaultJSONCallback);
		}
		
		static public function submitLevel(_levelFilesString:String, saveType:String, fileType:int = 1):void
		{
			//this involves:
			//saving the level (layout and constraints, on either save or submit/share)
			//saving the score, level and player info
			//reporting the player performance/preference to the RA
			
			var fileHandler:GameFileHandler = new GameFileHandler();
			fileHandler.m_fileType = fileType;
			fileHandler.m_saveType = saveType;
			fileHandler.m_levelFilesString = _levelFilesString;
			//need to create an RA Level so we can use the levelID
			if(saveType == MenuEvent.SUBMIT_LEVEL)
			{
				fileHandler.sendMessage(CREATE_RA_LEVEL, fileHandler.onRALevelCreated);
			}
			else //save level
			{
				fileHandler.saveLevelWithID(null);
			}
		}	
		
		static public function reportScore():void
		{
			var fileHandler:GameFileHandler = new GameFileHandler();
			fileHandler.sendMessage(REPORT_LEADERBOARD_SCORE, null);
		}
		
		static public function loadGameFiles(worldFileLoadedCallback:Function, layoutFileLoadedCallback:Function, constraintsFileLoadedCallback:Function):void
		{
			var gameFileHandler:GameFileHandler;
			//do this so I can debug the object...
			var levelInformation:LevelInformation = PipeJamGame.levelInfo;
			
			Scene.m_gameSystem.dispatchEvent(new starling.events.Event(Game.START_BUSY_ANIMATION,true));
			
			var m_id:int = 100000;
			if(PipeJamGame.levelInfo && PipeJamGame.levelInfo.m_id && PipeJamGame.levelInfo.m_id.length < 5)
				m_id = parseInt(PipeJamGame.levelInfo.m_id);
			if(m_id < 1000) // in the tutorial if a low level id
			{
				PipeJamGameScene.inTutorial = true;
				PipeJamGameScene.inDemo = false;
//				fileName = "tutorial";
			}
			if (PipeJamGameScene.DEBUG_PLAY_WORLD_ZIP && !PipeJam3.RELEASE_BUILD)
			{
				//load the zip file from it's location
				loadType = USE_URL;
				gameFileHandler = new GameFileHandler(worldFileLoadedCallback);
				gameFileHandler.loadFile(USE_LOCAL, PipeJamGameScene.DEBUG_PLAY_WORLD_ZIP, gameFileHandler.zipLoaded);
			}
			else if(PipeJamGameScene.inTutorial)
			{
				layoutFileLoadedCallback(TutorialController.tutorialLayoutXML);
				constraintsFileLoadedCallback(TutorialController.tutorialConstraintsXML);
				worldFileLoadedCallback(TutorialController.tutorialXML);
			}
			else
			{
				var loadType:int = USE_LOCAL;
				
				var fileName:String;
				if(PipeJamGame.levelInfo && PipeJamGame.levelInfo.m_baseFileName)
					fileName = PipeJamGame.levelInfo.m_baseFileName;
				else
					fileName = PipeJamGame.m_pipeJamGame.m_fileName;

				
				if(PipeJamGame.levelInfo && PipeJamGame.levelInfo.m_constraintsID != null && !PipeJamGameScene.inTutorial) //load from MongoDB
				{
					loadType = USE_DATABASE;
					//is this an all in one file?
					var version:int = 0;
					if(PipeJamGame.levelInfo.m_version)
						version = PipeJamGame.levelInfo.m_version;
					if(version == PipeJamGame.ALL_IN_ONE)
					{
						gameFileHandler = new GameFileHandler(worldFileLoadedCallback);
						gameFileHandler.loadFile(loadType, "/file/get/" +PipeJamGame.levelInfo.m_constraintsID+"/constraints");
					}
					else
					{
						var levelInfo:LevelInformation = PipeJamGame.levelInfo;
						var worldFileHandler:GameFileHandler = new GameFileHandler(worldFileLoadedCallback);
						worldFileHandler.loadFile(loadType, "/file/get/" + PipeJamGame.levelInfo.m_xmlID+"/xml");
						var layoutFileHandler:GameFileHandler = new GameFileHandler(layoutFileLoadedCallback);
						layoutFileHandler.loadFile(loadType, "/file/get/" + PipeJamGame.levelInfo.m_layoutID+"/layout");
						var constraintsFileHandler:GameFileHandler = new GameFileHandler(constraintsFileLoadedCallback);
						constraintsFileHandler.loadFile(loadType, "/file/get/" +PipeJamGame.levelInfo.m_constraintsID+"/constraints");	
					}
				}
				else if(fileName && fileName.length > 0)
				{
					var worldFileHandler1:GameFileHandler = new GameFileHandler(worldFileLoadedCallback);
					worldFileHandler1.loadFile(loadType, fileName+".zip");
					var layoutFileHandler1:GameFileHandler = new GameFileHandler(layoutFileLoadedCallback);
					layoutFileHandler1.loadFile(loadType, fileName+"Layout.zip");
					var constraintsFileHandler1:GameFileHandler = new GameFileHandler(constraintsFileLoadedCallback);
					constraintsFileHandler1.loadFile(loadType, fileName+"Constraints.zip");
				}
			}
		}
		
/************************ End of static functions *********************************/
		
		public function GameFileHandler(callback:Function =  null)
		{
			m_callback = callback;
		}
		
		
		//load files from disk or database
		public function loadFile(loadType:int,fileName:String, callback:Function = null):void
		{
			fzip = new FZip();
			fzip.addEventListener(flash.events.Event.COMPLETE, zipLoaded);
			fzip..addEventListener(IOErrorEvent.IO_ERROR, ioErrorHandler);
			
			var loader:URLLoader = new URLLoader();
			switch(loadType)
			{
				case USE_DATABASE:
				{
					
					fzip.load(new URLRequest(NetworkConnection.PROXY_URL +fileName+ "&method=DATABASE"));
					break;
				}
				case USE_LOCAL:
				{
					fzip.load(new URLRequest(fileName + "?version=" + Math.round(1000000*Math.random())));
					break;
				}
				case USE_URL:
				{
					loader.addEventListener(flash.events.Event.COMPLETE, callback);
					loader.load(new URLRequest(fileName + "?version=" + Math.round(1000000*Math.random())));
					break;
				}
			}
		}
		
		private function ioErrorHandler(event:IOErrorEvent):void {
			trace("ioErrorHandler: " + event);
		}
		
		private function zipLoaded(e:flash.events.Event):void {
			fzip.removeEventListener(flash.events.Event.COMPLETE, zipLoaded);
			var zipFile:FZipFile;
			if(fzip.getFileCount() == 3)
			{
				var xmlArray:Array = new Array(3);
				for (var i:int = 0; i < fzip.getFileCount(); i++) {
					zipFile = fzip.getFileAt(i);
					if (zipFile.filename.toLowerCase().indexOf("layout") > -1) {
						xmlArray[2] = new XML(zipFile.content);
					} else if (zipFile.filename.toLowerCase().indexOf("constraints") > -1) {
						xmlArray[1] = new XML(zipFile.content);
					} else {
						xmlArray[0] = new XML(zipFile.content);
					}
				}
				m_callback(xmlArray);

			}
			else
			{
				zipFile = fzip.getFileAt(0);
				var containerXML:XML = new XML(zipFile.content);
				trace(zipFile.filename);

				if(containerXML.world.length()>0 &&
					containerXML.constraints.length()>0 &&
					containerXML.layout.length()>0)
				{
					var containerArray:Array = new Array(3);
					containerArray[0] = containerXML.world[0];
					containerArray[1] = containerXML.constraints[0];
					containerArray[2] = containerXML.layout[0];
	
					m_callback(containerArray);
				}
				else
				{
					//		trace("zip failed unexpected # of files:" + fz1.getFileCount());
					zipFile = fzip.getFileAt(0);
					var xml:XML = new XML(zipFile.content);
					m_callback(xml);
				}
			}
		}
		
		//just pass results on to the real callback
		public function defaultCallback(result:int, e:flash.events.Event):void
		{
			if(m_callback != null)
				m_callback(result, e);
		}
		
		//just pass results on to the real callback
		public function defaultJSONCallback(result:int, list:Vector.<Object>):void
		{
			if(m_callback != null)
				m_callback(result, list);
		}
		
		public function onRequestLevelFinished(result:int, e:flash.events.Event):void
		{
			if(e != null && (e.target.data as String).length > 0)
			{
				matchArrayObjects = JSON.parse(e.target.data).matches;
				//handle callback ourselves since we want to use request info, not refuse;
			}
			m_callback(result);
			sendMessage(REFUSE_LEVELS, null);
		}
		
		public function onRequestSavedLevelsFinished(result:int, layoutObjects:Vector.<Object>):void
		{
			savedMatchArrayObjects = layoutObjects;
			m_callback(result);
		}
		
		//called when level metadata is loaded 
		public function setLevelMetadataFromCurrent(result:int, layoutObjects:Vector.<Object>):void
		{
			levelInfoVector = layoutObjects;
			m_callback(result);
		}
		

		public function onRALevelCreated(result:int, e:flash.events.Event):void
		{
			var raLevelObj:Object = JSON.parse(e.target.data);
			var levelID:String = raLevelObj.id;
			m_levelCreated = true;
			saveLevelWithID(levelID);
		}
		
		//if levelID == null, we are just saving, not submitting (which creates a new level id for future use...)
		public function saveLevelWithID(levelID:String):void
		{
			sendMessage(SAVE_LEVEL, onLevelSubmitted, levelID, m_levelFilesString);
		}
		
		public function onLevelSubmitted(result:int, e:flash.events.Event):void
		{
			if(m_saveType == MenuEvent.SAVE_LEVEL)
				World.m_world.dispatchEvent(new MenuEvent(MenuEvent.LEVEL_SAVED));
			else
				World.m_world.dispatchEvent(new MenuEvent(MenuEvent.LEVEL_SUBMITTED));
		}
		
		public function onDBLevelCreated():void
		{
			//need the constraints file id and the level id to create a db level (reuse the current xmlID and layoutID)
			//also should add user id, so we can track who did what
			if(m_constraintsSaved == true && m_levelCreated == true)
			{
				//	sendMessage(CREATE_DB_LEVEL, null, ??????);
			}
		}
		
		public function sendMessage(type:int, callback:Function = null, info:String = null, data:String = null):void
		{
			var request:String;
			var method:String;
			var url:String = null;
			
			if(callback == null)
				callback = defaultCallback;
			
			switch(type)
			{
				case REQUEST_LEVELS:
					request = "/ra/games/"+PipeJam3.GAME_ID+"/players/"+PlayerValidation.playerID+"/count/"+numLevels+"/match&method=POST";
					method = URLRequestMethod.POST; 
					break;
				case REFUSE_LEVELS:
					request = "/ra/games/"+PipeJam3.GAME_ID+"/players/"+PlayerValidation.playerID+"/refused&method=PUT";
					method = URLRequestMethod.POST; 
					break;
				case START_LEVEL:
					request = "/ra/games/"+PipeJam3.GAME_ID+"/players/"+PlayerValidation.playerID+"/levels/"+ PipeJamGame.levelInfo.m_levelId+"/started&method=PUT";
					method = URLRequestMethod.POST; 
					break;
				case STOP_LEVEL:
					request = "/ra/games/"+PipeJam3.GAME_ID+"/players/"+PlayerValidation.playerID+"/stopped&method=PUT";
					method = URLRequestMethod.POST; 
					break;
				case REPORT_PLAYER_RATING:
					// /level/report/playerID/level/preference/performance
					request = "/level/report/"+PlayerValidation.playerID+"/"+ PipeJamGame.levelInfo.m_levelId
					+"/"+PipeJamGame.levelInfo.preference+"&method=DATABASE";
					method = URLRequestMethod.POST; 
					break;
				case CREATE_RA_LEVEL:
					request = "/ra/games/"+PipeJam3.GAME_ID+"/levels/new&method=POST";
					method = URLRequestMethod.POST; 
					break;
				
				//database messages
				case GET_ALL_LEVEL_METADATA:
					request = METADATA_GET_ALL_REQUEST+"&method=DATABASE";
					method = URLRequestMethod.POST; 
					break;
				case REQUEST_LAYOUT_LIST:
					request = LAYOUTS_GET_ALL_REQUEST+PipeJamGame.levelInfo.m_xmlID+"&method=DATABASE";
					method = URLRequestMethod.POST; 
					break;
				case GET_ALL_SAVED_LEVELS:
					request = "/level/get/saved/"+PlayerValidation.playerID+"&method=DATABASE";
					method = URLRequestMethod.POST; 
					break;
				case GET_SAVED_LEVEL:
					request = "/level/get/saved/0/"+data+"&method=DATABASE";
					method = URLRequestMethod.POST; 
					break;
				case SAVE_LAYOUT:
					request = "/layout/save/"+PlayerValidation.playerID+"/"+PipeJamGame.levelInfo.m_xmlID+"/"+info+"&method=DATABASE";
					method = URLRequestMethod.POST; 
					break;
				case DELETE_SAVED_LEVEL:
					request = "/level/delete/"+info+"&method=DATABASE";
					method = URLRequestMethod.POST; 
					break;
				case SAVE_LEVEL:
					var props:Object = PipeJamGame.levelInfo.m_metadata.properties;
					var scoreASString:String = String(PipeJamGame.levelInfo.m_score);
					var levelID:String = info as String;
					method = URLRequestMethod.POST;
					var requestStart:String = "";
					var requestMiddle:String = "";
					var requestEnd:String = "";
					//var paramObject:String = ""; maybe in the future json params and add as a param on end of request?
					if(info == null) //we are just saving the level, because we don't have a new ID
					{
						requestStart = "/level/save/";
						levelID = PipeJamGame.levelInfo.m_levelId;
						requestEnd = "/"+m_fileType+"/"+PipeJamGame.levelInfo.shareWithGroup;
					}
					else
					{
						requestStart = "/level/submit/";
						var eRating:int = int(Math.round(PipeJamGame.levelInfo.enjoymentRating*20));
						requestEnd = "/" + eRating+"/"+m_fileType;
					}
					
					//these need to match the proxy server, or we need to figure out json transfer...
					requestMiddle = PlayerValidation.playerID+"/"+PipeJamGame.levelInfo.m_xmlID+"/"+encodeURIComponent(PipeJamGame.levelInfo.m_layoutName)+"/"+PipeJamGame.levelInfo.m_layoutID
					+ "/"+encodeURIComponent(PipeJamGame.levelInfo.m_name)
					+ "/" + levelID +"/"+scoreASString
					+ "/" + props.boxes + "/" + props.lines+ "/"+ props.visibleboxes
					+ "/" + props.visiblelines + "/" + props.conflicts+ "/"+ props.bonusnodes;
					
					request = requestStart + requestMiddle + requestEnd + "&method=DATABASE";
					
					break;
				case REPORT_LEADERBOARD_SCORE:
					var leaderboardScore:int = 1;
					var levelScore:int = PipeJamGame.levelInfo.m_score;
					var targetScore:int = PipeJamGame.levelInfo.m_targetScore;
					if(levelScore > targetScore)
						leaderboardScore = 2;
					request = "/api/score&method=URL";
					var dataObj:Object = new Object;
					dataObj.playerId = PlayerValidation.playerID;
					dataObj.gameId = PipeJam3.GAME_ID;
					dataObj.levelId = PipeJamGame.levelInfo.m_levelId;
					var parameters:Array = new Array;
					var paramScoreObj:Object = new Object;
					paramScoreObj.name = "score";
					paramScoreObj.value = PipeJamGame.levelInfo.m_score;
					var paramLeaderScoreObj:Object = new Object;
					paramLeaderScoreObj.name = "leaderboardScore";
					paramLeaderScoreObj.value = leaderboardScore;
					parameters.push(paramScoreObj);
					parameters.push(paramLeaderScoreObj);
					dataObj.parameter = parameters;
					data = JSON.stringify(dataObj);
					var enc:Base64Encoder = Base64Encoder.getEncoder();
					enc.encode(data);
					data = enc.toString();
					method = URLRequestMethod.POST; 
					break;
			}
			
			NetworkConnection.sendMessage(callback, request, data, url, method);
		}
	}
}