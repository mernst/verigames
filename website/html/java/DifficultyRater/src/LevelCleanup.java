import javax.xml.parsers.DocumentBuilder;
import javax.xml.parsers.DocumentBuilderFactory;
import javax.xml.parsers.SAXParser;
import javax.xml.parsers.SAXParserFactory;
import javax.xml.transform.Result;
import javax.xml.transform.Source;
import javax.xml.transform.Transformer;
import javax.xml.transform.TransformerFactory;
import javax.xml.transform.dom.DOMSource;
import javax.xml.transform.stream.StreamResult;

import org.w3c.dom.Document;
import org.w3c.dom.Element;
import org.w3c.dom.Node;
import org.w3c.dom.NodeList;
import org.xml.sax.Attributes;
import org.xml.sax.SAXException;
import org.xml.sax.helpers.DefaultHandler;

import com.cgs.elements.EdgeElement;
import com.cgs.elements.EdgeSet;
import com.cgs.elements.Level;
import com.cgs.elements.NodeElement;
import com.cgs.elements.Port;

import java.io.File;
import java.io.PrintWriter;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.Vector;

public class LevelCleanup {

    File layoutFile;
    File constraintsFile;
    String outputFileName;
    static File outputFile;
    static PrintWriter printWriter;
    static File countFile;
    static PrintWriter countPrintWriter;
    static File outputDirectory;
    
    ArrayList<Level> levels;
    protected HashMap<String, NodeElement> nodes;
    protected HashMap<String, EdgeElement> edges;
    protected Vector<NodeElement> nodeVector;
    protected Vector<EdgeElement> edgeVector;
    
    //used to build up current element
    protected Level currentLevel;
    protected NodeElement currentNode;
    protected EdgeElement currentEdge;

    Vector<Vector<NodeElement>> nodeChains;
    Vector<ChainInfo> chainInfo;
    
    int editableChainCount;
	int editableNodes;
	int uneditableChainCount;
	int uneditableNodes;
	int visibleNodes;
	int visibleEdges;
	
	int totalConflicts;
	int totalBonusNodes;
	
	int numChainsWithConflicts;
	int longestChainSizeWithConflict;
	int numNodesWithConflictInChain;
	
    int currentChainNumber;
	static int mostNumConflicts;
	static int totalEditableChains;
	static int totalUneditableChains;
	
	static String scriptName = "";
	
        /**
         * @param args
         */
        public static void main(String[] args) {

 
        	if(args.length != 3)
        	{
        		System.out.println("Usage: java -jar DifficultyRater.jar sourcedir outputdir typecheckerscriptname");
        		return;
        	}
            try{

               File root = new File(args[0]);
                outputDirectory = new File(args[1]);
                scriptName = args[2];
                outputFile = new File(outputDirectory + "/conflicts.txt");
                printWriter = new PrintWriter(outputFile);
                countFile = new File(outputDirectory + "/difficultyratings.xml");
                countPrintWriter = new PrintWriter(countFile);
                countPrintWriter.println("<files>");
                
                if(root.isDirectory())
                {
                        File[] listOfFiles = root.listFiles();
        
                        for (File file : listOfFiles) {
                            if (file.isFile()) {
                                    if(file.getName().endsWith("Layout.xml"))
                                    {
                                        handleFile(file);
                                    }
                            }
                        }
                }
                else
                {
                	if(root.getName().endsWith("Layout.xml"))
                		handleFile(root);
                        
                }
                
                printWriter.flush();
                printWriter.close();
                countPrintWriter.println("</files>");
                countPrintWriter.flush();
                countPrintWriter.close();
                }
            catch(Exception e)
            {
               System.out.println(e);     
            }
        }
        
        public static void handleFile(File file)
        {
        	 
             String layoutFileName = file.getPath();
             int strLen = layoutFileName.length();
             String constraintsFileName = file.getPath().substring(0, strLen-10) + "Constraints.xml";
             File constraintsFile = new File(constraintsFileName);
             LevelCleanup rater = new LevelCleanup(file, constraintsFile);
         	 
            rater.parseLayoutFile();
             rater.parseConstraintsFile();
             rater.connectNodes();
             
            rater.checkChains();
            rater.outputLayout(file, outputDirectory);
            
            rater.reportOnFile(file);
            printWriter.print(mostNumConflicts + " " + totalEditableChains + " " + totalUneditableChains);
            
            
        }
        
