package server
{
	import cgs.server.logging.CGSServer;
	import cgs.server.logging.CGSServerConstants;
	import cgs.server.logging.CGSServerProps;
	import cgs.server.logging.GameServerData;
	import cgs.server.logging.actions.ClientAction;
	
	import system.VerigameServerConstants;
	
	public class LoggingServerInterface
	{
		public static var START_LOGGING:String = "startLogging";
		
		public static var m_serverInitialized:Boolean = false;

		public function LoggingServerInterface()
		{
		}
		
		
		
		public static function initializeServer():void
		{
			m_serverInitialized = true;
			
			 //Initialize logging
			if (PipeJamGame.LOGGING_ON) {
				
				var props:CGSServerProps = new CGSServerProps(
					VerigameServerConstants.VERIGAME_SKEY,
					GameServerData.NO_SKEY_HASH,
					VerigameServerConstants.VERIGAME_GAME_NAME,
					VerigameServerConstants.VERIGAME_GAME_ID,
					VerigameServerConstants.VERIGAME_VERSION_SEEDLING_BETA,
					VerigameServerConstants.VERIGAME_CATEGORY_SEEDLING_BETA,
					CGSServerConstants.DEV_URL
				);
				props.cacheUid = false;
				props.uidValidCallback = onUidSet;
				props.forceUid = "cgs_test_tdp";
				CGSServer.setup(props);
				var saveCacheToServer:Boolean = false;
				CGSServer.initialize(props, saveCacheToServer, onServerInit);
				
				function onServerInit(failed:Boolean):void {
					trace("onServerInit() failed=" + failed.toString());
				}
				
				function onUidSet(uid:String, failed:Boolean):void {
					trace("onUidSet() failed=" + failed.toString());
				}
			}
		}
		
		public static function log(action:String):void
		{
			//log start do this:
			//CGSServer.logQuestStart(VerigameServerConstants.VERIGAME_QUEST_ID_UNDEFINED_WORLD, levelInfo, onLogQuestStart);
		}
	}
}