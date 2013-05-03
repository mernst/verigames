package com.cgs.elements;

import java.util.Hashtable;

public class BoardInfo
{
	public String boardName;
	public String levelName;
	private Hashtable<String, Port> incomingPortHashMap;
	private Hashtable<String, Port> outgoingPortHashMap;
	
	public BoardInfo(String _boardName, String _levelName)
	{
		boardName = _boardName;
		levelName = _levelName;
		incomingPortHashMap = new Hashtable<String, Port>();
		outgoingPortHashMap = new Hashtable<String, Port>();
	}
	
	public void associateIncomingPort(Port port)
	{
		incomingPortHashMap.put(port.portNumber, port);
	}
	
	public void associateOutgoingPort(Port port)
	{
		outgoingPortHashMap.put(port.portNumber, port);
	}
	
	public Port getIncomingPort(String portNum)
	{
		return incomingPortHashMap.get(portNum);
	}
	
	public Port getOutgoingPort(String portNum)
	{
		return outgoingPortHashMap.get(portNum);
	}
}
