package com.cgs.elements;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.Iterator;
import java.util.Set;

public class Level extends Element
{
	public ArrayList<EdgeSet> edgesets;	
	public HashMap<String, NodeElement> nodes;
	public HashMap<String, EdgeElement> edges;
	
	public Rectangle boundingBox;
	
	public Level(String _id)
	{
		super(_id);
		edgesets = new ArrayList<EdgeSet>();
		nodes = new HashMap<String, NodeElement>();
		edges = new HashMap<String, EdgeElement>();

		boundingBox = new Rectangle();
	}
	
	public void addEdgeSet(EdgeSet edgeset)
	{
		edgesets.add(edgeset);
	}
	
	public void addNode(NodeElement node)
	{
		nodes.put(node.id, node);
		node.parent = this;
	}
	public void addEdge(EdgeElement edge)
	{
		edges.put(edge.id, edge);
	}
	
	public int nullFromNodeCount = 0;
	public int nullToNodeCount = 0;
	//run through all edges finding their attached nodes and edge sets.
	public void attachNodes()
	{

		for (EdgeElement edge : edges.values())
		{
			NodeElement fromNode = edge.inputPort.connectedNode;
			NodeElement toNode = edge.outputPort.connectedNode;
			
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
					EdgeElement connectedEdge = toNode.outputPorts.get(i).connectedEdge;
					if(!connectedEdge.parent.id.equals(edge.parent.id))
					{
						edge.isInternal = false;
					}					
				}				
			}
			else
				edge.isInOrOutConnection = true;
			
			if(edge.levelID != fromNode.levelID || edge.levelID != toNode.levelID)
			{
				System.out.println("is level connector " + edge.id);
				edge.isLevelConnection = true;
			}
		}
	}
	
	public void markStartEdgeSets()
	{
		  for(int i = 0; i<edgesets.size(); i++)
			{
				EdgeSet edgeSet = edgesets.get(i);
				edgeSet.markStart(nodes);
			}		
	}
	
	//searches recursively through the whole node tree
	public NodeElement findSubNode(String nodeID)
	{
		NodeElement foundNode = null;
		for(int index=0; index < nodes.size(); index++)
		{
			NodeElement node = nodes.get(index);
			if(node.id.compareTo(nodeID) == 0)
				foundNode = node;
			else
				foundNode = findSubNode(nodeID);
			
			if(foundNode != null)
				break;
		}
		
		return foundNode;
	}
	
	//searches for direct children only
	public NodeElement findChildNode(String nodeID)
	{
		for(int index=0; index < nodes.size(); index++)
		{
			NodeElement node = nodes.get(index);
			if(node.id.compareTo(nodeID) == 0)
				return node;
		}
		
		return null;
	}
	
	public void layoutNodes()
	{
		//layout internal shape of clusters first, to make sure they are the right size
		//currently all we do is resize
		LevelMap grid = new LevelMap(this);
		grid.sizeClusters();
		grid.assignRanks();
		grid.assignColumns();
		grid.adjustConnections();
		grid.adjustColumns();
		grid.layoutClusters();
		grid.setMapDimensions();
	}
	

	public void writeOutput(StringBuffer out)
	{
		  try{
			  
			  out.append("<level id=\""+id+"\">\r");
			  for(int i = 0; i<edgesets.size(); i++)
			  {
				  EdgeSet edgeset = edgesets.get(i);
				  edgeset.writeOutput(out);
			  }
			  
			  out.append("</level>\r");
			  //Close the output stream
		  }catch (Exception e){//Catch exception if any
			  System.err.println("Error: " + e.getMessage());
		  }
	}
	
	public void writeElement(StringBuffer out)
	{
		out.append("<level id=\""+id+"\" ");
		out.append(boundingBox.toAttributeString());
		out.append(">\r");
		for(int edgesetIndex = 0;edgesetIndex<edgesets.size(); edgesetIndex++)
		{
			EdgeSet edgeset = edgesets.get(edgesetIndex);
			edgeset.writeElement(out);
		}
		
		// outgoing edges are now written by the edgesets
//		Object[] edgeList = edges.values().toArray();
//		for(int edgeIndex = 0; edgeIndex < edges.values().size(); edgeIndex++)
//		{
//			EdgeElement edge = (EdgeElement)edgeList[edgeIndex];
//			edge.writeElement(out);
//		}
		out.append("</level>\r");
	}
	
	public void writeXMLElement(StringBuffer out)
	{
		out.append("<level name=\""+id+"\">\r");
		out.append("<linked-edges>\r");
		for(int edgesetIndex = 0;edgesetIndex<edgesets.size(); edgesetIndex++)
		{
			EdgeSet edgeset = edgesets.get(edgesetIndex);
			edgeset.writeXMLEdgeSetElement(out);
		}
		out.append("</linked-edges>\r");

		out.append("<boards>\r<board name=\"test\">\r");
		Set<String> nodeKeys = nodes.keySet();
		Iterator<String> iter = nodeKeys.iterator();
		while(iter.hasNext())
		{
			String key = iter.next();
			NodeElement node = nodes.get(key);

			node.writeXMLElement(out);
		}
		
		Set<String> edgeKeys = edges.keySet();
		Iterator<String> edgeIter = edgeKeys.iterator();
		while(edgeIter.hasNext())
		{
			String key = edgeIter.next();
			EdgeElement edge = edges.get(key);

			edge.writeXMLElement(out);
		}
		out.append("</board>\r</boards>\r");
		out.append("</level>\r");
	}

}