package scenes.game.display 
{
	import constraints.ConstraintGraph;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.Dictionary;
	import utils.PropDictionary;
	import starling.display.Sprite;
	
	public class GridChild 
	{
		public var id:String;
		
		public var layoutObject:Object;
		
		public var bb:Rectangle;
		public var centerPoint:Point;
		
		public var isSelected:Boolean = false;
		public var isEditable:Boolean;
		public var isNarrow:Boolean;
		public var isDirty:Boolean = false;
		
		public var startingSelectionState:Boolean = false;
		
		public var connectedEdgeIds:Vector.<String> = new Vector.<String>();
		public var outgoingEdgeIds:Vector.<String> = new Vector.<String>();
		public var unused:Boolean = true;
		
		public var skin:NodeSkin;
		public var backgroundSkin:NodeSkin;
		public var currentGroupDepth:uint = 0;
		
		public function GridChild(_id:String, _bb:Rectangle) 
		{
			id = _id;
			bb = _bb;
			
			//calculate center point
			var xCenter:Number = bb.x + bb.width * .5;
			var yCenter:Number = bb.y + bb.height * .5;
			centerPoint = new Point(xCenter, yCenter);
			isNarrow = false;
			isEditable = true;
			
			isDirty = true;
		}
		
		public function createSkin():void
		{
			removeSkin();
			// implemented by children
		}
		
		public function scaleSkin(newScaleX:Number, newScaleY:Number):void
		{
			
		}
		
		public function removeSkin():void
		{
			if (skin) skin.removeFromParent();
			if (backgroundSkin) backgroundSkin.removeFromParent();
			skin = null;
			backgroundSkin = null;
		}
		
		public function select():void
		{
			isSelected = true;
		}
		
		public function unselect():void
		{
			isSelected = false;
		}
		
		public function setDirty(dirtyEdges:Boolean = false, flashChange:Boolean = false):void
		{
			isDirty = true;
			if(dirtyEdges)
			{
				for each(var gameEdgeID:String in connectedEdgeIds)
				{
					// TODO: Circular dependency
					var edgeObj:Edge = World.m_world.active_level.edgeLayoutObjs[gameEdgeID];
					if (edgeObj) edgeObj.isDirty = true;
				}
			}
		}
		
		public function updateSelectionAssignment(_isWide:Boolean, levelGraph:ConstraintGraph, setEdgesDirty:Boolean = false):void
		{
			if(isEditable)
			{
				isNarrow = !_isWide;
				isDirty = true;
			}
		}
	}
	
}