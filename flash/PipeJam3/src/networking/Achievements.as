package networking
{
	import server.LoggingServerInterface;
	
	import starling.core.Starling;
	import flash.events.Event;
	
	import utils.XString;
	import scenes.game.display.World;
	import events.MenuEvent;
	import starling.display.Sprite;
	import flash.utils.Dictionary;
	
	
	public class Achievements extends Sprite
	{
		public static var TUTORIAL_FINISHED:String = "5228b505cb99a6030800002a";
		public static var TUTORIAL_FINISHED_STRING:String = "Achievement: You've Finished All the Tutorials!";

		
		protected var m_type:String;
		protected var m_message:String;
		
		static protected var currentAchievementList:Dictionary;
		
		public static function getAchievementsEarnedForPlayer():void
		{
			LoginHelper.getLoginHelper().sendMessage(LoginHelper.GET_ACHIEVEMENTS, getAchievements);
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
		
		public function Achievements(type:String, message:String):void
		{
			m_type = type;
			m_message = message;
			World.m_world.addChild(this);
		}
		
		public function post():void
		{
			LoginHelper.getLoginHelper().sendMessage(LoginHelper.ADD_ACHIEVEMENT, postMessage, null, m_type);
		}
		
		protected function postMessage(result:int, e:Event):void
		{
			World.m_world.dispatchEvent(new MenuEvent(MenuEvent.ACHIEVEMENT_ADDED, m_message));
		}
		
		static public function isAchievementNew(achievementNumber:String):Boolean
		{
			if(currentAchievementList && (currentAchievementList[achievementNumber] != null))
				return false;
			else
				return true;
		}
	}
}