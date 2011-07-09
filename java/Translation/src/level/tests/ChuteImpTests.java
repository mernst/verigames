package level.tests;

import level.Chute;

import org.junit.Test;

public class ChuteImpTests
{
   /**
    * Tests that the getStartPort accessor throws an IllegalStateException if
    * there is no starting Intersection
    */
   @Test(expected = IllegalStateException.class) public void getStartPortTest()
   {
      (new Chute(null, true, true, null)).getStartPort();
   }
   
   /**
    * Tests that the getEndPort accessor throws an IllegalStateException if
    * there is no ending Intersection
    */
   @Test(expected = IllegalStateException.class) public void getEndPortTest()
   {
      (new Chute(null, true, true, null)).getEndPort();
   }
}
