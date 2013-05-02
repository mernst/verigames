package com.cgs.elements;

import java.util.ArrayList;

import com.cgs.elements.Level;

public class Graph extends Element
{
	public ArrayList<Level> levels;
	public Graph(String _id)
	{
		super(_id);
		levels = new ArrayList<Level>();
	}

	public void addLevel(Level level)
	{
		levels.add(level);
	}
	
	public void attachNodes()
	{
		for(int levelIndex = 0;levelIndex<levels.size(); levelIndex++)
		{
			Level level = levels.get(levelIndex);
			level.attachNodes();
		}
	}
	
	public void writeXMLFile(StringBuffer out)
	{
		out.append("<world>\r");

		for(int levelIndex = 0;levelIndex<levels.size(); levelIndex++)
		{
			Level level = levels.get(levelIndex);
			level.writeXMLElement(out);
		}
		out.append("</world>\r");
	}
	
	public void writeLayoutFile(StringBuffer out)
	{
		out.append("<graph " + "id=\"" + id + "\">\r");

		for(int levelIndex = 0;levelIndex<levels.size(); levelIndex++)
		{
			Level level = levels.get(levelIndex);
			level.writeElement(out);
		}
		out.append("</graph>\r");
	}
	
	public void writeConstraintsFile(StringBuffer out)
	{
		out.append("<graph " + "id=\"" + id + "\">\r");

		for(int levelIndex = 0;levelIndex<levels.size(); levelIndex++)
		{
			Level level = levels.get(levelIndex);
			level.writeOutput(out);
		}
		out.append("</graph>\r");
	}
}
