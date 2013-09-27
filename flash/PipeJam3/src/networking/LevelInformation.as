package networking
{	
	import deng.fzip.FZip;
	import deng.fzip.FZipFile;
	
	import events.MenuEvent;
	import events.NavigationEvent;
	
	import flash.events.*;
	import flash.net.*;
	import flash.system.Security;
	import flash.text.*;
	import flash.utils.*;
	
	import graph.BoardNodes;
	
	import scenes.game.display.World;
	
	import starling.events.*;
	
	import utils.XString;

	/** this is the main holder of information about the level.*/
	public class LevelInformation
	{				

		public var m_version:int;
		
		public var m_levelId:String;
		public var m_xmlID:String
		public var m_layoutID:String;
		public var m_constraintsID:String;
		
		public var m_name:String;
		public var m_layoutName:String;
		public var m_layoutDescription:String;
		
		public var m_baseFileName:String;
		
		public var m_score:int;
		public var m_targetScore:int;
		
		public var m_checked:Boolean;
		public var m_unlocked:Boolean;
		
		public var m_properties:Object;
		public var m_metadata:Object;
		
		public var preference:Number;
		public var performance:Number;	
		
		public var enjoymentRating:Number;
		public var difficultyRating:Number;		
		
		public var shareWithGroup:int;
		

		public function LevelInformation(levelObj:Object = null)
		{
			if(levelObj)
			{
				//steal properties for ourselves...  "Mine all Mine, me precious"
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
		}
		

	}
}	

