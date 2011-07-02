package level.tests;

import level.Board;
import level.Chute;
import level.Intersection;
import level.Intersection.Kind;
import level.Level;

import org.junit.Before;
import org.junit.Test;

public class LevelSpecTests
{
   /*
    * TODO write the following tests:
    * 
    * - Test linked edge behavior (link edges, make sure they're linked, repeat)
    */
   
   public Chute[] chutes;
   
   public Board b;
   
   public Level l;
   
   
   @Before public void init()
   {
      chutes = new Chute[10];
      
      for (int i = 0; i < chutes.length; i++)
         chutes[i] = new Chute(null, false, true, null);
      
      // Add all of these to a board, then add the board to a level in order to
      // satisfy precondition for makeLinked
      b = new Board();
      
      Intersection in = new Intersection(Kind.INCOMING);
      Intersection out = new Intersection(Kind.OUTGOING);
      
      b.addNode(in);
      b.addNode(out);
      
      for (int i = 0; i < chutes.length; i++)
         b.addEdge(in, i, out, i, chutes[i]);
      
      l = new Level();
      l.addBoard("asdf", b);
      // now any subset of the chutes in the array can be given as an argument
      // to makeLinked
   }
   
   @Test public void testLinkedEdges1()
   {
      
   }
}
