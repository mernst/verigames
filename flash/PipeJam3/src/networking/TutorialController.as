package networking
{
	import flash.events.Event;
	import flash.net.URLRequestMethod;
	import flash.utils.Dictionary;
	
	import events.MenuEvent;
	
	import scenes.game.PipeJamGameScene;
	import scenes.game.display.Level;
	import scenes.game.display.World;
	import scenes.loadingscreen.LoadingScreenScene;
	
	import server.LoggingServerInterface;
	
	import starling.core.Starling;
	import starling.display.Sprite;
	
	import utils.XString;
	
	
	public class TutorialController extends Sprite
	{			
		[Embed(source = "../../lib/levels/tutorial/tutorial.xml", mimeType = "application/octet-stream")]
		static public const tutorialFileClass:Class;
		static public const tutorialXML:XML = XML(new tutorialFileClass());
		
		[Embed(source = "../../lib/levels/tutorial/tutorialLayout.xml", mimeType = "application/octet-stream")]
		static public const tutorialLayoutFileClass:Class;
		static public const tutorialLayoutXML:XML = XML(new tutorialLayoutFileClass());
		
		[Embed(source = "../../lib/levels/tutorial/tutorialConstraints.xml", mimeType = "application/octet-stream")]
		static public const tutorialConstraintsFileClass:Class;
		static public const tutorialConstraintsXML:XML = XML(new tutorialConstraintsFileClass());

		public static var TUTORIAL_LEVEL_COMPLETE:int = 0;
		public static var GET_COMPLETED_TUTORIAL_LEVELS:int = 1;
		
		public static var TUTORIALS_COMPLETED_STRING:String = "tutorials_completed";

		//used as a ordered array of order values containing all tutorial orders
		protected var tutorialOrderedList:Vector.<Number>;
		
		//these are tutorial level lookups for all tutorials
		protected var orderToTutorialDictionary:Dictionary;
		protected var qidToTutorialDictionary:Dictionary;
		
		//lookup by qid, if not null, has been completed
		public var completedTutorialList:Dictionary;
		
		protected static var tutorialController:TutorialController;
		
		public var fromLevelSelectList:Boolean = false;
		
		protected var levelCompletedQID:String;
		
		static public function getTutorialController():TutorialController
		{
			if(tutorialController == null)
				tutorialController = new TutorialController;
			
			return tutorialController;
		}
		
		public function getTutorialsCompletedByPlayer():void
		{
			sendMessage(GET_COMPLETED_TUTORIAL_LEVELS, getTutorialsCompleted);
		}
		
		protected function getTutorialsCompleted(result:int, completedTutorials:Vector.<Object>):void
		{
			if(completedTutorialList == null)
				completedTutorialList = new Dictionary;
			for each(var tutorial:Object in completedTutorials)
			{
				completedTutorialList[tutorial.levelID] = tutorial;
			}
			//also check cookies for levels played when not logged in
			var tutorialsCompleted:String = HTTPCookies.getCookie(TUTORIALS_COMPLETED_STRING);
			if(tutorialsCompleted)
				getTutorialsCompletedFromCookieString(tutorialsCompleted);
			
			setTutorialXML(tutorialXML);
			
			LoadingScreenScene.getLoadingScreenScene().changeScene();
		}
		
		public function getTutorialsCompletedFromCookieString(tutorialsCompleted:String):void
		{
			if(completedTutorialList == null)
				completedTutorialList = new Dictionary;
			
			var tutorialListArray:Array = tutorialsCompleted.split(",");
			for each(var tutorial:String in tutorialListArray)
			{
				completedTutorialList[tutorial] = tutorial;
			}
			setTutorialXML(tutorialXML);
			
			LoadingScreenScene.getLoadingScreenScene().changeScene();
		}
		
		public function addCompletedTutorial(qid:String, markComplete:Boolean):void
		{
			if(PipeJam3.RELEASE_BUILD)
			{
				if (!PipeJamGame.levelInfo) return;
				if (!completedTutorialList) completedTutorialList = new Dictionary();
				var currentLevel:int = parseInt(PipeJamGame.levelInfo.m_levelId);
				if(completedTutorialList[currentLevel] == null)
				{
					var newTutorialObj:TutorialController = new TutorialController();
					newTutorialObj.levelCompletedQID = PipeJamGame.levelInfo.m_levelId;
					completedTutorialList[currentLevel] = newTutorialObj;
					newTutorialObj.post();
				}
			}
		}
		public function post():void
		{
			if(PlayerValidation.playerLoggedIn)
				sendMessage(TUTORIAL_LEVEL_COMPLETE, postMessage);
			else
			{
				//add to cookie string
				var tutorialsCompleted:String = HTTPCookies.getCookie(TUTORIALS_COMPLETED_STRING);
				tutorialsCompleted += "," + levelCompletedQID;
				HTTPCookies.setCookie(TUTORIALS_COMPLETED_STRING, tutorialsCompleted);
			}
		}
		
		protected function postMessage(result:int, e:Event):void
		{
		}
		
		public function isTutorialLevelCompleted(tutorialQID:String):Boolean
		{
			return (completedTutorialList && (completedTutorialList[tutorialQID] != null));
		}

		
		//first tutorial should be unlocked
		//any played tutorials should be unlocked
		//first unplayed tutorial that immediately follows a completed tutorial should be unlocked
		public function tutorialShouldBeUnlocked(tutorialQID:String):Boolean
		{
			var tutorialQIDInt:int = int(tutorialQID);
			
			if(tutorialQIDInt == getFirstTutorialLevel())
				return true;
			else if(completedTutorialList && (completedTutorialList[tutorialQID] != null))
				return true;
			else
			{
				//find first next level to play, then compare with argument
				var levelFound:Boolean = false;
				for each(var order:int in tutorialOrderedList)
				{
					var nextQID:String = orderToTutorialDictionary[order].@qid;
					
					if(!isTutorialLevelCompleted(nextQID))
					{
						if(nextQID == tutorialQID)
							return true;
						else
							return false;
					}
				}
			}
			return false;
		}
		
		//returns the first tutorial level qid in the sequence
		public function getFirstTutorialLevel():int
		{
			if (!tutorialOrderedList) return 0;
			var order:Number = tutorialOrderedList[0];
			return orderToTutorialDictionary[order].@qid;
		}
		
		//uses the current PipeJamGame.levelInfo.levelId to find the next level in sequence that hasn't been played
		//returns qid of next level to play, else 0
		public function getNextUnplayedTutorial():int
		{
			var currentLevelQID:int;
			if (!PipeJamGame.levelInfo) 
				return 0;
			currentLevelQID = parseInt(PipeJamGame.levelInfo.m_levelId);
			
			var currentLevel:XML = qidToTutorialDictionary[currentLevelQID];
			
			var currentPosition:int = currentLevel.@position;
			
			currentPosition++;
			var nextPosition:int = currentPosition;
			
			var levelFound:Boolean = false;
			while(!levelFound)
			{
				if(nextPosition == tutorialOrderedList.length)
					return 0;
				
				var nextQID:int = orderToTutorialDictionary[nextPosition].@qid;
				
				//if we chose the last level from the level select screen, assume we want to play in order, done or not
				if(fromLevelSelectList)
					return nextQID;
				
				if(completedTutorialList[nextQID] == null)
					return nextQID;
				
				nextPosition++;
			}
			
			return 0;
		}

		
		public function setTutorialXML(m_worldXML:XML):void
		{
			tutorialOrderedList = new Vector.<Number>;
			orderToTutorialDictionary = new Dictionary;
			qidToTutorialDictionary = new Dictionary;
			//order the levels and store the order
			var children:XMLList = m_worldXML.children();
			var count:int = 0;
			for each(var level:XML in children)
			{
				var qid:Number = Number(level.attribute("qid"));
				qidToTutorialDictionary[qid] = level;
				
				orderToTutorialDictionary[count] = level;
				
				level.@position = count;
				
				tutorialOrderedList.push(count);
				count++;
			}
		}
		
		public function clearPlayedTutorials():void
		{
			completedTutorialList = new Dictionary;
		}
		
		public function resetTutorialStatus():void
		{
			clearPlayedTutorials();
		}
		

		public function isTutorialDone():Boolean
		{
			if(tutorialOrderedList == null)
				return false;
			
			for each(var position:int in tutorialOrderedList)
			{
				var level:XML = orderToTutorialDictionary[position];
				var qid:String = level.attribute("qid");
				
				if(isTutorialLevelCompleted(qid) == false)
					return false;				
			}
			
			return true;
		}
		
		public function sendMessage(type:int, callback:Function):void
		{
			var request:String;
			var method:String;
			var url:String = null;
			switch(type)
			{
				case TUTORIAL_LEVEL_COMPLETE:
					request = "/tutorial/level/complete/"+PlayerValidation.playerID+"/"+PipeJamGame.levelInfo.m_levelId+"&method=DATABASE";
					method = URLRequestMethod.POST; 
					break;
				case GET_COMPLETED_TUTORIAL_LEVELS:
					request = "/tutorial/levels/completed/"+PlayerValidation.playerID+"&method=DATABASE";
					method = URLRequestMethod.POST; 
					break;
			}
			
			NetworkConnection.sendMessage(callback, request, null, null, method);
		}
	}
}