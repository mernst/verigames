import javax.xml.parsers.DocumentBuilderFactory;
import javax.xml.parsers.DocumentBuilder;
import javax.xml.parsers.SAXParser;
import javax.xml.parsers.SAXParserFactory;

import org.w3c.dom.Document;
import org.w3c.dom.NodeList;
import org.w3c.dom.Node;
import org.w3c.dom.Element;
import org.xml.sax.Attributes;
import org.xml.sax.SAXException;
import org.xml.sax.helpers.DefaultHandler;

import com.cgs.elements.EdgeElement;
import com.cgs.elements.EdgeSet;
import com.cgs.elements.Level;
import com.cgs.elements.NodeElement;
import com.cgs.elements.Port;

import java.io.File;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.Vector;

public class DifficultyRater {

	String inputFileName;
	String outputFileName;

	ArrayList<Level> levels;
	protected HashMap<String, NodeElement> nodes;
	protected HashMap<String, EdgeElement> edges;
	protected Vector<EdgeElement> edgeVector;
	
	//used to build up current element
	protected Level currentLevel;
	protected EdgeSet currentEdgeSet;
	protected NodeElement currentNode;
	protected EdgeElement currentEdge;
	
	protected String attributeKey;
	protected boolean inNode = false;
	protected boolean inEdge = false;
	
	/**
	 * @param args
	 */
	public static void main(String[] args) {
		// TODO Auto-generated method stub
		File root = new File(args[0]);
		if(root.isDirectory())
		{
			int count = 0;
			File[] listOfFiles = root.listFiles();
	
			for (File file : listOfFiles) {
			    if (file.isFile()) {
			    	count++;
			 //   	System.out.println(count);
			        System.out.println("<file name=\""+file.getName()+"\" ");
			        DifficultyRater rater = new DifficultyRater(args);
					rater.parseFile(file);
					rater.rateFile();
					System.out.println("/>");
			    }
			}
		}
		else
		{
	        System.out.println("<file name=\""+root.getName()+"\" ");
	        DifficultyRater rater = new DifficultyRater(args);
			rater.parseFile(root);
			rater.rateFile();
			System.out.println("</file>");
			
		}
	}
	
	public DifficultyRater(String[] args)
	{
		inputFileName = args[0];
		
		levels = new ArrayList<Level>();
		nodes = new HashMap<String, NodeElement>();
		edges = new HashMap<String, EdgeElement>();
		edgeVector = new Vector<EdgeElement>();
	}
	
	public void parseFile(File fXmlFile) 
	{ 
		try {
			
			SAXParserFactory factory = SAXParserFactory.newInstance();
			//factory.setFeature("http://apache.org/xml/features/nonvalidating/load-external-dtd", false);

			SAXParser saxParser = factory.newSAXParser();
			
			DefaultHandler handler = new DefaultHandler() {
				 
				boolean inInputNode = false; //false suggests we are in an output node
				boolean inFromNode = false;  //ditto...
				
				public void startElement(String uri, String localName,String qName, 
			                Attributes attributes) throws SAXException {
			 
					if (qName.equalsIgnoreCase("level")) {
						String levelName = attributes.getValue("name");
						currentLevel = new Level(levelName);
						levels.add(currentLevel);
					}
					else if (qName.equalsIgnoreCase("edge-set")) {
						String id = attributes.getValue("id");
						currentEdgeSet = new EdgeSet(id);
						currentLevel.addEdgeSet(currentEdgeSet);
					}
					else if (qName.equalsIgnoreCase("edgeref")) {
						String id = attributes.getValue("id");
						currentEdge = new EdgeElement(currentEdgeSet, id, currentLevel.id);
						currentEdgeSet.addEdge(currentEdge);
						edges.put(id, currentEdge);
						edgeVector.add(currentEdge);
					}
					else if (qName.equalsIgnoreCase("input")) {
						inInputNode = true;
					}
					else if (qName.equalsIgnoreCase("output")) {
						inInputNode = false;
					}
					else if (qName.equalsIgnoreCase("port")) {
						String edgeID = attributes.getValue("edge");
						if(inInputNode == true)
							currentNode.addInputPort(edgeID);
						else
							currentNode.addOutputPort(edgeID);
					}
					else if (qName.equalsIgnoreCase("node")) {
						String id = attributes.getValue("id");
						currentNode = new NodeElement(id, currentLevel.id);
						nodes.put(id, currentNode);
						for(int i = 0; i<attributes.getLength(); i++)
						{
							String key = attributes.getLocalName(i);
							String value = attributes.getValue(i);
							currentNode.addAttribute(key, value);
						}
					}
					else if (qName.equalsIgnoreCase("edge")) {
						String id = attributes.getValue("id");
						//lookup the edge, and copy attributes
						currentEdge = edges.get(id);
						for(int i = 0; i<attributes.getLength(); i++)
						{
							String key = attributes.getLocalName(i);
							String value = attributes.getValue(i);
							currentEdge.addAttribute(key, value);
						}
					}
					else if (qName.equalsIgnoreCase("from")) {
						inFromNode = true;
					}
					else if (qName.equalsIgnoreCase("to")) {
						inFromNode = false;
					}
					else if (qName.equalsIgnoreCase("noderef")) {
						String ID = attributes.getValue("id");
						if(inFromNode == true)
							currentEdge.setInputNode(ID);
						else
							currentEdge.setOutputNode(ID);
					}
				}
			 
				public void endElement(String uri, String localName,
					String qName) throws SAXException {
					 
				}
			};

			saxParser.parse(fXmlFile, handler);
			
		}catch (Exception e){//Catch exception if any
			System.err.println("Error: " + e.getMessage());
		}	
	  }
	
	public void rateFile()
	{
		int conflictCount = 0;
		for(int i = 0; i<edgeVector.size(); i++)
		{
			EdgeElement edge = edgeVector.get(i);
			NodeElement toNode = nodes.get(edge.toNodeID);
			for(int j = 0; j<toNode.outputPorts.size(); j++)
			{
				String outputEdgeID = toNode.outputPorts.get(j);
				EdgeElement outgoingEdge = edges.get(outputEdgeID);
				
				String incomingWidth = edge.getAttribute("width");
				String outgoingWidth = outgoingEdge.getAttribute("width");
				String nodeType = toNode.getAttribute("kind");
				if(incomingWidth.equals("wide") && outgoingWidth.equals("narrow"))
				{
					//System.out.println("conflict Node Type " + nodeType + " " + edge.id + " " + outgoingEdge.id);
					conflictCount++;
				}
			}
		}
		
		System.out.println("nodes=\"" + nodes.size() + "\" edges=\"" + edges.size()+"\" conflicts=\""+conflictCount+"\"");
		if(conflictCount > 0 && nodes.size()<100)
			System.out.println("Ding");
	}

}
