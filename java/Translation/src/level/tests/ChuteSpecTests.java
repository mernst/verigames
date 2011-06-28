package level.tests;

import static org.junit.Assert.*;

import java.util.ArrayList;
import java.util.List;

import javax.lang.model.element.Name;

import level.Chute;

import org.junit.Before;
import org.junit.Test;

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
   
   @Before
   public void initChutes()
   {
      namedPinchedEditable = new Chute(null, true, true);
      namedPinchedUneditable = new Chute(null, true, false);
      namedUnpinchedEditable = new Chute(null, false, true);
      namedUnpinchedUneditable = new Chute(null, false, false);
      unnamedPinchedEditable = new Chute(null, true, true);
      unnamedPinchedUneditable = new Chute(null, true, false);
      unnamedUnpinchedEditable = new Chute(null, false, true);
      unnamedUnpinchedUneditable = new Chute(null, false, false);
      
      allChutes = new ArrayList<Chute>();
      
      allChutes.add(namedPinchedEditable);
      allChutes.add(namedPinchedUneditable);
      allChutes.add(namedUnpinchedEditable);
      allChutes.add(namedUnpinchedUneditable);
      allChutes.add(unnamedPinchedEditable);
      allChutes.add(unnamedPinchedUneditable);
      allChutes.add(unnamedUnpinchedEditable);
      allChutes.add(unnamedUnpinchedUneditable);
   }
   
   @Test
   public void testUID()
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
   
   // TODO write some tests with Intersection, once that's nailed down.
}
