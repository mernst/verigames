package level;

import java.io.IOException;
import java.io.PrintStream;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;

import level.Intersection.Kind;
import utilities.Pair;
import utilities.Printer;

import nu.xom.*;

public class WorldXMLPrinter extends Printer<World, Void>
{
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

      levelElt.appendChild(constructLinkedEdges(l));
      levelElt.appendChild(constructBoardsMap(l));

      return levelElt;
   }

   private Element constructLinkedEdges(Level l)
   {
      Element edgesElt = new Element("linked-edges");
      
      // Output all linked edges explicitly listed in linkedEdgeClasses
      Set<Chute> alreadyPrintedEdges = new HashSet<Chute>();
      for (Set<Chute> set : l.linkedEdgeClasses())
      {
         Element setElt = new Element("edge-set");
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
      }
      
      // Output all remaining edges -- edges not listed are in equivalence
      // classes of size 1
      
      for (Board b : l.boards().values())
      {
         for (Chute c : b.getEdges())
         {
            if (!alreadyPrintedEdges.contains(c))
            {
               Element setElt = new Element("edge-set");
               if (c.underConstruction())
                  throw new IllegalStateException(
                        "constructLinkedEdges called when linkedEdgeClasses contains underConstruction Chute");
               Element edgeElt = new Element("edgeref");
               edgeElt.addAttribute(new Attribute("id", "e" + c.getUID()));
               setElt.appendChild(edgeElt);
               edgesElt.appendChild(setElt);
            }
         }
      }
      
      return edgesElt;
   }

   private Element constructBoardsMap(Level l)
   {
      Map<String, Board> boardNames = l.boards();
      
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

            if (node.getIntersectionKind() == Kind.SUBNETWORK)
            {
               if (node.isSubnetwork())
                  nodeElt.addAttribute(new Attribute("name", node.asSubnetwork().getSubnetworkName()));
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
            
            String edgeName = null;
            {
               Set<String> names = board.getChuteNames(edge);
               if (!names.isEmpty())
                  edgeName = names.iterator().next();
            }

            Element edgeElt = new Element("edge");
            {
               edgeElt.addAttribute(new Attribute("var", (edgeName == null) ? "null" : edgeName));
               edgeElt.addAttribute(new Attribute("pinch", Boolean.toString(edge.isPinched())));
               edgeElt.addAttribute(new Attribute("width", edge.isNarrow() ? "narrow" : "wide"));
               edgeElt.addAttribute(new Attribute("id", "e" + edge.getUID()));
            }
            
            {
               Element fromElt = new Element("from");

               Element noderefElt = new Element("noderef");
               // TODO do something about this nullness warning
               noderefElt.addAttribute(new Attribute("id", "n" + edge.getStart().getUID()));
               noderefElt.addAttribute(new Attribute("port", Integer.toString(edge.getStartPort())));
               fromElt.appendChild(noderefElt);

               edgeElt.appendChild(fromElt);
            }

            {
               Element toElt = new Element("to");

               Element noderefElt = new Element("noderef");
               // TODO do something about this nullness warning
               noderefElt.addAttribute(new Attribute("id", "n" + edge.getEnd().getUID()));
               noderefElt.addAttribute(new Attribute("port", Integer.toString(edge.getEndPort())));
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
