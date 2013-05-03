package com.cgs;

import java.io.BufferedWriter;
import java.io.FileWriter;
import java.util.HashMap;

import com.cgs.elements.*;

public class FileHandler {

	String m_inFile;
	String m_outFile;
	
	public HashMap<String, NodeElement> nodeMap;

	protected NodeElement graph;
	
	//used to build up current element
	protected BoardInfo currentBoard;
	protected NodeElement currentNode;
	protected EdgeElement currentEdge;
	
	protected String attributeKey;
	protected boolean inNode = false;
	protected boolean inEdge = false;
	
	StringBuffer outFileStringBuffer;
	
	
	public FileHandler(String inFile, String outFile)
	{
		m_inFile = inFile;
		m_outFile = outFile;
		
		outFileStringBuffer = new StringBuffer();
		
		graph = new NodeElement("world");
		nodeMap = new HashMap<String, NodeElement>();

	}
	
	public void runSaxParser()
	{

	}
	
	public void organizeNodes()
	{
		
	}

	public void addMapFileStart()
	{
		outFileStringBuffer.append("digraph world {\r");
		outFileStringBuffer.append("graph [splines=ortho rankdir=LR ranksep=1 nodesep=1]\r");
		outFileStringBuffer.append("node [shape=rect height=2 width=1]\r");
	}
	
	public void writeFileMain()
	{
	}
	
	public void addMapFileEnd()
	{
		outFileStringBuffer.append("}\r");
	}
	
	public void writeMapFile()
	{
		  try{
			  // Create file 
			  FileWriter fstream = new FileWriter(m_outFile);
			  BufferedWriter out = new BufferedWriter(fstream);

			  out.write(new String(outFileStringBuffer));
			  //Close the output stream
			  out.close();
		  }catch (Exception e){//Catch exception if any
			  System.err.println("Error: " + e.getMessage());
		  }
	}
}
