package verigames.level;

import java.io.IOException;
import java.io.PrintStream;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;

import verigames.level.Intersection.Kind;
import verigames.utilities.Pair;
import verigames.utilities.Printer;

import nu.xom.*;

public class WorldXMLPrinter extends Printer<World, Void>
{
  public static final int version = 1;

  /**
   * Prints the XML representation for {@code toPrint}<br/>
   * 
   * @param toPrint
   * The {@link World} to print
   * 
   * @param out
   * The {@code PrintStream} to which the XML will be printed. Must be open.
   */
  @Override
  public void print(World toPrint, PrintStream out, Void data)
  {
    super.print(toPrint, out, data);
  }
  
  @Override
  protected void printMiddle(World toPrint, PrintStream out, Void data)
  {
    Element worldElt = new Element("world");
    Attribute versionAttr = new Attribute("version", Integer.toString(version));
    worldElt.addAttribute(versionAttr);
    
    for (Map.Entry<String, Level> entry : toPrint.getLevels().entrySet())
    {
      String name = entry.getKey();
      Level level = entry.getValue();
      worldElt.appendChild(constructLevel(level, name));
    }
    
    Document doc = new Document(worldElt);
    DocType docType = new DocType("world", "world.dtd");
    doc.insertChild(docType, 0);
    
    try
    {
      Serializer s = new Serializer(out);
      s.setLineSeparator("\n");
      s.setIndent(1);
      s.write(doc);
    }
    catch (IOException e)
    {
      // if this happens, it's fatal.
      throw new RuntimeException(e);
    }
  }
  
  private Element constructLevel(Level l, String name)
  {
    Element levelElt = new Element("level");
    
    Attribute nameAttr = new Attribute("name", name);
    levelElt.addAttribute(nameAttr);
    
    levelElt.appendChild(constructLinkedEdges(l, name));
    levelElt.appendChild(constructBoardsMap(l));
    
    return levelElt;
  }

  private Set<String> usedLinkedEdgeIDs = new HashSet<String>();
  
  private Element constructLinkedEdges(Level l, String name)
  {
    Element edgesElt = new Element("linked-edges");
    
    // Output all linked edges explicitly listed in linkedEdgeClasses
    Set<Chute> alreadyPrintedEdges = new HashSet<Chute>();

    // TODO: This is an arbitrary number assigned to each edge-set to identify
    // it for stamping. This should probably be changed to just be the
    // variableID associated with the linkedEdgeSet, but for now this will work
    // so that the XML at least validates.
    int edgeSetNumber = 0;
    for (Set<Chute> set : l.linkedEdgeClasses())
    {
      Element setElt = new Element("edge-set");

      // find an unused string for the edge-set ID. There is very small
      // probability that there will be collisions, as there would have to be
      // some really bizarre level names, but it's still possible.
      String edgeSetID = name + edgeSetNumber;
      while (usedLinkedEdgeIDs.contains(edgeSetID))
      {
        edgeSetNumber++;
        edgeSetID = name + edgeSetNumber;
      }
      // TODO associate linked edge sets with their ID somehow, so that they can
      // be referred to when needed.
      
      setElt.addAttribute(new Attribute("id", edgeSetID));

      // TODO add stamp elements here

      for (Chute c : set)
      {
        if (c.underConstruction())
          throw new IllegalStateException(
              "constructLinkedEdges called when linkedEdgeClasses contains underConstruction Chute");
        Element edgeElt = new Element("edgeref");
        edgeElt.addAttribute(new Attribute("id", "e" + c.getUID()));
        setElt.appendChild(edgeElt);
        
        alreadyPrintedEdges.add(c);
      }
      edgesElt.appendChild(setElt);

      edgeSetNumber++;
    }
    
    // TODO remove code cloning:
    // Output all remaining edges -- edges not listed are in equivalence
    // classes of size 1
    
    for (Board b : l.getBoards().values())
    {
      for (Chute c : b.getEdges())
      {
        if (!alreadyPrintedEdges.contains(c))
        {
          Element setElt = new Element("edge-set");

          String edgeSetID = name + edgeSetNumber;
          while (usedLinkedEdgeIDs.contains(edgeSetID))
          {
            edgeSetNumber++;
            edgeSetID = name + edgeSetNumber;
          }

          setElt.addAttribute(new Attribute("id", edgeSetID));

          if (c.underConstruction())
            throw new IllegalStateException(
                "constructLinkedEdges called when linkedEdgeClasses contains underConstruction Chute");
          Element edgeElt = new Element("edgeref");
          edgeElt.addAttribute(new Attribute("id", "e" + c.getUID()));
          setElt.appendChild(edgeElt);
          edgesElt.appendChild(setElt);
        }

        edgeSetNumber++;
      }
    }
    
    return edgesElt;
  }
  
