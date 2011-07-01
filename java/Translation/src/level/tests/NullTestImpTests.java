package level.tests;

import org.junit.Test;

public class NullTestImpTests
{
   /*
    * TODO write the following tests
    * 
    * - make sure exception is thrown on bad chute settings
    * 
    * - make sure checkRep() catches a mutation later on (if checkrep is
    * enabled)
    */
   
   /**
    * Tests that when an uneditable chute is passed into the setNullChute
    * setter, it throws an IllegalArgumentException.
    */
   @Test(expected = IllegalArgumentException.class) public void testUneditableNull()
   {
      
   }
}
