package scenes.game.display
{
	import flash.geom.Point;
	
	import scenes.BaseComponent;
	
	import starling.display.Quad;
	import starling.display.Shape;
	import starling.display.materials.StandardMaterial;
	import starling.events.Event;
	import starling.events.Touch;
	import starling.events.TouchEvent;
	import starling.events.TouchPhase;
	import starling.text.TextField;

	public class GameEdgeJoint extends GameComponent
	{		
		private var m_shape:Shape;
		public var m_showError:Boolean = false;
		private var m_isLastJoint:Boolean;
		private var m_isConnectionJoint:Boolean;
		protected var m_startPt:Point;
		protected var m_endPt:Point;
		
		protected var m_parentEdge:GameEdgeContainer;
		public var m_closestWall:int = 0;

		public var count:int = 0;
		private var m_quad:Quad;
		
		
		public function GameEdgeJoint(parentEdge:GameEdgeContainer, fromComponent:GameComponent, toComponent:GameComponent, isLastJoint:Boolean = false, isConnectionJoint:Boolean = false)
		{
			super();
			
			m_parentEdge = parentEdge;
			m_fromComponent = fromComponent;
			m_toComponent = toComponent;
			m_isLastJoint = isLastJoint;
			m_isConnectionJoint = isConnectionJoint;
			m_isDirty = true;
			
			if(fromComponent is GameNode)
				m_closestWall = GameEdgeContainer.RIGHT_WALL;
			else if(toComponent is GameNode)
				m_closestWall = GameEdgeContainer.LEFT_WALL;
			
			addEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
			addEventListener(Event.REMOVED_FROM_STAGE, onRemovedFromStage);	
		}
		
		public function onAddedToStage(event:starling.events.Event):void
		{
			
			addEventListener(Event.ENTER_FRAME, onEnterFrame);
			addEventListener(TouchEvent.TOUCH, onTouch);
			m_isDirty = true;
			
		}
		
		private function onRemovedFromStage():void
		{
			this.removeChildren(0, -1, true);
			if(m_shape)
			{
				m_shape.removeChildren(0, -1, true);
				m_shape.dispose();
			}
			removeEventListener(Event.ENTER_FRAME, onEnterFrame);
			removeEventListener(TouchEvent.TOUCH, onTouch);
		}
		
		private var isMoving:Boolean = false;
		private var isHover:Boolean = false;
		private function onTouch(event:TouchEvent):void
		{
			var touches:Vector.<Touch> = event.touches;
			if(event.getTouches(this, TouchPhase.ENDED).length)
			{
				if (touches.length == 1)
				{
					m_isDirty = true;
					isMoving = false;
					isHover = false;
				}
			}
			
			if(event.getTouches(this, TouchPhase.HOVER).length)
			{
				if (touches.length == 1 && m_isConnectionJoint && event.shiftKey)
				{
					m_isDirty = true;
					isHover = true;
				}
			}
			else
			{
				m_isDirty = true;
				isMoving = false;
				isHover = false;
			}
			
			if(event.getTouches(this, TouchPhase.MOVED).length){
				if (touches.length == 1)
				{
					if(!isMoving)
						isMoving = true;
					
					var currentMoveLocation:Point = touches[0].getLocation(this);
					var previousLocation:Point = touches[0].getPreviousLocation(this);

					if(m_isConnectionJoint)
					{
						//pin to edge of GameNode
						var containerComponent:GameComponent;
						if(m_fromComponent is GameNode)
						 containerComponent = m_fromComponent;
						else 
							containerComponent = m_toComponent;
						
						var startPt:Point = new Point(x,y);
						
						//find difference in mouse movement, and apply to x,y
						var differencePt:Point = currentMoveLocation.subtract(previousLocation);						
						var updatedXY:Point = startPt.add(differencePt);
						var jointStartGlobalPt:Point = parent.localToGlobal(startPt);
						var jointUpdatedGlobalPt:Point = localToGlobal(currentMoveLocation);
						//find global coordinates of container, subtracting off joints height and width
						var containerPt:Point = new Point(containerComponent.x+0.5*width,containerComponent.y+0.5*height);
						var containerGlobalPt:Point = containerComponent.parent.localToGlobal(containerPt);						
						var boundsGlobalPt:Point = containerComponent.parent.localToGlobal(new Point(containerComponent.x + containerComponent.width-0.5*width, containerComponent.y + containerComponent.height-0.5*height));
						
						//make sure we are in bounds
						if(jointUpdatedGlobalPt.x < containerGlobalPt.x)
						{
							jointUpdatedGlobalPt.x = containerGlobalPt.x;
						}
						else if(jointUpdatedGlobalPt.x > boundsGlobalPt.x)
						{
							jointUpdatedGlobalPt.x = boundsGlobalPt.x;
						}
						if(jointUpdatedGlobalPt.y < containerGlobalPt.y)
						{
							jointUpdatedGlobalPt.y = containerGlobalPt.y;
						}
						else if(jointUpdatedGlobalPt.y > boundsGlobalPt.y)
						{
							jointUpdatedGlobalPt.y = boundsGlobalPt.y;
						}
						
						var isOutgoingEdge:Boolean = m_fromComponent is GameNode ? true : false;
						
						//glue to same rim of container
						if(!isOutgoingEdge)
						{
							//left wall closest
							jointUpdatedGlobalPt.x = containerGlobalPt.x;
							m_closestWall = GameEdgeContainer.LEFT_WALL;
						}
						else
						{
							//right wall closest
							jointUpdatedGlobalPt.x = boundsGlobalPt.x;
							m_closestWall = GameEdgeContainer.RIGHT_WALL;
						}
						
						var finalPt:Point = parent.globalToLocal(jointUpdatedGlobalPt);
						var updatePoint:Point = finalPt.subtract(startPt);		
						
						m_parentEdge.rubberBandEdge(updatePoint, isOutgoingEdge);
					}
					
				}
			}
		}
		
		public function draw():void
		{
			var lineSize:Number = isWide() ? GameEdgeContainer.WIDE_WIDTH : GameEdgeContainer.NARROW_WIDTH;
			var color:int;
			color = getColor();
		
			removeChildren();
			if(m_shape)
			{
				m_shape.removeChildren(0, -1, true);
				m_shape.dispose();
			}

			if(isHover)
			{
				m_quad = new Quad(lineSize+1, lineSize+1, 0xeeeeee);
				m_quad.x = -lineSize;
				m_quad.y = -lineSize;
				addChild(m_quad);
			}
			m_quad = new Quad(lineSize, lineSize, color);
			m_quad.x = -lineSize/2;
			m_quad.y = -lineSize/2;
			addChild(m_quad);
			

//			var number:String = ""+count;
//			var txt:TextField = new TextField(10, 10, number, "Veranda", 6,0x00ff00); 
//			txt.y = 1;
//			txt.x = 1;
//			m_shape.addChild(txt);
//			addChild(m_shape);
		}
		
		override public function isWide():Boolean
		{
	//		if(!m_isLastJoint)
				return m_toComponent.isWide();
	//		else
	//			return m_fromComponent.isWide();
		}
		
		override public function getColor():int
		{
			if(m_isLastJoint && m_showError)
				return 0xff0000;
			else
				return 0x00ff00;
				
		}
		
		public function onEnterFrame(event:Event):void
		{
			if(m_isDirty)
			{
				draw();
				m_isDirty = false;
			}
		}
	}
}