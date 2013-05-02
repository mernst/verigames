import java.io.File;
import java.util.Collection;
import java.util.HashMap;
import java.util.Iterator;
import java.util.Map;

import javax.xml.parsers.SAXParser;
import javax.xml.parsers.SAXParserFactory;

import org.xml.sax.Attributes;
import org.xml.sax.SAXException;
import org.xml.sax.helpers.DefaultHandler;

import com.cgs.*;
import com.cgs.elements.*;
import com.cgs.file.GraphFile;

/*
 * steps to get this working, and why you do each step:
 * 1) generate xml from 'the system'
 * 		reason - well duh...
 * 2) run this code passing the input and output directory
 * the output consists of two files, the layout file, and the constraints file.
 * (And zipped copies of them.)
  */
public class MapMaker
{
	public HashMap<String, EdgeElement> edges;
	protected HashMap<String, String> addedEdgeHashMap;
	
	protected Graph graph;
	
	//used to build up current element
	protected Level currentLevel;
	protected EdgeSet currentEdgeSet;
	protected NodeElement currentNode;
	protected EdgeElement currentEdge;
	
	protected String attributeKey;
	protected boolean inNode = false;
	protected boolean inEdge = false;
		
	protected Map<String,EdgeSet> edgeIDtoEdgeSet;

	/**
	 * @param args
	 */
	public static void main(String arg[])
	{
	    try {
	 
			File inputFile = new File(arg[0]);
			File outputDirectory = null;
			if(arg.length < 1)
			{
				System.out.println("Usage: java -jar mapmaker.jar inputfile outputdirectory [-c(onstraints)]");
				return;
			}
			if(arg.length > 1)
				outputDirectory = new File(arg[1]);
			
			String newFileName = inputFile.getName();
			int index = newFileName.lastIndexOf('.');
			newFileName = newFileName.substring(0,index);
			
			if(!inputFile.isDirectory())
			{
				MapMaker mm = new MapMaker();

				String outFileName = newFileName+"Graph.xml";
				File outputFile = new File(outputDirectory, outFileName);
				mm.makeMaps(inputFile, outputFile);

				outFileName = newFileName+"Constraints.xml";
				outputFile = new File(outputDirectory, outFileName);
				mm.makeConstraints(inputFile, outputFile);
			}
			else
			{
				for (File file : inputFile.listFiles())
				{
					MapMaker mm = new MapMaker();
					String outFileName = newFileName+"Graph.xml";
					File outputFile = new File(outputDirectory, outFileName);
					mm.makeMaps(file, outputFile);

					outFileName = newFileName+"Constraints.xml";
					outputFile = new File(outputDirectory, outFileName);
					mm.makeConstraints(inputFile, outputFile);
				}

			}
			
			GraphFile zippedInputFile = new GraphFile(inputFile, new File(outputDirectory,inputFile.getName()));
			zippedInputFile.zipFileFromDisk();
			
	    }
	    catch(Exception e)
	    {
	    }
	}
	
	public MapMaker()
	{
		edgeIDtoEdgeSet = new HashMap<String, EdgeSet>();
		edges = new HashMap<String, EdgeElement>();
		graph = new Graph("world");
		
		addedEdgeHashMap = new HashMap<String, String>();
	}
	
	public void makeMaps(File inputFile, File outputFile)
	{
		  try{
			  if(inputFile.getName().indexOf(".xml") != -1)
			  {
				  runSaxParser(inputFile);
				  attachNodes();
				  removeDuplicateEdges(edges);
				  
				  LayoutHelper lh = new LayoutHelper();
				  lh.organizeNodes(graph); 
				  GraphFile gFile = new GraphFile(inputFile, outputFile);
				  gFile.writeLayoutFile(graph);
			  }

		  }catch (Exception e){//Catch exception if any
			  System.err.println("Error: " + e.getMessage());
		  }
	}
	
	public void makeConstraints(File inputFile, File outputFile)
	{
		  try{
			  if(inputFile.getName().indexOf(".xml") != -1)
			  {
				  runSaxParser(inputFile);
				  attachNodes();
				  removeDuplicateEdges(edges);
				  
				  ConstraintHelper ch = new ConstraintHelper();
				  ch.attachNodes();
				  ch.markStartEdgeSets(graph);
				  GraphFile gFile = new GraphFile(inputFile, outputFile);
				  gFile.writeConstraintsFile(graph);
			  }

		  }catch (Exception e){//Catch exception if any
			  System.err.println("Error: " + e.getMessage());
		  }
	}
		  
