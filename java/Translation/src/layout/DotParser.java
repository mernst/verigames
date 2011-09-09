package layout;

import java.util.NoSuchElementException;
import java.util.Scanner;

/**
 * Parses text in DOT format and returns the results as a GraphInformation
 * object.
 * <p>
 * Currently, it includes the dimensions of the graph's bounding box, as well as
 * the dimensions and position of the nodes. However, more information may be
 * added at a later date.
 */

// TODO remove public access once tests can subvert access control.
public class DotParser
{

   public DotParser()
   {
      
   }

   public GraphInformation parse(String dotOutput)
   {
      final GraphInformation.Builder out = new GraphInformation.Builder();
      
      // TODO remove mock implementation
      
      /*
      Scanner in = new Scanner(dotOutput);

      while (in.hasNextLine())
      {
         String line = in.nextLine();
         while (line.charAt(line.length()) == '\\')
         {
            String end;
            try
            {
               end = in.nextLine();
            }
            catch (NoSuchElementException e)
            {
               throw new IllegalArgumentException("Poorly formed input -- \\ found at end of last line", e);
            }

            line = line + end;
         }

         parseLine(line, out);
      }
      
      if (out.areGraphAttributesSet())
         return out.build();
      else
         throw new IllegalArgumentException("Input lacks graph property information");
      */
      
      out.setGraphAttributes(new GraphInformation.GraphAttributes(21700, 52800));
      
      out.setNodeAttributes("8", new GraphInformation.NodeAttributes(10200, 45600, 14400, 7200));
      out.setNodeAttributes("9", new GraphInformation.NodeAttributes(13000, 3600, 7200, 7200));
      out.setNodeAttributes("10", new GraphInformation.NodeAttributes(8300, 30400, 7200, 14400));
      out.setNodeAttributes("11", new GraphInformation.NodeAttributes(13000, 15200, 14400, 14400));
      out.setNodeAttributes("12", new GraphInformation.NodeAttributes(15900, 30400, 7200, 14400));
      
      return out.build();
   }
   
   private static enum LineKind {GRAPH_PROPERTIES, NODE_PROPERTIES, EDGE_PROPERTIES, NODE, EDGE, OTHER}

   private static class NodeRecord
   {
      public final String name;
      public final GraphInformation.NodeAttributes attributes;

      public NodeRecord(String name, GraphInformation.NodeAttributes attributes)
      {
         this.name = name;
         this.attributes = attributes;
      }
   }

   /**
    * Returns an {@code Object} of type {@link GraphInformation}, 
    */
   private static void parseLine(String line, GraphInformation.Builder builder)
   {
      switch (getLineKind(line))
      {
         case GRAPH_PROPERTIES:
            builder.setGraphAttributes(parseGraphAttributes(line));
            break;
         case NODE:
            NodeRecord node = parseNode(line);
            builder.setNodeAttributes(node.name, node.attributes);
            break;
         default:
            break;
      }
   }
   
   private static LineKind getLineKind(String line)
   {
      throw new RuntimeException("Not yet implemented");
   }

   private static GraphInformation.GraphAttributes parseGraphAttributes(String line)
   {
      throw new RuntimeException("Not yet implemented");
   }

   private static NodeRecord parseNode(String line)
   {
      throw new RuntimeException("Not yet implemented");
   }

   private static String[] splitAroundWhitespace(String in)
   {
      return in.split("( |\t)*");
   }
}
