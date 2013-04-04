package com.cgs.elements;

public class PortInfo extends Element 
{
	public String portNumber;
	public String ID;
	public Point connectionPoint;
	
	public EdgeElement connectedEdge;
	public NodeElement connectedNode;
	
	PortInfo(String _number, String _ID)
	{
		portNumber = _number;
		ID = _ID;
	}
	
	PortInfo(EdgeElement edge, NodeElement node)
	{
		connectedEdge = edge;
		connectedNode = node;
		ID = edge.id;
	}
	
	public void setPoint(int x, int y)
	{
		connectionPoint = new Point(x,y);
	}
}
