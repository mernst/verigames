package com.cgs.elements;

import java.util.Collections;
import java.util.Comparator;

public class LevelMap
{
	
	Level level;
	int height;
	int width;
	
	int minimumRow = 0;
	int maxX = 0;
	int maxY = 0;
	double[] maxColumnWidth;
	double[] columnStartingPos;
	//both of these will be multiplied by 10 at the finish
	//the height of a box == 1 unit
	double gridBoxSize = 1; 
	double gridSpaceSize = 1;
	
	/**
	 * Create a new test map with some default configuration
	 */
	public LevelMap(Level _level) {
		
		level = _level;
	}
	
	
	public void cleanUp()
	{
		level = null;
	}

	public void sizeClusters()
	{
		//set sizes based on # of connections
		for(int nodeIndex = 0; nodeIndex < level.edgesets.size(); nodeIndex++)
		{
			EdgeSet edgeset = level.edgesets.get(nodeIndex);
				
			//assign heights and widths
			if(edgeset.inputEdgeSetEdges.size() > edgeset.outputEdgeSetEdges.size())
				edgeset.boundingBox.width = edgeset.inputEdgeSetEdges.size();
			else if(edgeset.outputEdgeSetEdges.size() > 1)
				edgeset.boundingBox.width = edgeset.outputEdgeSetEdges.size();
			else
				edgeset.boundingBox.width = 1;
			
			edgeset.boundingBox.height = 1;
		}
	}
	
	//organize boxes into ranks based on order of connectivity
	public void assignRanks()
	{
		//semi-arbitrarily assign starting rank to a node, and place other nodes
		//before or after that node
		for(int i = 0; i<level.edgesets.size(); i++)
		{
			EdgeSet edgeSet = level.edgesets.get(i);
			
			int currentRow = 0;
			if(edgeSet.isPlaced == false)
			{
				edgeSet.boundingBox.y = currentRow;
				edgeSet.isPlaced = true;
				int newMinimumRow = placeConnectedEdgeSets(edgeSet, currentRow, minimumRow);
				if(minimumRow > newMinimumRow)
					minimumRow = newMinimumRow;
			}
		}
	}
	
	protected int placeConnectedEdgeSets(EdgeSet edgeSet, int currentRow, int minimumRow)
	{
		//note - input ports are behind this edgeset
		for(int i = 0; i<edgeSet.inputEdgeSetEdges.size(); i++)
		{
			EdgeSet newEdgeSet = edgeSet.inputEdgeSetEdges.get(i).fromEdgeSet;
			if(newEdgeSet.isPlaced == false)
			{
				newEdgeSet.boundingBox.y = currentRow - 2;
				newEdgeSet.isPlaced = true;
				if(minimumRow > currentRow)
					minimumRow = currentRow;
				int newCurrentRow  = currentRow - 2;
				int newMinimumRow = placeConnectedEdgeSets(newEdgeSet, newCurrentRow, minimumRow);
				if(minimumRow > newMinimumRow)
					minimumRow = newMinimumRow;
			}
		}
		
		for(int i = 0; i<edgeSet.outputEdgeSetEdges.size(); i++)
		{
			EdgeSet newEdgeSet = edgeSet.outputEdgeSetEdges.get(i).toEdgeSet;
			if(newEdgeSet.isPlaced == false)
			{
				newEdgeSet.boundingBox.y = currentRow + 2;
				newEdgeSet.isPlaced = true;
				int newCurrentRow  = currentRow + 2;
				int newMinimumRow = placeConnectedEdgeSets(newEdgeSet, newCurrentRow, minimumRow);
				if(minimumRow > newMinimumRow)
					minimumRow = newMinimumRow;
			}
		}
		return minimumRow;
	}
	
