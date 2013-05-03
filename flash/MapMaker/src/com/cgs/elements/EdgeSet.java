package com.cgs.elements;

import java.util.ArrayList;
import java.util.HashMap;

public class EdgeSet extends Element
{
	protected ArrayList<EdgeElement> edges;
	
	public ArrayList<GridLine> inputGridLines;
	public ArrayList<GridLine> outputGridLines;
	
	//used for seth conversion, as an anchor for edges that connect to this edgeset
	public NodeElement node;
	
	public EdgeElement edgeAttributes;

	protected boolean isConstrainableStartingNode = false;
	
	public Rectangle boundingBox;

	public boolean isPlaced = false;
	static int count = 1;
	
	public EdgeSet(String _id)
	{
		super(_id);
		edges = new ArrayList<EdgeElement>();
		inputGridLines = new ArrayList<GridLine>();
		outputGridLines = new ArrayList<GridLine>();

		boundingBox = new Rectangle();
		
		node = new NodeElement(_id);
	}
	
	public void addEdge(EdgeElement edge)
	{
		if(edge.id.indexOf('n')!= -1)
			System.out.println("here");
		edges.add(edge);
	}
	
	public void addInputGridLine(GridLine edgeSetEdge)
	{
		// TODO: THIS MUST MATCH THE OUTPUT GRIDLINE CORRESPONDING TO AN EDGE ID FROM THE ORIGINAL GRAPH
		edgeSetEdge.inputPosition = inputGridLines.size();
		inputGridLines.add(edgeSetEdge);
	}
	
	public void addOutputGridLine(GridLine edgeSetEdge)
	{
		// TODO: THIS MUST MATCH THE INPUT GRIDLINE CORRESPONDING TO AN EDGE ID FROM THE ORIGINAL GRAPH
		edgeSetEdge.outputPosition = outputGridLines.size();
		outputGridLines.add(edgeSetEdge);
	}
	
	//We want to find those edgesets that should be included in the constraints file.
	//Qualifying ones are those that have an edge that has an input node of
	// kind="START_xxx" except not START_LARGE_BALL, as that fixes the node,
	// or of kinds INCOMING, or SUBBOARD if the edge itself isn't of type non-editable
	public void markStart(HashMap<String, NodeElement> nodes)
	{
		  for(int i = 0; i<edges.size(); i++)
			{
				EdgeElement edge = edges.get(i);
				if(edge.inputPort.connectedNode != null)
				{
					NodeElement startNode = edge.inputPort.connectedNode;
					if(startNode.kind.indexOf("START_") != -1 && startNode.kind.indexOf("START_LARGE") == -1)
						isConstrainableStartingNode = true;
					else if(startNode.kind.indexOf("INCOMING") != -1 || startNode.kind.indexOf("SUBBOARD") != -1)
					{
						if(!edge.editableState.equals("false"))
							isConstrainableStartingNode = true;
					}
					
					if(isConstrainableStartingNode)
						break;
				}
			}		
	}
	
	public void writeElement(StringBuffer out)
	{
		 out.append("<edgeset id=\""+id+"\" ");
		 out.append(boundingBox.toAttributeString());
		 out.append("/>\r");
		 for(int i = 0; i<inputGridLines.size(); i++)
		 {
			 writeEdge(inputGridLines.get(i), out);
		 }
		 for(int i = 0; i<outputGridLines.size(); i++)
		 {
			writeEdge(outputGridLines.get(i), out);
		 }
	}
	
	public void writeXMLEdgeSetElement(StringBuffer out)
	{
		 out.append("<edge-set id=\""+id+"\">\r");
		 for(int i = 0; i<edges.size(); i++)
		 {
			EdgeElement edge = edges.get(i);
			out.append("<edgeref id=\""+edge.id+"\"/>\r");
		 }
		 
		 out.append("</edge-set>\r");
		 

	}
	
	public void writeXMLEdgeElement(StringBuffer out)
	{
		for(int edgeIndex=0; edgeIndex < edges.size(); edgeIndex++)
		{
			EdgeElement edge = edges.get(edgeIndex);
			 out.append("<edge description=\"test\" pinch=\"false\" buzzsaw=\"false\" id=\""+id+"\" "
					 + "width=\"" + edge.widthState + "\" " 
					 + "editable=\"" + edge.editableState + "\" "
					 + ">\r");
			 out.append("<from>\r");
			 out.append("<noderef port=\"0\" id=\"" + edge.inputPort.id + "\">\r");
			 out.append("</from>\r");
			 out.append("<to>\r");
			 out.append("<noderef port=\"0\" id=\"" + edge.outputPort.id + "\">\r");
			 out.append("</to>\r");
			 out.append("</edge>\r");
			 
			 for(int i = 0; i<outputGridLines.size(); i++)
			 {
				writeEdge(outputGridLines.get(i), out);
			 }
		}
	}
	
	public void writeEdge(GridLine line, StringBuffer out)
	{
		JointElement joint = line.joint;
		EdgeSet edgeSet = line.edgeSet;
		String fromID;
		String toID;
		double startPointX;
		double startPointY;
		double endPointX;
		double endPointY;
		if (line.jointToEdgeSet) {
			fromID = line.joint.id;
			toID = line.edgeSet.id;
			
			int numInputLines = line.edgeSet.inputGridLines.size();
			endPointX = line.edgeSet.boundingBox.finalXPos+line.edgeSet.boundingBox.width*(line.inputPosition+1)/(numInputLines+1);
			endPointY = line.edgeSet.boundingBox.finalYPos;
			
			int numOutputLines = line.joint.outputPorts.size();
			startPointX = line.joint.boundingBox.finalXPos+((double)fromEdgeSet.boundingBox.width*(line.outputPosition+1)/(numOutputLines+1));
			startPointY = endPointY - 1;// TODO: For now, place just above the output edgeSet
			
			
		} else {
			fromID = line.edgeSet.id;
			toID = line.joint.id;
		}
		out.append("<edge from=\"" + fromID + "\" to=\"" + toID + "\">\r");
		out.append("<point x=\"" + startPointX + "\" y=\"" + startPointY + "\"/>\r");
		out.append("<point x=\"" + endPointX + "\" y=\"" + endPointY + "\"/>\r");
		out.append("</edge>\r");
	}
	
	public void writeConstrainableOutput(StringBuffer out)
	{
		  try{
			  if(isConstrainableStartingNode)
			  {
				 writeOutput(out);
			  }
			  //Close the output stream
		  }catch (Exception e){//Catch exception if any
			  System.err.println("Error: " + e.getMessage());
		  }
	}
	
	public void writeOutput(StringBuffer out)
	{
		  try{
				 out.append("<edge-set id=\""+id+"\"");
				 
				 boolean isPinched = false;
				 boolean isWide = false;
				 boolean isEditable = false;
				 for(int i = 0; i<edges.size(); i++)
				 {
					 EdgeElement edge = edges.get(i);
					 if(edge.pinchState.equals("true"))
						 isPinched = true;
					 
					 if(edge.widthState.equals("true"))
						 isWide = true;
					 
					 if(edge.editableState.equals("true"))
						 isEditable = true;
				 }
				 out.append(" pinch=\""+isPinched+"\"");
				 if(isWide)
					 out.append(" width=\"wide\"");
				 else
					 out.append(" width=\"narrow\"");
				 out.append(" editable=\""+isEditable+"\"");
				 out.append("/>\r");
				 
			  //Close the output stream
		  }catch (Exception e){//Catch exception if any
			  System.err.println("Error: " + e.getMessage());
		  }
	}
}

