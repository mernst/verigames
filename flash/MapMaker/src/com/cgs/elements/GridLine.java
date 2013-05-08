package com.cgs.elements;

import java.io.BufferedWriter;

//Container for edges that connect edge sets
public class GridLine extends EdgeElement
{
	public static String OUTPUT_XML_TAG = "edge";
	
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
	
	public String getFromID()
	{
		if (jointToEdgeSet) {
			return joint.id;
		} else {
			return edgeSet.id;
		}
	}
	
	public String getToID()
	{
		if (jointToEdgeSet) {
			return edgeSet.id;
		} else {
			return joint.id;
		}
	}
	
	public void writeElement(StringBuffer buffer)
	{
		String fromID = getFromID();
		String toID = getToID();
		buffer.append("<"+OUTPUT_XML_TAG+" from=\"" + fromID + "\" to=\"" + toID + "\" isdirected=\"true\" jointToBox=\""+jointToEdgeSet.toString()+"\" id=\"" + fromID + "--"+ toID + "\">\r");
		
		writeAttributes(buffer);		
		buffer.append("</"+OUTPUT_XML_TAG+">\r");
	}
	
	public void writeOutput(BufferedWriter out)
	{
		  try{
			  
			  out.write("<"+OUTPUT_XML_TAG+" id=\""+id+"\">\r");
			  
			  if(!isInternal)
				  out.write("isInternal="+isInternal+"\r");
			  if(isInOrOutConnection)
				  out.write("isInOrOutConnection="+isInOrOutConnection+"\r");
			  if(isLevelConnection)
				  out.write("isLevelConnection="+isLevelConnection+"\r");
			  
			  out.write("</"+OUTPUT_XML_TAG+">\r");
			  //Close the output stream
		  }catch (Exception e){//Catch exception if any
			  System.err.println("Error: " + e.getMessage());
		  }
	}
	
}
