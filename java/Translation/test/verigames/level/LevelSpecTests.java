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
  
  @Before public void init()
  {
    chutes = new Chute[10];
    
    for (int i = 0; i < chutes.length; i++)
      chutes[i] = new Chute(i, null);
    
    // Add all of these to a board, then add the board to a level in order to
    // satisfy precondition for makeLinked
    b = new Board();
    
    Intersection in = Intersection.factory(Kind.INCOMING);
    Intersection out = Intersection.factory(Kind.OUTGOING);
    
    b.addNode(in);
    b.addNode(out);
    
    for (int i = 0; i < chutes.length; i++)
      b.addEdge(in, Integer.toString(i), out, Integer.toString(i), chutes[i]);
    
    l = new Level();
    l.addBoard("asdf", b);
    // now any subset of the chutes in the array can be given as an argument
    // to makeLinked
  }
  
  /**
   * Test basic functionality in makeLinked.
   */
  @Test public void testLinkedEdges1()
  {
    Set<Chute> set1 = new HashSet<Chute>();
    for (int i = 0; i < 5; i++)
      set1.add(chutes[i]);
    
    Set<Chute> set2 = new HashSet<Chute>();
    for (int i = 5; i < chutes.length; i++)
      set2.add(chutes[i]);
    
    l.makeLinked(set1);
    l.makeLinked(set2);
    
    assertTrue(l.areLinked(set1));
    assertTrue(l.areLinked(set2));
    
    // Check that not all of the chutes are linked
    Set<Chute> set3 = new HashSet<Chute>();
    for (Chute c : chutes)
      set3.add(c);
    assertFalse(l.areLinked(set3));
    
    // Check that two chutes (an arbitrary one from each original set) are not
    // linked
    Set<Chute> set4 = new HashSet<Chute>();
    set4.add(chutes[1]);
    set4.add(chutes[8]);
    assertFalse(l.areLinked(set4));
  }
  
  /**
   * Test that different sets of linked chutes are combined into one when
   * necessary
   */
  @Test public void testLinkedEdges2()
  {
    Set<Chute> set1 = new HashSet<Chute>();
    set1.add(chutes[0]);
    set1.add(chutes[1]);
    set1.add(chutes[2]);
    
    Set<Chute> set2 = new HashSet<Chute>();
    set2.add(chutes[3]);
    set2.add(chutes[4]);
    
    l.makeLinked(set1);
    l.makeLinked(set2);
    
    assertTrue(l.areLinked(set1));
    assertTrue(l.areLinked(set2));
    
    Set<Chute> set3 = new HashSet<Chute>();
    set3.add(chutes[0]);
    set3.add(chutes[3]);
    
    assertFalse(l.areLinked(set3));
    
    l.makeLinked(set3);
    
    assertTrue(l.areLinked(set3));
    
    Set<Chute> set4 = new HashSet<Chute>();
    for (int i = 0; i < 5; i++)
      set4.add(chutes[i]);
    
    assertTrue(l.areLinked(set4));
  }
  
  /**
   * Test that any given edge is always linked with itself (reflexivity in the
   * equivalence relation)
   */
  @Test public void testLinkedEdges3()
  {
    Set<Chute> set1 = new HashSet<Chute>();
    set1.add(chutes[0]);
    
    assertTrue(l.areLinked(set1));
    
    Set<Chute> set2 = new HashSet<Chute>();
    for (Chute c : chutes)
      set2.add(c);
    
    l.makeLinked(set2);
    assertTrue(l.areLinked(set1));
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
