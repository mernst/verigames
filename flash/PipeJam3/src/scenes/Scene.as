package scenes
{
    import starling.display.Sprite;
    import starling.events.Event;
    
    public class Scene extends BaseComponent
    {	
		protected var m_gameSystem:Game;
		
		//used by RA level chooser
		public static var levelNumberString:String = null;
		public static var useCurrentLevelNumber:Boolean = false;
		
		//the first address is verigames, the second my machine
		//static public var PROXY_URL:String = "http://128.208.6.231:8001";
		static public var PROXY_URL:String = "http://128.95.2.112:8001";
		//		protected var apiURL:String = "http://ec2-184-72-152-11.compute-1.amazonaws.com:80";

		
		public static function getScene(className:Class, game:Game):Scene
		{
			return new className(game);
		}
		
        public function Scene(game:Game)
        {
			m_gameSystem = game;
			this.addEventListener(starling.events.Event.ADDED_TO_STAGE, addedToStage);
			this.addEventListener(starling.events.Event.REMOVED_FROM_STAGE, removedFromStage);
        }
		
		//override to get your scene initialized for viewing
		protected function addedToStage(event:starling.events.Event):void
		{
		}
		
		protected function removedFromStage(event:starling.events.Event):void
		{
			
		}
		
		public function setGame(game:Game):void
		{
			m_gameSystem = game;
		}
	}
}