        public LevelCleanup(File layoutFile, File constraintsFile)
        {
                try{
                this.layoutFile = layoutFile;
                this.constraintsFile = constraintsFile;
                               
                levels = new ArrayList<Level>();
                nodes = new HashMap<String, NodeElement>();
                edges = new HashMap<String, EdgeElement>();
                nodeVector = new Vector<NodeElement>();
                edgeVector = new Vector<EdgeElement>();
                
                nodeChains = new Vector<Vector<NodeElement>>();
                chainInfo = new Vector<ChainInfo>();
                
                visibleNodes = 0;
                visibleEdges = 0;
                totalConflicts = 0;
                totalBonusNodes = 0;
                }
                catch(Exception e)
                {
                        
                }
        }
        
        public void parseLayoutFile() 
        { 
                try {
                        
                        SAXParserFactory factory = SAXParserFactory.newInstance();
                        //factory.setFeature("http://apache.org/xml/features/nonvalidating/load-external-dtd", false);

                        SAXParser saxParser = factory.newSAXParser();
                        
                        DefaultHandler handler = new DefaultHandler() {
                                                               
                                public void startElement(String uri, String localName,String qName, 
                                        Attributes attributes) throws SAXException {
                         
                                        if (qName.equalsIgnoreCase("level")) {
                                                String levelName = attributes.getValue("id");
                                                currentLevel = new Level(levelName);
                                                levels.add(currentLevel);
                                        }
                                        else if (qName.equalsIgnoreCase("box") || qName.equalsIgnoreCase("joint")) {
                                                String nodeName = attributes.getValue("id");
                                                currentNode = new NodeElement(nodeName, currentLevel.id);
                                                nodes.put(nodeName, currentNode);
                                                nodeVector.add(currentNode);
                                                if(qName.equalsIgnoreCase("box"))
                                                        currentNode.isBox = true;
                                        }
                                        else if (qName.equalsIgnoreCase("line")) {
                                                String id = attributes.getValue("id");
                                                currentEdge = new EdgeElement(null, id, currentLevel.id);
                                                edges.put(id, currentEdge);
                                                edgeVector.add(currentEdge);
                                        }
                                        else if (qName.equalsIgnoreCase("fromjoint") || qName.equalsIgnoreCase("frombox")) {
                                                String nodeID = attributes.getValue("id");
                                                NodeElement elem = nodes.get(nodeID);
                                                if(elem != null)
                                                {
                                                        elem.addOutputPort(currentEdge.id);
                                                        currentEdge.fromNodeID = nodeID;
                                                }
                                                else
                                                        printWriter.println("missing node "+ nodeID);
                                        }
                                        else if (qName.equalsIgnoreCase("tojoint") || qName.equalsIgnoreCase("tobox")) {
                                            String nodeID = attributes.getValue("id");
                                            String portID = attributes.getValue("port");
                                            NodeElement elem = nodes.get(nodeID);
                                            if(elem != null)
                                            {
                                                    elem.addInputPort(currentEdge.id);
                                                    currentEdge.toNodeID = nodeID;
                                            }
                                            else
                                                    printWriter.println("missing node "+ nodeID);
                                    }
                                }
                         
                                public void endElement(String uri, String localName,
                                        String qName) throws SAXException {
                                         
                                }
                        };

                        saxParser.parse(layoutFile, handler);
                        
                }catch (Exception e){//Catch exception if any
                        System.err.println("Error: " + e.getMessage());
                }        
          }
        
        public void parseConstraintsFile() 
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
             
