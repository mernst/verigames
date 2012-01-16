package layout;

import level.*;
import utilities.FileCompare;
import sampleLevels.level.LevelWorld;

import java.io.*;

import org.junit.Test;
import static org.junit.Assert.*;

/**
 * Tests that the XML produced after a World is laid out is consistent with past
 * results.
 *
 * Based on output from graphviz version 2.26.3 (20100126.1600). A failure on a
 * different version is not necessarily an indicator of a defect in the code.
 */
public class XMLComparisonTests
{
   @Test
   public void levelWorldTest() throws FileNotFoundException
   {
      World w = LevelWorld.getWorld();
      WorldLayout.layout(w);

      PrintStream out = new PrintStream(new File("levelWorld.actual.xml"));
      try
      {
         new WorldXMLPrinter().print(w, out, null);
      }
      finally
      {
         out.close();
      }

      FileCompare.Result result = FileCompare.compareFiles(
            new File("levelWorld.expected.xml"),
            new File("levelWorld.actual.xml"));

      assertTrue("Difference at line " + result.getLineNumber() + ":\n" +
            "Expected: " + result.getFirstLine() + "\n" +
            "But was : " + result.getSecondLine() + "\n",
            result.getResult());
   }
}
