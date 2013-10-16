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

import com.cgs.elements.*;

import java.io.File;
import java.io.PrintWriter;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.Map;
import java.util.Vector;

public class WorldParser {

    File layoutFile;
    File constraintsFile;
    String outputFileName;
    static File outputFile;
    static PrintWriter printWriter;
    static File countFile;
    static PrintWriter countPrintWriter;
    static File outputDirectory;
    
    ArrayList<Level> levelList;
    protected HashMap<String, NodeElement> nodes;
    protected HashMap<String, EdgeElement> edges;
    protected HashMap<String, EdgeSet> edgesets;
    protected HashMap<String, Board> boards;
    protected HashMap<String, Level> boardToLevel;
    
    protected Vector<NodeElement> nodeVector;
    protected Vector<EdgeElement> edgeVector;
    
    //used to build up current element
    protected Level currentLevel;
    protected Board currentBoard;
    protected NodeElement currentNode;
    protected EdgeElement currentEdge;
    protected EdgeSet currentEdgeSet;

    Vector<Vector<NodeElement>> nodeChains;
    Vector<ChainInfo> chainInfoVector;
    
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

 
        	if(args.length != 1)
        	{
        		System.out.println("Usage: java -jar WorldParser.jar sourcefile");
        		return;
        	}
            try{

               File root = new File(args[0]);                
                handleFile(root);
                }
            catch(Exception e)
            {
               System.out.println(e);     
            }
            
