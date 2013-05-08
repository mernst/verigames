package com.cgs.elements;

import java.util.ArrayList;

public class JointElement extends NodeElement
{
	public Rectangle boundingBox;
	public Boolean isPlaced;
	
	/**
	 * Create Joint using nodes's input/output ports
	 * @param _nodeToCreateFrom
	 */
	public JointElement(NodeElement _nodeToCreateFrom)
	{
		super(_nodeToCreateFrom.id);
		this.inputPorts = _nodeToCreateFrom.inputPorts;
		this.outputPorts = _nodeToCreateFrom.outputPorts;
		boundingBox = new Rectangle();
		isPlaced = false;
	}
	
	/**
	 * To be used to create a joint using custom ports for the joint, i.e. for SUBBOARD nodes
	 * @param _nodeToCreateFrom
	 * @param iPorts
	 * @param oPorts
	 */
	public JointElement(NodeElement _nodeToCreateFrom, ArrayList<Port> iPorts, ArrayList<Port> oPorts)
	{
		super(_nodeToCreateFrom.id);
		this.inputPorts = iPorts;
		this.outputPorts = oPorts;
	}
}