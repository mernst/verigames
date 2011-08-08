package level.tests;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertFalse;
import static org.junit.Assert.assertNull;
import static org.junit.Assert.assertTrue;

import java.lang.reflect.InvocationTargetException;
import java.lang.reflect.Method;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Iterator;
import java.util.List;

import level.Chute;
import level.Intersection;
import level.Intersection.Kind;

import org.junit.Before;
import org.junit.Test;

public class ChuteSpecTests
{
   // TODO add test for aux chute traversal
   
   public Chute namedPinchedEditable;
   public Chute namedPinchedUneditable;
   public Chute namedUnpinchedEditable;
   public Chute namedUnpinchedUneditable;
   public Chute unnamedPinchedEditable;
   public Chute unnamedPinchedUneditable;
   public Chute unnamedUnpinchedEditable;
   public Chute unnamedUnpinchedUneditable;
   
   public List<Chute> allChutes;
   
   public static List<Method> chuteMethods;
   static
   {
      chuteMethods = new ArrayList<Method>();
      
      // add all declared methods in Chute class and superclasses
      for (Class<?> currentClass = Chute.class; currentClass != null; currentClass = currentClass
            .getSuperclass())
         chuteMethods.addAll(Arrays.asList(currentClass.getDeclaredMethods()));
   }
   
   public Intersection incoming;
   public Intersection outgoing;
   
   @Before public void initChutes()
   {
      namedPinchedEditable = new Chute(null, true);
      namedPinchedEditable.setPinched(true);
      namedPinchedUneditable = new Chute(null, false);
      namedPinchedUneditable.setPinched(true);
      namedUnpinchedEditable = new Chute(null, true);
      namedUnpinchedUneditable = new Chute(null, false);
      unnamedPinchedEditable = new Chute(null, true);
      unnamedPinchedEditable.setPinched(true);
      unnamedPinchedUneditable = new Chute(null, false);
      unnamedPinchedUneditable.setPinched(true);
      unnamedUnpinchedEditable = new Chute(null, true);
      unnamedUnpinchedUneditable = new Chute(null, false);
      
      allChutes = new ArrayList<Chute>();
      
      allChutes.add(namedPinchedEditable);
      allChutes.add(namedPinchedUneditable);
      allChutes.add(namedUnpinchedEditable);
      allChutes.add(namedUnpinchedUneditable);
      allChutes.add(unnamedPinchedEditable);
      allChutes.add(unnamedPinchedUneditable);
      allChutes.add(unnamedUnpinchedEditable);
      allChutes.add(unnamedUnpinchedUneditable);
      
      incoming = Intersection.factory(Kind.INCOMING);
      outgoing = Intersection.factory(Kind.OUTGOING);
   }
   
   @Test public void testUID()
   {
      for (Chute i : allChutes)
      {
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
      Chute chute = new Chute(null, true);
      
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
    * Test that copy copies all attributes, performs a deep copy, and that the
    * copied Chute has a different UID
    */
   @Test public void testCopy()
   {
      Chute c1 = unnamedPinchedEditable.copy();
      assertTrue(chuteValueEquals(c1, unnamedPinchedEditable));
      assertFalse(c1.getUID() == unnamedPinchedEditable.getUID());
      
      Chute withAux = new Chute("asdf", true);
      Chute withAuxCopy = withAux.copy();
      
      assertTrue(chuteValueEquals(withAux, withAuxCopy));
      assertFalse(withAux.getUID() == withAuxCopy.getUID());
   }
   
   /**
    * Returns true iff the given chutes have equal attributes, excluding UID and
    * start and end Intersections
    */
   private boolean chuteValueEquals(Chute c1, Chute c2)
   {
      if (c1 == null)
         return c2 == null;
      if (!(c1.getName() == null ? c2.getName() == null : c1.getName().equals(c2.getName())))
         return false;
      if (c1.isEditable() != c2.isEditable())
         return false;
      if (c1.isNarrow() != c2.isNarrow())
         return false;
      if (c1.isPinched() != c2.isPinched())
         return false;
      
      return true;
   }
}
