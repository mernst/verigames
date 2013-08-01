package com.cgs.elements;


import java.io.BufferedWriter;
import java.util.ArrayList;

public class Level extends Element
{
	protected ArrayList<EdgeSet> edgesets;	
		
	public Level(String _id)
	{
		super(_id);
		edgesets = new ArrayList<EdgeSet>();
	}
	
	public void addEdgeSet(EdgeSet edgeset)
	{
		edgesets.add(edgeset);
	}
	
	public void writeOutput(BufferedWriter out)
	{
		  try{
			  
			  out.write("<level id=\""+id+"\">\r");
			  for(int i = 0; i<edgesets.size(); i++)
				{
					EdgeSet edgeset = edgesets.get(i);
					edgeset.writeOutput(out);
				}
			  
			  out.write("</level>\r");
			  //Close the output stream
		  }catch (Exception e){//Catch exception if any
			  System.err.println("Error: " + e.getMessage());
		  }
	}

}