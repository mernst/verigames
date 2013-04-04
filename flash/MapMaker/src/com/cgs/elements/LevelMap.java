package com.cgs.elements;

import java.text.SimpleDateFormat;
import java.util.Calendar;
import java.util.Collections;
import java.util.Comparator;

import org.newdawn.slick.util.pathfinding.*;
import org.newdawn.slick.util.pathfinding.heuristics.*;

public class LevelMap implements TileBasedMap
{
	
	NodeElement level;
	int height;
	int width;
	
	int numRows;
	int numColumns;
	int[] maxColumnDimensions;
	int[] maxRowDimensions;
	int[] startingRowYValue;
	int[] startingColumnXValue;
	int internalGridSize = 2;
	int gridSize = 10;
	public int xMultiplier = 5;
	public int yMultiplier = 5;

	//for laying out clusters initially
	private int[][] map;
	/** Indicator if a given tile has been visited during the search */
	private boolean[][] visited;
	
	private AStarPathFinder finder;

	
	/**
	 * Create a new test map with some default configuration
	 */
	public LevelMap(NodeElement _level) {
		
		level = _level;
	}
	
	public void allocateMap()
	{
		map = new int[width][height];	
	}
	
	public void cleanUp()
	{
		map = null;
		level = null;
	}

	//read in and set height and width accordingly - fix dot to generate the right size nodes??!!
	public void sizeClusters()
	{
		//set sizes based on # of connections
		for(int nodeIndex = 0; nodeIndex < level.nodes.size(); nodeIndex++)
		{
			NodeElement cluster = level.nodes.get(nodeIndex);
				
			//assign heights and widths
			if(cluster.incomingPorts.size() > cluster.outgoingPorts.size())
				cluster.boundingBox.height = cluster.incomingPorts.size() * internalGridSize;
			else if(cluster.outgoingPorts.size() > 0)
				cluster.boundingBox.height = cluster.outgoingPorts.size() * internalGridSize;
			else
				cluster.boundingBox.height = internalGridSize;
			
			cluster.boundingBox.width = internalGridSize;
		}
	}
	
	//organize clusters into  ranks and columns
	public void assignColumnAndRank()
	{
		//set column and rank indexes
		Collections.sort(level.nodes, new yBlockComparator());
		Collections.sort(level.nodes, new xBlockComparator());
		
		int currentColumn = 0;
		int currentRow = 0;
		
		//figure out largest rank width, and store value
		int currentRankX = 0;
		for(int i = 0; i<level.nodes.size(); i++)
		{
			currentRow++;
			NodeElement cluster = level.nodes.get(i);
			
			if(currentRankX == 0)
			{
				currentRankX = cluster.boundingBox.x;
				currentRow = 0;
			}
			
			if(cluster.boundingBox.x > currentRankX)
			{
				currentRankX = cluster.boundingBox.x;
				currentRow = 0;
				currentColumn++;
			}			
			if(currentRow+1 > numRows)
				numRows = currentRow+1;
			
			cluster.row = currentRow;
			cluster.column = currentColumn;
		}
		maxRowDimensions = new int[numRows];
		numColumns = currentColumn+1;
		maxColumnDimensions = new int[numColumns];
		
	}
	
