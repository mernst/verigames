package com.cgs.elements;

import java.util.HashMap;
import java.util.Iterator;

public class Element
{
	public String id;
	public HashMap<String, String> attributeMap;
	public Element parent;
	
	public int chainNumber;
		
	Element(String _id)
	{
		id = _id;
		attributeMap = new HashMap<String, String>();
	}
	
	public void addAttribute(String key, String value)
	{
		attributeMap.put(key, value);
	}
	
	public String getAttribute(String key)
	{
		return attributeMap.get(key);
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