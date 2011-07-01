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
    * Tests that when an uneditable chute is passed into the setNullChute
    * setter, it throws an IllegalArgumentException.
    */
   @Test public void testUneditableNull() throws IllegalAccessException,
         InvocationTargetException
   {
      Chute uneditable = new Chute(null, false, true, null);
      
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
    * 
    */
   
   /**
    * runs the given method on the given receiver with the given arguments
    * (subverting access control)
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
         throw new RuntimeException("Given method not run");
   }
}