	//randomly assign columns
	public void assignColumns()
	{
		Collections.sort(level.edgesets, new yComparator());
		
		int currentRow = level.edgesets.get(0).boundingBox.y;
		int currentColumn = 1;
		for(int i = 0; i<level.edgesets.size(); i++)
		{
			EdgeSet edgeSet = level.edgesets.get(i);
			if(currentRow != edgeSet.boundingBox.y)
			{
				currentRow = edgeSet.boundingBox.y;
				currentColumn = 1;
			}
			
			edgeSet.boundingBox.x = currentColumn;
			currentColumn++;
		}
	}
	
	//move nodes left or right to try to get them facing a direct connection
	public void adjustColumns()
	{
		normalizeRank();
		//sort in reverse order of x coordinates, so I can pull them to the right without much fear of hitting something
		Collections.sort(level.edgesets, new xReverseComparator());

		EdgeSet[][] nodeArray = new EdgeSet[maxX+1][maxY+1];
		for(int i = 0; i<level.edgesets.size(); i++)
		{
			EdgeSet edgeSet = level.edgesets.get(i);
			nodeArray[edgeSet.boundingBox.x][edgeSet.boundingBox.y] = edgeSet;
		}
		
		//try to line up with nodes at end of output edges
		for(int i = 0; i<level.edgesets.size(); i++)
		{
			EdgeSet edgeSet = level.edgesets.get(i);

			//shorten edges by having them in the same row as one they connect to, if possible
			//check only the first port, live with the others where ever they connect
			if(edgeSet.outputEdgeSetEdges.size() > 0)
			{
				EdgeSetEdge outputEdgeSetEdge = edgeSet.outputEdgeSetEdges.get(0);
				int currentColumn = edgeSet.boundingBox.x;
				int currentRow = edgeSet.boundingBox.y;
				int possibleColumn = outputEdgeSetEdge.toEdgeSet.boundingBox.x;
				//try to place it in exact right spot, and if that doesn't work, back out toward original position
				while(possibleColumn > currentColumn && nodeArray[possibleColumn][currentRow] != null)
				{
					possibleColumn--;
				}
				
				if(possibleColumn != currentColumn && nodeArray[possibleColumn][currentRow] == null)
				{
					//remove, update, replace
					nodeArray[currentColumn][currentRow] = null;
					edgeSet.boundingBox.x = possibleColumn;
					nodeArray[possibleColumn][currentRow] = edgeSet;

				}
			}
		}
		
		//now do the same for input edges
		for(int i = 0; i<level.edgesets.size(); i++)
		{
			EdgeSet edgeSet = level.edgesets.get(i);

			//shorten edges by having them in the same row as one they connect to, if possible
			//check only the first port, live with the others where ever they connect
			if(edgeSet.inputEdgeSetEdges.size() > 0)
			{
				EdgeSetEdge inputEdgeSetEdge = edgeSet.inputEdgeSetEdges.get(0);
				int currentColumn = edgeSet.boundingBox.x;
				int currentRow = edgeSet.boundingBox.y;
				int possibleColumn = inputEdgeSetEdge.fromEdgeSet.boundingBox.x;
				//try to place it in exact right spot, and if that doesn't work, back out toward original position
				while(possibleColumn > currentColumn && nodeArray[possibleColumn][currentRow] != null)
				{
					possibleColumn--;
				}
				
				if(possibleColumn != currentColumn && nodeArray[possibleColumn][currentRow] == null)
				{
					//remove, update, replace
					nodeArray[currentColumn][currentRow] = null;
					edgeSet.boundingBox.x = possibleColumn;
					nodeArray[possibleColumn][currentRow] = edgeSet;

				}
			}
		}
	}

