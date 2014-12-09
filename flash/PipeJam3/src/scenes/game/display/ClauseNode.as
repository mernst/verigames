package scenes.game.display
{
	import constraints.ConstraintClause;
	import constraints.ConstraintSide;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.Dictionary;
	
	import constraints.ConstraintEdge;
	import constraints.ConstraintGraph;
	import constraints.ConstraintVar;
	
	import utils.PropDictionary;
	
	import starling.display.Image;
	import starling.display.Quad;


	public class ClauseNode extends Node
	{
		
		public function ClauseNode(_layoutObject:Object, _id:String, _bb:Rectangle, _graphClause:ConstraintClause, _parentGrid:GridSquare)
		{
			super(_layoutObject, _id, _bb, _graphClause, _parentGrid);
			
			isEditable = false;
			isClause = true;
		}
		
		public function get graphClause():ConstraintClause { return graphConstraintSide as ConstraintClause; }
		
		public override function createSkin():void
		{
			super.createSkin();
			var newSkin:NodeSkin = NodeSkin.getNextSkin();
			if (newSkin == null) return;
			newSkin.setNode(this, true);
			newSkin.draw();
			backgroundSkin = newSkin;
			
			backgroundSkin.x = centerPoint.x - gridOffset.x - 0.5 * backgroundSkin.width;
			backgroundSkin.y = centerPoint.y - gridOffset.y - 0.5 * backgroundSkin.height;
			setDirty(true);
		}
		
		public override function removeSkin():void
		{
			super.removeSkin();
			if (backgroundSkin) backgroundSkin.disableSkin();
		}
		
		public override function scaleSkin(newScaleX:Number, newScaleY:Number):void
		{
			//check to see if we have an error, and if so, scale our error marker at a lower rate
			if(_hasError && backgroundSkin)
			{
				var currentWidth:Number = backgroundSkin.width;
 				backgroundSkin.scaleX = backgroundSkin.scaleY = 1 / World.m_world.active_level.scaleX / World.m_world.active_level.parent.scaleX;
				var newWidth:Number = backgroundSkin.width;
				backgroundSkin.x -= (newWidth-currentWidth)/2;
				backgroundSkin.y -= (newWidth-currentWidth)/2;
			}
		}
		
	}
}