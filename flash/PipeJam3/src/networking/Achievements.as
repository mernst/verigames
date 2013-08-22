package networking
{
	import server.LoggingServerInterface;
	
	import starling.core.Starling;
	import flash.events.Event;
	
	import utils.XString;
	import scenes.game.display.World;
	import events.MenuEvent;
	import starling.display.Sprite;
	
	
	public class Achievements extends Sprite
	{
		public static var TUTORIAL_FINISHED:String = "521553d9d171ab5017000043";
		public static var TUTORIAL_FINISHED_STRING:String = "Achievement: You've Finished All the Tutorials!";

		
		protected var m_type:String;
		protected var m_message:String;
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
		
		public function postMessage(result:int, e:Event):void
		{
			World.m_world.dispatchEvent(new MenuEvent(MenuEvent.ACHIEVEMENT_ADDED, m_message));
		}
	}
}