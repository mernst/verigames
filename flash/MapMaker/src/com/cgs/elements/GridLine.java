package com.cgs.elements;

//Container for edges that connect edge sets
public class GridLine extends EdgeElement
{
	public EdgeSet edgeSet;
	//public EdgeSet fromEdgeSet;
	public JointElement joint;
	public Boolean jointToEdgeSet;
	
	public int inputPosition = 0;
	public int outputPosition = 0;
	
	public GridLine(String _id, EdgeSet _edgeSet, JointElement _joint, Boolean _jointToEdgeSet)
	{
		super(_id);
		edgeSet = _edgeSet;
		joint = _joint;
		jointToEdgeSet = _jointToEdgeSet;
	}
}
