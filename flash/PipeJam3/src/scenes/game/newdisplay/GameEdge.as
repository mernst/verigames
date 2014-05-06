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
	
	public class GameEdge extends GameEdgeContainer
	{
		
		private var m_dir:String;
		
		private var m_edgeSegments:Vector.<GameEdgeSegment> = new Vector.<GameEdgeSegment>();
		private var m_edgeJoints:Vector.<GameEdgeJoint> = new Vector.<GameEdgeJoint>();
		
		
		public static const EDGES_OVERLAPPING_JOINTS:Boolean = true;
		public static var WIDE_WIDTH:Number = .3 * Constants.GAME_SCALE;
		public static var NARROW_WIDTH:Number = .1 * Constants.GAME_SCALE;
		public static var ERROR_WIDTH:Number = .6 * Constants.GAME_SCALE;

		protected var m_shape:Quad;
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
			
			var fromComponentCenter:Point = new Point(fromComponent.boundingBox.x+(fromComponent.boundingBox.width/2),
							fromComponent.boundingBox.y+(fromComponent.boundingBox.height/2));
			var toComponentCenter:Point = new Point(toComponent.boundingBox.x+(toComponent.boundingBox.width/2),
							toComponent.boundingBox.y+(toComponent.boundingBox.height/2));
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
			boundingBox = new Rectangle(this.edgeArray[0].x, edgeArray[0].y, edgeArray[edgeArray.length-1].x-edgeArray[0].x, edgeArray[edgeArray.length-1].y-edgeArray[0].y);
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
			if(count > 1000)
				return null;
			
			count++;
			trace(p1.x, p1.y, p2.x, p2.y);
			m_p1 = p1;
			m_p2 = p2;
			
			//a^2 + b^2 = c^2
			var a:Number = (p2.x - p1.x) * (p2.x - p1.x);
			var b:Number = (p2.y - p1.y) * (p2.y - p1.y);
			var hyp:Number = Math.sqrt(a +b);
			
		//	var m_parentshape:Quad = new Quad(hyp, width*1, 0x000000);
			m_shape = new Quad(hyp, width);
			var fromColor:int = (m_fromNode as GameNode2).currentColor;
			var toColor:int = (m_toNode as GameNode2).currentColor;
 
			m_shape.setVertexColor(0, fromColor);
			m_shape.setVertexColor(1, toColor);
			m_shape.setVertexColor(2, fromColor);
			m_shape.setVertexColor(3, toColor);
			
			//stage.addChild ( q );
	//		m_parentshape.x = p1.x;
	//		m_parentshape.y = p1.y;
			m_shape.x = p1.x + 1;
			m_shape.y = p1.y;
			
			//get theta
			//Sin(x) = opp/hyp
			var theta:Number; // radians
			
			theta = Math.asin( (p2.y-p1.y) / hyp );  // radians
			
			// degrees:90 radians:1.5707963267948966
			// degrees:180 radians:3.141592653589793
			
			var dX:Number = p1.x - p2.x
			var dY:Number = p1.y - p2.y
			
			if(dX>0 && dY<0) // Q2
				theta = (Math.PI/2) + ((Math.PI/2) - theta);
			else if(dX>0 && dY>0) // Q3
				theta = -Math.PI - theta;
			
		//	m_parentshape.rotation = theta;
		//	addChild(m_parentshape);
			m_shape.rotation = theta;
			addChild(m_shape);
			return m_shape;
		}
		
		override public function onWidgetChange(widgetChanged:GameNode = null):void
		{
			
		}
	}
}