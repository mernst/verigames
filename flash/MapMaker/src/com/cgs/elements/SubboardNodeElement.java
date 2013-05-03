package com.cgs.elements;

public class SubboardNodeElement extends NodeElement
{
	public String boardID;
	
	public SubboardNodeElement(String _id, String _boardID)
	{
		super(_id);
		boardID = _boardID;
	}
}