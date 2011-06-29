package level.tests;

import static org.junit.Assert.assertFalse;
import level.Intersection;
import level.Intersection.Kind;

import org.junit.Test;

/**
 * @author Nathaniel Mote
 * 
 */

public class IntersectionSpecTests
{
   // TODO write tests:
   /*
    * is_____() methods return false
    * 
    * test UID uniqueness and evenness
    * 
    * test get__chute with existing chutes, non-existing chutes, and ports
    * higher than any given so far
    */
   
   /**
    * Tests that isSubnetwork returns false
    */
   @Test public void isSubNetworkTest()
   {
      assertFalse(
            "isSubnetwork should return false on a regular Intersection.",
            (new Intersection(Kind.MERGE)).isSubnetwork());
   }
   
   /**
    * Tests that isNullTest returns false
    */
   @Test public void isNullTestTest()
   {
      assertFalse(
            "isNullTest should return false on a regular Intersection.",
            (new Intersection(Kind.MERGE)).isNullTest());
   }
   
}
