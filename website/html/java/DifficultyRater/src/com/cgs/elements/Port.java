package com.cgs.elements;

import java.io.PrintWriter;

public class Port extends Element 
{
	String portNum;
	public Port( String _edgeID)
	{
		super(_edgeID);
	}
	
	public Port( String _edgeID, String _portNum)
	{
		super(_edgeID);
		portNum = _portNum;
	}
	
	public void write(PrintWriter printWriter)
	{
		printWriter.println("<port num=\"" + portNum + "\" edge=\"" + id + "\"/>");
	}
}
