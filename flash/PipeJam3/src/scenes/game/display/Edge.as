package scenes.game.display
{
	import flash.geom.Point;
	import constraints.Constraint;
	import starling.display.Sprite;
	
	public class Edge
	{
		public var id:String;
		protected var graphConstraint:Constraint;
		public var fromNode:Node;
		public var toNode:Node;
		
		public var parentXOffset:Number;
		public var parentYOffset:Number;
		
		public var edgeSkin:EdgeSkin;
		
		public var isHighlighted:Boolean;
		public var isDirty:Boolean;
		
		public static const LINE_THICKNESS:Number = 5;
		
		public function Edge(_constraintId:String, _graphConstraint:Constraint, _fromNode:Node, _toNode:Node)
		{
			id = _constraintId;
			graphConstraint = _graphConstraint;
			fromNode = _fromNode;
			toNode = _toNode;
		}
		
		public function createEdgeSkin():EdgeSkin
		{
			if(!edgeSkin)
			{					
				createSkin();
			}
			isDirty = false;
			
			return edgeSkin;
		}
		
		public function updateEdge(currentNode:Node):void
		{
			if(edgeSkin && edgeSkin.parent)
			{					
				(edgeSkin.parent as Sprite).unflatten();
				setLineColor(currentNode);
				(edgeSkin.parent as Sprite).flatten();
				isDirty = false;
			}
		}
		
		//need to keep track of lines
		public function createSkin():void
		{
			var p1:Point = fromNode.centerPoint;
			var p2:Point = toNode.centerPoint;
			//a^2 + b^2 = c^2
			var a:Number = (p2.x - p1.x) * (p2.x - p1.x);
			var b:Number = (p2.y - p1.y) * (p2.y - p1.y);
			var hyp:Number = Math.sqrt(a+b);
			
			//draw the quad flat, rotate later
			edgeSkin = new EdgeSkin(hyp, Edge.LINE_THICKNESS);
			setLineColor(null);
			var otherEdgeId:String = toNode.id + " -> " + fromNode.id;
			var otherEdgeObj:Object = World.m_world.active_level.edgeLayoutObjs[otherEdgeId];
			rotateLine(p1, p2, hyp, otherEdgeObj);
		}
		
		protected function rotateLine(p1:Point, p2:Point, hyp:Number, offsetDoubleLine:Boolean):void
		{
			//get theta
			//Sin(x) = opp/hyp
			var theta:Number = Math.asin( (p2.y-p1.y) / hyp );  // radians
			
			var dX:Number = p1.x - p2.x;
			var dY:Number = p1.y - p2.y;
			
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
				centerDy = 0.5 * LINE_THICKNESS * Math.cos(theta);
			} else if (dX >= 0 && dY > 0) { // Q2
				theta = -Math.PI - theta;
				if (dX == 0) {
					centerDx = -0.5 * LINE_THICKNESS;
				}
			} else { // Q1
				centerDx = 0.5 * LINE_THICKNESS * Math.sin(theta);
				if (dY == 0) {
					centerDy = -0.5 * LINE_THICKNESS * Math.cos(theta);
				}
			}
			edgeSkin.rotation = theta;
			
			if (offsetDoubleLine) {
				centerDx += 1.5 * Math.sin(theta);
				centerDy += 1.5 * Math.cos(theta);;
			}
			
			edgeSkin.x = -edgeSkin.bounds.left + Math.min(p1.x, p2.x)  + centerDx;
			edgeSkin.y = -edgeSkin.bounds.top + Math.min(p1.y, p2.y)  + centerDy;
			
			//trace(centerDx, centerDy, theta, dX, dY, " <-- Line made");
		}
		
		private function setLineColor(currentHoverNode:Node):void
		{
			var fromColor:int = NodeSkin.getColor(fromNode);
			var toColor:int = NodeSkin.getColor(toNode);
			var fromColorComplement:int = NodeSkin.getComplementColor(fromNode);
			
			if(!fromNode.isNarrow && toNode.isNarrow)
				toColor = 0xff0000;
			
			edgeSkin.setColor(toColor, fromColor, fromColorComplement);
			
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
					
					edgeSkin.setHighlight(color);
				}
			}
			else
			{
				edgeSkin.removeHighlight();
			}
		}
	}
}