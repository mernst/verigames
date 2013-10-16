package com.cgs.elements;

import java.util.ArrayList;
import java.util.HashMap;

public class Board extends Element {

	public ArrayList<NodeElement> subboards;
	
	public HashMap<String, Board> dependsOn;
	public HashMap<String, Board> dependedOn;
	
	public Level containerLevel;

	public Board(String _id) {
		super(_id);
		subboards = new ArrayList<NodeElement>();
		dependsOn = new HashMap<String, Board>();
		dependedOn = new HashMap<String, Board>();
	}
	
	public void addSubboard(NodeElement subboard)
	{
		subboards.add(subboard);
	}

}
