package scenes.game.display 
{
	
	public class GameNodeFixed extends GameNode 
	{
		
		private var m_isStartingNode:Boolean;
		
		public function GameNodeFixed(_layoutXML:XML, _isWide:Boolean, _isStartingNode:Boolean) 
		{
			super(_layoutXML);
			m_editable = false;
			m_isWide = _isWide;
			m_isStartingNode = _isStartingNode;
		}
		
		override public function isWide():Boolean
		{
			return m_isWide;
		}
		
		override public function isStartingNode():Boolean
		{
			return m_isStartingNode;
		}
	}

}