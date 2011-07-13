package level.tests;

import static org.junit.Assert.assertFalse;
import static org.junit.Assert.assertNull;
import static org.junit.Assert.assertTrue;
import static org.junit.Assert.assertEquals;
import level.Board;
import level.Chute;
import level.Intersection;
import level.Intersection.Kind;

import org.junit.Before;
import org.junit.Test;

public class BoardSpecTests
{
   
   public Board board;
   
   public Intersection incoming;
   public Intersection outgoing;
   public Intersection split;
   public Intersection merge;
   
   public Chute chute1;
   public Chute chute2;
   
   @Before public void initBoards()
   {
      board = new Board();
      
      incoming = Intersection.intersectionFactory(Kind.INCOMING);
      outgoing = Intersection.intersectionFactory(Kind.OUTGOING);
      split = Intersection.intersectionFactory(Kind.SPLIT);
      merge = Intersection.intersectionFactory(Kind.MERGE);
      
      chute1 = new Chute(null, false, true, null);
      chute2 = new Chute(null, false, true, null);
   }
   
   // tests the contains method
   @Test public void containsTest()
   {
      assertFalse("An empty board should contain no elements",
            board.contains(incoming));
      assertFalse("An empty board should contain no elements",
            board.contains(chute1));
      
      board.addNode(incoming);
      assertTrue("board should contain incoming node", board.contains(incoming));
      
      board.addNode(split);
      assertTrue("board should contain split node", board.contains(split));
      
      board.addEdge(incoming, 0, split, 0, chute1);
      assertTrue("board should contain chute1", board.contains(chute1));
      
   }
   
   // tests getIncomingNode
   @Test public void incomingTest()
   {
      assertNull(
            "getIncomingNode should return null before an incoming node is added",
            board.getIncomingNode());
      
      board.addNode(incoming);
      assertEquals("getIncomingNode should return incoming", incoming,
            board.getIncomingNode());
   }
   
   // tests getOutgoingNode
   @Test public void outgoingTest()
   {
      assertNull(
            "getOutgoingNode should return null before an outgoing node is added",
            board.getOutgoingNode());
      
      board.addNode(incoming);
      board.addNode(outgoing);
      assertEquals("getOutgoingNode should return outgoing", outgoing,
            board.getOutgoingNode());
   }
   
   // tests that addEdge performs the proper connections
   @Test public void addEdgeTest()
   {
      board.addNode(incoming);
      board.addNode(outgoing);
      board.addEdge(incoming, 3, outgoing, 5, chute1);
      
      // verify that the connections between the chute and nodes have all been
      // made properly
      assertEquals(incoming.getOutputChute(3), chute1);
      assertEquals(outgoing.getInputChute(5), chute1);
      assertEquals(chute1.getStart(), incoming);
      assertEquals(chute1.getStartPort(), 3);
      assertEquals(chute1.getEnd(), outgoing);
      assertEquals(chute1.getEndPort(), 5);
   }
   
   @Test
   public void deactivateTest1()
   {
      // TODO make sure Board behaves when deactivated
   }
   
}
