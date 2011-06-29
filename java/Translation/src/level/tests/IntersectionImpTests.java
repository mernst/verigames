package level.tests;

import level.Intersection;
import level.Intersection.Kind;

import org.junit.Test;

/**
 * @author Nathaniel Mote
 * 
 */

public class IntersectionImpTests
{
   /**
    * Tests to make sure that the Intersection constructor fails on Kind
    * SUBNETWORK
    */
   @Test(expected=IllegalArgumentException.class)
   public void testConstructorFailure1()
   {
      new Intersection(Kind.SUBNETWORK);
   }
   
   /**
    * Tests to make sure that the Intersection constructor fails on Kind
    * NULL_TEST
    */
   @Test(expected=IllegalArgumentException.class)
   public void testConstructorFailure2()
   {
      new Intersection(Kind.NULL_TEST);
   }
}
