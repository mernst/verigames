package com.cgs;

import java.util.ArrayList;
import java.util.HashMap;

import com.cgs.elements.*;

public class ConstraintHelper {

	ArrayList<Level> levels;
	protected HashMap<String, NodeElement> nodes;
	protected HashMap<String, EdgeElement> edges;
	

	public ConstraintHelper()
	{		
		levels = new ArrayList<Level>();
		nodes = new HashMap<String, NodeElement>();
		edges = new HashMap<String, EdgeElement>();
	}
	
	public int nullFromNodeCount = 0;
	public int nullToNodeCount = 0;
	//run through all edges finding their attached nodes and edge sets.
	public void attachNodes()
	{
		for (EdgeElement edge : edges.values()) {
			NodeElement fromNode = edge.outputPort.connectedNode;
			NodeElement toNode = edge.inputPort.connectedNode;
			
			if(fromNode != null && fromNode.inputPorts.size() > 0)
			{
				for(int i = 0; i< fromNode.inputPorts.size(); i++)
				{
					EdgeElement connectedEdge = fromNode.inputPorts.get(i).connectedEdge;
					if(!connectedEdge.parent.id.equals(edge.parent.id))
					{
						edge.isInternal = false;
					}
				}
			}
			else
				edge.isInOrOutConnection = true;
			if(toNode != null && toNode.outputPorts.size() > 0)
			{
				for(int i = 0; i< toNode.outputPorts.size(); i++)
				{
					EdgeElement connectedEdge = fromNode.outputPorts.get(i).connectedEdge;
					if(!connectedEdge.parent.id.equals(edge.parent.id))
					{
						edge.isInternal = false;
					}					
				}				
			}
			else
				edge.isInOrOutConnection = true;
			
			if(edge.levelID != fromNode.levelID || edge.levelID != toNode.levelID)
				edge.isLevelConnection = true;
		}
	}
	
	public void markStartEdgeSets(Graph graph)
	{
		  for(int i = 0; i<graph.levels.size(); i++)
			{
				Level level = graph.levels.get(i);
				level.markStartEdgeSets();
			}		
	}
}
