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
		public var x:Number;
		public var y:Number;
		
		public var bb:Rectangle;
		public var centerPoint:Point;
		
		public var isSelected:Boolean = false;
		public var isEditable:Boolean;
		public var isNarrow:Boolean;
		public var isLocked:Boolean = false;
		public var isDirty:Boolean = false;
		
		public var startingSelectionState:Boolean = false;
		
		public var parentGrid:GridSquare;
		
		public var connectedEdgeIds:Vector.<String> = new Vector.<String>();
		public var unused:Boolean = true;
		
		protected var gridOffset:Point;
		
		public var skin:NodeSkin;
		
		public function GridChild(_layoutObject:Object, _id:String, _bb:Rectangle, _parentGrid:GridSquare) 
		{
			layoutObject = _layoutObject;
			id = _id;
			bb = _bb;
			
			parentGrid = _parentGrid;
			gridOffset = new Point(parentGrid.componentXDisplacement, parentGrid.componentYDisplacement);
			
			x = layoutObject["x"];
			y = layoutObject["y"];
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
			if (false && skin) // not working properly yet
			{
				var oldScaleX:Number = skin.scaleX;
				var oldScaleY:Number = skin.scaleY;
				
				skin.scaleX = newScaleX;
				skin.scaleY = newScaleY;
				skin.x -= 0.5 * (newScaleX - oldScaleX) * skin.width;
				skin.y -= 0.5 * (newScaleY - oldScaleY) * skin.height;
			}
		}
		
		public function removeSkin():void
		{
			if (skin) skin.removeFromParent();
			skin = null;
		}
		
		public function select():void
		{
			isSelected = true;
			parentGrid.NumNodesSelected++;
		}
		
		public function unselect():void
		{
			isSelected = false;
			parentGrid.NumNodesSelected--;
		}
		
		public function lock():void
		{
			if(isLocked == false)
			{
				isLocked = true;
				setDirty(false);
			}
		}
		
		public function unlock():void
		{
			if(isLocked == true)
			{
				isLocked = false;
				setDirty(false);
			}
		}
		
		public function setDirty(dirtyEdges:Boolean = false, flashChange:Boolean = false):void
		{
			parentGrid.isDirty = true;
			isDirty = true;
			if(dirtyEdges)
			{
				for each(var gameEdgeID:String in connectedEdgeIds)
				{
					// TODO: Circular dependency
					var edgeObj:Object = World.m_world.active_level.edgeLayoutObjs[gameEdgeID];
					edgeObj.isDirty = true;
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
		
		public function hasError():Boolean
		{
			//implemented by children
			return false;
		}

	}

}