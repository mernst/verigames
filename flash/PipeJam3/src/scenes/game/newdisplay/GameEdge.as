package scenes.game.newdisplay
{
	import flash.errors.ScriptTimeoutError;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import constraints.Constraint;
	import constraints.ConstraintGraph;
	import constraints.ConstraintScoringConfig;
	
	import display.NineSliceBatch;
	import display.TextBubble;
	
	import events.ConflictChangeEvent;
	import events.EdgeContainerEvent;
	import events.ToolTipEvent;
	
	import graph.Edge;
	import graph.Port;
	import graph.PropDictionary;
	
	import networking.Achievements;
	
	import particle.ErrorParticleSystem;
	
	import scenes.game.PipeJamGameScene;
	import scenes.game.display.GameComponent;
	import scenes.game.display.GameEdgeContainer;
	import scenes.game.display.GameEdgeJoint;
	import scenes.game.display.GameEdgeSegment;
	import scenes.game.display.GameNode;
	
	import starling.display.DisplayObject;
	import starling.display.DisplayObjectContainer;
	import starling.display.Quad;
	import starling.display.Sprite;
	import starling.events.Event;
	import starling.events.Touch;
	import starling.events.TouchEvent;
	import starling.events.TouchPhase;
	import starling.text.TextField;
	
	public class GameEdge extends GameEdgeContainer
	{
		
		private var m_dir:String;
		
		private var m_edgeSegments:Vector.<GameEdgeSegment> = new Vector.<GameEdgeSegment>();
		private var m_edgeJoints:Vector.<GameEdgeJoint> = new Vector.<GameEdgeJoint>();
		
		
		public static const EDGES_OVERLAPPING_JOINTS:Boolean = true;
		public static var WIDE_WIDTH:Number = .3 * Constants.GAME_SCALE;
		public static var NARROW_WIDTH:Number = .1 * Constants.GAME_SCALE;
		public static var ERROR_WIDTH:Number = .6 * Constants.GAME_SCALE;

		public var m_shape:Quad;
		protected var m_p1:Point;
		protected var m_p2:Point;
		
		protected static var count:int = 0;
		
		public function GameEdge(_id:String, _edgeArray:Array, 
										  fromComponent:GameNode2, toComponent:GameNode2, 
										  _graphConstraint:Constraint, _draggable:Boolean,
										  _hideSegments:Boolean = false)
		{
			super(_id,_edgeArray, 
				fromComponent, toComponent, 
				_graphConstraint, _draggable,
				_hideSegments);
			draggable = _draggable;
			edgeArray = _edgeArray;
			m_fromNode = fromComponent;
			m_toNode = toComponent;
			graphConstraint = _graphConstraint;
			hideSegments = _hideSegments;
			m_isEditable = fromComponent.isEditable();
			m_isWide = fromComponent.isWide();
			
			fromComponent.setOutgoingEdge(this); // this also sets m_fromPortID
			toComponent.setIncomingEdge(this); // this also sets m_toPortID
			
			var fromComponentCenter:Point = new Point(fromComponent.boundingBox.x,
							fromComponent.boundingBox.y);
			var toComponentCenter:Point = new Point(toComponent.boundingBox.x,
							toComponent.boundingBox.y);
			drawLine(fromComponentCenter, toComponentCenter, 1, 0xff0000);
			updateBoundingBox();
		}
		
		private function onAddedToStage(evt:Event):void
		{
			if(!initialized)
			{
				initialized = true;

				addEventListener(Event.ENTER_FRAME, onEnterFrame);
			}
		}
		
		protected function updateBoundingBox():void
		{
			x = Math.min(m_p1.x, m_p2.x);
			y = Math.min(m_p1.y, m_p2.y);
			var width:Number = Math.abs(m_p2.x - m_p1.x);
			var height:Number = Math.abs(m_p2.y - m_p1.y);
			boundingBox = new Rectangle(x, y, width, height);
		}
		
		override public function draw():void
		{
			var fromColor:int = (m_fromNode as GameNode2).currentColor;
			var toColor:int = (m_toNode as GameNode2).currentColor;
			
			if(m_shape)
			{
				m_shape.setVertexColor(0, fromColor);
				m_shape.setVertexColor(1, toColor);
				m_shape.setVertexColor(2, fromColor);
				m_shape.setVertexColor(3, toColor);
			}
		}
		
		public function drawLine(p1:Point, p2:Point, width:Number=1, color:uint=0x000000):Quad
		{
			m_p1 = p1;
			m_p2 = p2;
			//a^2 + b^2 = c^2
			var a:Number = (p2.x - p1.x) * (p2.x - p1.x);
			var b:Number = (p2.y - p1.y) * (p2.y - p1.y);
			var hyp:Number = Math.sqrt(a +b);
			
			m_shape = new Quad(hyp, width);
			var fromColor:int = (m_fromNode as GameNode2).currentColor;
			var toColor:int = (m_toNode as GameNode2).currentColor;
			
			m_shape.setVertexColor(0, fromColor);
			m_shape.setVertexColor(1, toColor);
			m_shape.setVertexColor(2, fromColor);
			m_shape.setVertexColor(3, toColor);
			
			
			//get theta
			//Sin(x) = opp/hyp
			var theta:Number; // radians
			
			theta = Math.asin( (p2.y-p1.y) / hyp );  // radians
			
			// degrees:90 radians:1.5707963267948966
			// degrees:180 radians:3.141592653589793
			
			var dX:Number = p1.x - p2.x;
			var dY:Number = p1.y - p2.y;
			
			if(dX>0 && dY<0) // Q2
				theta = (Math.PI/2) + ((Math.PI/2) - theta);
			else if(dX>0 && dY>0) // Q3
				theta = -Math.PI - theta;
			
		
			m_shape.rotation = theta;
			m_shape.x = -m_shape.bounds.left;
			m_shape.y = -m_shape.bounds.top;
			
//			var w:Number = Math.abs(p1.x - p2.x);
//			var h:Number = Math.abs(p1.y - p2.y);
//			var q:Quad = new Quad(w, h, 0xff0000);
//			
//			addChild(q);
			addChild(m_shape);
			
			if(p1.x < p2.x)
				x = p1.x;
			else
				x = p2.x;
			if(p1.y < p2.y)
				y = p1.y;
			else
				y = p2.y;
			return m_shape;
		}
		
		override public function setupPoints(newEdgeArray:Array = null):void
		{
			if(newEdgeArray) edgeArray = newEdgeArray;
			
			m_startPoint = edgeArray[0];
			m_endPoint = edgeArray[edgeArray.length-1];
			
			var minXedge:Number = Math.min(m_startPoint.x, m_endPoint.x);
			var minYedge:Number = Math.min(m_startPoint.y, m_endPoint.y);
			
			this.x = minXedge;
			this.y = minYedge;
		}
		
		override public function onWidgetChange(widgetChanged:GameNode = null):void
		{
			
		}
		
		override public function updateInnerSegments():void
		{
		}
	}
}