            System.out.println("Run Completed"); 
        }
        
        static String layoutFileName = null;
        public static void handleFile(File file)
        {
            layoutFileName = file.getPath();
            WorldParser rater = new WorldParser(file);
         	 
            rater.parseWorldFile();
            System.out.println("Parsed File");
            System.out.println("node/edge count "+ rater.nodes.size() + "/"+rater.edges.size());
            rater.connectNodes();
            System.out.println("Nodes Connected");
            rater.checkChains();
        //    rater.createLevelHierarchy();

  //          rater.outputLayout(file, outputDirectory);
            
            rater.reportOnFile(file);
        //    printWriter.print(mostNumConflicts + " " + totalEditableChains + " " + totalUneditableChains);
            
            
        }
        
        public WorldParser(File layoutFile)
        {
                try{
                this.layoutFile = layoutFile;
                              
                levelList = new ArrayList<Level>();
                nodes = new HashMap<String, NodeElement>();
                edges = new HashMap<String, EdgeElement>();
                edgesets = new HashMap<String, EdgeSet>();
                boards = new HashMap<String, Board>();
                boardToLevel = new  HashMap<String, Level>();
                nodeVector = new Vector<NodeElement>();
                edgeVector = new Vector<EdgeElement>();
                
                nodeChains = new Vector<Vector<NodeElement>>();
                chainInfoVector = new Vector<ChainInfo>();
                
                visibleNodes = 0;
                visibleEdges = 0;
                totalConflicts = 0;
                totalBonusNodes = 0;
                }
                catch(Exception e)
                {
                        
                }
        }
        
        public boolean isIncoming;
        public void parseWorldFile() 
        { 
                try {
                        
                        SAXParserFactory factory = SAXParserFactory.newInstance();
                        factory.setFeature("http://apache.org/xml/features/nonvalidating/load-external-dtd", false);

                        SAXParser saxParser = factory.newSAXParser();
                        
                        DefaultHandler handler = new DefaultHandler() {
                                                               
                                public void startElement(String uri, String localName,String qName, 
                                        Attributes attributes) throws SAXException {
                         
                                        if (qName.equalsIgnoreCase("level")) 
                                        {
                                             String levelName = attributes.getValue("name");
                                             System.out.println(levelName);
                                                currentLevel = new Level(levelName);
                                                levelList.add(currentLevel);
                                        }
                                        if (qName.equalsIgnoreCase("board")) 
                                        {
                                             String boardName = attributes.getValue("name");
                                                currentBoard = new Board(boardName);
                                                currentLevel.addBoard(currentBoard);
                                                currentBoard.containerLevel = currentLevel;
                                                boardToLevel.put(boardName, currentLevel);
                                        }
                                        else if (qName.equalsIgnoreCase("edge-set")) {
                                        	String edgeSetID = attributes.getValue("id");
                                        	currentEdgeSet = new EdgeSet(edgeSetID);
                                        }
                                        else if (qName.equalsIgnoreCase("edgeref")) {
                                        	String edgeID = attributes.getValue("id");
                                        	edgesets.put(edgeID, currentEdgeSet);
                                        	currentEdgeSet.addEdgeID(edgeID);
                                        }
                                        else if (qName.equalsIgnoreCase("edge")) {
                                        	String id = attributes.getValue("id");
                                            //System.out.println(id);
                                            currentEdge = new EdgeElement(null, id, null);
                                            currentEdge.addAttributes(attributes);
                                            edges.put(id, currentEdge);
                                            
                                            String editableAttr = attributes.getValue("editable");
                                            if(editableAttr.equals("false"))
                                            	currentEdge.isEditable = false;
                                            else
                                            	currentEdge.isEditable = true;
                                        }
                                        else if (qName.equalsIgnoreCase("from")) {
                                        	isIncoming = true;
                                      }
                                      else if (qName.equalsIgnoreCase("to")) {
                                    	  isIncoming = false;
                                      }
                                      else if (qName.equalsIgnoreCase("noderef")) {
                                          String nodeID = attributes.getValue("id");
                                          String portID = attributes.getValue("port");
                                        
                                          if(isIncoming)
                                        	  currentEdge.setInputNode(nodeID, portID);
                                          else
                                        	  currentEdge.setOutputNode(nodeID, portID);
                                      }
                                        else if (qName.equalsIgnoreCase("node")) {
                                        	String id = attributes.getValue("id");
                                        	String kind = attributes.getValue("kind");
                                            //System.out.println(id);
                                        	//pass kind as levelID, yeah, it's a misuse. So sue me...
                                        	currentNode = new NodeElement(id, kind);
                                        	currentNode.addAttributes(attributes);
                                        	nodes.put(id, currentNode);
                                        	nodeVector.add(currentNode);
                                        	currentNode.containerBoard = currentBoard;
                                        	currentNode.containerLevel = currentLevel;
                                        	if(kind.equals("SUBBOARD"))
                                        	{
                                        		String name = attributes.getValue("name");
                                        		currentNode.name = name;
                                        		currentBoard.addSubboard(currentNode);
                                        	}
                                        	boards.put(id, currentBoard);
                                        }
                                        else if (qName.equalsIgnoreCase("input")) {
                                            isIncoming = true;
                                        }
                                        else if (qName.equalsIgnoreCase("output")) {
                                        	isIncoming = false;
                                        }
                                        else if (qName.equalsIgnoreCase("port")) {
                                            String edgeID = attributes.getValue("edge");
                                        	String portNum = attributes.getValue("num");
                                          
                                            if(isIncoming)
                                          	  currentNode.addInputPort(new Port(edgeID, portNum));
                                            else
                                            	currentNode.addOutputPort(new Port(edgeID, portNum));
                                        }
                                }
                         
                                public void endElement(String uri, String localName,
                                        String qName) throws SAXException {
                                         
                                }
                        };

                        saxParser.parse(layoutFile, handler);
                        
                }catch (Exception e){//Catch exception if any
                        System.err.println("Error: ");
                        e.printStackTrace();
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
                    node.counted = true;
                    Vector<NodeElement> returnNodes = new Vector<NodeElement>();
                    chainInfoVector.add(new ChainInfo());
                    returnNodes.add(node);
                    node.chainNumber = currentChainNumber;
                    traceNode(node, returnNodes);
                    nodeChains.add(returnNodes);
                    currentChainNumber++;
       //             System.out.println(currentChainNumber);
              }
            }
        }
        
        public void checkChains()
        {
        	for(int i = 0; i<nodeChains.size();i++)
        	{
        		Vector<NodeElement> chain = nodeChains.get(i);
        		ChainInfo info = chainInfoVector.get(i);
        	//	findConflictsInChain(chain, info);
        		checkIfChainIsEditable(chain, info);
        	//	reportOnChain(chain, info);
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
                	boolean nodeIsEditable = node.isEditable;
                    for(int j = 0; j<node.outputPortNames.size(); j++)
                    {
                        String outputEdgeID = node.outputPortNames.get(j);
                        EdgeElement outgoingEdge = edges.get(outputEdgeID);
                        
                        boolean incomingWidth = node.isWide;
                        NodeElement toJoint = nodes.get(outgoingEdge.toNodeID);
                        if(toJoint.outputPortNames.size() > 0)
                        {
                            String jointOutputEdgeID = toJoint.outputPortNames.get(0);
                            EdgeElement outgoingJointEdge = edges.get(jointOutputEdgeID);
                            NodeElement toNode = nodes.get(outgoingJointEdge.toNodeID); 
                            if(toNode.hasConflict)
                            	continue;
                            boolean toNodeIsEditable = toNode.isEditable;
                            boolean outgoingWidth = toNode.isWide;
                            if(incomingWidth && !outgoingWidth)
                            {
                              //  printWriter.println("conflict Node Type " + node.id + " " + outputEdgeID + " " + toNode.id);
                            	if(toNodeIsEditable || node.isEditable)
                            		chainInfo.numConflicts++;
                            	toNode.hasConflict = true;
                            	break;
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
        	//check all outgoing edges in a node, and if one editable one is found, set to true
            for(int j = 0; j < nodeChain.size(); j++)
            {
                NodeElement elem = nodeChain.get(j);
                ArrayList<Port> outgoingPorts = elem.outputPorts;
                for(int i = 0; i< outgoingPorts.size(); i++)
                {
                	Port port = outgoingPorts.get(i);
                	String edgeID = port.id;
                	EdgeElement edge = edges.get(edgeID);
	                if(edge.isEditable)
	                {
	                	chainInfo.isEditable = true;
	                	break;
	                }
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
        
        public void createLevelHierarchy()
        {
        	for(int i = 0; i< levelList.size(); i++)
        	{
        		Level level = levelList.get(i);
        		for(int j = 0; j< level.boards.size(); j++)
        		{
        			Board board = level.boards.get(j);
        			for(int k=0; k< board.subboards.size(); k++)
        			{
        				NodeElement subboard = board.subboards.get(k);
        				//Find the level that contains the board with the same name, and add relationship from current level to level that contains that board
        				Level containerLevel = boardToLevel.get(subboard.name);
        				if(containerLevel != level)
        				{
	        				containerLevel.dependedOn.put(level.id,level);
	        				level.dependsOn.put(containerLevel.id, containerLevel);
	        				
	        				System.out.println(level.name + "->" + containerLevel.name);
        				}
        				
        				//Find the board with the same name, and add relationship from that board to current board
        				Board containerBoard = boards.get(subboard.id);
        				containerBoard.dependedOn.put(board.id, board);
        				board.dependsOn.put(containerBoard.id, containerBoard);
        			}
        		}
        	}
        }
        
        public void reportOnChain(Vector<NodeElement> nodeChain, ChainInfo chainInfo)
        {
//        	if(chainInfo.numConflicts > 0)
//        	{
//        		printWriter.println(layoutFileName);
//
//        		printWriter.println("Chain Length " + nodeChain.size() + " " + "editable " + chainInfo.isEditable + " " + "Num Conflicts " + chainInfo.numConflicts);
//        	}
//        	if(chainInfo.numConflicts > mostNumConflicts)
//        		mostNumConflicts = chainInfo.numConflicts;
        }
        
        public void reportOnFile(File file)
        {
//        	if(numChainsWithConflicts > 0)
//        	{
//	        	 String layoutFileName = file.getName();
//	             int strLen = layoutFileName.length();
//	        	String regularFileName = file.getPath().substring(0, strLen-10) + ".xml";
//        	String fileName = layoutFileName.substring(0, strLen-10);
//	        	String constraintsFileName = file.getPath().substring(0, strLen-10) + "Constraints.xml";
//	        	printWriter.println("\"" + regularFileName + "\"'");
//	        	printWriter.println("\"" + constraintsFileName + "\"'");
//	        	printWriter.println("\"" + file.getPath() + "\"'");
//        	}
//            countPrintWriter.println("<file id=\"" + fileName + "\" name=\"" + currentLevel.id
//            		+ "\" nodes=\"" + nodes.size() + "\" edges=\"" + edges.size()+"\" visible_nodes=\"" 
//            		+ visibleNodes + "\" visible_edges=\"" + visibleEdges
//            			+"\" conflicts=\""+totalConflicts+"\" bonus_nodes=\""+totalBonusNodes
//            			+"\" scriptname=\"" + scriptName + "\"/>");
            System.out.println("Chain Count/#editable/#nodes " + nodeChains.size() + "/" + editableChainCount + "/" + editableNodes);
            HashMap<Integer,Vector<Vector<NodeElement>>> countMap = new HashMap<Integer,Vector<Vector<NodeElement>>>();
            
            for(int i = 0; i< nodeChains.size(); i++)
            {
            	Vector<NodeElement> list = nodeChains.get(i);
            	ChainInfo chainInfo = chainInfoVector.get(i);
            	//if(chainInfo.isEditable == true)
             	{
	            	int size = list.size();
	            	Integer temp = new Integer(size);
	            	if(countMap.get(temp) == null)
	            	{
	            		Vector<Vector<NodeElement>> array = new Vector<Vector<NodeElement>>();
	            		array.add(list);
	            		countMap.put(temp, array);
	            	}
	            	else
	            	{
	            		Vector<Vector<NodeElement>> array = countMap.get(temp);
	            		array.add(list);
	            	}
            	}
            }
            
            int maxKey = 0;
            for (Map.Entry<Integer, Vector<Vector<NodeElement>>> entry : countMap.entrySet()) {
                System.out.println("Key = " + entry.getKey() + ", Value = " + entry.getValue().size());
                if(entry.getKey() > maxKey)
                	maxKey = entry.getKey();
                
//                if(entry.getKey() == 2)
//                {
//                	Vector<Vector<NodeElement>> value = entry.getValue();
//                	for(int ii = 0; ii< value.size(); ii++)
//                	{
//                		Vector<NodeElement> vec = value.get(ii);
//                		for(int jj = 0; jj< vec.size(); jj++)
//                		{
//                			NodeElement node = vec.get(jj);
//                			//if(!(node.levelID.equals("OUTGOING") || node.levelID.equals("INCOMING")))
//                				System.out.println(node.id + " " + node.levelID);
//                		}
//                	}
//                }
            }
            
            //write out longest chain
            Vector<Vector<NodeElement>> maxArray = countMap.get(maxKey);
            Vector<NodeElement> maxChain = maxArray.get(0);
            try
            {
	         	File outputFile = new File("parsed.xml");
	            PrintWriter printWriter = new PrintWriter(outputFile);
	            printWriter.println("<world>");
	           
	            writeChainToFile(maxChain, printWriter);
	           printWriter.println("</world>");
	            printWriter.flush();
	            printWriter.close();   
            }
            catch(Exception e)
            {
            	
            }
        }
            
        protected void writeChainToFile(Vector<NodeElement> chain, PrintWriter printWriter)
        {
 
        	printWriter.println("<level name=\"foo\">");
        	printWriter.println("<board name=\"main\">");
        	Vector<EdgeElement> edgesInChain = new Vector<EdgeElement>();
        	Vector<EdgeSet> edgesetsInChain = new Vector<EdgeSet>();
        	for(int i = 0; i<chain.size(); i++)
            {
            	NodeElement elem = chain.get(i);
            	elem.write(printWriter);
            	
            	ArrayList<Port> outgoingPorts = elem.outputPorts;
                for(int ii = 0; ii< outgoingPorts.size(); ii++)
                {
                	Port port = outgoingPorts.get(ii);
                	String edgeID = port.id;
                	EdgeElement edge = edges.get(edgeID);
	                edge.write(printWriter);
	                edgesInChain.add(edge);
	                
	                //look up edge set, and add if not previously added
	                EdgeSet edgeset = edgesets.get(edgeID);
	                if(edgeset.hasBeenOutputted == false)
	                {
	                	edgeset.hasBeenOutputted = true;
	                	edgesetsInChain.add(edgeset);
	                }
                }
            }
        	
        	printWriter.println("<linked-edges>");
        	for(int iii = 0; iii<edgesetsInChain.size(); iii++)
            {
        		EdgeSet edgeset = edgesetsInChain.get(iii);
        		edgeset.write(printWriter);
            }
        	printWriter.println("</linked-edges>");
        	printWriter.println("</board>");
        	printWriter.println("</level>");
  
  
        }
            
           // System.out.println("editableChainCount " + editableChainCount + " " + "editableNodes " + editableNodes);
           // System.out.println("uneditableChainCount " + uneditableChainCount + " " + "uneditableNodes " + uneditableNodes);
           // System.out.println("numChainsWithConflicts " + numChainsWithConflicts);
           // System.out.println("longestChainSizeWithConflict " + longestChainSizeWithConflict + " " + "numNodesWithConflictInChain " + numNodesWithConflictInChain);
 //      totalEditableChains += editableChainCount;
 //      totalUneditableChains += uneditableChainCount;
       //System.out.println("reported");
      //  }
        
        public void traceNode(NodeElement startNode, Vector<NodeElement> returnNodes)
        {
            for(int j = 0; j<startNode.outputPorts.size(); j++)
            {
                Port outputPort = startNode.outputPorts.get(j);
                String outputEdgeID = outputPort.id;
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
                Port inputPort = startNode.inputPorts.get(j);
                String inputEdgeID = inputPort.id;
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
						ChainInfo info = chainInfoVector.get(nodeElem.chainNumber);
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
						ChainInfo info = chainInfoVector.get(nodeElem.chainNumber);
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
						ChainInfo info = chainInfoVector.get(edgeElem.chainNumber);
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
