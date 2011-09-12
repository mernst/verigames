package layout;

import java.math.BigDecimal;
import java.util.Arrays;
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
      
      Scanner in = new Scanner(dotOutput);

      while (in.hasNextLine())
      {
         String line = in.nextLine();
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

         parseLine(line, out);
      }
      
      if (out.areGraphAttributesSet())
         return out.build();
      else
         throw new IllegalArgumentException("Input lacks graph property information");
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
    * Takes a logical Graphviz line and returns what kind of information it represents.
    *
    * @param line
    * Must be a valid line of Graphviz output. Must be a logical line -- that
    * is, it must not be terminated by '\' (this would indicate that it should
    * be joined with the line after).
    *
    * @return a {@link #LineKind} indicating what kind of information {@code
    * line} represents.
    */
   private static LineKind getLineKind(String line)
   {
      String[] tokens = splitAroundWhitespace(line);

      // TODO add out of bounds tests

      // If the line is the start or end of a graph, return OTHER
      if (tokens[0].equals("digraph"))
         return LineKind.OTHER;
      else if (tokens[0].equals("}"))
         return LineKind.OTHER;
      // else, there should be at least two tokens ("}" is the only 1-token
      // line)
      else if (tokens[0].equals("graph"))
         return LineKind.GRAPH_PROPERTIES;
      else if (tokens[0].equals("node"))
         return LineKind.NODE_PROPERTIES;
      else if (tokens[0].equals("edge"))
         return LineKind.EDGE_PROPERTIES;
      else if (tokens[1].equals("->"))
         return LineKind.EDGE;
      else
         return LineKind.NODE;
   }

   /**
    * Takes a logical Graphviz line representing a graph attributes statement
    * and returns a GraphAttributes object containing the information from it.
    * 
    * @param line
    * Must be a valid, logical line of Graphviz output describing attributes of
    * the graph itself (as oppose to particular edges or nodes).
    */
   private static @Nullable GraphInformation.GraphAttributes parseGraphAttributes(String line)
   {
      // sample line: "  graph [bb="0,0,216.69,528"];"
      
      String[] tokens = tokenizeLine(line);

      if(tokens.length < 2 || !tokens[0].equals("graph"))
         throw new IllegalArgumentException("illegal graph line passed to parseGraphAttributes");

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

      int xStart = parseToHundredths(bbCoords[0]);
      int yStart = parseToHundredths(bbCoords[1]);
      int xEnd = parseToHundredths(bbCoords[2]);
      int yEnd = parseToHundredths(bbCoords[3]);

      if (xStart != 0 || yStart != 0)
         throw new IllegalArgumentException("bottom-left corner of bounding box not at (0,0) -- it is (" + xStart + "," + yStart + ")");

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
   private static NodeRecord parseNode(String line)
   {
      // an example of a node line:
      // "   9 [label=OUTGOING9, width=1, height=1, pos="129.64,36"];"
      
      String[] tokens = tokenizeLine(line);
      
      String name = tokens[0];

      String widthStr = null;
      String heightStr = null;
      String pos = null;

      // TODO change to for each loop?
      // Search for attributes:
      for (int i = 0; i < tokens.length; i++)
      {
         String cur = tokens[i];

         // if the string starts with "pos"
         if (cur.matches("^pos=.*"))
            pos=cur;
         
         if (cur.matches("^width=.*"))
            widthStr=cur;
         
         if (cur.matches("^height=.*"))
            heightStr=cur;
      }
      
      // TODO clean up error messages and improve error handling (ie handle
      // index out of bounds exceptions)
      if (pos == null)
         throw new IllegalArgumentException("line does not contain position information");
      if (widthStr == null)
         throw new IllegalArgumentException("line does not contain width information");
      if (heightStr == null)
         throw new IllegalArgumentException("line does not contain height information");
      
      // The pos attribute takes the form pos="xx.xx,yy.yy"

      // split around quotes, and take only the xx.xx,yy.yy part
      String coordsStr = pos.split("\"")[1];

      // split around comma, to get [xx.xx, yy.yy]
      String[] coords = coordsStr.split(",");

      int x = parseToHundredths(coords[0]);
      int y = parseToHundredths(coords[1]);
      
      // TODO abstract width and height parsing into private function

      // The width and height attributes take the form width=ww.ww Graphviz
      // gives them in inches, but they must be converted to hundredths of
      // points (1 inch = 72 points = 7200 hundredths of points)

      // a BigDecimal is used instead of a double so that there can be no loss
      // of precision
      BigDecimal widthInches = new BigDecimal(widthStr.split("=")[1]);
      BigDecimal widthBig = widthInches.multiply(new BigDecimal(7200));

      // TODO make this round rather than drop anything after the decimal point
      int width = widthBig.intValue();

      BigDecimal heightInches = new BigDecimal(heightStr.split("=")[1]);
      BigDecimal heightBig = heightInches.multiply(new BigDecimal(7200));

      // TODO make this round rather than drop anything after the decimal point
      int height = heightBig.intValue();

      return new NodeRecord(name, new GraphInformation.NodeAttributes(x, y, width, height));
   }

   /**
    * Splits the given line into tokens separated by whitespace. Removes
    * brackets ([,]), as well as semicolons and trailing commas in tokens.
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
    * @param String
    * Must represent a nonnegative decimal number
    * @return {@code int} indicating the number of hundredths in the given
    * number
    */
   private static int parseToHundredths(String str)
   {
      if (str.contains("."))
      {
         String[] parts = str.split("\\.");
         String firstStr = parts[0];
         String secondStr = parts[1];

         int first = Integer.parseInt(firstStr);
         
         int fraction = Integer.parseInt(secondStr);
         
         // We want to get the first two digits, so we divide by 10 ^ (# digits
         // - 2) (for example: 4700 / 10 ^ (4 - 2) = 47)
         int divisor = pow(10, getNumDigits(fraction) - 2);

         // to round, we add by half of the smallest unit, then do integer
         // division:
         int second = (fraction + (divisor / 2)) / divisor;

         return first * 100 + second;

      }
      else
      {
         return Integer.parseInt(str) * 100;
      }
   }
   
   /**
    * Returns the number of digits {@code n} has when represented as base 10.
    * <p>
    * 0 is considered to have 1 digit.
    * 
    * @param n
    * Must be a nonnegative integer
    */
   private static int getNumDigits(int n)
   {
      if (n < 0)
         throw new IllegalArgumentException(
               "negative argument passed to getNumDigits");
      // not incredibly elegant, but it works:
      return Integer.toString(n).length();
   }

   /**
    * Returns a to the power of b. Included because Math.pow only take doubles.
    * 
    * @param a
    * @param b
    * must be nonnegative
    */
   private static int pow(int a, int b)
   {
      if (b < 0)
         throw new IllegalArgumentException("negative argument passed to pow");
      
      int result = 1;
      for (int i = b; i > 0; i--)
         result *= a;
      
      return result;
   }
}