	//move nodes up or down to try to get them facing a direct connection
	public void adjustRanks()
	{
		//sort by column and rank indexes
		Collections.sort(level.nodes, new rowComparator());
		Collections.sort(level.nodes, new columnComparator());

		NodeElement[][] nodeArray = new NodeElement[numRows][numColumns];
		for(int i = 0; i<level.nodes.size(); i++)
		{
			NodeElement cluster = level.nodes.get(i);
			nodeArray[cluster.row][cluster.column] = cluster;
		}
		
		for(int i = 0; i<level.nodes.size(); i++)
		{
			NodeElement cluster = level.nodes.get(i);
			
			if(cluster.column > 0)
			{	
				//shorten edges by having them in the same row as one they connect to, if possible
				//check only the first port, live with the others where ever they connect
				if(cluster.incomingPorts.size() > 0)
				{
					EdgeElement edge = cluster.incomingPorts.get(0).connectedEdge;
					if(edge.incomingPorts.size() > 0)
					{
						NodeElement node = edge.incomingPorts.get(0).connectedNode;
						int possibleRow = node.row;
						//try to place it in exact right spot, and if that doesn't work, back out toward original position
						while(possibleRow > cluster.row && nodeArray[possibleRow][cluster.column] != null)
							possibleRow--;
						
						if(possibleRow != cluster.row && nodeArray[possibleRow][cluster.column] == null)
						{
							//remove, update, replace
							nodeArray[cluster.row][cluster.column] = null;
							cluster.row = possibleRow;
							nodeArray[possibleRow][cluster.column] = cluster;

						}
					}
				}
			}
		}
		
		//do the same for the first column, just for neatness
		for(int i = 0; i<level.nodes.size(); i++)
		{
			NodeElement cluster = level.nodes.get(i);
			
			if(cluster.column == 0)
			{	
				//shorten edges by having them in the same row as one they connect to, if possible
				//check only the first port, live with the others where ever they connect
				if(cluster.outgoingPorts.size() > 0)
				{
					EdgeElement edge = cluster.outgoingPorts.get(0).connectedEdge;
					if(edge.outgoingPorts.size() > 0)
					{
						NodeElement node = edge.outgoingPorts.get(0).connectedNode;
						int possibleRow = node.row;
						//try to place it in exact right spot, and if that doesn't work, back out toward original position
						while(possibleRow > cluster.row && nodeArray[possibleRow][cluster.column] != null)
							possibleRow--;
						
						if(possibleRow != cluster.row && nodeArray[possibleRow][cluster.column] == null)
						{
							//remove, update, replace
							nodeArray[cluster.row][cluster.column] = null;
							cluster.row = possibleRow;
							nodeArray[possibleRow][cluster.column] = cluster;

						}
					}
				}
			}
		}
	}

	//adjust ports to try to get higher ports connected to higher nodes
	public void adjustConnections()
	{		
		for(int i = 0; i<level.nodes.size(); i++)
		{
			NodeElement cluster = level.nodes.get(i);
			
			//trace backward connections. Check to make sure higher row has higher connection else switch.
			if(cluster.incomingPorts.size() > 1)
			{
				//organize connections by comparing starting node's rank with neighbor
				//loop through those above you, remember the currently highest rank, and switch with that at the end
				for(int j = 0; j<cluster.incomingPorts.size(); j++)
				{
					EdgeElement currentEdge = cluster.incomingPorts.get(j).connectedEdge;
					int currentHighestRow = currentEdge.incomingPorts.get(0).connectedNode.row;
					int highestEdgePosition = 0;
					for(int k = j+1; k<cluster.incomingPorts.size(); k++)
					{							
						EdgeElement newEdge = cluster.incomingPorts.get(k).connectedEdge;
						if(currentEdge != null && newEdge != null)
						{
								int newEdgeRow = newEdge.incomingPorts.get(0).connectedNode.row;
							
							if(currentHighestRow > newEdgeRow)
							{
								currentHighestRow = newEdgeRow;
								highestEdgePosition = k;
							}
						}
					}
					if(highestEdgePosition != 0)
					{
						PortInfo jPort = cluster.incomingPorts.get(j);
						PortInfo kPort = cluster.incomingPorts.get(highestEdgePosition);
						cluster.incomingPorts.set(j, kPort);
						cluster.incomingPorts.set(highestEdgePosition, jPort);
					}
				}
			}
			
			//trace forward connections. Check to make sure higher row has higher connection else switch.
			if(cluster.outgoingPorts.size() > 1)
			{
				//organize connections by comparing starting node's rank with neighbor
				//loop through those above you, remember the currently highest rank, and switch with that at the end
				for(int j = 0; j<cluster.outgoingPorts.size(); j++)
				{
					EdgeElement currentEdge = cluster.outgoingPorts.get(j).connectedEdge;
					int currentHighestRow = currentEdge.outgoingPorts.get(0).connectedNode.row;
					int highestEdgePosition = 0;
					for(int k = j+1; k<cluster.outgoingPorts.size(); k++)
					{							
						EdgeElement newEdge = cluster.outgoingPorts.get(k).connectedEdge;
						if(currentEdge != null && newEdge != null)
						{
								int newEdgeRow = newEdge.outgoingPorts.get(0).connectedNode.row;
							
							if(currentHighestRow > newEdgeRow)
							{
								currentHighestRow = newEdgeRow;
								highestEdgePosition = k;
							}
						}
					}
					if(highestEdgePosition != 0)
					{
						PortInfo jPort = cluster.outgoingPorts.get(j);
						PortInfo kPort = cluster.outgoingPorts.get(highestEdgePosition);
						cluster.outgoingPorts.set(j, kPort);
						cluster.outgoingPorts.set(highestEdgePosition, jPort);
					}
				}
			}
		}
	}
	
