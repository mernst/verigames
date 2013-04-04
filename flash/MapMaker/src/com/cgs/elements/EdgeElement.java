package com.cgs.elements;

import java.util.ArrayList;

import org.newdawn.slick.util.pathfinding.Path;

public class EdgeElement extends Element
{
	public String id;
	public String fromNodeID;
	public String toNodeID;
	
	public boolean isNormalized;
	public ArrayList<Point> points;
	
	Path path;
	
	public EdgeElement(String _id)
	{
		super();
		id = _id;
		points = new ArrayList<Point>();
	}
	
	public EdgeElement(String _id, String _fromNodeID, String _toNodeID)
	{
		super();
		id = _id;
		fromNodeID = _fromNodeID;
		toNodeID = _toNodeID;
		isNormalized = true;
		points = new ArrayList<Point>();
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
		if(points.size() > 1)
		{
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
}
