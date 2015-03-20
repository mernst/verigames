package scenes.game.display
{
	import flash.geom.Rectangle;
	
	import constraints.ConstraintClause;
	
	public class ClauseNode extends Node
	{
		
		private var _hasError:Boolean = false;
		private var _hadError:Boolean = false;
		
		public function ClauseNode(_id:String, _bb:Rectangle, _graphClause:ConstraintClause)
		{
			super(_id, _bb, _graphClause);
			
			isEditable = false;
			isClause = true;
		}
		
		public function get graphClause():ConstraintClause { return graphConstraintSide as ConstraintClause; }
		
		public function hasError():Boolean
		{
			return _hasError;
		}
		
		public function get hadError():Boolean
		{
			return _hadError;
		}
		
		public function set hadError(_val:Boolean):void
		{
			_hadError = _val;
		}
		
		public function addError(_error:Boolean):void
		{
			if(isClause && _hasError != _error)
			{
				_hasError = _error;
				setDirty(true);
			}			
		}
		
		public override function createSkin():void
		{
			super.createSkin();
			var newSkin:NodeSkin = NodeSkin.getNextSkin();
			if (newSkin == null) return;
			newSkin.setNode(this, true);
			newSkin.draw();
			backgroundSkin = newSkin;
			backgroundSkin.x = centerPoint.x - 0.5 * backgroundSkin.width;
			backgroundSkin.y = centerPoint.y - 0.5 * backgroundSkin.height;
			
			setDirty(true);
		}
		
	}
}