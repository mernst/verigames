package com.cgs;


import java.io.File;
import java.io.FileNotFoundException;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Calendar;

import javax.xml.parsers.SAXParser;
import javax.xml.parsers.SAXParserFactory;

import org.xml.sax.Attributes;
import org.xml.sax.SAXException;
import org.xml.sax.helpers.DefaultHandler;
import com.cgs.elements.*;


public class LayoutHelper  extends FileHandler
{	
	StringBuilder builder;
	
	/**
	 * @param args
	 * @throws FileNotFoundException 
	 */
	public static void main(String[] args) throws FileNotFoundException {
		
		File f = new File(args[0]);
		if(args.length != 2 || f.exists() == false)
			throw new FileNotFoundException("Missing 2 args, or file not found" + args[0]);
		
		 LayoutHelper layoutHelper = new LayoutHelper(args[0], args[1]);
		  try{
			  layoutHelper.runSaxParser();
			  layoutHelper.organizeNodes();
			  layoutHelper.addMapFileStart();
			  layoutHelper.writeFileMain();
			  layoutHelper.addMapFileEnd();
			  
			  layoutHelper.writeMapFile();

		  }catch (Exception e){//Catch exception if any
			  System.err.println("Error: " + e.getMessage());
			  layoutHelper.writeMapFile();
		  }
	}
	
	public LayoutHelper(String filename, String outFileName)
	{
		super(filename, outFileName);
	}
	
	public void runSaxParser()
	{
		try {
			SAXParserFactory factory = SAXParserFactory.newInstance();
			factory.setFeature("http://apache.org/xml/features/nonvalidating/load-external-dtd", false);

			SAXParser saxParser = factory.newSAXParser();
			
			DefaultHandler handler = new DefaultHandler()
			{				
				public void startElement(String uri, String localName,String qName, 
			                Attributes attributes) throws SAXException {
			 
					if (qName.equalsIgnoreCase("node")) {
						String nodeName = attributes.getValue("id");
						if(nodeName.indexOf("_level_") != -1)
						{
							currentLevel = new LevelElement(nodeName);
							currentNode = currentLevel; 
							graph.addNode(currentLevel);
							inNode = true;
						}
						else
						{
							currentNode = new NodeElement(nodeName);
							currentLevel.addNode(currentNode);
							nodeMap.put(nodeName, currentNode);
							inNode = true;
						}

					}
					else if (qName.equalsIgnoreCase("edge")) {
						String id = attributes.getValue("id");
						String fromNode = attributes.getValue("from");
						String toNode = attributes.getValue("to");
						currentEdge = new EdgeElement(id, fromNode, toNode);
						currentLevel.addEdge(currentEdge);
						inEdge = true;
					}
					else if (qName.equalsIgnoreCase("attr")) {
						attributeKey = attributes.getValue("name");
					}
					else if (qName.equalsIgnoreCase("string")) {
						builder = new StringBuilder();
					}
				}
				
				public void characters(char[] ch, int start, int length) {
					if(builder != null)
					   builder.append(ch,start,length);
					}

			 
				public void endElement(String uri, String localName,
					String qName) throws SAXException {
			 					 
					if (qName.equalsIgnoreCase("node")) {
						if(inNode)
							inNode = false;
						
						currentNode = currentLevel;
					}
					else if (qName.equalsIgnoreCase("edge")) {
						inEdge = false;
					}
					else if (qName.equalsIgnoreCase("string")) {
						String value = builder.toString();
						if(inNode)
							currentNode.addAttribute(attributeKey, value);
						else if(inEdge)
							currentEdge.addAttribute(attributeKey, value);
						else
							System.out.println("no node");
						inEdge = false;
					}
				}
			};

			//set initial values
			inNode = true;
			currentNode = graph;
			saxParser.parse(m_inFile, handler);
			
		  }catch (Exception e){//Catch exception if any
			  System.err.println("Error: " + e.getMessage());
		  }	 
	}
	
	public void organizeNodes()
	{
		//lays out nodes where they should be, size and position
		//	based on input gxl file that gives size and relative positions
		
		Calendar cal = Calendar.getInstance();
    	cal.getTime();
    	SimpleDateFormat sdf = new SimpleDateFormat("HH:mm:ss");
    	System.out.println( "starting " + sdf.format(cal.getTime()) );
    	
		graph.parseBoundingBox();
		
		int currentYPosition = 0;
		for(int i = 0; i<graph.nodes.size(); i++)
		{
			NodeElement level = graph.nodes.get(i);
			level.setupLevel();
			level.shiftNodeAndChildren(-level.boundingBox.x+10, -level.boundingBox.y+10);
			level.layoutClusters();
			level.layoutTopLevelEdges();
			level.expandLevel();
			level.shiftNodeAndChildren(level.boundingBox.x, currentYPosition);
			level.writeBackPositions();
			currentYPosition += level.boundingBox.height;
			level.cleanUp();
			
			cal.getTime();
	    	SimpleDateFormat sdf1 = new SimpleDateFormat("HH:mm:ss:SSS");
		   	System.out.println( "done with " + i + " level at "+ sdf1.format(cal.getTime()) );
		    
		}	
	}

	public void addMapFileStart()
	{
		outFileStringBuffer.append("<?xml version=\"1.0\" encoding=\"iso-8859-1\"?>\r<gxl>\r");
		outFileStringBuffer.append("<graph id=\"world\" edgeids=\"true\" edgemode=\"directed\">\r");
	}
	
	public void addMapFileEnd()
	{
		outFileStringBuffer.append("</graph>\r</gxl>\r");
	}
	
	public void writeFileMain()
	{		
		graph.writeAttributes(outFileStringBuffer);
		
		ArrayList<NodeElement> levels = graph.nodes;
		for(int levelIndex = 0; levelIndex<levels.size(); levelIndex++)
		{
			NodeElement level = levels.get(levelIndex);
			level.writeElement(outFileStringBuffer);
		}
	}
}
