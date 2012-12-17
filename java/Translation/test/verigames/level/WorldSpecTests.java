package verigames.level;

import static org.junit.Assert.*;

import org.junit.*;

import verigames.level.*;

import java.io.*;
import java.util.*;

public class WorldSpecTests
{
  @Test(expected = IllegalStateException.class)
  public void testDuplicateNames()
  {
    Board first = boardFactory(Intersection.factory(Intersection.Kind.SPLIT), 1, 2);
    Board second = boardFactory(Intersection.factory(Intersection.Kind.SPLIT), 1, 2);

    World w = makeWorldWithBoards("name", first, "name", second);

    triggerException(w);
  }

  @Test(expected = IllegalStateException.class)
  public void testNonexistentReferent()
  {
    Board first = boardFactory(Intersection.subboardFactory("non-existent-name"), 2, 2);
    Board second = boardFactory(Intersection.factory(Intersection.Kind.SPLIT), 1, 2);

    World w = makeWorldWithBoards("name1", first, "name2", second);

    triggerException(w);
  }

  @Test(expected = IllegalStateException.class)
  public void testInconsistentInputPortNumbers()
  {
    Board first = boardFactory(Intersection.factory(Intersection.Kind.SPLIT), 1, 2);
    Board second = boardFactory(Intersection.subboardFactory("name1"), 2, 2);

    World w = makeWorldWithBoards("name1", first, "name2", second);

    triggerException(w);
  }

  @Test(expected = IllegalStateException.class)
  public void testInconsistentOutputPortNumbers()
  {
    Board first = boardFactory(Intersection.factory(Intersection.Kind.SPLIT), 1, 2);
    Board second = boardFactory(Intersection.subboardFactory("name1"), 1, 1);

    World w = makeWorldWithBoards("name1", first, "name2", second);

    triggerException(w);
  }

  @Test(expected = IllegalStateException.class)
  public void testInconsistentInputPortIdentifiers()
  {
    Board first = boardFactory(Intersection.factory(Intersection.Kind.SPLIT), 1, 2, Arrays.asList("1"), Arrays.asList("1", "2"));
    Board second = boardFactory(Intersection.subboardFactory("name1"), 1, 2, Arrays.asList("one"), Arrays.asList("1", "2"));

    World w = makeWorldWithBoards("name1", first, "name2", second);

    triggerException(w);
  }

  @Test(expected = IllegalStateException.class)
  public void testInconsistentOutputPortIdentifiers()
  {
    Board first = boardFactory(Intersection.factory(Intersection.Kind.SPLIT), 1, 2, Arrays.asList("1"), Arrays.asList("1", "2"));
    Board second = boardFactory(Intersection.subboardFactory("name1"), 1, 2, Arrays.asList("1"), Arrays.asList("1", "two"));

    World w = makeWorldWithBoards("name1", first, "name2", second);

    triggerException(w);
  }

  private Board boardFactory(Intersection intersection, int numInPorts, int numOutPorts)
  {
    List<String> inPorts = new ArrayList<String>();
    List<String> outPorts = new ArrayList<String>();
    for (int i = 0; i < numInPorts; i++)
      inPorts.add(Integer.toString(i));
    for (int i = 0; i < numOutPorts; i++)
      outPorts.add(Integer.toString(i));

    return boardFactory(intersection, numInPorts, numOutPorts, inPorts, outPorts);
  }

  /** returns a board that contains only the given Intersection */
  private Board boardFactory(Intersection intersection, int numInPorts, int numOutPorts, List<String> inPorts, List<String> outPorts)
  {
    Board b = new Board();
    Intersection incoming = Intersection.factory(Intersection.Kind.INCOMING);
    Intersection outgoing = Intersection.factory(Intersection.Kind.OUTGOING);

    b.addNode(incoming);
    b.addNode(outgoing);
    b.addNode(intersection);

    for (int i = 0; i < numInPorts; i++)
    {
      String portStr = inPorts.get(i);
      b.addEdge(incoming, portStr, intersection, portStr, new Chute());
    }
    for (int i = 0; i < numOutPorts; i++)
    {
      String portStr = outPorts.get(i);
      b.addEdge(intersection, portStr, outgoing, portStr, new Chute());
    }

    b.finishConstruction();

    return b;
  }

  /** returns a World with the two given Boards in different levels. */
  private World makeWorldWithBoards(String firstName, Board first, String secondName, Board second)
  {
    Level firstLevel = new Level();
    Level secondLevel = new Level();

    firstLevel.addBoard(firstName, first);
    secondLevel.addBoard(secondName, second);

    firstLevel.finishConstruction();
    secondLevel.finishConstruction();

    World w = new World();
    w.addLevel("first", firstLevel);
    w.addLevel("second", secondLevel);

    return w;
  }

  private final PrintStream outputStub;
  {
    OutputStream outputStreamStub = new OutputStream()
    {
      @Override
      public void write(int b) { }
    };

    outputStub = new PrintStream(outputStreamStub);
  }

  // elicits an IllegalStateException if the given World fails the
  // board/subboard consistency checks
  public void triggerException(World w)
  {
    WorldXMLPrinter p = new WorldXMLPrinter();
    p.print(w, outputStub, null);
  }
}
