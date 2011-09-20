package layout.tests;

import org.junit.Test;
import static org.junit.Assert.*;

import layout.GraphInformation;
import layout.DotParser;

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
      + "	8 -> 9 [style=invis, weight=0, pos=\"e,93.412,44.093 48.526,383.68 47.463,381.14 46.493,378.57 45.635,376 4.021,251.18 -28.789,191.77 40.635,80 50.291,64.456 67.244,\\\n"
      + "54.237 83.782,47.6\"];\n"
      + "	8 -> 10 [style=invis, weight=0, pos=\"e,92.411,376.22 93.33,383.56 93.311,383.41 93.292,383.26 93.272,383.1\"];\n"
      + "	10 -> 9 [style=invis, weight=0, pos=\"e,93.298,48.781 53.201,231.76 39.261,185.57 30.689,125.93 56.635,80 62.952,68.817 73.377,60.159 84.399,53.6\"];\n"
      + "	8 -> 11 [style=invis, weight=0, pos=\"e,126.81,224.05 115.66,383.67 116.01,381.08 116.34,378.52 116.64,376 119.79,349.38 123.59,286.68 126.29,234.36\"];\n"
      + "	11 -> 9 [style=invis, weight=0, pos=\"e,130.34,72.256 130.37,79.855 130.36,79.693 130.36,79.532 130.36,79.371\"];\n"
      + "	8 -> 12 [style=invis, weight=0, pos=\"e,131.55,376.22 128.8,383.56 128.86,383.41 128.91,383.26 128.97,383.1\"];\n"
      + "	12 -> 9 [style=invis, weight=0, pos=\"e,165.85,50.213 194.77,237.19 196.29,232.8 197.6,228.38 198.64,224 213.34,161.71 229.41,136.12 198.64,80 193.09,69.883 184.12,61.757\\\n"
      + " 174.45,55.377\"];\n"
      + "}\n";

   private static final GraphInformation testOutput;
   static
   {
      GraphInformation.Builder builder = new GraphInformation.Builder();

      builder.setGraphAttributes(new GraphInformation.GraphAttributes(21669, 52800));

      builder.setNodeAttributes("8", new GraphInformation.NodeAttributes(10164, 45600, 14400, 14400));
      builder.setNodeAttributes("9", new GraphInformation.NodeAttributes(12964, 3600, 7200, 7200));
      builder.setNodeAttributes("10", new GraphInformation.NodeAttributes(8264, 30400, 7200, 14400));
      builder.setNodeAttributes("11", new GraphInformation.NodeAttributes(12964, 15200, 14400, 14400));
      builder.setNodeAttributes("12", new GraphInformation.NodeAttributes(15864, 30400, 7200, 14400));

      testOutput = builder.build();
   }

   /**
    * Tests that the parser gives testOutput on testInput
    */
   @Test
   public void simpleTest()
   {
      DotParser parser = new DotParser();
      assertEquals(testOutput, parser.parse(testInput));
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

      DotParser parser = new DotParser();
      assertEquals(output, parser.parse(input));
   }
}
