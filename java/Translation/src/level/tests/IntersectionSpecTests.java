package level.tests;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertFalse;
import static org.junit.Assert.assertNull;
import static org.junit.Assert.assertTrue;

import java.lang.reflect.InvocationTargetException;
import java.lang.reflect.Method;
import java.util.ArrayList;

import level.Chute;
import level.Intersection;
import level.Intersection.Kind;

import org.junit.Before;
import org.junit.Test;

/**
 * @author Nathaniel Mote
 * 
 */

public class IntersectionSpecTests
{
   // TODO write tests:
   /*
    * test get__chute with existing chutes, non-existing chutes, and ports
    * higher than any given so far
    */
   
   /**
    * Tests that isSubnetwork returns false
    */
   @Test public void isSubNetworkTest()
   {
      assertFalse(
            "isSubnetwork should return false on a regular Intersection.",
            (new Intersection(Kind.MERGE)).isSubnetwork());
   }
   
   /**
    * Tests that isNullTest returns false
    */
   @Test public void isNullTestTest()
   {
      assertFalse("isNullTest should return false on a regular Intersection.",
            (new Intersection(Kind.MERGE)).isNullTest());
   }
   
   /**
    * Tests that the UID of every intersection is unique and even
    */
   @Test public void testUID()
   {
      ArrayList<Intersection> elts = new ArrayList<Intersection>();
      for (int i = 0; i < 8; i++)
         elts.add(new Intersection(Kind.CONNECT));
      
      for (Intersection i : elts)
      {
         assertEquals("Intersections' UID's should be even (" + i.getUID()
               + ")", i.getUID() % 2, 0);
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
   
   public Method[] intersectionMethods;
   
   @Before public void init()
   {
      i = new Intersection(Kind.INCOMING);
      j = new Intersection(Kind.OUTGOING);
      chute1 = new Chute(null, true, true, null);
      chute2 = new Chute(null, true, true, null);
      
      intersectionMethods = Intersection.class.getDeclaredMethods();
   }
   
   /**
    * Tests that getInputChute returns the correct chute or null
    */
   @Test public void getInputChuteTest() throws IllegalAccessException,
         InvocationTargetException
   {
      assertNull(j.getInputChute(5));
      
      for (Method m : intersectionMethods)
      {
         if (m.getName().equals("setInputChute"))
         {
            m.setAccessible(true);
            Object[] args = { chute1, 5 };
            m.invoke(j, args);
         }
      }
      
      assertEquals(j.getInputChute(5), chute1);
      assertNull(j.getInputChute(1));
      assertNull(j.getInputChute(7));
   }
   
   /**
    * Tests that getOutputChute returns the correect chute or null 
    */
   @Test public void getOutputChuteTest() throws IllegalAccessException, InvocationTargetException
   {
      assertNull(i.getOutputChute(5));
      
      for (Method m : intersectionMethods)
      {
         if (m.getName().equals("setOutputChute"))
         {
            m.setAccessible(true);
            Object[] args = { chute1, 5 };
            m.invoke(i, args);
         }
      }
      
      assertEquals(i.getOutputChute(5), chute1);
      assertNull(i.getOutputChute(1));
      assertNull(i.getOutputChute(7));
   }
}
