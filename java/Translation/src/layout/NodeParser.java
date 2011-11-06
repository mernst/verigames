package layout;

import checkers.nullness.quals.Nullable;

import static layout.GraphvizParser.*;

/**
 * Parses text in DOT format and returns the results as a GraphInformation
 * object.
 * <p>
 * Currently, it includes the dimensions of the graph's bounding box, as well as
 * the dimensions and position of the nodes. However, more information may be
 * added at a later date.
 * <p>
 * This parser is very brittle, and makes little attempt to account for
 * variations in input. It attempts to match Graphviz's output, which is a
 * subset of legal DOT. Therefore, some legal DOT may be rejected simply
 * because it doesn't match what Graphviz outputs.
 */

class NodeParser extends GraphvizParser
{

   /**
    * Returns an {@code Object} of type {@link GraphInformation}, 
    * <p>
    * Modifies: {@code builder}
    *
    * @param line
    * The line to parse
    * @param builder
    * The {@link GraphInformation#Builder} to which the data from the parsed
    * line will be added.
    */
   @Override
   protected void parseLine(String line, GraphInformation.Builder builder) throws IllegalLineException
   {
      switch (getLineKind(line))
      {
         case GRAPH_PROPERTIES:
            GraphInformation.GraphAttributes graph = parseGraphAttributes(line);
            if (graph != null)
               builder.setGraphAttributes(graph);
            break;
         case NODE:
            NodeRecord node = parseNode(line);
            builder.setNodeAttributes(node.name, node.attributes);
            break;
         default:
            // Right now, the graph attributes and node attributes is all the
            // information that is used
            break;
      }
   }

   /**
    * Takes a logical Graphviz line representing a graph attributes statement
    * and returns a GraphAttributes object containing the information from it.
    * <p>
    * Currently only parses the "bb" attribute.
    * 
    * @param line
    * Must be a valid, logical line of Graphviz output describing attributes of
    * the graph itself (as oppose to particular edges or nodes).
    */
   private static @Nullable GraphInformation.GraphAttributes parseGraphAttributes(String line) throws IllegalLineException
   {
      // sample line: "  graph [bb="0,0,216.69,528"];"
      
      String[] tokens = tokenizeLine(line);

      if(tokens.length < 2 || !tokens[0].equals("graph"))
         throw new IllegalLineException("\"" + line + "\" is not a valid graph attributes line");

      String bb = null;
      
      for (String s : tokens)
      {
         if (s.matches("^bb=.*"))
            bb = s;
      }

      // If the bounding box attribute is not present in this line, just return null.
      // This may need to be changed if more graph information is desired.
      if (bb == null)
         return null;

      // take the text inside the quotes and split around commas
      String[] bbCoords = bb.split("\"")[1].split(",");

      int xStart;
      int yStart;
      int xEnd;
      int yEnd;

      try
      {
         xStart = parseToHundredths(bbCoords[0]);
         yStart = parseToHundredths(bbCoords[1]);
         xEnd = parseToHundredths(bbCoords[2]);
         yEnd = parseToHundredths(bbCoords[3]);
      }
      catch (ArrayIndexOutOfBoundsException e)
      {
         throw new IllegalLineException("bounding box attribute poorly formed: " + line);
      }
      catch (NumberFormatException e)
      {
         throw new IllegalLineException("bounding box attribute poorly formed: " + line);
      }

      if (xStart != 0 || yStart != 0)
         throw new IllegalLineException("bottom-left corner of bounding box not at (0,0) -- it is (" + xStart + "," + yStart + ")");

      return new GraphInformation.GraphAttributes(xEnd, yEnd);
   }

   /**
    * Takes a logical Graphviz line representing a node and returns a NodeRecord
    * object containing the information from it.
    * 
    * @param line
    * Must be a valid, logical line of Graphviz output describing attributes of
    * a node.
    */
   private static NodeRecord parseNode(String line) throws IllegalLineException
   {
      // an example of a node line:
      // "   9 [label=OUTGOING9, width=1, height=1, pos="129.64,36"];"
      //     ^
      // node name
      
      String[] tokens = tokenizeLine(line);

      if (tokens.length == 0)
         throw new IllegalLineException("empty line: " + line);
      
      String name = tokens[0];

      String widthStr = null;
      String heightStr = null;
      String pos = null;

      // Search for attributes:
      for (String cur : tokens)
      {
         // if the string starts with "pos"
         if (cur.matches("^pos=.*"))
            pos=cur;
         
         if (cur.matches("^width=.*"))
            widthStr=cur;
         
         if (cur.matches("^height=.*"))
            heightStr=cur;
      }
      
      if (pos == null)
         throw new IllegalLineException("No position information: " + line);
      if (widthStr == null)
         throw new IllegalLineException("No width information: " + line);
      if (heightStr == null)
         throw new IllegalLineException("No height information: " + line);
      
      // The pos attribute takes the form pos="xx.xx,yy.yy"

      try
      {
         // split around quotes, and take only the xx.xx,yy.yy part
         String coordsStr = pos.split("\"")[1];

         // split around comma, to get [xx.xx, yy.yy]
         String[] coords = coordsStr.split(",");

         int x = parseToHundredths(coords[0]);
         int y = parseToHundredths(coords[1]);

         int width = parseDimension(widthStr);
         int height = parseDimension(heightStr);

         return new NodeRecord(name, new GraphInformation.NodeAttributes(x, y, width, height));
      }
      catch (ArrayIndexOutOfBoundsException e)
      {
         throw new IllegalLineException("Poorly formed line: " + line);
      }
      catch (NumberFormatException e)
      {
         throw new IllegalLineException("Poorly formed line: " + line);
      }
   }
}