	//adjust ports to try to get higher ports connected to higher nodes
	public void adjustConnections()
	{		
		
		for(int i = 0; i<level.edgesets.size(); i++)
		{
			EdgeSet edgeSet = level.edgesets.get(i);
			
			//trace backward connections. Check to make sure higher row has higher connection else switch.
			if(edgeSet.inputEdgeSetEdges.size() > 1)
			{
				//organize connections by comparing starting node's rank with neighbor
				//loop through those above you, remember the currently highest rank, and switch with that at the end
				for(int j = 0; j<edgeSet.inputEdgeSetEdges.size(); j++)
				{
					EdgeSet fromEdgeSet = edgeSet.inputEdgeSetEdges.get(j).fromEdgeSet;
					int currentHighestRow = edgeSet.inputEdgeSetEdges.get(j).inputPosition;
					int highestEdgePosition = 0;
					for(int k = j+1; k<edgeSet.inputEdgeSetEdges.size(); k++)
					{							
						EdgeSet nextEdgeSet = edgeSet.inputEdgeSetEdges.get(k).fromEdgeSet;
						if(fromEdgeSet != null && nextEdgeSet != null)
						{
							int nextEdgeSetRow = edgeSet.inputEdgeSetEdges.get(k).inputPosition;
							
							if(currentHighestRow < nextEdgeSetRow)
							{
								currentHighestRow = nextEdgeSetRow;
								highestEdgePosition = k;
							}
						}
					}
					if(highestEdgePosition != 0)
					{
						EdgeSetEdge jEdgeSetEdge = edgeSet.inputEdgeSetEdges.get(j);
						EdgeSetEdge kEdgeSetEdge = edgeSet.inputEdgeSetEdges.get(highestEdgePosition);
						edgeSet.inputEdgeSetEdges.set(j, kEdgeSetEdge);
						edgeSet.inputEdgeSetEdges.set(highestEdgePosition, jEdgeSetEdge);
						int oldJPos = jEdgeSetEdge.inputPosition;
						jEdgeSetEdge.inputPosition = kEdgeSetEdge.inputPosition;
						kEdgeSetEdge.inputPosition = oldJPos;
						
					}
				}
			}
			
			//trace forward connections. Check to make sure higher row has higher connection else switch.
			//trace backward connections. Check to make sure higher row has higher connection else switch.
			if(edgeSet.outputEdgeSetEdges.size() > 1)
			{
				//organize connections by comparing starting node's rank with neighbor
				//loop through those above you, remember the currently highest rank, and switch with that at the end
				for(int j = 0; j<edgeSet.outputEdgeSetEdges.size(); j++)
				{
					EdgeSet fromEdgeSet = edgeSet.outputEdgeSetEdges.get(j).toEdgeSet;
					int currentHighestRow = edgeSet.outputEdgeSetEdges.get(j).outputPosition;
					int highestEdgePosition = 0;
					for(int k = j+1; k<edgeSet.outputEdgeSetEdges.size(); k++)
					{							
						EdgeSet nextEdgeSet = edgeSet.outputEdgeSetEdges.get(k).toEdgeSet;
						if(fromEdgeSet != null && nextEdgeSet != null)
						{
							int nextEdgeSetRow = edgeSet.outputEdgeSetEdges.get(k).outputPosition;
							
							if(currentHighestRow < nextEdgeSetRow)
							{
								currentHighestRow = nextEdgeSetRow;
								highestEdgePosition = k;
							}
						}
					}
					if(highestEdgePosition != 0)
					{
						EdgeSetEdge jEdgeSetEdge = edgeSet.outputEdgeSetEdges.get(j);
						EdgeSetEdge kEdgeSetEdge = edgeSet.outputEdgeSetEdges.get(highestEdgePosition);
						edgeSet.outputEdgeSetEdges.set(j, kEdgeSetEdge);
						edgeSet.outputEdgeSetEdges.set(highestEdgePosition, jEdgeSetEdge);
						int oldJPos = jEdgeSetEdge.outputPosition;
						jEdgeSetEdge.outputPosition = kEdgeSetEdge.outputPosition;
						kEdgeSetEdge.outputPosition = oldJPos;
					}
				}
			}
		}
	}
	
	//invert the rows so I get higher rows first
	public class yComparator implements Comparator<EdgeSet>{
	    public int compare(EdgeSet object1, EdgeSet object2) {
	    	return Double.compare(object1.boundingBox.y, object2.boundingBox.y);
	    }
	}
	
