package level.tests;

import org.junit.Before;
import org.junit.Test;

/**
 * @author Nathaniel Mote
 *
 */

public class BoardImpTests
{
   // uses the test objects initialized in the spec tests. I know it's not the
   // best style, but it's just a test. Still, if anybody has an objection, I
   // can rewrite it.
   BoardSpecTests testObjs = new BoardSpecTests();
   
   @Before public void init()
   {
      testObjs.initBoards();
   }
   
   // tests that the addEdge method throws exceptions on bad arguments
   @Test public void testAddEdge()
   {
      
   }
   
   // tests that the addNode method throws exceptions on bad arguments
   @Test public void testAddNode()
   {
      
   }
}
