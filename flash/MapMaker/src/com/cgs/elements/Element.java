package com.cgs.elements;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.Iterator;

public class Element
{
	public HashMap<String, String> attributeMap;
	
	public ArrayList<PortInfo> incomingPorts;
	public ArrayList<PortInfo> outgoingPorts;

	public int uniqueOutgoingPorts = 0;
	public int uniqueIncomingPorts = 0;
	
	public Rectangle boundingBox;

	public Element parent;
	public int nodeNumber;

	static int nodeCount = 0;
		
	Element()
	{
		attributeMap = new HashMap<String, String>();
		nodeNumber = nodeCount;
		nodeCount++;
		
		incomingPorts = new ArrayList<PortInfo>();
		outgoingPorts = new ArrayList<PortInfo>();
	}
	
	public void addAttribute(String key, String value)
	{
		attributeMap.put(key, value);
	}
	
	public void writeAttributes(StringBuffer buffer)
	{
		Iterator<String> iter = attributeMap.keySet().iterator();
		
		while (iter.hasNext()) {
			String key = iter.next();
			String val = attributeMap.get(key);

			buffer.append("<attr name=\"" + key + "\">\r");
			buffer.append("<string>" + val + "</string>\r");
			buffer.append("</attr>\r");
		}
	}
	
	public void addIncomingPort(String _number, String _nodeID)
	{
		incomingPorts.add(new PortInfo(_number, _nodeID));
	}
	
	public void addIncomingPort(PortInfo port)
	{
		incomingPorts.add(port);
	}
	
	public void addOutgoingPort(String _number, String _nodeID)
	{
		outgoingPorts.add(new PortInfo(_number, _nodeID));
	}
	
	public void addOutgoingPort(PortInfo port)
	{
		outgoingPorts.add(port);
	}
	
	public void parseBoundingBox()
	{
		if(boundingBox == null)
		{
			String bbString = attributeMap.get("bb");
	
			
			int firstComma = bbString.indexOf(',');
			int secondComma = bbString.indexOf(',', firstComma+1);
			int thirdComma = bbString.indexOf(',', secondComma+1);
				
			double x = new Double(bbString.substring(0,firstComma)).doubleValue();
			double y = new Double(bbString.substring(firstComma+1, secondComma)).doubleValue();
			double x2 = new Double(bbString.substring(secondComma+1, thirdComma)).doubleValue();
			double y2 = new Double(bbString.substring(thirdComma+1)).doubleValue();
			
			double width = x2 - x;
			double height = y2 - y;
			
			boundingBox = new Rectangle(x, y, width, height);

		}
	}
	
	void updateBoundingBoxString()
	{	
		attributeMap.put("bb", (Integer.toString(boundingBox.x)+','+Integer.toString(boundingBox.y)+','
			+Double.toString(boundingBox.x+boundingBox.width)+','+Double.toString(boundingBox.y+boundingBox.height)));
	}
	
	//parse position strings
	public void parsePosition()
	{
		if(boundingBox == null)
		{
			boundingBox = new Rectangle();
			String posString = attributeMap.get("pos");
	
			int comma = posString.indexOf(',');
			double x = new Double(posString.substring(0,comma)).doubleValue();
			double y = new Double(posString.substring(comma+1)).doubleValue();
			
			boundingBox = new Rectangle(x, y, 0, 0);
		}
	}
	
	//parse position strings
	public void parseSize()
	{
		if(boundingBox == null)
			boundingBox = new Rectangle();
			
		String heightString = attributeMap.get("height");
		if(heightString == null)
			heightString = "1";
		
		boundingBox.height = new Double(heightString).doubleValue();

		String widthString = attributeMap.get("width");
		if(widthString == null)
			widthString = "1";
		
		boundingBox.width = new Double(widthString).doubleValue();
	}
	
	void updatePositionString()
	{	
		attributeMap.put("pos", (Integer.toString(boundingBox.x)
							+','+Integer.toString(boundingBox.y)));
	}
	
	void updateHeightAndWidthString()
	{	
		attributeMap.put("width", (Double.toString(boundingBox.width)));
		attributeMap.put("height", (Double.toString(boundingBox.height)));
	}
	
	//make an even multiple of 10
	void normalizeXY()
	{
		boundingBox.x = boundingBox.x/10;
		boundingBox.x *= 10;
		boundingBox.y = boundingBox.y/10;
		boundingBox.y *= 10;
	}

}