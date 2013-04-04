package com.cgs;

import java.util.Hashtable;
import java.util.HashMap;
import java.util.Iterator;
import java.util.Map;
import java.util.Set;

import javax.xml.parsers.SAXParser;
import javax.xml.parsers.SAXParserFactory;

import org.xml.sax.Attributes;
import org.xml.sax.SAXException;
import org.xml.sax.helpers.DefaultHandler;

import com.cgs.elements.*;

public class ClusterFinder extends FileHandler
{
	protected Map<String,NodeElement> edgeIDtoNodeHashMap;
	protected Map<String, NodeElement> nodeHashMap;
	protected Map<String, EdgeElement> edgeHashMap;
	
	protected Hashtable<String, String> addedEdgeHashMap;

	/**
	 * @param args
	 * 
	 * read in xml file, drop anything below cluster level
	 * remap top level edges FROM node to node TO cluster to cluster
	 */
	public static void main(String[] args) {
		 ClusterFinder clusterFinder = new ClusterFinder(args[0], args[1]);
		  try{
			  clusterFinder.runSaxParser();
			  clusterFinder.organizeNodes();
			  clusterFinder.addMapFileStart();
			  clusterFinder.writeFileMain();
			  clusterFinder.addMapFileEnd();
			  
			  clusterFinder.writeMapFile();

		  }catch (Exception e){//Catch exception if any
			  System.err.println("Error: " + e.getMessage());
			  clusterFinder.writeMapFile();
		  }
	}
	
	public ClusterFinder(String filename, String outfilename)
	{
		super(filename, outfilename);
		
		edgeIDtoNodeHashMap = new HashMap<String, NodeElement>();
		nodeHashMap = new HashMap<String, NodeElement>();
		edgeHashMap = new HashMap<String, EdgeElement>();
		addedEdgeHashMap = new Hashtable<String, String>();
	
	}
	
	public void runSaxParser()
	{
		try {
			SAXParserFactory factory = SAXParserFactory.newInstance();
			factory.setFeature("http://apache.org/xml/features/nonvalidating/load-external-dtd", false);

			SAXParser saxParser = factory.newSAXParser();
			
			DefaultHandler handler = new DefaultHandler() {
				 
				boolean inInputNode = false; //false suggests we are in an output node
				boolean inFromNode = false;  //ditto...
				
				public void startElement(String uri, String localName,String qName, 
			                Attributes attributes) throws SAXException {
			 
					if (qName.equalsIgnoreCase("level")) {
						String levelName = attributes.getValue("name");
						currentLevel = new NodeElement(levelName);
						graph.addNode(currentLevel);
					}
					else if (qName.equalsIgnoreCase("edge-set")) {
						String id = attributes.getValue("id");
						currentNode = new NodeElement(id);
						currentLevel.addNode(currentNode);
					}
					else if (qName.equalsIgnoreCase("edgeref")) {
						String id = attributes.getValue("id");
						edgeIDtoNodeHashMap.put(id, currentNode);
						currentNode.addNode(new NodeElement(id));
					}
					 
					else if (qName.equalsIgnoreCase("input")) {
						inInputNode = true;
					}
					else if (qName.equalsIgnoreCase("output")) {
						inInputNode = false;
					}
					else if (qName.equalsIgnoreCase("port")) {
						String num = attributes.getValue("num");
						String edgeID = attributes.getValue("edge");
						if(inInputNode == true)
							currentNode.addIncomingPort(num, edgeID);
						else
							currentNode.addOutgoingPort(num, edgeID);
					}
					else if (qName.equalsIgnoreCase("node")) {
						String id = attributes.getValue("id");
						currentNode = new NodeElement(id);
					}
					else if (qName.equalsIgnoreCase("edge")) {
						String id = attributes.getValue("id");
						currentEdge = new EdgeElement(id);
						currentLevel.addEdge(currentEdge);
					}
					else if (qName.equalsIgnoreCase("from")) {
						inFromNode = true;
					}
					else if (qName.equalsIgnoreCase("to")) {
						inFromNode = false;
					}
					else if (qName.equalsIgnoreCase("noderef")) {
						String portID = attributes.getValue("port");
						String ID = attributes.getValue("id");
						if(inFromNode == true)
							currentEdge.addIncomingPort(portID, ID);
						else
							currentEdge.addOutgoingPort(portID, ID);
					}
				}
			 
				public void endElement(String uri, String localName,
					String qName) throws SAXException {
			 					 
					if (qName.equalsIgnoreCase("node")) {
						nodeHashMap.put(currentNode.id, currentNode);
					}
					else if (qName.equalsIgnoreCase("edge")) {
						edgeHashMap.put(currentEdge.id, currentEdge);
					}	 
				}
			};

			saxParser.parse(m_inFile, handler);
			
		  }catch (Exception e){//Catch exception if any
			  System.err.println("Error: " + e.getMessage());
		  }	 
	}
	