  private Element constructBoardsMap(Level l)
  {
    Map<String, Board> boardNames = l.getBoards();
    
    Element boardsElt = new Element("boards");
    
    for (Map.Entry<String, Board> entry : boardNames.entrySet())
    {
      String name = entry.getKey();
      Board board = entry.getValue();
      
      Element boardElt = new Element("board");
      boardElt.addAttribute(new Attribute("name", name));
      
      for (Intersection node : board.getNodes())
      {
        if (node.underConstruction())
          throw new IllegalStateException("underConstruction Intersection in Level while printing XML");
        
        Element nodeElt = new Element("node");
        nodeElt.addAttribute(new Attribute("kind", node.getIntersectionKind().toString()));
        
        if (node.getIntersectionKind() == Kind.SUBBOARD)
        {
          if (node.isSubboard())
            nodeElt.addAttribute(new Attribute("name", node.asSubboard().getSubnetworkName()));
          else
            throw new RuntimeException("node " + node + " has kind subnetwork but isSubnetwork returns false");
        }
        nodeElt.addAttribute(new Attribute("id", "n" + node.getUID()));
        
        {
          Element inputElt = new Element("input");
          
          Chute input = node.getInput(0);
          for (int i = 0; input != null; input = node.getInput(++i))
          {
            Element portElt = new Element("port");
            portElt.addAttribute(new Attribute("num", Integer.toString(i)));
            portElt.addAttribute(new Attribute("edge", "e" + input.getUID()));
            inputElt.appendChild(portElt);
          }
          
          nodeElt.appendChild(inputElt);
        }
        
        {
          Element outputElt = new Element("output");
          
          Chute output = node.getOutput(0);
          for (int i = 0; output != null; output = node.getOutput(++i))
          {
            Element portElt = new Element("port");
            portElt.addAttribute(new Attribute("num", Integer.toString(i)));
            portElt.addAttribute(new Attribute("edge", "e" + Integer.toString(output.getUID())));
            outputElt.appendChild(portElt);
          }
          
          nodeElt.appendChild(outputElt);
        }
        
        double x = node.getX();
        double y = node.getY();
        if (x >= 0 && y >= 0)
        {
          Element layoutElt = new Element("layout");
          
          Element xElt = new Element("x");
          xElt.appendChild(String.format("%.5f", x));
          layoutElt.appendChild(xElt);
          
          Element yElt = new Element("y");
          yElt.appendChild(String.format("%.5f", y));
          layoutElt.appendChild(yElt);
          
          nodeElt.appendChild(layoutElt);
        }
        
        boardElt.appendChild(nodeElt);
        
      }
      
      for (Chute edge : board.getEdges())
      {
        if (edge.underConstruction())
          throw new IllegalStateException("underConstruction Chute in Level while printing XML");
        
        Element edgeElt = new Element("edge");
        {
          edgeElt.addAttribute(new Attribute("description", edge.getDescription()));
          edgeElt.addAttribute(new Attribute("variableID", Integer.toString(edge.getVariableID())));
          edgeElt.addAttribute(new Attribute("pinch", Boolean.toString(edge.isPinched())));
          edgeElt.addAttribute(new Attribute("width", edge.isNarrow() ? "narrow" : "wide"));
          edgeElt.addAttribute(new Attribute("editable", Boolean.toString(edge.isEditable())));
          edgeElt.addAttribute(new Attribute("id", "e" + edge.getUID()));
          edgeElt.addAttribute(new Attribute("buzzsaw", Boolean.toString(edge.hasBuzzsaw())));
        }
        
        {
          Element fromElt = new Element("from");
          
          Element noderefElt = new Element("noderef");
          // TODO do something about this nullness warning
          noderefElt.addAttribute(new Attribute("id", "n" + edge.getStart().getUID()));
          noderefElt.addAttribute(new Attribute("port", edge.getStartPort()));
          fromElt.appendChild(noderefElt);
          
          edgeElt.appendChild(fromElt);
        }
        
        {
          Element toElt = new Element("to");
          
          Element noderefElt = new Element("noderef");
          // TODO do something about this nullness warning
          noderefElt.addAttribute(new Attribute("id", "n" + edge.getEnd().getUID()));
          noderefElt.addAttribute(new Attribute("port", edge.getEndPort()));
          toElt.appendChild(noderefElt);
          
          edgeElt.appendChild(toElt);
        }
        
        // output layout information, if it exists:
        List<Pair<Double, Double>> layout = edge.getLayout();
        if (layout != null)
        {
          Element edgeLayoutElt = new Element("edge-layout");
          
          for (Pair<Double, Double> point : layout)
          {
            Element pointElt = new Element("point");
            
            Element xElt = new Element("x");
            xElt.appendChild(String.format("%.5f", point.getFirst()));
            pointElt.appendChild(xElt);
            
            Element yElt = new Element("y");
            yElt.appendChild(String.format("%.5f", point.getSecond()));
            pointElt.appendChild(yElt);
            
            edgeLayoutElt.appendChild(pointElt);
          }
          
          edgeElt.appendChild(edgeLayoutElt);
        }
        
        boardElt.appendChild(edgeElt);
      }
      
      boardsElt.appendChild(boardElt);
    }
    
    return boardsElt;
  }
}
