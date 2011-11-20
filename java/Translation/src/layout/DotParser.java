package layout;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.NoSuchElementException;
import java.util.Scanner;

import checkers.nullness.quals.Nullable;

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

class DotParser
{

   /**
    * An {@code Exception} that is thrown when a bad line of DOT is
    * encountered. It should only be used internally to ensure that errors are
    * handled and expressed to clients in an appropriate way. A reference to an
    * {@code IllegalLineException} should never escape this class.
    * <p>
    * A message is required, and it should contain the bad line or the bad part
    * of the line.
    */
   private static class IllegalLineException extends Exception
   {
      public IllegalLineException(String message)
      {
         super(message);
      }

      public IllegalLineException(String message, Throwable cause)
      {
         super(message, cause);
      }
   }

   /**
    * Parses the given {@code String} as a single graph in DOT format, and
    * returns the information as a {@code GraphInformation} object.
    *
    * @param dotOutput
    * Must be well-formed output from dot.
    */
   public GraphInformation parse(String dotOutput)
   {
      final GraphInformation.Builder out = new GraphInformation.Builder();
      
      Scanner in = new Scanner(dotOutput);

      while (in.hasNextLine())
      {
         String line = in.nextLine();
         
         // if the line is terminated by a \, the next line is logically part of
         // this line, so stitch them together
         while (line.charAt(line.length() - 1) == '\\')
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

            // Join the current line with the next line, and remove the \ at
            // the end of the current line
            line = line.substring(0, line.length() - 1) + end;
         }

         try
         {
            parseLine(line, out);
         }
         catch (IllegalLineException e)
         {
            throw new IllegalArgumentException(e.getMessage(), e);
         }
      }
      
