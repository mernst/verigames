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
 * This class provides the structure for a parser. Subclasses will specify the
 * exact behavior of the parser.
 * <p>
 * This class also provides some protected static methods that will be useful
 * for subclasses.
 */

abstract class GraphvizParser
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
   protected static class IllegalLineException extends Exception
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
   
   protected static enum LineKind {GRAPH_PROPERTIES, NODE_PROPERTIES, EDGE_PROPERTIES, NODE, EDGE, OTHER}
 
   /**
    * An immutable record type that stores the name of a node along with its
    * attributes.
    */
   protected static class NodeRecord
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
   protected abstract void parseLine(String line, GraphInformation.Builder builder) throws IllegalLineException;

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
   protected static LineKind getLineKind(String line) throws IllegalLineException
   {
      String[] tokens = splitAroundWhitespace(line);

      try
      {
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
      catch (ArrayIndexOutOfBoundsException e)
      {
         throw new IllegalLineException(line, e);
      }
   }

   /**
    * Takes a text representation of a decimal number and returns an {@code
    * int} 7200 times larger. Rounds to the nearest integer.
    * <p>
    * Used for converting height and width dimensions from inches to hundredths
    * of points.
    */
   protected static int parseDimension(String dimensionStr) throws IllegalLineException
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
    * brackets ([,]), as well as semicolons and trailing commas in tokens.
    */
   protected static String[] tokenizeLine(String line)
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
   protected static int parseToHundredths(String str)
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
