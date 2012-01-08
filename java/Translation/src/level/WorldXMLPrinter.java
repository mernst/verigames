package level;

import java.io.PrintStream;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;

import level.Intersection.Kind;
import utilities.Pair;
import utilities.Printer;

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
   protected void printIntro(World toPrint, PrintStream out, Void data)
   {
      out.println("<?xml version=\"1.0\"?>");
      out.println("<!DOCTYPE world SYSTEM \"world.dtd\">");
      out.println("<world>");
   }

   @Override
   protected void printMiddle(World toPrint, PrintStream out, Void data)
   {
      for (Map.Entry<String, Level> entry : toPrint.getLevels().entrySet())
      {
         String name = entry.getKey();
         Level level = entry.getValue();
         printLevel(level, out, name);
      }
   }

   @Override
   protected void printOutro(World toPrint, PrintStream out, Void data)
   {
      out.println("</world>");
   }

   private void printLevel(Level l, PrintStream out, String name)
   {
      out.println("<level name=\"" + name + "\">");
      printLinkedEdges(l, out);
      printBoardsMap(l, out);
      out.println("</level>");
   }

   private void printLinkedEdges(Level l, PrintStream out)
   {
      out.println(" <linked-edges>");
      
      // Output all linked edges explicitly listed in linkedEdgeClasses
      Set<Chute> alreadyPrintedEdges = new HashSet<Chute>();
      for (Set<Chute> set : l.linkedEdgeClasses())
      {
         out.println("  <edge-set>");
         for (Chute c : set)
         {
            if (c.isActive())
               throw new IllegalStateException(
                     "outputlinkedEdgeClasses called when linkedEdgeClasses contains active Chute");
            out.println("   <edgeref id=\"e" + c.getUID() + "\"/>");
            alreadyPrintedEdges.add(c);
         }
         out.println("  </edge-set>");
      }
      
      // Output all remaining edges -- edges not listed are in equivalence
      // classes of size 1
      
      for (Board b : l.boards().values())
      {
         for (Chute c : b.getEdges())
         {
            if (!alreadyPrintedEdges.contains(c))
            {
               out.println("  <edge-set>");
               if (c.isActive())
                  throw new IllegalStateException(
                        "outputlinkedEdgeClasses called when linkedEdgeClasses contains active Chute");
               out.println("   <edgeref id=\"e" + c.getUID() + "\"/>");
               out.println("  </edge-set>");
            }
         }
      }
      
      out.println(" </linked-edges>");
   }

   private void printBoardsMap(Level l, PrintStream out)
   {
      Map<String, Board> boardNames = l.boards();
      
      out.println(" <boards>");

      for (Map.Entry<String, Board> entry : boardNames.entrySet())
      {
         String name = entry.getKey();
         Board board = entry.getValue();

         out.println("  <board name=\"" + name + "\">");
         
         for (Intersection node : board.getNodes())
         {
            if (node.isActive())
               throw new IllegalStateException("active Intersection in Level while printing XML");
            
            out.print("   <node kind=\"" + node.getIntersectionKind()+ "\"");
            if (node.getIntersectionKind() == Kind.SUBNETWORK)
            {
               if (node.isSubnetwork())
                  out.print(" name=\"" + node.asSubnetwork().getSubnetworkName() + "\"");
               else
                  throw new RuntimeException("node " + node + " has kind subnetwork but isSubnetwork returns false");
            }
            out.println(" id=\"n" + node.getUID() + "\">");
            out.println("    <input>");
            
            Chute input = node.getInput(0);
            for (int i = 0; input != null; input = node.getInput(++i))
               out.println("     <port num=\"" + i + "\" edge=\"e"
                     + input.getUID() + "\"/>");
            
            out.println("    </input>");
            out.println("    <output>");
            
            Chute output = node.getOutput(0);
            for (int i = 0; output != null; output = node.getOutput(++i))
               out.println("     <port num=\"" + i + "\" edge=\"e"
                     + output.getUID() + "\"/>");
            
            out.println("    </output>");
            
            double x = node.getX();
            double y = node.getY();
            if (x >= 0 && y >= 0)
            {
               out.println("<layout>");
               out.printf("<x>%.5f</x>\n", x);
               out.printf("<y>%.5f</y>\n", y);
               out.println("</layout>");
            }
            
            out.println("   </node>");
         }
         
         for (Chute edge : board.getEdges())
         {
            if (edge.isActive())
               throw new IllegalStateException("active Chute in Level while printing XML");
            
            String edgeName = null;
            {
               Set<String> names = board.getChuteNames(edge);
               if (!names.isEmpty())
                  edgeName = names.iterator().next();
            }
            
            out.println("   <edge var=\"" + edgeName + "\" pinch=\""
                  + edge.isPinched() + "\" width=\""
                  + (edge.isNarrow() ? "narrow" : "wide") + "\" id=\"e"
                  + edge.getUID() + "\">");
            
            out.println("    <from>");
            // TODO do something about this nullness warning
            out.println("     <noderef id=\"n" + edge.getStart().getUID()
                  + "\" port=\"" + edge.getStartPort() + "\"/>");
            out.println("    </from>");
            out.println("    <to>");
            // TODO do something about this nullness warning
            out.println("     <noderef id=\"n" + edge.getEnd().getUID()
                  + "\" port=\"" + edge.getEndPort() + "\"/>");
            out.println("    </to>");

            // output layout information, if it exists:
            List<Pair<Double, Double>> layout = edge.getLayout();
            if (layout != null)
            {
               out.println("<edge-layout>");

               for (Pair<Double, Double> point : layout)
               {
                  out.println("<point>");
                  out.printf("<x>%.5f</x>\n", point.getFirst());
                  out.printf("<y>%.5f</y>\n", point.getSecond());
                  out.println("</point>");
               }

               out.println("</edge-layout>");
            }

            out.println("   </edge>");
            
         }
         
         out.println("  </board>");
      }
      out.println(" </boards>");
   }
}
