package networking
{	
	import flash.utils.*;

	/** this is the main holder of information about the level.*/
	public class LevelInformation
	{				

		public var m_version:int;
		
		public var m_id:String;
		
		/** the RA level. */
		public var m_RaLevelID:String;
		
		/** various DB file ids */
		public var m_levelID:String
		public var m_layoutID:String;
		public var m_assignmentsID:String;
		
		public var m_name:String;
		public var m_layoutName:String;
		public var m_layoutDescription:String;
		public var m_layoutUpdated:Boolean;
		
		public var m_baseFileName:String;
		
		public var m_score:int;
		public var m_targetScore:int;
		
		public var m_revision:String;
		
		public var m_checked:Boolean;
		public var m_unlocked:Boolean;
		
		public var m_properties:Object;
		public var m_metadata:Object;
		
		//these are currently the same values as the two ratings below
		public var preference:String;
		
		public var enjoymentRating:Number;
		public var difficultyRating:Number;		
		
		public var shareWithGroup:int;
		
		public var m_hashArray:Array;

		public function LevelInformation(levelObj:Object = null)
		{
			if(levelObj)
			{
				if(levelObj._id != null)
				{
					if(levelObj._id is String)
						m_id = levelObj._id;
					else
						m_id = levelObj._id.$oid;
				}
				
				//steal properties for ourselves...
				for(var id:String in levelObj) {
					var value:Object = levelObj[id];
					
					if(this.hasOwnProperty("m_"+id))
					{
						this["m_"+id] = value;
						//trace("Found level info property " + id);
					}
					else
						trace("Can't find level info property " + id);
				}
			}
			m_layoutUpdated = false;
		}
		
		public function createLevelObject():Object
		{
			var levelObj:Object = new Object();
			levelObj.m_version = m_version;
			levelObj.m_id = m_id;
			levelObj.m_levelId = m_RaLevelID;
			levelObj.m_levelID = m_levelID;
			levelObj.m_layoutID = m_layoutID;
			levelObj.m_assignmentsID = m_assignmentsID;
			
			levelObj.m_name = m_name;
			levelObj.m_layoutName = m_layoutName;
			levelObj.m_layoutDescription = m_layoutDescription;
			
			levelObj.m_baseFileName = m_baseFileName;
			
			levelObj.m_score = m_score;
			levelObj.m_targetScore = m_targetScore;
			
			levelObj.m_revision = m_revision;
			
			levelObj.m_checked = m_checked;
			levelObj.m_unlocked = m_unlocked;
			
			levelObj.m_properties = cloneObj(m_properties);
			levelObj.m_metadata = cloneObj(m_metadata);
			
			levelObj.preference = preference;
			
			levelObj.enjoymentRating = enjoymentRating;
			levelObj.difficultyRating = difficultyRating;	
			
			levelObj.shareWithGroup = shareWithGroup;
			levelObj.m_layoutChanged = m_layoutUpdated;
			
			return levelObj;
		}
		
		private static function cloneObj(obj:Object):Object
		{
			var clone:Object = new Object();
			for (var key:Object in obj) {
				clone[key] = obj[key];
			}
			return clone;
		}
		
		//need the object without the "m_" in variable names 
		public function cloneObjForDatabase():Object
		{
			var varList:XMLList = flash.utils.describeType(this)..variable;
			var clone:Object = new Object();
			for(var i:int; i < varList.length(); i++)
			{
				var key:String = varList[i].@name;
				var cloneKey:String = null;
				if(key.indexOf("m_") != -1)
					cloneKey = key.substring(2);
				else
					cloneKey = key;
				clone[cloneKey] = this[key];
			}

			return clone;
		}
	}
}	

