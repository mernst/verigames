package verigames.layout;

import verigames.layout.WorldLayout;
import verigames.level.*;
import verigames.sampleLevels.level.LevelWorld;
import verigames.utilities.FileCompare;

import java.io.*;

import org.junit.Test;
import static org.junit.Assert.*;

/**
 * Tests that the XML produced after a World is laid out is consistent with past
 * results.
 *
 * Based on output from graphviz version 2.26.3 (20100126.1600) on the
 * department research lab machines. A failure on a different version or machine
 * is not necessarily an indicator of a defect in the code.
 */
public class XMLComparisonTests
{
  @Test
  public void levelWorldTest() throws FileNotFoundException
  {
    final File expectedOutput = new File("levelWorld.expected.xml");
    final File actualOutput   = new File("levelWorld.actual.xml");
    final World w = LevelWorld.getWorld();
    WorldLayout.layout(w);
    
    PrintStream out = new PrintStream(actualOutput);
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
            actualOutput);
    
    assertTrue(result.toString(), result.getResult());
  }
}
