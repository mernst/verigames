package scenes.game.display
{
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import scenes.game.display.GameComponent;
	import scenes.game.display.GameEdgeContainer;
	import scenes.game.display.GameJointNode;
	import scenes.game.display.GameNodeBase;
	import scenes.game.display.Level;
	
	import starling.display.DisplayObject;

	/* a class to find nodes in a view rect */
	public class VisibleNodeManager
	{
		protected var m_nodeArray:Array;
		protected var m_edgeArray:Array;
		protected var m_visibleNodeList:Array;
		protected var m_visibleEdgeList:Array;
		protected var m_currentViewRect:Rectangle;
		protected var m_container:Level;
		
		protected var COLLECTION_SIZE:int = 1;
		
		public function VisibleNodeManager(_size:int, _container:Level)
		{
			m_nodeArray = new Array(int(_size/COLLECTION_SIZE));
			m_edgeArray = new Array(int(_size/COLLECTION_SIZE));
			m_container = _container;

		}
		
		public function addNode(node:GameNodeBase):void
		{
		//	node.visible = false;
			//push 4 corners
			node.storedXPosition = int(node.x);
			node.storedYPosition = int(node.y);
			addNodeAtPoint(node, node.storedXPosition, node.storedYPosition);
			addNodeAtPoint(node, node.storedXPosition, node.storedYPosition+node.height);
			addNodeAtPoint(node, node.storedXPosition+node.width, node.storedYPosition);
			addNodeAtPoint(node, node.storedXPosition+node.width, node.storedYPosition+node.height);
			m_container.addChild(node);
			node.visible = true;
		}
		
		public function updateNode(node:GameNodeBase):void
		{
			//remove old position and place in new
			removeNodeAtPoint(node, node.storedXPosition, node.storedYPosition, 0);
			removeNodeAtPoint(node, node.storedXPosition, node.storedYPosition+node.height,1);
			removeNodeAtPoint(node, node.storedXPosition+node.width, node.storedYPosition,2);
			removeNodeAtPoint(node, node.storedXPosition+node.width, node.storedYPosition+node.height,3);
			
			//push 4 corners
			node.storedXPosition = int(node.x);
			node.storedYPosition = int(node.y);
			addNodeAtPoint(node, node.x, node.y);
			addNodeAtPoint(node, node.x, node.y+node.height);
			addNodeAtPoint(node, node.x+node.width, node.y);
			addNodeAtPoint(node, node.x+node.width, node.y+node.height);
		}
		
		public function addEdge(edge:DisplayObject):void
		{
			m_edgeArray.push(edge);
			edge.visible = false;
			m_container.addGameComponentToStage(edge as GameComponent);
		}
		
		protected function addNodeAtPoint(node:GameNodeBase, xVal:int, yVal:int):void
		{
			var arr:Array;
			if((m_nodeArray[xVal]) == undefined)
			{
				arr = new Array;
				m_nodeArray[xVal] = arr;
			}
			if((m_nodeArray[xVal][yVal]) == undefined)
			{
				arr = new Array;
				m_nodeArray[xVal][yVal] = arr;
			}
			if(arr)
				arr.push(node);
		}
		
		protected function removeNodeAtPoint(node:DisplayObject, xVal:Number, yVal:Number, vertexNum:int):void
		{
			if(!m_nodeArray || !m_nodeArray[int(xVal/COLLECTION_SIZE)] || !m_nodeArray[int(xVal/COLLECTION_SIZE)][int(yVal/COLLECTION_SIZE)])
			{
				trace("Wrong!", vertexNum);
				return;
			}
			trace("Right", vertexNum);
			var arr:Array = m_nodeArray[int(xVal/COLLECTION_SIZE)][int(yVal/COLLECTION_SIZE)];
			if(arr)
			{
				var index:int = arr.indexOf(node);
				arr.splice(index, 0);
			}
		}
		
		//check all viewpoint integral points to see if it contains a node, if so add it to the list
		//then visit all nodes in list and add their edges
		public function updateVisibleList(newViewRect:Rectangle):void
		{			
			//should compare newViewRect with currentViewRect, find delta offsets and just look at those
			var component:DisplayObject;
			if(m_visibleEdgeList)
				for each(component in m_visibleEdgeList)
					component.visible = false;
				
			m_visibleNodeList = new Array;
			m_visibleEdgeList = new Array;
			var width:int = int(newViewRect.x) + int(newViewRect.width);
			var height:int = int(newViewRect.y) + int(newViewRect.height);
			for(var xVal:int = int(newViewRect.x); xVal<width; xVal++)
			{
				for(var yVal:int=int(newViewRect.y); yVal<height;yVal++)
				{
					if(m_nodeArray[xVal] && m_nodeArray[xVal][yVal] && m_nodeArray[xVal][yVal] is Array)
					{
						for each(var elem:DisplayObject in m_nodeArray[xVal][yVal])
						{
							if(m_visibleNodeList.indexOf(elem) == -1)
							{
								m_visibleNodeList.push(elem);
							}
						}
					}
				}
			}
			
			for each(component in m_visibleNodeList)
			{
				//update all edge connections to be true also, and add to the visibleList
				if(component is GameNodeBase)
				{
					var node:GameNodeBase = component as GameNodeBase;
					for each(var iedge:GameEdgeContainer in node.m_incomingEdges)
					{
						iedge.visible = true;
						m_visibleEdgeList.push(iedge);
						iedge.m_isDirty = true;
				//		m_container.addGameComponentToStage(iedge as GameComponent);
						iedge.flatten();
					}
					for each(var oedge:GameEdgeContainer in node.m_outgoingEdges)
					{
						oedge.visible = true;
						m_visibleEdgeList.push(oedge);
						oedge.m_isDirty = true;
		//				m_container.addGameComponentToStage(oedge as GameComponent);
						oedge.flatten();
					}
				}
			}
			trace("visible ",m_visibleNodeList.length, m_visibleEdgeList.length);
		}
	}
}