      if (out.areGraphAttributesSet())
         return out.build();
      else
         throw new IllegalArgumentException("Input lacks graph property information");
   }
   
   private static enum LineKind {GRAPH_PROPERTIES, NODE_PROPERTIES, EDGE_PROPERTIES, NODE, EDGE, OTHER}
 
   /**
    * An immutable record type that stores the name of a node along with its
    * attributes.
    */
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
    * An immutable record type that stores the start and end nodes of an edge
    * along with its attributes.
    */
   private static class EdgeRecord
   {
      public final String start;
      public final String end;
      public final GraphInformation.EdgeAttributes attributes;

      public EdgeRecord(String start, String end, GraphInformation.EdgeAttributes attributes)
      {
         this.start = start;
         this.end = end;
         this.attributes = attributes;
      }
   }

   /**
    * Mutates {@code builder} such that 
    * <p>
    * Modifies: {@code builder}
    *
    * @param line
    * The line to parse
    * @param builder
    * The {@link GraphInformation#Builder} to which the data from the parsed
    * line will be added.
    */
   private static void parseLine(String line, GraphInformation.Builder builder) throws IllegalLineException
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
         case EDGE:
            EdgeRecord edge = parseEdge(line);
            builder.setEdgeAttributes(edge.start, edge.end, edge.attributes);
            break;
         default:
            // Right now, the graph attributes and node attributes is all the
            // information that is used
            break;
      }
   }

   /**
    * Takes a logical Graphviz line and returns what kind of information it represents.
    *
    * @param line
    * Must be a valid line of Graphviz output. Must be a logical line -- that
    * is, it must not be terminated by '\' (this would indicate that it should
    * be joined with the line after).
    *
    * @return a {@link LineKind} indicating what kind of information {@code
    * line} represents.
    */
   private static LineKind getLineKind(String line) throws IllegalLineException
   {
      String[] tokens = splitAroundWhitespace(line);

      try
      {
         if (tokens[0].equals("}"))
            return LineKind.OTHER;
         // else, there should be at least two tokens ("}" is the only 1-token
         // line)
         // If the line is the start or end of a graph, return OTHER
         else if ((tokens[0].equals("digraph") || tokens[0].equals("graph")) && tokens[1].equals("{"))
            return LineKind.OTHER;
         else if (tokens[0].equals("graph"))
            return LineKind.GRAPH_PROPERTIES;
         else if (tokens[0].equals("node"))
            return LineKind.NODE_PROPERTIES;
         else if (tokens[0].equals("edge"))
            return LineKind.EDGE_PROPERTIES;
         else if (tokens[1].equals("->") || tokens[1].equals("--"))
            return LineKind.EDGE;
         else
            return LineKind.NODE;
      }
      catch (ArrayIndexOutOfBoundsException e)
      {
         throw new IllegalLineException(line, e);
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
      // '   9 [label=OUTGOING9, width=1, height=1, pos="129.64,36"];'
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

   private static EdgeRecord parseEdge(String line)
   {
      // An example of an edge line:
      //    '   8 -- 10 [pos="37,493 37,493 54,341 54,341"];'
      //        ^    ^          ^      ^      ^      ^
      // start node  |         spline   control   points
      //          end node

      List<GraphInformation.Point> points = new ArrayList<GraphInformation.Point>();

      points.add(new GraphInformation.Point(5, 6));

      return new EdgeRecord("8", "10", new GraphInformation.EdgeAttributes(points));
   }

   /**
    * Takes a text representation of a decimal number and returns an {@code
    * int} 7200 times larger. Rounds to the nearest integer.
    * <p>
    * Used for converting height and width dimensions from inches to hundredths
    * of points.
    */
   private static int parseDimension(String dimensionStr) throws IllegalLineException
   {
      // The width and height attributes take the form width=ww.ww
      //
      // Graphviz gives them in inches, but they must be converted to
      // hundredths of points (1 inch = 72 points = 7200 hundredths of points)

      // a BigDecimal is used instead of a double so that there can be no loss
      // of precision
      BigDecimal dimInches; 
      try
      {
         dimInches = new BigDecimal(dimensionStr.split("=")[1]);
      }
      catch (ArrayIndexOutOfBoundsException e)
      {
         throw new IllegalLineException("Poorly formed attribute:" + dimensionStr, e);
      }
      catch (NumberFormatException e)
      {
         throw new IllegalLineException("Poorly formed attribute:" + dimensionStr, e);
      }

      BigDecimal dimension = dimInches.multiply(new BigDecimal(7200));

      // rounds by adding 0.5, then taking the floor
      return dimension.add(new BigDecimal("0.5")).intValue();
   }

   /**
    * Splits the given line into tokens separated by whitespace. Removes
    * brackets ([,]), as well as semicolons, quotes, and trailing commas in
    * tokens.
    */
   private static String[] tokenizeLine(String line)
   {
      // remove extraneous characters -- '[', ']', ';' -- from the line.
      line = line.replaceAll("[\\[\\];]", "");
      
      String[] tokens = splitAroundWhitespace(line);
      
      // remove trailing commas at the end of tokens
      for(int i = 0; i < tokens.length; i++)
         tokens[i] = tokens[i].replaceAll(",$", "");

      return tokens;
   }

   /**
    * Splits the given {@code String} into an array of tokens separated by
    * whitespace. Whitespace is defined as one or more spaces, tabs, or
    * newlines.
    */
   private static String[] splitAroundWhitespace(String in)
   {
      // Split the input around one or more spaces, tabs, or newlines
      String[] result = in.split("[ \t\n]+");

      // If the first thing in the String is whitespace, there will be an empty
      // String at the beginning of the resulting array. If this is the case,
      // remove it.
      if (result.length > 0 && result[0].length() == 0)
         result = Arrays.copyOfRange(result, 1, result.length);

      return result;
   }

   /**
    * Parses the given nonnegative decimal number, represented as a
    * {@code String} into hundredths of units. That is, given "123.45", it would
    * return 12345. Rounds to the nearest hundredth.
    * 
    * @param str
    * Must be a nonnegative decimal number. There may not be a leading '.'
    * (e.g.  ".35" must be written "0.35").
    * @return {@code int} indicating the number of hundredths in the given
    * number
    * @throws NumberFormatException if {@code str} is poorly formed
    */
   private static int parseToHundredths(String str)
   {
      // 1 or more digits, optionally followed by a single dot and one or more
      // digits
      if (!str.matches("[0-9]+(\\.[0-9]+)?"))
         throw new NumberFormatException(str + " is not a well-formed nonnegative decimal number");

      BigDecimal hundredths = new BigDecimal(str).multiply(new BigDecimal(100));

      // round by adding 0.5, then taking the floor.
      return hundredths.add(new BigDecimal("0.5")).intValue();
   }
}
