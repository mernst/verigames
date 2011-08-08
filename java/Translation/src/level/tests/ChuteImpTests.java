package level.tests;

import static org.junit.Assert.fail;

import java.lang.reflect.InvocationTargetException;
import java.lang.reflect.Method;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;

import level.Chute;
import level.Intersection;

import org.junit.Before;
import org.junit.Test;

public class ChuteImpTests
{
   /**
    * Tests that the getStartPort accessor throws an IllegalStateException if
    * there is no starting Intersection
    */
   @Test(expected = IllegalStateException.class) public void getStartPortTest()
   {
      (new Chute(null, true)).getStartPort();
   }
   
   /**
    * Tests that the getEndPort accessor throws an IllegalStateException if
    * there is no ending Intersection
    */
   @Test(expected = IllegalStateException.class) public void getEndPortTest()
   {
      (new Chute(null, true)).getEndPort();
   }
   
   private Chute c;
   
   public static List<Method> chuteMethods;
   static
   {
      chuteMethods = new ArrayList<Method>();
      
      // add all declared methods in Chute class and superclasses
      for (Class<?> currentClass = Chute.class; currentClass != null; currentClass = currentClass
            .getSuperclass())
         chuteMethods.addAll(Arrays.asList(currentClass.getDeclaredMethods()));
   }
   
   /**
    * Invokes a method with the given name on the given receiver, with the given
    * arguments, subverting access control
    */
   private void invokeChuteMethod(Chute receiver, String name, Object[] args)
         throws IllegalArgumentException, IllegalAccessException,
         InvocationTargetException
   {
      boolean methodInvoked = false;
      for (Method m : chuteMethods)
      {
         if (m.getName().equals(name))
         {
            m.setAccessible(true);
            m.invoke(receiver, args);
            methodInvoked = true;
         }
      }
      if (!methodInvoked)
         throw new IllegalArgumentException("method " + name
               + " does not exist");
   }
   
   @Before public void initC() throws IllegalArgumentException,
         IllegalAccessException, InvocationTargetException
   {
      c = new Chute("asdf", false);
      
      // c.setStart(Intersection.intersectionFactory(Intersection.Kind.INCOMING),0);
      invokeChuteMethod(
            c,
            "setStart",
            new Object[] {
                  Intersection.factory(Intersection.Kind.INCOMING),
                  0 });
      
      // c.setEnd(Intersection.intersectionFactory(Intersection.Kind.OUTGOING));
      invokeChuteMethod(
            c,
            "setEnd",
            new Object[] {
                  Intersection.factory(Intersection.Kind.OUTGOING),
                  0 });
      
      // c.deactivate();
      invokeChuteMethod(c, "deactivate", new Object[] {});
      
   }
   
   @Test(expected = IllegalStateException.class) public void deactivateTest()
         throws Throwable
   {
      // c.deactivate() (calling it a second time should throw an
      // IllegalStateException)
      try
      {
         invokeChuteMethod(c, "deactivate", new Object[] {});
      }
      catch (InvocationTargetException e)
      {
         throw e.getCause();
      }
      catch (Exception e)
      {
         fail();
      }
   }
   
   @Test(expected = IllegalStateException.class) public void narrowTest()
   {
      c.setNarrow(true);
   }
   
   @Test(expected = IllegalStateException.class) public void setStartTest() throws Throwable
   {
      // c.setStart(Intersection.intersectionFactory(Intersection.Kind.START_WHITE_BALL),0);
      try
      {
         invokeChuteMethod(c, "setStart", new Object[] {Intersection.factory(Intersection.Kind.START_WHITE_BALL), 0});
      }
      catch (InvocationTargetException e)
      {
         throw e.getCause();
      }
      catch (Exception e)
      {
         fail();
      }
   }
   
   @Test(expected = IllegalStateException.class) public void setEndTest() throws Throwable
   {
      // c.setEnd(Intersection.intersectionFactory(Intersection.Kind.END),0);
      try
      {
         invokeChuteMethod(c, "setEnd", new Object[] {Intersection.factory(Intersection.Kind.END), 0});
      }
      catch (InvocationTargetException e)
      {
         throw e.getCause();
      }
      catch (Exception e)
      {
         fail();
      }
   }
}
