package com.cgs.elements;

import java.io.BufferedWriter;
import java.util.ArrayList;

public class EdgeElement extends Element
{
	public Port inputPort;
	public Port outputPort;
	
	public boolean isNormalized;
	public ArrayList<Point> points;
	
	public String levelID;
	
	public boolean isInternal = true;
	public boolean isDuplicate = false;
	public boolean isInOrOutConnection = false;
	public boolean isLevelConnection = false;
	
	public String pinchState;
	public String widthState;
	public String editableState;
	
	public EdgeElement(String _id)
	{
		super(_id);
		points = new ArrayList<Point>();
		inputPort = new Port(id);
		inputPort.setEdge(this);
		outputPort = new Port(id);
		outputPort.setEdge(this);
	}
	
	public void setAttributes(String _pinchState, String _widthState, String _editableState)
	{
		pinchState = _pinchState;
		widthState = _widthState;
		editableState = _editableState;
	}
	
	public void updatePositionString()
	{
		StringBuffer buffer = new StringBuffer();
		buffer.append("e,");
		for(int i=0; i<points.size();i++)
		{
			Point point = points.get(i);
			buffer.append(point.x+","+point.y);
			if(i+1 != points.size())
				buffer.append(" ");
		}
		attributeMap.put("pos", new String(buffer));
	}
	
	public void writeElement(StringBuffer buffer)
	{
		if(!isInternal && !isDuplicate)
		{
			String fromNodeID = inputPort.connectedNode.id;
			String toNodeID = outputPort.connectedNode.id;
			buffer.append("<edge from=\"" + fromNodeID + "\" to=\"" + toNodeID + "\" isdirected=\"true\" id=\"" + fromNodeID + "--"+ toNodeID + "\">\r");
			writeAttributes(buffer);		
			buffer.append("</edge>\r");
		}
	}
	
	public void expandEdge(int xMultiplier, int yMultiplier) 
	{
		for(int i=0; i<points.size();i++)
		{
			Point point = points.get(i);
			point.x *= xMultiplier;
			point.y *= yMultiplier;
		}
	}
	
	public void setInputPort(Port _inputPort)
	{
		inputPort = _inputPort;
	}
	
	public void setOutputPort(Port _outputPort)
	{
		outputPort = _outputPort;
	}
	
	public void writeOutput(BufferedWriter out)
	{
		  try{
			  
			  out.write("<edge id=\""+id+"\">\r");
			  
			  if(!isInternal)
				  out.write("isInternal="+isInternal+"\r");
			  if(isInOrOutConnection)
				  out.write("isInOrOutConnection="+isInOrOutConnection+"\r");
			  if(isLevelConnection)
				  out.write("isLevelConnection="+isLevelConnection+"\r");
			  
			  out.write("</edge>\r");
			  //Close the output stream
		  }catch (Exception e){//Catch exception if any
			  System.err.println("Error: " + e.getMessage());
		  }
	}
	
	public void writeXMLElement(StringBuffer buffer)
	{
		EdgeElement edgeAttributes = ((EdgeSet)parent).edgeAttributes;
		
		buffer.append("<edge kind=\"CONNECT\" id=\"" + id + "\""
				+ " description=\"this\""
				+ " pinch=\"" + edgeAttributes.pinchState + "\""
				+ " editable=\"" + edgeAttributes.editableState + "\""
				+ " width=\"" + edgeAttributes.widthState + "\""
				+ ">\r");
		
		buffer.append("<from>\r");
		buffer.append("<noderef id=\"" + this.inputPort.connectedNode.id + "\" port=\"0\"/>\r");	
		buffer.append("</from>\r");

		buffer.append("<to>\r");
		buffer.append("<noderef id=\"" + this.outputPort.connectedNode.id + "\" port=\"0\"/>\r");	
		buffer.append("</to>\r");	
		
		buffer.append("</edge>\r");
	}
}
