package com.cgs.elements;

import java.util.ArrayList;

public class NodeElement extends Element
{
	public ArrayList<Port> inputPorts;
	public ArrayList<Port> outputPorts;
	
	public String levelID;
	public String kind;

	public int column;
	public int row;	
	
	//grid for plotting child locations
	protected LevelMap grid;
	
	public NodeElement(String _id)
	{
		this(_id, "", "CONNECT");
	}
	
	public NodeElement(String _id, String _levelID, String _kind)
	{
		super(_id);
		levelID = _levelID;
		this.kind = _kind;
		inputPorts = new ArrayList<Port>();
		outputPorts = new ArrayList<Port>();
	}
	
	public void cleanUp()
	{
		grid.cleanUp();
	}
	
	public void addInputPort(Port port)
	{
		inputPorts.add(port);
	}
	
	public void addOutputPort(Port port)
	{
		outputPorts.add(port);
	}
	
	//writes nodes that are also containers - levels, clusters
	public void writeElement(StringBuffer buffer)
	{
		buffer.append("<node id=\"" + id + "\">\r");
		writeAttributes(buffer);
		buffer.append("</node>\r");
		
	}
	
	public void writeXMLElement(StringBuffer buffer)
	{
		buffer.append("<node kind =\"CONNECT\" id=\"" + id + "\">\r");
		if(inputPorts.size() == 0)
			buffer.append("<input/>\r");
		else
		{
			buffer.append("<input>\r");
			for(int inPort = 0; inPort < inputPorts.size(); inPort++)
			{
				Port port = inputPorts.get(inPort);
				buffer.append("<port num=\"" + inPort + "\" edge=\""+port.id+"\"/>\r");
			}
			buffer.append("</input>\r");
		}
		if(outputPorts.size() == 0)
			buffer.append("<output/>\r");
		else
		{
			buffer.append("<output>\r");
			for(int outPort = 0; outPort < outputPorts.size(); outPort++)
			{
				Port port = outputPorts.get(outPort);
				buffer.append("<port num=\"" + outPort + "\" edge=\""+port.id+"\"/>\r");
			}
			buffer.append("</output>\r");
		}
		buffer.append("</node>\r");
		
	}

	public int getPortNumber(Port port) 
	{
		//find port in portList, search both incoming and outgoing lists
		int portNum = outputPorts.indexOf(port);
		if(portNum != -1)
			return portNum;
		else
			return inputPorts.indexOf(port);
	}
}