	//invert the rows so I get higher rows first
	public class rowComparator implements Comparator<NodeElement>{
	    public int compare(NodeElement object1, NodeElement object2) {
	    	return Double.compare(object2.row, object1.row);
	    }
	}
	
	public class columnComparator implements Comparator<NodeElement>{
	    public int compare(NodeElement object1, NodeElement object2) {
	    	return Double.compare(object1.column, object2.column);
	    }
	}
	
	//find, and then total each column and row max dimensions, to use for layout
	//currently assume width = 10 everywhere, and set them accordingly
	public void setMapDimensions()
	{
		startingRowYValue = new int[numRows];
		startingColumnXValue = new int[numColumns];
		System.out.println("max row and column " + numRows + " " + numColumns);
		for(int i = 0; i<level.nodes.size(); i++)
		{
			NodeElement cluster = level.nodes.get(i);
			if(maxRowDimensions[cluster.row] < cluster.boundingBox.height)
				maxRowDimensions[cluster.row] = (int)cluster.boundingBox.height;
			
			if(maxColumnDimensions[cluster.column] < cluster.boundingBox.width)
				maxColumnDimensions[cluster.column] = (int)cluster.boundingBox.width;
		}
		//use the ratio of nodes to edges to help set how big the gridSize difference is
		int nodeCount = level.nodes.size();
		int edgeCount = level.edges.size(); 
		double ratio = edgeCount/nodeCount;
		if(ratio <= 1)
			gridSize = 3;
		else if(ratio < 1.2)
			gridSize = 10;
		else
			gridSize = 20;
		System.out.println("gridSize = " + gridSize);
		//total the row/column dimensions
		height = gridSize; //first grid size for the outer near side
		int rowNum = 0;
		for(; rowNum < numRows; rowNum++)
		{
			startingRowYValue[rowNum] = height;
			height += maxRowDimensions[rowNum] + gridSize;
		}
		
		width = gridSize;
		int columnNum = 0;
		for(; columnNum < numColumns; columnNum++)
		{
			startingColumnXValue[columnNum] = width;
			width += maxColumnDimensions[columnNum] + gridSize;

		}
		level.boundingBox.x = 0;
		level.boundingBox.y = 0;
		level.boundingBox.width = width;
		level.boundingBox.height = height;
	}
	
	
	public void layoutClusters()
	{		
		System.out.println("w/h " +width + " " + height);
		allocateMap();
		
		//set x and y values
		for(int i = 0; i<level.nodes.size(); i++)
		{
			NodeElement cluster = level.nodes.get(i);
			int maxHeightOfRow = maxRowDimensions[cluster.row];
			cluster.boundingBox.x = startingColumnXValue[cluster.column];
			//center node in the y direction
			cluster.boundingBox.y = startingRowYValue[cluster.row] + (int)(0.5*(maxHeightOfRow-cluster.boundingBox.height));
		}
		
		//build map
		
		for(int i = 0; i<level.nodes.size(); i++)
		{
			NodeElement cluster = level.nodes.get(i);
			//mark this space as used
			for(int j=-1;j<cluster.boundingBox.width+1;j++)
				for(int k=-1;k<cluster.boundingBox.height+1;k++)
				{
					map[cluster.boundingBox.x+j][cluster.boundingBox.y+k] = (cluster.nodeNumber+100);		
					
				}

			//set connection point locations and dig hole for each port

			int incomingPortSpacing = (int)(cluster.boundingBox.height/cluster.incomingPorts.size());
			for(int portNum=0; portNum<cluster.incomingPorts.size(); portNum++)
			{
				//incoming ports go on the left wall, evenly spaced
				PortInfo port = cluster.incomingPorts.get(portNum);
				int xVal = cluster.boundingBox.x;
				int yVal = (int)(cluster.boundingBox.y + (portNum+0.5)* incomingPortSpacing);
				port.setPoint(xVal, yVal);
				while(map[xVal][yVal] != 0)
				{
					map[xVal][yVal] = 0;
					xVal--;
				}
			}
			
			int outgoingPortSpacing = (int)(cluster.boundingBox.height/cluster.outgoingPorts.size());
			for(int portNum=0; portNum<cluster.outgoingPorts.size(); portNum++)
			{
				//outgoing ports go on the right wall, evenly spaced
				int xVal = (int)(cluster.boundingBox.x+cluster.boundingBox.width);
				int yVal = (int)(cluster.boundingBox.y + (portNum+0.5)* outgoingPortSpacing);
				PortInfo port = cluster.outgoingPorts.get(portNum);
				port.setPoint(xVal, yVal);
				while(map[xVal][yVal] != 0)
				{
					map[xVal][yVal] = 0;
					xVal++;
				}
			}
		}
	}
	
