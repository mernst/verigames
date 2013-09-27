package networking
{
	import events.MenuEvent;
	
	import flash.events.Event;
	import flash.utils.Dictionary;
	
	import scenes.game.display.World;
	
	import server.LoggingServerInterface;
	
	import starling.core.Starling;
	import starling.display.Sprite;
	
	import flash.net.URLRequestMethod;
	
	import utils.XString;
	import utils.Base64Encoder;
	
	public class Achievements
	{
		public static var ADD_ACHIEVEMENT:int = 0;
		public static var GET_ACHIEVEMENTS:int = 1;
		
		public static var TUTORIAL_FINISHED_ID:String = "5228b505cb99a6030800002a";
		public static var TUTORIAL_FINISHED_STRING:String = "Achievement: You've Finished All the Tutorials!";

		
		protected var m_id:String;
		protected var m_message:String;
		
		static protected var currentAchievementList:Dictionary;
		
		public static function getAchievementsEarnedForPlayer():void
		{
			var newAchievement:Achievements = new Achievements();
			newAchievement.sendMessage(GET_ACHIEVEMENTS, getAchievements);
		}
		
		protected static function getAchievements(result:int, e:Event):void
		{
			var achievementObject:Object = JSON.parse(e.target.data);
			currentAchievementList = new Dictionary;
			for each(var achievement:Object in achievementObject.playerAchievements)
			{
				currentAchievementList[achievement.achievementId] = achievement;
			}
		}
		
		public static function addAchievement(type:String, message:String):void
		{
			var newAchievement:Achievements = new Achievements(type, message);
			newAchievement.post();
		}
		
		static public function isAchievementNew(achievementNumber:String):Boolean
		{
			if(currentAchievementList && (currentAchievementList[achievementNumber] != null))
				return false;
			else
				return true;
		}
		
		public function Achievements(id:String = null, message:String = null):void
		{
			m_id = id;
			m_message = message;
		}
		
		public function post():void
		{
			sendMessage(ADD_ACHIEVEMENT, postMessage);
		}
		
		protected function postMessage(result:int, e:Event):void
		{
			World.m_world.dispatchEvent(new MenuEvent(MenuEvent.ACHIEVEMENT_ADDED, m_message));
		}
		
		public function sendMessage(type:int, callback:Function):void
		{
			var request:String;
			var data:String = null;
			var method:String;
			var url:String = null;
			
			var enc:Base64Encoder = Base64Encoder.getEncoder();
			
			switch(type)
			{
				case GET_ACHIEVEMENTS:
					request = "/api/achievements/search/player?playerId=" + PlayerValidation.playerID + "&method=URL";
					method = URLRequestMethod.GET; 
					break;
				case ADD_ACHIEVEMENT:
					request = "/api/achievement/assign&method=URL";
					var dataObj:Object = new Object;
					dataObj.playerId = PlayerValidation.playerID;
					dataObj.gameId = PipeJam3.GAME_ID;
					dataObj.achievementId = m_id;
					dataObj.earnedOn = (new Date()).time;
					
					data = JSON.stringify(dataObj);
					enc.encode(data);
					data = enc.toString();
					method = URLRequestMethod.POST; 
					break;
			}
			
			NetworkConnection.sendMessage(callback, request, data, url, method);
		}
	}
}