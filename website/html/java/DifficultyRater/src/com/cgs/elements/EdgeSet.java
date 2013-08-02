package com.cgs.elements;

import java.io.BufferedWriter;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.Map;

public class EdgeSet extends Element
{
	protected ArrayList<EdgeElement> edges;
	
	public EdgeSet(String _id)
	{
		super(_id);
		edges = new ArrayList<EdgeElement>();
	}
	
	public void addEdge(EdgeElement edge)
	{
		edges.add(edge);
	}
	
	public void writeOutput(BufferedWriter out)
	{
		  try{
			  
			  out.write("<edgeset id=\""+id+"\">\r");
			  for(int i = 0; i<edges.size(); i++)
				{
					EdgeElement edge = edges.get(i);
					edge.writeOutput(out);
				}
			  
			  out.write("</edgeset>\r");
			  //Close the output stream
		  }catch (Exception e){//Catch exception if any
			  System.err.println("Error: " + e.getMessage());
		  }
	}
}

