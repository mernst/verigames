package level.tests;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertNull;
import static org.junit.Assert.assertTrue;
import static org.junit.Assert.assertFalse;

import java.lang.reflect.InvocationTargetException;
import java.lang.reflect.Method;
import java.util.ArrayList;
import java.util.List;

import level.Chute;
import level.Intersection;
import level.Intersection.Kind;

import org.junit.Before;
import org.junit.Test;

/**
 * @author Nathaniel Mote
 * 
 */

public class ChuteSpecTests
{
   
   public Chute namedPinchedEditable;
   public Chute namedPinchedUneditable;
   public Chute namedUnpinchedEditable;
   public Chute namedUnpinchedUneditable;
   public Chute unnamedPinchedEditable;
   public Chute unnamedPinchedUneditable;
   public Chute unnamedUnpinchedEditable;
   public Chute unnamedUnpinchedUneditable;
   
   public List<Chute> allChutes;
   
   // TODO replace Name with whatever we end up using, and make that field
   // not-null in some of the Chutes
   
   public Method[] chuteMethods;
   
   public Intersection incoming;
   public Intersection outgoing;
   
   @Before public void initChutes()
   {
      namedPinchedEditable = new Chute(null, true, true, null);
      namedPinchedUneditable = new Chute(null, true, false, null);
      namedUnpinchedEditable = new Chute(null, false, true, null);
      namedUnpinchedUneditable = new Chute(null, false, false, null);
      unnamedPinchedEditable = new Chute(null, true, true, null);
      unnamedPinchedUneditable = new Chute(null, true, false, null);
      unnamedUnpinchedEditable = new Chute(null, false, true, null);
      unnamedUnpinchedUneditable = new Chute(null, false, false, null);
      
      allChutes = new ArrayList<Chute>();
      
      allChutes.add(namedPinchedEditable);
      allChutes.add(namedPinchedUneditable);
      allChutes.add(namedUnpinchedEditable);
      allChutes.add(namedUnpinchedUneditable);
      allChutes.add(unnamedPinchedEditable);
      allChutes.add(unnamedPinchedUneditable);
      allChutes.add(unnamedUnpinchedEditable);
      allChutes.add(unnamedUnpinchedUneditable);
      
      chuteMethods = Chute.class.getDeclaredMethods();
      
      incoming = new Intersection(Kind.INCOMING);
      outgoing = new Intersection(Kind.OUTGOING);
   }
   
   @Test public void testUID()
   {
      for (Chute i : allChutes)
      {
         assertTrue("A chute does not have an odd UID (" + i.getUID() + ")",
               i.getUID() % 2 == 1);
         for (Chute j : allChutes)
         {
            assertTrue(
                  "Two chutes with different identities have the same UID",
                  i == j || i.getUID() != j.getUID());
         }
      }
   }
   
   // Tests that the Chute behaves properly with its start and end intersections
   @Test public void testIntersections() throws InvocationTargetException,
         IllegalAccessException
   {
      Chute chute = new Chute(null, false, true, null);
      
      assertNull(chute.getStart());
      assertNull(chute.getEnd());
      
      // chute.setStart(incoming, 4);
      for (Method m : chuteMethods)
      {
         if (m.getName().equals("setStart"))
         {
            m.setAccessible(true);
            Object[] args = { incoming, 4 };
            m.invoke(chute, args);
         }
      }
      
      assertEquals(chute.getStart(), incoming);
      assertEquals(chute.getStartPort(), 4);
      
      assertNull(chute.getEnd());
      
      // chute.setEnd(outgoing, 7);
      for (Method m : chuteMethods)
      {
         if (m.getName().equals("setEnd"))
         {
            m.setAccessible(true);
            Object[] args = { outgoing, 7 };
            m.invoke(chute, args);
         }
      }
      
      assertEquals(chute.getEnd(), outgoing);
      assertEquals(chute.getEndPort(), 7);
   }
   
   /**
    * Tests that the isPinched getter is working properly
    */
   @Test public void testIsPinched()
   {
      assertTrue(namedPinchedEditable.isPinched());
      assertTrue(namedPinchedUneditable.isPinched());
      assertTrue(unnamedPinchedEditable.isPinched());
      
      assertFalse(namedUnpinchedEditable.isPinched());
      assertFalse(namedUnpinchedUneditable.isPinched());
      assertFalse(unnamedUnpinchedEditable.isPinched());
   }
   
   /**
    * Tests that the isEditable getter is working properly
    */
   @Test public void testIsEditable()
   {
      assertTrue(namedPinchedEditable.isEditable());
      assertTrue(namedUnpinchedEditable.isEditable());
      assertTrue(unnamedUnpinchedEditable.isEditable());
      
      assertFalse(unnamedUnpinchedUneditable.isEditable());
      assertFalse(namedPinchedUneditable.isEditable());
      assertFalse(namedUnpinchedUneditable.isEditable());
   }
   
   /**
    * Test that the auxiliary chute accessors work properly
    */
   @Test public void testAuxChutes()
   {
      // Represents the variable
      // Map<String, Integer> map;
      
      Chute IntegerChute = new Chute(null, false, true, null);
      Chute StringChute = new Chute(null, false, true, null);
      List<Chute> aux = new ArrayList<Chute>();
      aux.add(StringChute);
      aux.add(IntegerChute);
      Chute mapChute = new Chute("map", false, true, aux);
      
      assertEquals(aux, mapChute.getAuxiliaryChutes());
      
      List<Chute> aux2 = new ArrayList<Chute>(aux);
      assertEquals(aux, aux2);
      
      // make sure that it copies the given list
      aux.remove(1);
      assertEquals(aux2, mapChute.getAuxiliaryChutes());
   }
   
}
