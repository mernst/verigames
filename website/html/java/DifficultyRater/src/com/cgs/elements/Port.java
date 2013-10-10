package com.cgs.elements;

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
}
