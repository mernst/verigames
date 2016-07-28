package networking
{
	import flash.net.URLRequestMethod;
	import flash.utils.Dictionary;
	import scenes.game.display.TutorialLevelManager;
	import starling.display.Sprite;
	import server.LoggingServerInterface;
	
	public class TutorialController extends Sprite
	{			
		[Embed(source = "../../lib/levels/tutorial/tutorial.json", mimeType = "application/octet-stream")]
		private static const tutorialFileClass:Class;
		private static var tutorialObj_instance:Object;
		
		[Embed(source = "../../lib/levels/tutorial/tutorialLayout.json", mimeType = "application/octet-stream")]
		private static const tutorialLayoutFileClass:Class;
		private static const tutorialLayoutJson:String = new tutorialLayoutFileClass();
		public static const tutorialLayoutObj:Object = JSON.parse(tutorialLayoutJson);
		
		[Embed(source = "../../lib/levels/tutorial/tutorialAssignments.json", mimeType = "application/octet-stream")]
		private static const tutorialAssignmentsFileClass:Class;
		private static const tutorialAssignmentsJson:String = new tutorialAssignmentsFileClass();
		public static const tutorialAssignmentsObj:Object = JSON.parse(tutorialAssignmentsJson);
		
		public static var TUTORIAL_LEVEL_COMPLETE:int = 0;
		public static var GET_COMPLETED_TUTORIAL_LEVELS:int = 1;
		
		public static var TUTORIALS_COMPLETED_STRING:String = "tutorials_completed";
		
		public static var tutorialsDone:Boolean = false;

		//used as a ordered array of order values containing all tutorial orders
		protected var tutorialOrderedList:Vector.<Number>;
		
		//these are tutorial level lookups for all tutorials
		protected var orderToTutorialDictionary:Dictionary;
		protected var qidToTutorialDictionary:Dictionary;
		
		//lookup by qid, if not null, has been completed
		public var completedTutorialDictionary:Dictionary;
		
		protected static var tutorialController:TutorialController;
		
		public var fromLevelSelectList:Boolean = false;
		
		protected var levelCompletedQID:String;
		
		//All tutorial info gets saved locally in cookies
		public function TutorialController()
		{
			setTutorialObj(tutorialObj);
		}
		
		
		// these getters allow us to modify the embedded JSON before it is used
		public static function get tutorialObj():Object
		{
			if (tutorialObj_instance == null) {
				var worldJson:String = new tutorialFileClass();
				var worldObj:Object = JSON.parse(worldJson);
				
				var levels:Array = worldObj["levels"];
				if (levels)
				{
					var newLevels:Array = [];
					for (var i:int = 0; i < levels.length; i++)
					{
						var levelObj:Object = levels[i];
						if (!TutorialLevelManager.excludeLevel(levelObj["id"]))
						{
							newLevels.push(levelObj);
						}
					}
					worldObj["levels"] = newLevels;
				}
				
				tutorialObj_instance = worldObj;
			}
			return tutorialObj_instance;
		}
		

		static public function getTutorialController():TutorialController
		{
			if(tutorialController == null)
				tutorialController = new TutorialController;
			
			return tutorialController;
		}
		
		public function getTutorialsCompletedByPlayer():void
		{
			if(completedTutorialDictionary == null)
				completedTutorialDictionary = new Dictionary;
			
			var tutorialsCompleted:String = (PipeJam3.ASSET_SUFFIX == "Turk") ? null : HTTPCookies.getCookie(TutorialController.TUTORIALS_COMPLETED_STRING);
			if(tutorialsCompleted != null)
			{
				var tutorialListArray:Array = tutorialsCompleted.split(",");
				for each(var tutorial:String in tutorialListArray)
				{
					completedTutorialDictionary[tutorial] = tutorial;
				}
			}
		}
		
		public function addCompletedTutorial(qid:String, markComplete:Boolean):void
		{
			if(PipeJam3.RELEASE_BUILD)
			{
				if (!PipeJamGame.levelInfo) return;
				if (!completedTutorialDictionary) completedTutorialDictionary = new Dictionary();
				var currentLevel:int = parseInt(PipeJamGame.levelInfo.tutorialLevelID);
				if(completedTutorialDictionary[currentLevel] == null)
				{
					var newTutorialObj:TutorialController = new TutorialController();
					newTutorialObj.levelCompletedQID = PipeJamGame.levelInfo.tutorialLevelID;
					completedTutorialDictionary[currentLevel] = newTutorialObj;
					newTutorialObj.post();
				}
			}
		}
		public function post():void
		{
			var tutorialsCompleted:String = (PipeJam3.ASSET_SUFFIX == "Turk") ? "" : HTTPCookies.getCookie(TUTORIALS_COMPLETED_STRING);
			tutorialsCompleted += "," + levelCompletedQID;
 			HTTPCookies.setCookie(TUTORIALS_COMPLETED_STRING, tutorialsCompleted);
		}
		
		public function isTutorialLevelCompleted(tutorialQID:String):Boolean
		{
			return (completedTutorialDictionary && (completedTutorialDictionary[tutorialQID] != null));
		}

		
		//returns the first tutorial level qid in the sequence
		public function getFirstTutorialLevel():int
		{
			if (!tutorialOrderedList) return 0;
			var order:Number = tutorialOrderedList[0];
			return orderToTutorialDictionary[order]["qid"];
		}
		
		//uses the current PipeJamGame.levelInfo.levelId to find the next level in sequence that hasn't been played
		//returns qid of next level to play, else 0
		public function getNextUnplayedTutorial():int
		{
			var currentLevelQID:int;
			if (!PipeJamGame.levelInfo) 
				return 0;
			currentLevelQID = parseInt(PipeJamGame.levelInfo.tutorialLevelID);
			
			var currentLevel:Object = qidToTutorialDictionary[currentLevelQID];
			trace("THIS IS THE CURRENT LEVEL---------------------------------------", LoggingServerInterface.obj2str(currentLevel));
			
			
			if (!currentLevel) return 0;
			var currentPosition:int = currentLevel["position"];
			var nextPosition:int = currentPosition + 1;
			
			var levelFound:Boolean = false;
			while(!levelFound)
			{
				if(nextPosition == tutorialOrderedList.length)
					return 0;
				if (!orderToTutorialDictionary.hasOwnProperty(nextPosition))
					return 0;
				if (!orderToTutorialDictionary[nextPosition].hasOwnProperty("qid"))
					return 0;
				var nextQID:int = orderToTutorialDictionary[nextPosition]["qid"];
				
				//if we chose the last level from the level select screen, assume we want to play in order, done or not
				if(fromLevelSelectList)
					return nextQID;
				
				if(completedTutorialDictionary[nextQID] == null)
					return nextQID;
				
				nextPosition++;
			}
			
			return 0;
		}
		
		public function setTutorialObj(m_worldObj:Object):void
		{
			var levels:Array = m_worldObj["levels"];
			if (!levels) throw new Error("Expecting 'levels' Array in tutorial world JSON");
			tutorialOrderedList = new Vector.<Number>;
			orderToTutorialDictionary = new Dictionary;
			qidToTutorialDictionary = new Dictionary;
			//order the levels and store the order
			for (var i:int = 0; i < levels.length; i++)
			{
				var levelObj:Object = levels[i];
				var qid:Number = Number(levelObj["qid"]);
				qidToTutorialDictionary[qid] = levelObj;
				orderToTutorialDictionary[i] = levelObj;
				levelObj["position"] = i;
				tutorialOrderedList.push(i);
			}
		}
		
		public function clearPlayedTutorials():void
		{
			completedTutorialDictionary = new Dictionary;
			PipeJamGame.levelInfo = null;
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
				var level:Object = orderToTutorialDictionary[position];
				var qid:String = level["qid"];
				if(isTutorialLevelCompleted(qid) == false)
					return false;				
			}
			
			return true;
		}
		
		public function isLastTutorialLevel():Boolean
		{
			
			if (!PipeJamGame.levelInfo) return false;
			var currentLevelQID:int = parseInt(PipeJamGame.levelInfo.tutorialLevelID);
			
			var currentLevel:Object = qidToTutorialDictionary[currentLevelQID];
			if (!currentLevel) return false;
			var currentPosition:int = currentLevel["position"];
			return (currentPosition == tutorialOrderedList.length - 1);
		}
		
		public function sendMessage(type:int, callback:Function):void
		{
			var request:String;
			var method:String;
			var data:Object;
			var url:String = null;
			
			var messages:Array = new Array ();  			

			
			switch(type)
			{
				case TUTORIAL_LEVEL_COMPLETE:
					messages.push ({'playerID': PlayerValidation.playerID,'levelID': PipeJamGame.levelInfo.tutorialLevelID});
					var data_id:String = JSON.stringify(messages);
					url = NetworkConnection.productionInterop + "?function=reportPlayedTutorial2&data_id='"+data_id+"'";
					method = URLRequestMethod.POST; 
					break;
				case GET_COMPLETED_TUTORIAL_LEVELS:
					url = NetworkConnection.productionInterop + "?function=findPlayedTutorials2&data_id="+PlayerValidation.playerID;
					method = URLRequestMethod.POST; 
					break;
			}
			


			NetworkConnection.sendMessage(callback, null, url, method, "");
		}
	}
}