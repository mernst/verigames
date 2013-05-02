package com.cgs.elements;

import java.util.Hashtable;

public class BoardInfo
{
	public String boardName;
	public String levelName;
	private Hashtable<String, String> incomingPortToEdgeIdHashMap;
	private Hashtable<String, String> outgoingPortToEdgeIdHashMap;
	
	public BoardInfo(String _boardName, String _levelName)
	{
		boardName = _boardName;
		levelName = _levelName;
		incomingPortToEdgeIdHashMap = new Hashtable<String, String>();
		outgoingPortToEdgeIdHashMap = new Hashtable<String, String>();
	}
	
	public void associateIncomingEdgeId(String portNum, String edgeID)
	{
		incomingPortToEdgeIdHashMap.put(portNum, edgeID);
	}
	
	public void associateOutgoingEdgeId(String portNum, String edgeID)
	{
		outgoingPortToEdgeIdHashMap.put(portNum, edgeID);
	}
	
	public String getEdgeIdForIncomingPort(String portNum)
	{
		return incomingPortToEdgeIdHashMap.get(portNum);
	}
	
	public String getEdgeIdForOutgoingPort(String portNum)
	{
		return outgoingPortToEdgeIdHashMap.get(portNum);
	}
}