	public class xBlockComparator implements Comparator<NodeElement>{
	    public int compare(NodeElement object1, NodeElement object2) {
	    	return Double.compare(object1.boundingBox.x, object2.boundingBox.x);
	    }
	}
	
	public class yBlockComparator  implements Comparator<NodeElement>{
	    public int compare(NodeElement object1, NodeElement object2) {
	    	return Double.compare(object1.boundingBox.y, object2.boundingBox.y);
	    }
	}
	
	int pathNum;
	private boolean recordBlocks = false;
	public void layoutTopLevelEdges(NodeElement level)
	{				
		//make sure to set maxSearchDistance before actually searching
		finder = new AStarPathFinder(this, 0, false, new ManhattanHeuristic(0));

		//sort edges from shortest to longest
		Collections.sort(level.edges, new LengthComparator());
		//move and layout each edge
		for(int i = 0; i<level.edges.size(); i++)
		{
			pathNum = i;
			Calendar cal = Calendar.getInstance();
	    	cal.getTime();
	    	SimpleDateFormat sdf = new SimpleDateFormat("HH:mm:ss:SSS");
	    	
			visited = new boolean[width][height];

			EdgeElement edge = level.edges.get(i);
			System.out.println( "edge " + edge.fromNodeID + "  to " + edge.toNodeID );
			layoutTopLevelEdge(edge);
			
	    	System.out.println( "done with edge " + i + "(" +(level.edges.size()-i)+ ")" + "  at " + sdf.format(cal.getTime()) );

//	    	if(i>10)
//	    		break;
		}
	}
	
	public class LengthComparator implements Comparator<EdgeElement>{
	    public int compare(EdgeElement object1, EdgeElement object2) 
	    {
		    PortInfo outgoingPort1 = object1.outgoingPorts.get(0);
		    PortInfo incomingPort1 = object1.incomingPorts.get(0);
			double distance1 = Math.abs(outgoingPort1.connectionPoint.x - incomingPort1.connectionPoint.x) 
			+ Math.abs(outgoingPort1.connectionPoint.y - incomingPort1.connectionPoint.y);
			
			PortInfo outgoingPort2 = object2.outgoingPorts.get(0);
		    PortInfo incomingPort2 = object2.incomingPorts.get(0);
			double distance2 = Math.abs(outgoingPort2.connectionPoint.x - incomingPort2.connectionPoint.x) 
			+ Math.abs(outgoingPort2.connectionPoint.y - incomingPort2.connectionPoint.y);

			return Double.compare(distance1, distance2);
	    }
	}
	
