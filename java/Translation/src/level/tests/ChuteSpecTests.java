package level.tests;

import static org.junit.Assert.assertTrue;

import java.util.ArrayList;
import java.util.List;

import level.Chute;
import level.Intersection;
import level.Intersection.Kind;

import org.junit.Before;
import org.junit.Test;

/**
 * @author Nathaniel Mote
 * 
 */

public class ChuteSpecTests
{
   
   public Chute namedPinchedEditable;
   public Chute namedPinchedUneditable;
   public Chute namedUnpinchedEditable;
   public Chute namedUnpinchedUneditable;
   public Chute unnamedPinchedEditable;
   public Chute unnamedPinchedUneditable;
   public Chute unnamedUnpinchedEditable;
   public Chute unnamedUnpinchedUneditable;
   
   public List<Chute> allChutes;
   
   // TODO replace Name with whatever we end up using, and make that field
   // not-null in some of the Chutes
   
   public Intersection incoming;
   public Intersection outgoing;
   
   @Before public void initChutes()
   {
      namedPinchedEditable = new Chute(null, true, true, null);
      namedPinchedUneditable = new Chute(null, true, false, null);
      namedUnpinchedEditable = new Chute(null, false, true, null);
      namedUnpinchedUneditable = new Chute(null, false, false, null);
      unnamedPinchedEditable = new Chute(null, true, true, null);
      unnamedPinchedUneditable = new Chute(null, true, false, null);
      unnamedUnpinchedEditable = new Chute(null, false, true, null);
      unnamedUnpinchedUneditable = new Chute(null, false, false, null);
      
      allChutes = new ArrayList<Chute>();
      
      allChutes.add(namedPinchedEditable);
      allChutes.add(namedPinchedUneditable);
      allChutes.add(namedUnpinchedEditable);
      allChutes.add(namedUnpinchedUneditable);
      allChutes.add(unnamedPinchedEditable);
      allChutes.add(unnamedPinchedUneditable);
      allChutes.add(unnamedUnpinchedEditable);
      allChutes.add(unnamedUnpinchedUneditable);
      
      incoming = new Intersection(Kind.INCOMING);
      outgoing = new Intersection(Kind.OUTGOING);
   }
   
   @Test public void testUID()
   {
      for (Chute i : allChutes)
      {
         assertTrue("A chute does not have an odd UID (" + i.getUID() + ")",
               i.getUID() % 2 == 1);
         for (Chute j : allChutes)
         {
            assertTrue(
                  "Two chutes with different identities have the same UID",
                  i == j || i.getUID() != j.getUID());
         }
      }
   }
   
   // TODO write some tests with Intersection, once that's nailed down.
   /*
    * Tests to do:
    * 
    * - Test Intersection accessors (high port numbers, too)
    * 
    * - Double check other accessors
    * 
    * - Test auxiliary chutes
    */
   
   // Tests that the Chute behaves properly with its start and end intersections
   @Test public void testIntersections()
   {
      
   }
   
}
