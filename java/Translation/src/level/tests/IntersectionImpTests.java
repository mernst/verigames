package level.tests;

import level.Intersection;
import level.Intersection.Kind;

import org.junit.Test;

public class IntersectionImpTests
{
   // TODO add test to ensure that inactive Intersections can't be mutated
   /**
    * Tests to make sure that the Intersection factory fails on Kind SUBNETWORK
    */
   @Test(expected = IllegalArgumentException.class) public void testConstructorFailure1()
   {
      Intersection.intersectionFactory(Kind.SUBNETWORK);
   }
   
   /**
    * Tests that asSubnetwork fails on Intersection instances
    */
   @Test(expected = IllegalStateException.class) public void testAsSubnetworkFailure()
   {
      (Intersection.intersectionFactory(Kind.INCOMING)).asSubnetwork();
   }
   
   /**
    * Tests that asNullTest fails on Intersection instances
    */
   @Test(expected = IllegalStateException.class) public void testAsNullTestFailure()
   {
      (Intersection.intersectionFactory(Kind.INCOMING)).asNullTest();
   }
}