	public void layoutTopLevelEdge(EdgeElement edge)
	{
		PortInfo outgoingPort = null;
		if(edge.outgoingPorts.size() > 0)
			outgoingPort = edge.outgoingPorts.get(0);
		else
			outgoingPort = new PortInfo(edge, null);
		PortInfo incomingPort = null;
		if(edge.incomingPorts.size() > 0)
			incomingPort = edge.incomingPorts.get(0);
		else
			incomingPort = new PortInfo(edge, null);
		
		if(outgoingPort.connectionPoint == null)
			outgoingPort.setPoint(0,0);
		if(incomingPort.connectionPoint == null)
			incomingPort.setPoint(0,0);

		int maxSearchDistance = (Math.abs(outgoingPort.connectionPoint.x - incomingPort.connectionPoint.x) +
				Math.abs(outgoingPort.connectionPoint.y - incomingPort.connectionPoint.y))*40;
		System.out.println("distance " + maxSearchDistance);

		finder.maxSearchDistance = maxSearchDistance;
				
		if(outgoingPort.connectionPoint.x < width && incomingPort.connectionPoint.x  < width
				&& outgoingPort.connectionPoint.y < height && incomingPort.connectionPoint.y  < height)
		{
			edge.path = finder.findPath(new LevelMover(), 
					incomingPort.connectionPoint.x,incomingPort.connectionPoint.y, 
				outgoingPort.connectionPoint.x, outgoingPort.connectionPoint.y);
		}

		
		if(edge.path!=null)
			System.out.println("path exists");
		else
			System.out.println("path failed");
			
		if(edge.path!=null)
		{
			markPathCost(edge.path);
			simplifyPath(edge.path);
	
			edge.points.add(outgoingPort.connectionPoint);
			edge.points.add(incomingPort.connectionPoint);
			int pathLength = edge.path.getLength();
			//path is reversed, so we take it from the end
			for(int i = 1; i<pathLength; i++)
			{
				//if we are looking at the last path segment, figure out if we should add an extra joint
				//to get the error joint closer to the output port
				if(i+1 == pathLength)
				{
					int xDiff = Math.abs(edge.path.getX(i-1) - edge.path.getX(i));
					int yDiff = Math.abs(edge.path.getY(i-1) - edge.path.getY(i));
					
					//add in extra node
					if(xDiff + yDiff > 3)
					{
						int xpos = edge.path.getX(i) - 2;
						int ypos = edge.path.getY(i);
						Point newPoint1 = new Point(xpos, ypos);
						Point newPoint2 = new Point(xpos, ypos);
						Point newPoint3 = new Point(xpos, ypos);
						//it's a cubic bezier path, but I want straight lines, what can I say?
						edge.points.add(newPoint1);
						edge.points.add(newPoint2);
						edge.points.add(newPoint3);
					}
				}
				int xpos = edge.path.getX(i);
				int ypos = edge.path.getY(i);
				Point newPoint1 = new Point(xpos, ypos);
				Point newPoint2 = new Point(xpos, ypos);
				Point newPoint3 = new Point(xpos, ypos);
				//it's a cubic bezier path, but I want straight lines, what can I say?
				edge.points.add(newPoint1);
				edge.points.add(newPoint2);
				edge.points.add(newPoint3);
			}
		}
	}

	public class xPosComparator implements Comparator<Rectangle>{
	    public int compare(Rectangle object1, Rectangle object2) {
	    	if(Math.abs(object1.x - object2.x) < 2) 
	    		return 0;
	    	else
	    		return Double.compare(object1.x, object2.x);
	    }
	}
	