	//filter layer edges to remove all internal to edge set edges, and all duplicate edges from
	//x edge set to y edge set.
	// place in the addedEdgeHashMap map
	//also find for each node the number of incoming and the number of outgoing connections for size reasons
	public void organizeNodes()
	{
		Set<String> keys = edgeHashMap.keySet();
		
		String key;
		for(Iterator<String> iter = keys.iterator(); iter.hasNext();)
		{
			key = iter.next();
			EdgeElement elem = edgeHashMap.get(key);
			PortInfo portInfo = elem.outgoingPorts.get(0);
			NodeElement node = nodeHashMap.get(portInfo.ID);
			
			//we are ignoring both incoming and outgoing node types. Yes?
			if(node.outgoingPorts != null)
			{
				NodeElement keySet = edgeIDtoNodeHashMap.get(key);
				for(int index=0; index<node.outgoingPorts.size(); index++)
				{
					String edgeID = node.outgoingPorts.get(index).ID;
					NodeElement valueSet = edgeIDtoNodeHashMap.get(edgeID);
					if(keySet.id != valueSet.id)
					{
						//check to see if we've already added this edge
						String resultValue = addedEdgeHashMap.get(keySet.id + "->" + valueSet.id);
						if(resultValue == null)
						{
							addedEdgeHashMap.put(keySet.id + "->" + valueSet.id, valueSet.id);
							keySet.uniqueIncomingPorts++;
							valueSet.uniqueOutgoingPorts++;
						}
					}
				}
			}
		}
	}
	
	public void addMapFileStart()
	{
		outFileStringBuffer.append("digraph world {\r");
		outFileStringBuffer.append("graph [splines=ortho rankdir=LR ranksep=1 nodesep=1]\r");
		outFileStringBuffer.append("node [shape=rect height=1 width=1]\r");
	}
		
	public void writeFileMain()
	{
		for(int i = 0; i<graph.nodes.size(); i++)
		{
			NodeElement layer = graph.nodes.get(i);
			outFileStringBuffer.append("subgraph cluster_level_" + layer.id + "{\r");
			for(int nodeNum = 0; nodeNum<layer.nodes.size();nodeNum++)
			{
				NodeElement node = layer.nodes.get(nodeNum);
				outFileStringBuffer.append(node.id);
				int height = 1; 
				int width = 1;
				if(node.uniqueIncomingPorts > node.uniqueOutgoingPorts)
					height = node.uniqueIncomingPorts;
				else if (node.uniqueOutgoingPorts>0)
					height = node.uniqueOutgoingPorts;
				
				if(height > 1)
					outFileStringBuffer.append("[height=" + height + " width=" + width + "]");
				outFileStringBuffer.append("\r");
			}
			outFileStringBuffer.append("}\r");
		}
		
		Set<String> keys = addedEdgeHashMap.keySet();
		
		String key;
		for(Iterator<String> iter = keys.iterator(); iter.hasNext();)
		{
			key = iter.next();
			outFileStringBuffer.append(key + "\r");							
		}
	}
}
