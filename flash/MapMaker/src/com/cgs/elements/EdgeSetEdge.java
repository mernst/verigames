package com.cgs.elements;

//Container for edges that connect edge sets
public class EdgeSetEdge extends EdgeElement
{
	public EdgeSet toEdgeSet;
	public EdgeSet fromEdgeSet;
	
	int inputPosition = 0;
	int outputPosition = 0;
	
	public EdgeSetEdge(String _id, EdgeSet _fromEdgeSet, EdgeSet _toEdgeSet)
	{
		super(_id);
		toEdgeSet = _toEdgeSet;
		fromEdgeSet = _fromEdgeSet;
	}
}
