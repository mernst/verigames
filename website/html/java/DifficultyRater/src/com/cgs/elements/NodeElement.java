package com.cgs.elements;

import java.util.ArrayList;

public class NodeElement extends Element
{			
	public ArrayList<String> inputPorts;
	public ArrayList<String> outputPorts;
	
	public String levelID;
	
	public boolean isWide;
	public boolean isEditable;
	public boolean isBox = false;
	
	public boolean counted = false;
	
	public NodeElement(String _id, String _levelID)
	{
		super(_id);
		levelID = _levelID;
		inputPorts = new ArrayList<String>();
		outputPorts = new ArrayList<String>();
	}
	
	public void addInputPort(String port)
	{
		inputPorts.add(port);
	}
	
	public void addOutputPort(String port)
	{
		outputPorts.add(port);
	}
		
	//loops through top level edges connecting start and finish nodes
	public void connectClusters()
	{
//		for(int i = 0; i<edges.size();i++)
//		{
//			EdgeElement edge = edges.get(i);
//			String fromNodeID = edge.fromNodeID;
//			NodeElement fromNode = findSubNode(fromNodeID);
//			String toNodeID = edge.toNodeID;
//			NodeElement toNode = findSubNode(toNodeID); 
//			
//			if(fromNode != null && toNode != null)
//			{
//				PortInfo oport = new PortInfo(edge, fromNode);
//				fromNode.addOutgoingPort(oport);
//				edge.addIncomingPort(oport);
//				PortInfo iport = new PortInfo(edge, toNode);
//				toNode.addIncomingPort(iport);
//				edge.addOutgoingPort(iport);
//			}
//		}
	}	

	//writes nodes that are also containers - levels, clusters
	public void writeElement(StringBuffer buffer)
	{
//		buffer.append("<node id=\"" + id + "\">\r");
//		if(nodes.size() > 0)
//			buffer.append("<graph id=\""+id+"\" edgeids=\"true\" edgemode=\"directed\">\r");
//		writeAttributes(buffer);
//		for(int clusterIndex = 0;clusterIndex<nodes.size(); clusterIndex++)
//		{
//			NodeElement subCluster = nodes.get(clusterIndex);
//			subCluster.writeElement(buffer);
//		}
//		
//		for(int edgeIndex = 0; edgeIndex < edges.size(); edgeIndex++)
//			edges.get(edgeIndex).writeElement(buffer);
//		
//		if(nodes.size() > 0)
//			buffer.append("</graph>\r");
//		
//		buffer.append("</node>\r");
//		
	}

}