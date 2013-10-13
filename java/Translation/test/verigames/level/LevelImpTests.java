package verigames.level;

import static verigames.level.Intersection.Kind.*;

import org.junit.Before;
import org.junit.Test;

public class LevelImpTests
{
  Level l = null;
  Chute c1 = null;
  Chute c2 = null;

  @Before
  public void init()
  {
    l = new Level();
    Board b = new Board();
    
    Intersection incoming = Intersection.factory(INCOMING);
    Intersection outgoing = Intersection.factory(OUTGOING);

    b.addNode(incoming);
    b.addNode(outgoing);

    c1 = new Chute(0, null);
    c2 = new Chute(1, null);

    b.addEdge(incoming, "0", outgoing, "0", c1);
    b.addEdge(incoming, "1", outgoing, "1", c2);

    l.linkByVarID(0, 1);
  }

  /*
   * Test that when construction is finished, Level throws an exception if
   * linked {@link Chute}s have differing widths.
   */
  @Test(expected = IllegalStateException.class)
  public void testWidthConsistencyChecking1()
  {
    c1.setNarrow(false);
    c2.setNarrow(true);
    l.finishConstruction();
  }

  /*
   * Make sure that in the previous test, the {@code IllegalStateException}
   * isn't thrown for some other reason
   */
  @Test
  public void testWidthConsistencyChecking2()
  {
    c1.setNarrow(true);
    c2.setNarrow(true);
    l.finishConstruction();
  }
}
