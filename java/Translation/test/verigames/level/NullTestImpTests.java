package verigames.level;

import static org.junit.Assert.assertTrue;

import java.lang.reflect.Field;
import java.lang.reflect.InvocationTargetException;
import java.lang.reflect.Method;


import org.junit.Before;
import org.junit.Test;

import verigames.level.Chute;
import verigames.level.Intersection;
import verigames.level.NullTest;
import verigames.level.Intersection.Kind;

public class NullTestImpTests
{  
   public NullTest n;
   
   public static Method[] nullTestMethods = NullTest.class.getDeclaredMethods();
   
   @Before public void init()
   {
      n = Intersection.factory(Kind.NULL_TEST).asNullTest();
   }
   
   /**
    * Tests that when an editable chute is passed into the setNullChute setter,
    * it throws an IllegalArgumentException.
    */
   @Test public void testUneditableNull()
   {
      Chute uneditable = new Chute();
      uneditable.setNarrow(false);
      
      boolean exceptionThrown = false;
      
      // n.setNullChute(uneditable)
      try
      {
         runMethod(n, "setNullChute", new Object[] {uneditable});
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
      Chute uneditable = new Chute();
      uneditable.setNarrow(true);
      
      boolean exceptionThrown = false;
      
      // n.setNonNullChute(uneditable)
      try
      {
         runMethod(n, "setNonNullChute", new Object[] {uneditable});
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
      Chute narrow = new Chute();
      narrow.setNarrow(true);
      narrow.setEditable(false);
      
      boolean exceptionThrown = false;
      
      // n.setNonNullChute(narrow)
      try
      {
         runMethod(n, "setNullChute", new Object[] {narrow});
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
      Chute wide = new Chute();
      wide.setNarrow(false);
      wide.setEditable(false);
      
      boolean exceptionThrown = false;
      
      // n.setNonNullChute(wide)
      try
      {
         runMethod(n, "setNonNullChute", new Object[] {wide});
      } catch (Throwable e)
      {
         if (e instanceof IllegalArgumentException)
            exceptionThrown = true;
      }
      assertTrue("IllegalArgumentException not thrown when expected",
            exceptionThrown);
   }
   
   /**
    * Tests that when a chute is mutated after adding that checkRep()
    * catches it later
    */
   @Test public void testCheckRep() throws Throwable
   {
      boolean checkRepEnabled = true;
      
      // checkRepEnabled = NullTest.CHECK_REP_ENABLED
      Field[] fields = NullTest.class.getDeclaredFields();
      for (Field f : fields)
      {
         if (f.getName().equals("CHECK_REP_ENABLED"))
         {
            f.setAccessible(true);
            checkRepEnabled = (Boolean) f.get(NullTest.class);
         }
      }
      
      if (checkRepEnabled)
      {
         NullTest n = Intersection.factory(Kind.NULL_TEST).asNullTest();
         
         Chute wide = new Chute();
         wide.setNarrow(false);
         wide.setEditable(false);
         
         // n.setNullChute(wide)
         runMethod(n, "setNullChute", new Object[] {wide});
         
         wide.setNarrow(true);
         
         Chute narrow = new Chute();
         narrow.setNarrow(true);
         narrow.setEditable(false);
         
         // n.setNonNullChute(narrow)
         // should throw RuntimeException when checkRep catches the mutation to
         // wide
         boolean expectedExceptionThrown = false;
         try
         {
            runMethod(n, "setNonNullChute", new Object[] {narrow});
         } catch (Throwable e)
         {
            if (e instanceof RuntimeException)
               expectedExceptionThrown = true;
         }
         assertTrue(expectedExceptionThrown);
      }
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
         throw new Exception("Given method not found");
   }
}
