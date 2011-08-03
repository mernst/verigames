package level.tests;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertFalse;
import static org.junit.Assert.assertNull;
import static org.junit.Assert.assertTrue;

import java.lang.reflect.InvocationTargetException;
import java.lang.reflect.Method;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;

import level.Chute;
import level.Intersection;
import level.Intersection.Kind;

import org.junit.Before;
import org.junit.Test;

public class IntersectionSpecTests
{
   /**
    * Tests that isSubnetwork returns false
    */
   @Test public void isSubNetworkTest()
   {
      assertFalse(
            "isSubnetwork should return false on a regular Intersection.",
            (Intersection.factory(Kind.MERGE)).isSubnetwork());
   }
   
   /**
    * Tests that isNullTest returns false
    */
   @Test public void isNullTestTest()
   {
      assertFalse("isNullTest should return false on a regular Intersection.",
            (Intersection.factory(Kind.MERGE)).isNullTest());
   }
   
   /**
    * Tests that the UID of every intersection is unique
    */
   @Test public void testUID()
   {
      ArrayList<Intersection> elts = new ArrayList<Intersection>();
      for (int i = 0; i < 8; i++)
         elts.add(Intersection.factory(Kind.CONNECT));
      
      for (Intersection i : elts)
      {
         for (Intersection j : elts)
         {
            assertTrue(
                  "Intersections of different identities should have different UIDs",
                  i == j || i.getUID() != j.getUID());
         }
      }
   }
   
   public Intersection i;
   public Intersection j;
   public Chute chute1;
   public Chute chute2;
   
   public static List<Method> intersectionMethods;
   static
   {
      intersectionMethods = new ArrayList<Method>();
      
      // add all declared methods in Chute class and superclasses
      for (Class<?> currentClass = Intersection.class; currentClass != null; currentClass = currentClass
            .getSuperclass())
         intersectionMethods.addAll(Arrays.asList(currentClass.getDeclaredMethods()));
   }
   
   @Before public void init()
   {
      i = Intersection.factory(Kind.INCOMING);
      j = Intersection.factory(Kind.OUTGOING);
      chute1 = new Chute(null, true, null);
      chute2 = new Chute(null, true, null);
   }
   
   /**
    * Tests that getInput returns the correct chute or null
    */
   @Test public void getInputTest() throws IllegalAccessException,
         InvocationTargetException
   {
      assertNull(j.getInput(5));
      
      for (Method m : intersectionMethods)
      {
         if (m.getName().equals("setInput"))
         {
            m.setAccessible(true);
            Object[] args = { chute1, 5 };
            m.invoke(j, args);
         }
      }
      
      assertEquals(j.getInput(5), chute1);
      assertNull(j.getInput(1));
      assertNull(j.getInput(7));
   }
   
   /**
    * Tests that getOutput returns the correct chute or null
    */
   @Test public void getOutputTest() throws IllegalAccessException,
         InvocationTargetException
   {
      assertNull(i.getOutput(5));
      
      for (Method m : intersectionMethods)
      {
         if (m.getName().equals("setOutput"))
         {
            m.setAccessible(true);
            Object[] args = { chute1, 5 };
            m.invoke(i, args);
         }
      }
      
      assertEquals(i.getOutput(5), chute1);
      assertNull(i.getOutput(1));
      assertNull(i.getOutput(7));
   }
}
