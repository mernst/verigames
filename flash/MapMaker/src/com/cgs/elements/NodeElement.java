package com.cgs.elements;

import java.util.ArrayList;
import java.util.Comparator;

public class NodeElement extends Element
{
	public String id;
	public String kind;
	public ArrayList<NodeElement> nodes;
	public ArrayList<EdgeElement> edges;
	
	public int column;
	public int row;	
	
	//grid for plotting child locations
	protected LevelMap grid;
	
	public NodeElement(String _id)
	{
		super();
		id = _id;
		kind = "";
		nodes = new ArrayList<NodeElement>();
		edges = new ArrayList<EdgeElement>();
	}
	
	public NodeElement(String _id, String _kind)
	{
		super();
		id = _id;
		kind = _kind;
		nodes = new ArrayList<NodeElement>();
		edges = new ArrayList<EdgeElement>();
	}
	
	public void cleanUp()
	{
		grid.cleanUp();
	}
	
	public void addNode(NodeElement node)
	{
		nodes.add(node);
		node.parent = this;
	}
	public void addEdge(EdgeElement edge)
	{
		edges.add(edge);
		edge.parent = this;
	}
	
	public void setupLevel()
	{
		parseBoundingBox();
		
		//read in cluster information
		for(int i = 0; i<nodes.size(); i++)
		{
			NodeElement cluster = nodes.get(i);
			cluster.parsePosition();
		}
	}
	
	//searches recursively through the whole node tree
	public NodeElement findSubNode(String nodeID)
	{
		NodeElement foundNode = null;
		for(int index=0; index < nodes.size(); index++)
		{
			NodeElement node = nodes.get(index);
			if(node.id.compareTo(nodeID) == 0)
				foundNode = node;
			else
				foundNode = node.findSubNode(nodeID);
			
			if(foundNode != null)
				break;
		}
		
		return foundNode;
	}
	
	//searches for direct children only
	public NodeElement findChildNode(String nodeID)
	{
		for(int index=0; index < nodes.size(); index++)
		{
			NodeElement node = nodes.get(index);
			if(node.id.compareTo(nodeID) == 0)
				return node;
		}
		
		return null;
	}
	
	//normalize self and child nodes, ignore edges, which will change
	public void normalizeLevel()
	{
		normalizeNodeAndChildren();
	}
	
	void normalizeNodeAndChildren()
	{
		normalizeXY();
		for(int i = 0; i<nodes.size();i++)
		{
			NodeElement newNode = nodes.get(i);
			newNode.normalizeNodeAndChildren();
		}
	}
	
	public void layoutClusters()
	{

		//connect clusters so they can tell how big they should be (based on # of incoming edges + # of outgoing edges
		connectClusters();

		//layout internal shape of clusters first, to make sure they are the right size
		//currently all we do is resize
		grid = new LevelMap(this);
		grid.sizeClusters();
		grid.assignColumnAndRank();
		grid.adjustRanks();
		grid.adjustConnections();
		grid.setMapDimensions();
		grid.layoutClusters();
	}
	
	//loops through top level edges connecting start and finish nodes
	public void connectClusters()
	{
		for(int i = 0; i<edges.size();i++)
		{
			EdgeElement edge = edges.get(i);
			String fromNodeID = edge.fromNodeID;
			NodeElement fromNode = findSubNode(fromNodeID);
			String toNodeID = edge.toNodeID;
			NodeElement toNode = findSubNode(toNodeID); 
			
			if(fromNode != null && toNode != null)
			{
				PortInfo oport = new PortInfo(edge, fromNode);
				fromNode.addOutgoingPort(oport);
				edge.addIncomingPort(oport);
				PortInfo iport = new PortInfo(edge, toNode);
				toNode.addIncomingPort(iport);
				edge.addOutgoingPort(iport);
			}
		}
	}
	
	//shift a node and all it's children (if any) by dx,dy
	public void shiftNodeAndChildren(int dx, int dy)
	{
		boundingBox.x += dx;
		boundingBox.y += dy;
		for(int i = 0; i<nodes.size();i++)
		{
			NodeElement node = nodes.get(i);
			node.shiftNodeAndChildren(dx, dy);
		}
		for(int i = 0; i<edges.size();i++)
		{
			EdgeElement edge = edges.get(i);
			if(edge.points != null)
				for(int j=0; j<edge.points.size(); j++)
				{
					Point point = edge.points.get(j);
					point.x += dx;
					point.y += dy;
				}
		}
	}
	
	//update old bounding box/positions strings with new location/dimensions
	public void writeBackPositions()
	{
		updateBoundingBoxString();
		//write updated info back into string
		for(int i = 0; i<nodes.size(); i++)
		{
			NodeElement cluster = nodes.get(i);
			cluster.updatePositionString();
			cluster.updateHeightAndWidthString();
		}
		updateChildEdgePositions();
	}
	
	public class NodeIndexComparator implements Comparator<NodeElement>{
	    public int compare(NodeElement object1, NodeElement object2) {
	    	
	    	return Double.compare(object1.nodeNumber, object2.nodeNumber);
	    }
	}
		
	public void layoutTopLevelEdges()
	{
		grid.layoutTopLevelEdges(this);
	}
	
	void updateChildNodePositions()
	{
		//write positions back to XML
		for(int i = 0; i<nodes.size(); i++)
		{
			NodeElement node = nodes.get(i);
			node.updatePositionString();
		}	
	}
	
	void updateChildEdgePositions()
	{
		//write positions back to XML
		for(int i = 0; i<edges.size(); i++)
		{
			EdgeElement edge = edges.get(i);
			edge.updatePositionString();
		}	
	}
	
	//writes nodes that are also containers - levels, clusters
	public void writeElement(StringBuffer buffer)
	{
		buffer.append("<node id=\"" + id + "\">\r");
		if(nodes.size() > 0)
			buffer.append("<graph id=\""+id+"\" edgeids=\"true\" edgemode=\"directed\">\r");
		writeAttributes(buffer);
		for(int clusterIndex = 0;clusterIndex<nodes.size(); clusterIndex++)
		{
			NodeElement subCluster = nodes.get(clusterIndex);
			subCluster.writeElement(buffer);
		}
		
		for(int edgeIndex = 0; edgeIndex < edges.size(); edgeIndex++)
			edges.get(edgeIndex).writeElement(buffer);
		
		if(nodes.size() > 0)
			buffer.append("</graph>\r");
		
		buffer.append("</node>\r");
		
	}
	
	public void expandLevel()
	{
		expandNode(grid.xMultiplier,grid.yMultiplier);
	}

	public void expandNode(int xMultiplier, int yMultiplier) {
		//loop through all values and multiply by the multiplier
		this.boundingBox.x *= xMultiplier;
		this.boundingBox.y *= yMultiplier;
		this.boundingBox.width *= xMultiplier;
		this.boundingBox.height *= yMultiplier;
		for(int i = 0; i<nodes.size(); i++)
		{
			NodeElement node = nodes.get(i);
			node.expandNode(xMultiplier, yMultiplier);
		}	
			
		for(int i = 0; i<edges.size(); i++)
		{
			EdgeElement edge = edges.get(i);
			edge.expandEdge(xMultiplier, yMultiplier);
		}
	}
}