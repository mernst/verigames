package verigames.level;

import static org.junit.Assert.*;

import java.util.*;

import org.junit.Before;
import org.junit.Test;

import verigames.level.*;
import verigames.level.StubBoard.*;
import verigames.level.Intersection.*;

// TODO add tests for other features of level

public class LevelSpecTests
{
  public Chute[] chutes;

  public Board b;

  public Level l;

  @Before
  public void init()
  {
    chutes = new Chute[10];

    for (int i = 0; i < chutes.length; i++)
      chutes[i] = new Chute(i, null);

    b = new Board();

    Intersection in = Intersection.factory(Kind.INCOMING);
    Intersection out = Intersection.factory(Kind.OUTGOING);

    b.addNode(in);
    b.addNode(out);

    for (int i = 0; i < chutes.length; i++)
      b.addEdge(in, Integer.toString(i), out, Integer.toString(i), chutes[i]);

    l = new Level();
    l.addBoard("asdf", b);
  }

  /**
   * Test basic chute linking functionality
   */
  @Test
  public void testLinkedEdges1()
  {
    // link chutes 0 through 4
    for (int i = 0; i < 4; i++)
      l.linkByVarID(i, i + 1);

    // link chutes 5 through the end
    for (int i = 5; i < chutes.length - 1; i++)
      l.linkByVarID(i, i + 1);

    assertTrue(l.areVarIDsLinked(0, 4));
    assertTrue(l.areVarIDsLinked(5, chutes.length - 1));
    assertFalse(l.areVarIDsLinked(0, 6));
  }

  /**
   * Test that different sets of linked chutes are combined into one when
   * necessary
   */
  @Test
  public void testLinkedEdges2()
  {
    l.linkByVarID(0, 1);
    l.linkByVarID(1, 2);

    l.linkByVarID(3, 4);

    assertTrue(l.areVarIDsLinked(0, 2));
    assertTrue(l.areVarIDsLinked(3, 4));

    assertFalse(l.areVarIDsLinked(0, 3));

    l.linkByVarID(0, 3);

    assertTrue(l.areVarIDsLinked(0, 3));

    assertTrue(l.areVarIDsLinked(1, 4));
  }

  /**
   * Test that any given edge is always linked with itself (reflexivity in the
   * equivalence relation)
   */
  @Test
  public void testLinkedEdges3()
  {
    Set<Chute> set1 = new HashSet<Chute>();
    set1.add(chutes[0]);

    assertTrue(l.areVarIDsLinked(0, 0));

    l.linkByVarID(0, 1);

    assertTrue(l.areVarIDsLinked(0, 0));
  }

  @Test
  public void testLinkedVarIDs()
  {
    l.linkByVarID(1, 3);
    assertTrue(l.areVarIDsLinked(1, 3));
    assertFalse(l.areVarIDsLinked(1, 2));
  }

  @Test
  public void stubBoardSanityCheck()
  {
    Level l = new Level();

    List<StubConnection> inputs = new ArrayList<>();
    inputs.add(new StubConnection("input1", true));
    List<StubConnection> outputs = new ArrayList<>();
    outputs.add(new StubConnection("output1", false));

    StubBoard b = new StubBoard(inputs, outputs);

    l.addStubBoard("stub", b);

    assertEquals(b, l.getStubBoard("stub"));
    assertTrue(l.contains("stub"));
    assertEquals(inputs, b.getInputs());
    assertEquals(outputs, b.getOutputs());
  }
}
