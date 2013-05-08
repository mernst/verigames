package com.cgs.elements;

public class Port extends Element 
{
	public String portNumber;
	public Point connectionPoint;
	
	public EdgeElement connectedEdge;
	public NodeElement connectedNode;
	public GridLine connectedLine;
	
	public Port(String _edgeID)
	{
		super(_edgeID);
	}
	
	public void setEdge(EdgeElement edge)
	{
		connectedEdge = edge;
	}
	
	public void setNode(NodeElement node)
	{
		connectedNode = node;
	}
	
	public void setPoint(int x, int y)
	{
		connectionPoint = new Point(x,y);
	}
}