	public class xReverseComparator implements Comparator<EdgeSet>{
	    public int compare(EdgeSet object1, EdgeSet object2) {
	    	return Double.compare(object2.boundingBox.x, object1.boundingBox.x);
	    }
	}
	
	public void normalizeRank()
	{
		//loop through to find minimum and maximum values
		int minX = 10000;
		int minY = 10000;
		for(int i = 0; i<level.edgesets.size(); i++)
		{
			EdgeSet edgeSet = level.edgesets.get(i);
			if(edgeSet.boundingBox.x < minX)
				minX = edgeSet.boundingBox.x;
			if(edgeSet.boundingBox.y < minY)
				minY = edgeSet.boundingBox.y;
			if(edgeSet.boundingBox.x > maxX)
				maxX = edgeSet.boundingBox.x;
			if(edgeSet.boundingBox.y > maxY)
				maxY = edgeSet.boundingBox.y;	
		}
		System.out.println("first " + minX + " " + minY + " " + maxX + " " + maxY);
		
		// normalize for minimum rank = 0
		for(int i = 0; i<level.edgesets.size(); i++)
		{
			EdgeSet edgeSet = level.edgesets.get(i);
			System.out.println(maxX + " " + maxY + " " + edgeSet.boundingBox.x + " " + edgeSet.boundingBox.y);
			edgeSet.boundingBox.x -= minX;
			edgeSet.boundingBox.y -= minY;
			
			
			System.out.println(maxX + " " + maxY + " " + edgeSet.boundingBox.x + " " + edgeSet.boundingBox.y);
		}
		
		maxX = maxX - minX;
		maxY = maxY - minY;
		System.out.println(maxX + " " + maxY);
	}
	
	//find, and then total each column and row max dimensions, to use for layout
	//currently assume width = 10 everywhere, and set them accordingly
	public void setMapDimensions()
	{
		// normalize for minimum rank = 0
		for(int i = 0; i<level.edgesets.size(); i++)
		{
			EdgeSet edgeSet = level.edgesets.get(i);

			//multiply out edgeset bounding box dimensions
			edgeSet.boundingBox.x *= 10;
			edgeSet.boundingBox.y *= 10;
			edgeSet.boundingBox.width *= 10;
			edgeSet.boundingBox.height *= 10;
			
			edgeSet.boundingBox.finalXPos *= 10;
			edgeSet.boundingBox.finalYPos *= 10;
		}
		maxY = maxY - minimumRow;
		level.boundingBox.x = 0;
		level.boundingBox.y = 0;
		level.boundingBox.width = maxX*10 + 10;
		level.boundingBox.height = maxY*10;
	}
	
	//move to their respective column area, and center within
	public void layoutClusters()
	{		
		//find the max column size
		this.maxColumnWidth = new double[maxX+1];
		for(int i = 0; i<level.edgesets.size(); i++)
		{
			EdgeSet edgeSet = level.edgesets.get(i);
			int colNum = edgeSet.boundingBox.x;
			double width = edgeSet.boundingBox.width;
			if(maxColumnWidth[colNum]< width)
				maxColumnWidth[colNum] = width;
		}
		
		//roll up totals
		this.columnStartingPos = new double[maxX+1];
		//pad the outside with a space
		columnStartingPos[0] = this.gridSpaceSize;
		for(int i = 1; i<maxX+1; i++)
			columnStartingPos[i] = columnStartingPos[i-1]+maxColumnWidth[i-1] + this.gridSpaceSize;
		
		//now move each edgeset to the right location
		for(int i = 0; i<level.edgesets.size(); i++)
		{
			EdgeSet edgeSet = level.edgesets.get(i);
			int colNum = edgeSet.boundingBox.x;
			double width = edgeSet.boundingBox.width;
			double centeringAmount = (maxColumnWidth[colNum]-width)/2;
			edgeSet.boundingBox.finalXPos = columnStartingPos[edgeSet.boundingBox.x] + centeringAmount;
			edgeSet.boundingBox.finalYPos = edgeSet.boundingBox.y;
		}
	}
}
