package networking
{
	import flash.external.ExternalInterface;
	
	import events.MenuEvent;
	import events.NavigationEvent;
	
	import PipeJam3;
	
	import scenes.game.display.World;
	
	public class HTTPCookies
	{
		public static function initialize():void
		{
			if (!ExternalInterface.available) {
				return;
			}
			ExternalInterface.addCallback("loadAssignmentFile", loadAssignmentFile);
			ExternalInterface.addCallback("loadLevel", loadLevel);
		}
		
		public static function loadAssignmentFile(assignmentFileID:String):void
		{
			World.m_world.loadAssignmentFile(assignmentFileID);
		}
		
		public static function loadLevel(levelID:String):void
		{
			World.m_world.dispatchEvent(new NavigationEvent(NavigationEvent.CHANGE_SCREEN, "PipeJamGame", levelID));
		}
		
		public static function getCookie(key:String):*
		{
			if (!ExternalInterface.available) {
				return null;
			}
			return ExternalInterface.call("getCookie", key);
		}
		
		public static function setCookie(key:String, val:*):void
		{
			if (!ExternalInterface.available) {
				return;
			}
			ExternalInterface.call("setCookie", key, val);
		}
		
		public static function displayAlert(str:String):void
		{
			if (!ExternalInterface.available) {
				return;
			}
			ExternalInterface.call("alert", str);
		}
		
		protected static var warningDisplayed:Boolean = false;
		public static function addHighScores(str:String):void
		{
			if (!ExternalInterface.available) {
				if(World.m_world && PipeJam3.RELEASE_BUILD && !warningDisplayed)
				{
					World.m_world.dispatchEvent(new MenuEvent(MenuEvent.POST_DIALOG, "no external interface"));
					warningDisplayed = true;
				}
				return;
			}
			ExternalInterface.call("addHighScores", escape(str));
		}
		
		public static function addScoreImprovementTotals(str:String):void
		{
			if (!ExternalInterface.available) {
				return;
			}
			ExternalInterface.call("addScoreImprovementTotals",  escape(str));
		}
		
		public static function callGetEncodedCookie():void
		{
			if (!ExternalInterface.available) {
				return;
			}
			ExternalInterface.call("getEncodedCookie");
		}
		
		public static function getEncodedCookieResult():*
		{
			if (!ExternalInterface.available) {
				return;
			}
			return ExternalInterface.call("getEncodedCookieResult");
		}
	}
}

/*
Need to make sure this is in the JS:

			function getCookie(key)
			{
				var cookieValue = null;
				
				if (key)
				{
					var cookieSearch = key + "=";
					
					if (document.cookie)
					{
						var cookieArray = document.cookie.split(";");
						for (var i = 0; i < cookieArray.length; i++)
						{
							var cookieString = cookieArray[i];
							
							// skip past leading spaces
							while (cookieString.charAt(0) == ' ')
							{
								cookieString = cookieString.substr(1);
							}
							
							// extract the actual value
							if (cookieString.indexOf(cookieSearch) == 0)
							{
								cookieValue = cookieString.substr(cookieSearch.length);
							}
						}
					}
				}
			
				return cookieValue;
			}

function setCookie(key, val)
{
	if (key)
	{
		var date = new Date();
		
		if (val != null)
		{
			// expires in one year
			date.setTime(date.getTime() + (365*24*60*60*1000));
			document.cookie = key + "=" + val + "; expires=" + date.toGMTString();
		}
		else
		{
			// expires yesterday
			date.setTime(date.getTime() - (24*60*60*1000));
			document.cookie = key + "=; expires=" + date.toGMTString();
		}
	}
}

*/