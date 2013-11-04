package verigames.level;

import static org.junit.Assert.*;

import org.junit.*;

import java.io.*;
import java.util.*;

/**
 * Contains a bunch of tests specific to the {@link World} described by {@code
 * hadoop-distcp.xml} in this directory.
 */
public class WorldXMLParserSpecTests
{
  public static World hadoopWorld;
  public static Map<String, Level> levels;

  @BeforeClass
  public static void parseHadoop() throws FileNotFoundException, IOException
  {
    System.out.println(new File(".").getCanonicalPath());
    System.out.println(System.getProperty("user.dir"));
    InputStream in = new FileInputStream("hadoop-distcp.xml");
    WorldXMLParser parser = new WorldXMLParser();

    hadoopWorld = parser.parse(in);
    levels = hadoopWorld.getLevels();
  }

  @Test
  public void testUnderConstruction()
  {
    assertFalse(hadoopWorld.underConstruction());
  }

  @Test
  public void testVarIDLinking1()
  {
    assertTrue(hadoopWorld.areVarIDsLinked(171, 120));
  }

  @Test
  public void testVarIDLinking2()
  {
    assertFalse(hadoopWorld.areVarIDsLinked(171, 440));
  }

  @Test
  public void testLevelParsing()
  {
    Level l = levels.get("org.apache.hadoop.tools.OptionsParser$CustomParser");
    assertNotNull(l);
    // test that it contains a stub board
    assertTrue(l.contains("org.apache.commons.cli.GnuParser--init----void"));
    // test that it contains a board
    assertTrue(l.contains("org.apache.hadoop.tools.OptionsParser-CustomParser"));
  }
}