	public class yPosComparator  implements Comparator<Rectangle>{
	    public int compare(Rectangle object1, Rectangle object2) {
	    	return Double.compare(object1.y, object2.y);
	    }
	}
	
	public void markPathCost(Path path)
	{
		//record the path cost into the main map
		for(int index = 2; index<path.getLength(); index++)
		{
			Step step = path.getStep(index);
			int x = step.x;
			int y = step.y;
			map[x][y] += 2;
//			for(int j=x-3; j<x+4; j++)
//				for(int k=y-3; k<y+4;k++)
//				{
//					if(j>0 && k>0 && j<width && k<height)
//						map[j][k] += 10;
//				}
			
		}
	}
	
	//remove path sections that don't cause a change in direction
	public void simplifyPath(Path path)
	{
		int initialDirection;
		int previousDirection = 100;
		//compare our step with previous one, and if not different, remove previous step
		for(int index = path.getLength()-2; index>=0; index--)
		{
			Step currentStep = path.getStep(index);
			Step previousStep = path.getStep(index+1);
			initialDirection = currentStep.x - previousStep.x;
			if(initialDirection == 0)
			{
				//multiply by two just to get magnitude change
				initialDirection = (currentStep.y - previousStep.y)*2;
			}
			if(previousDirection != 100) //have we set previous direction yet?
			{
				//no change, so remove previous step
				if(initialDirection == previousDirection)
					path.removeStep(index+1);
			}
			previousDirection = initialDirection;
			
		}
		
		//if last segment larger than 7(?) add in a joint 5 pts away from end
		//Step lastStep = 
	}
	
	/**
	 * Clear the array marking which tiles have been visited by the path 
	 * finder.
	 */
	public void clearVisited() {
		for (int x=0;x<getWidthInTiles();x++) {
			for (int y=0;y<getHeightInTiles();y++) {
				visited[x][y] = false;
			}
		}
	}
	
	/**
	 * @see TileBasedMap#visited(int, int)
	 */
	public boolean visited(int x, int y) {
		return visited[x][y];
	}
	
	/**
	 * Get the terrain at a given location
	 * 
	 * @param x The x coordinate of the terrain tile to retrieve
	 * @param y The y coordinate of the terrain tile to retrieve
	 * @return The terrain tile at the given location
	 */
	public int getMap(int x, int y) {
		return map[x][y];
	}
	
	
	/**
	 * @see TileBasedMap#blocked(Mover, int, int)
	 */
	public boolean blocked(Mover mover, int x, int y) {
		if(recordBlocks)
			System.out.println(x + " " + y  + " " + map[x][y]);

		if(map[x][y] < 100)
			return false;
		else
			return true;
	}

	/**
	 * @see TileBasedMap#getCost(Mover, int, int, int, int)
	 */
	public float getCost(Mover mover, int sx, int sy, int tx, int ty)
	{	
		int extraCost = 0;
//		if(tx != 0 && ty != 0 && tx-2<width && ty-2< height)
//		{
//			if(map[tx-1][ty] != 0 || 
//					map[tx][ty-1] != 0 ||
//					map[tx+1][ty] != 0 ||
//					map[tx][ty+1] != 0)
//				extraCost = 1;
//		}
		return map[tx][ty] + extraCost;
	}

	/**
	 * @see TileBasedMap#getHeightInTiles()
	 */
	public int getHeightInTiles() {
		return height;
	}

	/**
	 * @see TileBasedMap#getWidthInTiles()
	 */
	public int getWidthInTiles() {
		return width;
	}

	/**
	 * @see TileBasedMap#pathFinderVisited(int, int)
	 */
	public void pathFinderVisited(int x, int y) {
		visited[x][y] = true;
	}
	
	class LevelMover implements Mover {
		/** The unit ID moving */
		private int type;
		public int previousMoveDirection;

		/**
		 * Get the ID of the unit moving
		 * not used, but makes the (pre-canned) code work
		 * @return The ID of the unit moving
		 */
		public int getType() {
			return type;
		}
	}
}
