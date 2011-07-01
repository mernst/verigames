package level.tests;

import static org.junit.Assert.assertTrue;

import java.lang.reflect.InvocationTargetException;
import java.lang.reflect.Method;

import level.Chute;
import level.NullTest;

import org.junit.Before;
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
   
   public NullTest n;
   
   public static Method[] nullTestMethods = NullTest.class.getDeclaredMethods();
   
   @Before public void init()
   {
      n = new NullTest();
   }
   
   /**
    * Tests that when an editable chute is passed into the setNullChute setter,
    * it throws an IllegalArgumentException.
    */
   @Test public void testUneditableNull()
   {
      Chute uneditable = new Chute(null, false, true, null);
      uneditable.setNarrow(false);
      
      boolean exceptionThrown = false;
      
      // n.setNullChute(uneditable)
      Object[] args = { uneditable };
      try
      {
         runMethod(n, "setNullChute", args);
      } catch (Throwable e)
      {
         if (e instanceof IllegalArgumentException)
            exceptionThrown = true;
      }
      assertTrue("IllegalArgumentException not thrown when expected",
            exceptionThrown);
   }
   
   /**
    * Tests that when an editable chute is passed into the setNonNullChute
    * setter, it throws an IllegalArgumentException
    */
   @Test public void testUneditableNonNull()
   {
      Chute uneditable = new Chute(null, false, true, null);
      uneditable.setNarrow(true);
      
      boolean exceptionThrown = false;
      
      // n.setNonNullChute(uneditable)
      Object[] args = { uneditable };
      try
      {
         runMethod(n, "setNonNullChute", args);
      } catch (Throwable e)
      {
         if (e instanceof IllegalArgumentException)
            exceptionThrown = true;
      }
      assertTrue("IllegalArgumentException not thrown when expected",
            exceptionThrown);
   }
   
   /**
    * Tests that when a narrow chute is passed into the setNullChute setter, it
    * throws an IllegalArgumentException
    */
   @Test public void testNarrowNull()
   {
      Chute narrow = new Chute(null, false, false, null);
      narrow.setNarrow(true);
      
      boolean exceptionThrown = false;
      
      // n.setNonNullChute(narrow)
      Object[] args = { narrow };
      try
      {
         runMethod(n, "setNullChute", args);
      } catch (Throwable e)
      {
         if (e instanceof IllegalArgumentException)
            exceptionThrown = true;
      }
      assertTrue("IllegalArgumentException not thrown when expected",
            exceptionThrown);
   }
   
   /**
    * Tests that when a wide chute is passed into the setNonNullChute setter, it
    * throws an IllegalArgumentException
    */
   @Test public void testWideNonNull()
   {
      Chute wide = new Chute(null, false, false, null);
      wide.setNarrow(false);
      
      boolean exceptionThrown = false;
      
      // n.setNonNullChute(wide)
      Object[] args = { wide };
      try
      {
         runMethod(n, "setNonNullChute", args);
      } catch (Throwable e)
      {
         if (e instanceof IllegalArgumentException)
            exceptionThrown = true;
      }
      assertTrue("IllegalArgumentException not thrown when expected",
            exceptionThrown);
   }
   
   /**
    * runs the given method on the given receiver with the given arguments
    * 
    * I know this is not awesome style, but subverting access control is
    * necessarily a little bit hackish, and it's just a test
    */
   private static void runMethod(NullTest receiver, String methodName,
         Object[] args) throws Throwable
   {
      boolean methodRun = false;
      for (Method m : nullTestMethods)
      {
         if (m.getName().equals(methodName))
         {
            m.setAccessible(true);
            try
            {
               m.invoke(receiver, args);
            } catch (InvocationTargetException e)
            {
               throw e.getCause();
            }
            methodRun = true;
         }
      }
      if (!methodRun)
         throw new RuntimeException("Given method not found");
   }
}