	public void runSaxParser(File inputFile)
	{
		try 
		{
			SAXParserFactory factory = SAXParserFactory.newInstance();
			factory.setFeature("http://apache.org/xml/features/nonvalidating/load-external-dtd", false);

			SAXParser saxParser = factory.newSAXParser();
			
			DefaultHandler handler = new DefaultHandler()
			{
				 
				boolean inInputNode = false; //false suggests we are in an output node
				boolean inFromNode = false;  //ditto...
				
				public void startElement(String uri, String localName,String qName, 
			                Attributes attributes) throws SAXException {
			 
					if (qName.equalsIgnoreCase("level")) {
						String levelName = attributes.getValue("name");
						currentLevel = new Level(levelName);
						graph.addLevel(currentLevel);
					}
					else if (qName.equalsIgnoreCase("edge-set")) {
						String id = attributes.getValue("id");
						currentEdgeSet = new EdgeSet(id);
						currentLevel.addEdgeSet(currentEdgeSet);
					}
					else if (qName.equalsIgnoreCase("edgeref")) {
						String id = attributes.getValue("id");
						edgeIDtoEdgeSet.put(id, currentEdgeSet);
						EdgeElement edge = new EdgeElement(id);
						edge.levelID = currentLevel.id;
						currentEdgeSet.addEdge(edge);
						edges.put(id, edge);
						edge.parent = currentEdgeSet;
					}
					else if (qName.equalsIgnoreCase("node")) {
						String id = attributes.getValue("id");
						String kind = attributes.getValue("kind");
						currentNode = new NodeElement(id, currentLevel.id, kind);
					}
					else if (qName.equalsIgnoreCase("input")) {
						inInputNode = true;
					}
					else if (qName.equalsIgnoreCase("output")) {
						inInputNode = false;
					}
					else if (qName.equalsIgnoreCase("port") || 
							qName.equalsIgnoreCase("subboardPort")) {
						String edgeID = attributes.getValue("edge");
						EdgeElement edge = edges.get(edgeID);
						if(inInputNode == true)
						{
							Port port = edge.outputPort;
							currentNode.addInputPort(port);
							port.setNode(currentNode);
						}
						else
						{
							Port port = edge.inputPort;
							currentNode.addOutputPort(port);
							port.setNode(currentNode);
						}
					}
					else if (qName.equalsIgnoreCase("edge")) {
						String id = attributes.getValue("id");
						currentEdge = edges.get(id);
						currentEdge.setAttributes(attributes.getValue("pinch"), attributes.getValue("width"), attributes.getValue("editable"));
						currentLevel.addEdge(currentEdge);
					}
					else if (qName.equalsIgnoreCase("from")) {
						inFromNode = true;
					}
					else if (qName.equalsIgnoreCase("to")) {
						inFromNode = false;
					}
					else if (qName.equalsIgnoreCase("noderef")) {
						//TODO: These are set by the edge, but subboard ports aren't handled yet
//						String portID = attributes.getValue("port");
//						String ID = attributes.getValue("id");
//						String boardNodeID = attributes.getValue("boardNodeID");
//						if(boardNodeID == null)
//							boardNodeID = portID;
//						if(inFromNode == true)
//							currentEdge.addIncomingPort(boardNodeID, ID);
//						else
//							currentEdge.addOutgoingPort(boardNodeID, ID);
					}
				}
			 
				public void endElement(String uri, String localName,
					String qName) throws SAXException {
			 					 
					if (qName.equalsIgnoreCase("node")) {
						currentLevel.addNode(currentNode);
					}
					else if (qName.equalsIgnoreCase("edge")) {
						currentLevel.addEdge(currentEdge);
					}	 
				}
			};

			saxParser.parse(inputFile, handler);
			
		}catch (Exception e){//Catch exception if any
			System.err.println("Error: " + e.getMessage());
		}	 
	}
	
	public void attachNodes()
	{
		graph.attachNodes();
	}
	
	//add edges to hashmap, if they don't exist, else edge as duplicate
	//also, tell input and output edges sets about the edge
	public void removeDuplicateEdges(HashMap<String, EdgeElement> edges)
	{
		Collection<EdgeElement> values = edges.values();
		
		EdgeElement edge;
		for(Iterator<EdgeElement> iter = values.iterator(); iter.hasNext();)
		{
			edge = iter.next();
			if(edge.outputPort.connectedNode != null)
			{
				NodeElement node = edge.outputPort.connectedNode;

				if(node.outputPorts != null)
				{
					for(int index=0; index<node.outputPorts.size(); index++)
					{
						EdgeElement outputEdge = node.outputPorts.get(index).connectedEdge;
						if(edge.parent.id != outputEdge.parent.id)
						{
							//check to see if we've already added this edge, if so, mark current as duplicate
							String resultValue = addedEdgeHashMap.get(edge.parent.id + "->" + outputEdge.parent.id);
							if(resultValue != null)
								edge.isDuplicate = true;
							else
							{
								addedEdgeHashMap.put(edge.parent.id + "->" + outputEdge.parent.id, edge.id);
								EdgeSetEdge edgeSetEdge = new EdgeSetEdge(edge.parent.id + "->" + outputEdge.parent.id,
										(EdgeSet)edge.parent, (EdgeSet)outputEdge.parent);
								((EdgeSet)edge.parent).addOutputEdgeSetEdge(edgeSetEdge);
								((EdgeSet)outputEdge.parent).addInputEdgeSetEdge(edgeSetEdge);
							}
						}
					}
				}
			}
			else
				System.out.println("ee"+edge.id);
		}
	}
}