                        if (qName.equalsIgnoreCase("box"))
                        {
                            String nodeID = attributes.getValue("id");
                            NodeElement elem = nodes.get(nodeID);
                            if(elem != null)
                            {
                                    String width = attributes.getValue("width");
                                    String editable = attributes.getValue("editable");
                                    elem.isWide = width.equals("wide") ? true : false;
                                    elem.isEditable = editable.equals("true") ? true : false;
                            }
                            else
                                    printWriter.println("missing node "+ nodeID);
                        }
                           
                    }
             
                    public void endElement(String uri, String localName,
                            String qName) throws SAXException {
                             
                    }
                };

                saxParser.parse(constraintsFile, handler);
                    
            }catch (Exception e){//Catch exception if any
                    System.err.println("Error: " + e.getMessage());
            }        
        }
        
        public void connectNodes()
        {
        	 //trace connected nodes       
            for(int i = 0; i<nodeVector.size(); i++)
            {
                NodeElement node = nodeVector.get(i);
                if(!node.counted)
                {
                    Vector<NodeElement> returnNodes = new Vector<NodeElement>();
                    chainInfo.add(new ChainInfo());
                    returnNodes.add(node);
                    node.chainNumber = currentChainNumber;
                    node.counted = true;
                    traceNode(node, returnNodes);
                    nodeChains.add(returnNodes);
                    currentChainNumber++;
              }
            }
        }
        
        public void checkChains()
        {
        	for(int i = 0; i<nodeChains.size();i++)
        	{
        		Vector<NodeElement> chain = nodeChains.get(i);
        		ChainInfo info = chainInfo.get(i);
        		findConflictsInChain(chain, info);
        		checkIfChainIsEditable(chain, info);
        		reportOnChain(chain, info);
        	}
        }
        
        public void findConflictsInChain(Vector<NodeElement> nodeChain, ChainInfo chainInfo)
        {
            //find conflicts
            for(int i = 0; i<nodeChain.size(); i++)
            {
                NodeElement node = nodeChain.get(i);
                if(node.isBox)
                {
                    for(int j = 0; j<node.outputPorts.size(); j++)
                    {
                        String outputEdgeID = node.outputPorts.get(j);
                        EdgeElement outgoingEdge = edges.get(outputEdgeID);
                        
                        boolean incomingWidth = node.isWide;
                        NodeElement toJoint = nodes.get(outgoingEdge.toNodeID);
                        if(toJoint.outputPorts.size() > 0)
                        {
                            String jointOutputEdgeID = toJoint.outputPorts.get(0);
                            EdgeElement outgoingJointEdge = edges.get(jointOutputEdgeID);
                            NodeElement toNode = nodes.get(outgoingJointEdge.toNodeID);;
                            boolean outgoingWidth = toNode.isWide;
                            if(incomingWidth && !outgoingWidth)
                            {
                              //  printWriter.println("conflict Node Type " + node.id + " " + outputEdgeID + " " + toNode.id);
                                chainInfo.numConflicts++;
                            }
                        }
                    }
                }
            }
            
            totalConflicts += chainInfo.numConflicts;
            
            if(chainInfo.numConflicts > 0)
            {
            	numChainsWithConflicts++;
            	if(nodeChain.size() > longestChainSizeWithConflict)
            		longestChainSizeWithConflict = nodeChain.size();
        		numNodesWithConflictInChain += nodeChain.size();
            }
                
        }
        
        public void checkIfChainIsEditable(Vector<NodeElement> nodeChain, ChainInfo chainInfo)
        {
        	chainInfo.isEditable = false;
            for(int j = 0; j < nodeChain.size(); j++)
            {
                NodeElement elem = nodeChain.get(j);
                if(elem.isEditable)
                {
                	chainInfo.isEditable = true;
                }
            }
            
            if(chainInfo.isEditable)
            {
            	editableChainCount++;
            	editableNodes+= nodeChain.size();
            }
            else
            {
            	uneditableChainCount++;
            	uneditableNodes += nodeChain.size();
            }
            
        }
        
        public void reportOnChain(Vector<NodeElement> nodeChain, ChainInfo chainInfo)
        {
        	printWriter.println("Chain Length " + nodeChain.size() + " " + "editable " + chainInfo.isEditable + " " + "Num Conflicts " + chainInfo.numConflicts);
        	if(chainInfo.numConflicts > mostNumConflicts)
        		mostNumConflicts = chainInfo.numConflicts;
        }
        
        public void reportOnFile(File file)
        {
//        	if(numChainsWithConflicts > 0)
//        	{
	        	 String layoutFileName = file.getName();
	             int strLen = layoutFileName.length();
//	        	String regularFileName = file.getPath().substring(0, strLen-10) + ".xml";
        	String fileName = layoutFileName.substring(0, strLen-10);
//	        	String constraintsFileName = file.getPath().substring(0, strLen-10) + "Constraints.xml";
//	        	printWriter.println("\"" + regularFileName + "\"'");
//	        	printWriter.println("\"" + constraintsFileName + "\"'");
//	        	printWriter.println("\"" + file.getPath() + "\"'");
//        	}
            countPrintWriter.println("<file id=\"" + fileName + "\" name=\"" + currentLevel.id
            		+ "\" nodes=\"" + nodes.size() + "\" edges=\"" + edges.size()+"\" visible_nodes=\"" 
            		+ visibleNodes + "\" visible_edges=\"" + visibleEdges
            			+"\" conflicts=\""+totalConflicts+"\" bonus_nodes=\""+totalBonusNodes
            			+"\" scriptname=\"" + scriptName + "\"/>");
          //  printWriter.println("Chain Count " + nodeChains.size());
            printWriter.println("editableChainCount " + editableChainCount + " " + "editableNodes " + editableNodes);
            printWriter.println("uneditableChainCount " + uneditableChainCount + " " + "uneditableNodes " + uneditableNodes);
        //    printWriter.println("numChainsWithConflicts " + numChainsWithConflicts);
         //   printWriter.println("longestChainSizeWithConflict " + longestChainSizeWithConflict + " " + "numNodesWithConflictInChain " + numNodesWithConflictInChain);
       totalEditableChains += editableChainCount;
       totalUneditableChains += uneditableChainCount;
       System.out.println("reported");
        }
        
        public void traceNode(NodeElement startNode, Vector<NodeElement> returnNodes)
        {
            for(int j = 0; j<startNode.outputPorts.size(); j++)
            {
                String outputEdgeID = startNode.outputPorts.get(j);
                EdgeElement outgoingEdge = edges.get(outputEdgeID);
                outgoingEdge.chainNumber = currentChainNumber;
                NodeElement toNode = nodes.get(outgoingEdge.toNodeID);
                if(toNode.counted == false)
                {
                    returnNodes.add(toNode);
                    toNode.chainNumber = currentChainNumber;
                    toNode.counted = true;
                    traceNode(toNode, returnNodes);
                }
            }
                
                for(int j = 0; j<startNode.inputPorts.size(); j++)
            {
                String inputEdgeID = startNode.inputPorts.get(j);
                EdgeElement incomingEdge = edges.get(inputEdgeID);
                incomingEdge.chainNumber = currentChainNumber;
                NodeElement fromNode = nodes.get(incomingEdge.fromNodeID);
                if(fromNode.counted == false)
                {
                    returnNodes.add(fromNode);
                    fromNode.chainNumber = currentChainNumber;
                    fromNode.counted = true;
                    traceNode(fromNode, returnNodes);
                }
            }
        }
        
        public void outputLayout(File layoutFile, File outputDirectory)
        {
        	try
        	{
	        	//open layout dom, make changes, save to new file
				DocumentBuilderFactory dbFactory = DocumentBuilderFactory.newInstance();
				dbFactory.setFeature("http://apache.org/xml/features/nonvalidating/load-external-dtd", false);
	
				DocumentBuilder dBuilder = dbFactory.newDocumentBuilder();
				Document doc = dBuilder.parse(layoutFile);
				
				//hide all boxes, joints and lines that don't have conflicts in their chain
				NodeList nodeList = doc.getElementsByTagName("box");
				for(int i=0; i<nodeList.getLength(); i++)
				{
					Element node = (Element)nodeList.item(i);
					String id = node.getAttribute("id");
					NodeElement nodeElem = nodes.get(id);
					if(nodeElem != null)
					{
						ChainInfo info = chainInfo.get(nodeElem.chainNumber);
						if(info.numConflicts > 0)
						{
							node.setAttribute("visible", "true");
							visibleNodes++;
						}
						else
							node.setAttribute("visible", "false");
					}
				}
				
				NodeList jointList = doc.getElementsByTagName("joint");
				for(int i=0; i<jointList.getLength(); i++)
				{
					Element node = (Element)jointList.item(i);
					String id = node.getAttribute("id");
					NodeElement nodeElem = nodes.get(id);
					if(nodeElem != null)
					{
						ChainInfo info = chainInfo.get(nodeElem.chainNumber);
						if(info.numConflicts > 0)
						{
							node.setAttribute("visible", "true");
							visibleNodes++;
						}
						else
							node.setAttribute("visible", "false");
					}
				}
				
				NodeList lineList = doc.getElementsByTagName("line");
				for(int i=0; i<lineList.getLength(); i++)
				{
					Element node = (Element)lineList.item(i);
					String id = node.getAttribute("id");
					EdgeElement edgeElem = edges.get(id);
					if(edgeElem != null)
					{
						ChainInfo info = chainInfo.get(edgeElem.chainNumber);
						if(info.numConflicts > 0)
						{
							node.setAttribute("visible", "true");
							visibleEdges++;
						}
						else
							node.setAttribute("visible", "false");
					}
				}
				
				// Prepare the DOM document for writing
		        Source source = new DOMSource(doc);

		        // Prepare the output file
		        File file = new File(outputDirectory, layoutFile.getName());
		        System.out.println(file.getAbsolutePath());
		        Result result = new StreamResult(file);

		        // Write the DOM document to the file
		        Transformer xformer = TransformerFactory.newInstance().newTransformer();
		        xformer.transform(source, result);
        	}
        	catch(Exception e)
        	{
        		
        	}
        }
        
     class ChainInfo
     {
    	 boolean isEditable;
    	 int numConflicts;
     }

}
