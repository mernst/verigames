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
		for(int edgeSetIndex = 0; edgeSetIndex < level.edgesets.size(); edgeSetIndex++)
		{
			EdgeSet edgeset = level.edgesets.get(edgeSetIndex);
				
			//assign heights and widths
			if(edgeset.inputGridLines.size() > edgeset.outputGridLines.size())
				edgeset.boundingBox.width = edgeset.inputGridLines.size();
			else if(edgeset.outputGridLines.size() > 1)
				edgeset.boundingBox.width = edgeset.outputGridLines.size();
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
		for(int i = 0; i<edgeSet.inputGridLines.size(); i++)
		{
			JointElement inJoint = edgeSet.inputGridLines.get(i).joint;
			if(inJoint.isPlaced == false)
			{
				inJoint.boundingBox.y = currentRow - 2;
				inJoint.isPlaced = true;
				if(minimumRow > currentRow)
					minimumRow = currentRow;
				int newCurrentRow  = currentRow - 2;
				int newMinimumRow = placeConnectedEdgeSets(inJoint, newCurrentRow, minimumRow);
				if(minimumRow > newMinimumRow)
					minimumRow = newMinimumRow;
			}
		}
		
		for(int i = 0; i<edgeSet.outputGridLines.size(); i++)
		{
			EdgeSet newEdgeSet = edgeSet.outputGridLines.get(i).edgeSet;
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
			if(edgeSet.outputGridLines.size() > 0)
			{
				GridLine outputEdgeSetEdge = edgeSet.outputGridLines.get(0);
				int currentColumn = edgeSet.boundingBox.x;
				int currentRow = edgeSet.boundingBox.y;
				int possibleColumn = outputEdgeSetEdge.edgeSet.boundingBox.x;
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
			if(edgeSet.inputGridLines.size() > 0)
			{
				GridLine inputEdgeSetEdge = edgeSet.inputGridLines.get(0);
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
			if(edgeSet.inputGridLines.size() > 1)
			{
				//organize connections by comparing starting node's rank with neighbor
				//loop through those above you, remember the currently highest rank, and switch with that at the end
				for(int j = 0; j<edgeSet.inputGridLines.size(); j++)
				{
					EdgeSet fromEdgeSet = edgeSet.inputGridLines.get(j).fromEdgeSet;
					int currentHighestRow = edgeSet.inputGridLines.get(j).inputPosition;
					int highestEdgePosition = 0;
					for(int k = j+1; k<edgeSet.inputGridLines.size(); k++)
					{							
						EdgeSet nextEdgeSet = edgeSet.inputGridLines.get(k).fromEdgeSet;
						if(fromEdgeSet != null && nextEdgeSet != null)
						{
							int nextEdgeSetRow = edgeSet.inputGridLines.get(k).inputPosition;
							
							if(currentHighestRow < nextEdgeSetRow)
							{
								currentHighestRow = nextEdgeSetRow;
								highestEdgePosition = k;
							}
						}
					}
					if(highestEdgePosition != 0)
					{
						GridLine jEdgeSetEdge = edgeSet.inputGridLines.get(j);
						GridLine kEdgeSetEdge = edgeSet.inputGridLines.get(highestEdgePosition);
						edgeSet.inputGridLines.set(j, kEdgeSetEdge);
						edgeSet.inputGridLines.set(highestEdgePosition, jEdgeSetEdge);
						int oldJPos = jEdgeSetEdge.inputPosition;
						jEdgeSetEdge.inputPosition = kEdgeSetEdge.inputPosition;
						kEdgeSetEdge.inputPosition = oldJPos;
						
					}
				}
			}
			
			//trace forward connections. Check to make sure higher row has higher connection else switch.
			//trace backward connections. Check to make sure higher row has higher connection else switch.
			if(edgeSet.outputGridLines.size() > 1)
			{
				//organize connections by comparing starting node's rank with neighbor
				//loop through those above you, remember the currently highest rank, and switch with that at the end
				for(int j = 0; j<edgeSet.outputGridLines.size(); j++)
				{
					EdgeSet fromEdgeSet = edgeSet.outputGridLines.get(j).edgeSet;
					int currentHighestRow = edgeSet.outputGridLines.get(j).outputPosition;
					int highestEdgePosition = 0;
					for(int k = j+1; k<edgeSet.outputGridLines.size(); k++)
					{							
						EdgeSet nextEdgeSet = edgeSet.outputGridLines.get(k).edgeSet;
						if(fromEdgeSet != null && nextEdgeSet != null)
						{
							int nextEdgeSetRow = edgeSet.outputGridLines.get(k).outputPosition;
							
							if(currentHighestRow < nextEdgeSetRow)
							{
								currentHighestRow = nextEdgeSetRow;
								highestEdgePosition = k;
							}
						}
					}
					if(highestEdgePosition != 0)
					{
						GridLine jEdgeSetEdge = edgeSet.outputGridLines.get(j);
						GridLine kEdgeSetEdge = edgeSet.outputGridLines.get(highestEdgePosition);
						edgeSet.outputGridLines.set(j, kEdgeSetEdge);
						edgeSet.outputGridLines.set(highestEdgePosition, jEdgeSetEdge);
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
		
		//now layout the joints in between these
		
	}
}
