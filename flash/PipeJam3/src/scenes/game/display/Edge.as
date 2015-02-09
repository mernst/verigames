package scenes.game.display
{
	import flash.geom.Point;
	
	import constraints.Constraint;
	
	import starling.display.Quad;
	import starling.display.Sprite;
	import flash.geom.Matrix;
	
	public class Edge
	{
		public var id:String;
		public var graphConstraint:Constraint;
		public var fromNode:Node;
		public var toNode:Node;
		
		public var parentXOffset:Number;
		public var parentYOffset:Number;
		
		public var skin:EdgeSkin;
		public var isHighlighted:Boolean;
		public var isDirty:Boolean;
		
		public var currentGroupDepth:uint = 0;
		
		public static const LINE_THICKNESS:Number = 5;
		
		public function Edge(_constraintId:String, _graphConstraint:Constraint, _fromNode:Node, _toNode:Node)
		{
			id = _constraintId;
			graphConstraint = _graphConstraint;
			fromNode = _fromNode;
			toNode = _toNode;
		}
		
		public function updateEdge(currentHoverNode:Node = null):void
		{
			if(skin && skin.parent)
			{					
				(skin.parent as Sprite).unflatten();
				setLineColor(currentHoverNode);
				//toNode.updateConnector();
				(skin.parent as Sprite).flatten();
				isDirty = false;
			}
		}
		
		//need to keep track of lines
		public function createSkin():void
		{
			if(!skin)
			{
				var fromGroup:String = fromNode.graphConstraintSide.getGroupAt(currentGroupDepth);
				var toGroup:String = toNode.graphConstraintSide.getGroupAt(currentGroupDepth);
				
				var fromGroupNode:Node = (fromGroup == "") ? fromNode : World.m_world.active_level.nodeLayoutObjs[fromGroup] as Node;
				var toGroupNode:Node = (toGroup == "") ? toNode : World.m_world.active_level.nodeLayoutObjs[toGroup] as Node;
				
				if (fromGroupNode == toGroupNode)
				{
					if (skin) skin.removeFromParent(true);
					skin = null;
					isDirty = false;
					return;
				}
				var p1:Point = fromGroupNode.centerPoint;
				var p2:Point = toGroupNode.centerPoint;
				
				//a^2 + b^2 = c^2
				var a:Number = (p2.x - p1.x) * (p2.x - p1.x);
				var b:Number = (p2.y - p1.y) * (p2.y - p1.y);
				var hyp:Number = Math.sqrt(a+b);
				
				//get theta
				//Sin(x) = opp/hyp
				var theta:Number = Math.asin( (p2.y-p1.y) / hyp );  // radians
				
				//draw the quad flat, rotate later
				skin = new EdgeSkin(hyp, Edge.LINE_THICKNESS, this);
				
				setLineColor(null);
				rotateLine(p1, p2, theta);
			}
			isDirty = false;
		}
		
		protected function rotateLine(p1:Point, p2:Point, theta:Number):void
		{
			var dX:Number = p1.x - p2.x;
			var dY:Number = p1.y - p2.y;
			
			skin.pivotX = dX/2;
			skin.pivotY = dY/2;

			var centerDx:Number = 0;
			var centerDy:Number = 0;
			if (dX <= 0 && dY < 0) { // Q4
				// theta = theta
				centerDx = -0.5 * LINE_THICKNESS * Math.sin(theta);
				centerDy = -0.5 * LINE_THICKNESS * Math.cos(theta);
			} else if (dX > 0 && dY <= 0) { // Q3
				if (dY == 0) { // -180
					theta = -Math.PI;
				} else {
					theta = (Math.PI / 2) + ((Math.PI / 2) - theta);
				}
				centerDx = -0.5 * LINE_THICKNESS * Math.sin(theta);
				centerDy = 0.5 * LINE_THICKNESS * Math.cos(theta);
			} else if (dX >= 0 && dY > 0) { // Q2
				theta = -Math.PI - theta;
				centerDx = 0.5 * LINE_THICKNESS * Math.sin(theta);
				centerDy = 0.5 * LINE_THICKNESS * Math.cos(theta);
				if (dX == 0) {
					centerDx = -0.5 * LINE_THICKNESS;
				}
			} else { // Q1
				centerDx = 0.5 * LINE_THICKNESS * Math.sin(theta);
				centerDy = -0.5 * LINE_THICKNESS * Math.cos(theta);
				if (dY == 0) {
					centerDy = -0.5 * LINE_THICKNESS * Math.cos(theta);
				}
			}
			skin.rotation = theta;
			
			skin.x = -skin.bounds.left + Math.min(p1.x, p2.x) + centerDx;
			skin.y = -skin.bounds.top + Math.min(p1.y, p2.y) + centerDy;
		}
		
		private function setLineColor(currentHoverNode:Node):void
		{
			var fromColor:int = NodeSkin.getColor(fromNode);
			var toColor:int = NodeSkin.getColor(toNode, this);
			var fromColorComplement:int = NodeSkin.getComplementColor(fromNode);
			
			if(!fromNode.isNarrow && toNode.isNarrow)
				toColor = 0xff0000;
			
			skin.setColor();
			
			if(isHighlighted)
			{
				if(currentHoverNode)
				{
					var color:int = 0x0000ff;
					if(currentHoverNode == fromNode)
					{
						if(fromNode.isNarrow && toNode.isNarrow)
						{
							color = 0xff0000;
						}
						else if(toColor == 0xff0000)
						{
							color = 0x00ff00;
						}
					}
					else if(currentHoverNode == toNode)
					{
						if(!toNode.isNarrow && !fromNode.isNarrow)
						{
							color = 0xff0000;
						}
						else if(toColor == 0xff0000)
						{
							color = 0x00ff00;
						}
					}
					else if(toColor == 0xff0000)
					{
						color = 0x00ff00;
					}
					
					skin.setHighlight(color);
				}
			}
			else
			{
				skin.removeHighlight();
			}
		}
	}
}