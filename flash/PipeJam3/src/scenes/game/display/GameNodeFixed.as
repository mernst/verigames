package scenes.game.display 
{
	
	public class GameNodeFixed extends GameNode 
	{
		public function GameNodeFixed(_layoutXML:XML, _draggable:Boolean, _isWide:Boolean) 
		{
			super(_layoutXML, _draggable);
			m_isEditable = false;
			m_isWide = _isWide;
		}
		
		override public function isWide():Boolean
		{
			return m_isWide;
		}
	}

}