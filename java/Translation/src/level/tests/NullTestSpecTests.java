package level.tests;

import static org.junit.Assert.assertEquals;

import java.lang.reflect.InvocationTargetException;
import java.lang.reflect.Method;

import level.Chute;
import level.NullTest;

import org.junit.Test;

public class NullTestSpecTests
{
   /*
    * TODO write the following tests:
    * 
    * - check that the output chutes match up correctly with the null and
    * non-null accessors
    */
   
   /**
    * Tests that the custom accessors access the right output port, as defined
    * in the class spec
    */
   @Test public void testNullChuteAccessors() throws IllegalAccessException, InvocationTargetException
   {
      NullTest nt = new NullTest();
      
      Chute nullable = new Chute(null, false, false, null);
      nullable.setNarrow(false);
      Chute nonNull = new Chute(null, false, false, null);
      nonNull.setNarrow(true);
      
      Method[] ntMethods = NullTest.class.getDeclaredMethods();
      
      // nt.setNonNullChute(nonNull);
      for (Method m : ntMethods)
      {
         if (m.getName().equals("setNonNullChute"))
         {
            m.setAccessible(true);
            m.invoke(nt, new Object[] {nonNull});
         }
      }
      
      // nt.setNullChute(nullable);
      for (Method m : ntMethods)
      {
         if (m.getName().equals("setNullChute"))
         {
            m.setAccessible(true);
            m.invoke(nt, new Object[] {nullable});
         }
      }
      
      assertEquals(nt.getNonNullChute(), nonNull);
      assertEquals(nt.getNullChute(), nullable);
      
      assertEquals(nt.getOutputChute(0), nonNull);
      assertEquals(nt.getOutputChute(1), nullable);
   }
}
