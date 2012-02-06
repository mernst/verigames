package verigames.layout;

import org.junit.Test;

import verigames.layout.DotParser;
import verigames.layout.GraphInformation;

import static org.junit.Assert.*;
import static verigames.layout.GraphInformation.*;

import java.util.*;


public class DotParserSpecTests
{
  private static final String testInput =
      "digraph {\n"
          + "	graph [nodesep=0, ranksep=0];\n"
          + "	node [label=\"\\N\", shape=box, fixedsize=true];\n"
          + "	graph [bb=\"0,0,216.69,528\"];\n"
          + "	8 [label=INCOMING8, width=2, height=2, pos=\"101.64,456\"];\n"
          + "	9 [label=OUTGOING9, width=1, height=1, pos=\"129.64,36\"];\n"
          + "	10 [label=END10, width=1, height=2, pos=\"82.635,304\"];\n"
          + "	11 [label=MERGE11, width=2, height=2, pos=\"129.64,152\"];\n"
          + "	12 [label=START_BLACK_BALL12, width=1, height=2, pos=\"158.64,304\"];\n"
          + "	8 -> 10 [pos=\"e,91.662,376.22 92.58,383.56 92.561,383.41 92.542,383.26 92.523,383.1\"];\n"
          + "	8 -> 11 [pos=\"e,126,224.05 114.66,383.67 115.01,381.08 115.34,378.52 115.64,376 118.79,349.38 122.59,286.68 125.44,234.36\"];\n"
          + "	11 -> 9 [pos=\"e,129.64,72.256 129.64,79.855 129.64,79.693 129.64,79.532 129.64,79.371\"];\n"
          + "	12 -> 11 [pos=\"e,143.41,224.22 144.81,231.56 144.79,231.41 144.76,231.26 144.73,231.1\"];\n"
          + "}\n";
  
  private static final GraphInformation testOutput;
  static
  {
    GraphInformation.Builder builder = new GraphInformation.Builder();
    
    builder.setGraphAttributes(new GraphAttributes(21669, 52800));
    
    builder.setNodeAttributes("8", new NodeAttributes(10164, 45600, 14400, 14400));
    builder.setNodeAttributes("9", new NodeAttributes(12964, 3600, 7200, 7200));
    builder.setNodeAttributes("10", new NodeAttributes(8264, 30400, 7200, 14400));
    builder.setNodeAttributes("11", new NodeAttributes(12964, 15200, 14400, 14400));
    builder.setNodeAttributes("12", new NodeAttributes(15864, 30400, 7200, 14400));
    
    builder.setEdgeAttributes("8", "10", new EdgeAttributes(Arrays.asList(new Point(9258, 38356), new Point(9256, 38341), new Point(9254, 38326), new Point(9252, 38310))));
    builder.setEdgeAttributes("8", "11", new EdgeAttributes(Arrays.asList(new Point(11466, 38367), new Point(11501, 38108), new Point(11534, 37852), new Point(11564, 37600), new Point(11879, 34938), new Point(12259, 28668), new Point(12544, 23436))));
    builder.setEdgeAttributes("11", "9", new EdgeAttributes(Arrays.asList(new Point(12964, 7986), new Point(12964, 7969), new Point(12964, 7953), new Point(12964, 7937))));
    builder.setEdgeAttributes("12", "11", new EdgeAttributes(Arrays.asList(new Point(14481, 23156), new Point(14479, 23141), new Point(14476, 23126), new Point(14473, 23110))));
    
    testOutput = builder.build();
  }
  
  /**
   * Tests that the parser gives testOutput on testInput
   */
  @Test
  public void simpleTest()
  {
    assertEquals(testOutput, DotParser.parse(testInput));
  }
  
  /**
   * Tests that the parser properly rounds dimensions, instead of just
   * truncating them.
   */
  @Test
  public void testDimensionRounding()
  {
    final String input = 
        "digraph {\n"
            + "	graph [bb=\"0,0,216.69,528\"];\n"
            + "	8 [label=INCOMING8, width=1.00007, height=2, pos=\"101.64,456\"];\n"
            + "}\n";
    
    GraphInformation.Builder builder = new GraphInformation.Builder();
    
    builder.setGraphAttributes(new GraphInformation.GraphAttributes(21669, 52800));
    
    builder.setNodeAttributes("8", new
        GraphInformation.NodeAttributes(10164, 45600, 7201, 14400));
    
    GraphInformation output = builder.build();
    
    assertEquals(output, DotParser.parse(input));
  }
  
  // included because at one point this escaped as an
  // ArrayIndexOutOfBoundsException
  @Test(expected = IllegalArgumentException.class)
  public void badLineTest()
  {
    String input = "graph {\ngraph [bb=0,0,216.69,528];\n";
    DotParser.parse(input);
  }
}
