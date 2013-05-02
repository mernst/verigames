package com.cgs.file;

import java.io.File;

import com.cgs.elements.Graph;

public class GraphFile extends BaseFile {

	public GraphFile(File inFile, File outFile)
	{
		super(inFile, outFile);
	}
	
	public void writeLayoutFile(Graph graph)
	{
		graph.writeLayoutFile(outFileStringBuffer);
		  
		writeFile(true);
	}
	
	public void writeConstraintsFile(Graph graph)
	{
		graph.writeConstraintsFile(outFileStringBuffer);
		  
		writeFile(true);
	}
	
	public void writeXMLFile(Graph graph)
	{
		graph.writeXMLFile(outFileStringBuffer);
		  
		writeFile(true);
	}
}
