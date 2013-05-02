package com.cgs.elements;

import java.util.HashMap;
import java.util.Iterator;

public class Element
{
	public HashMap<String, String> attributeMap;

	public String id;
	public Element parent;
	public int nodeNumber;

	static int nodeCount = 0;
		
	Element(String _id)
	{
		id = _id;
		attributeMap = new HashMap<String, String>();
		nodeNumber = nodeCount;
		nodeCount++;
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
}