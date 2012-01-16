package graph;

import static org.junit.Assert.assertTrue;
import static utilities.Reflect.invokeMethod;
import graph.Edge;

import java.lang.reflect.InvocationTargetException;

import org.junit.Test;

public class EdgeImpTests
{
   @Test
   public void testDeactivate1()
   {
      Edge<?> e = new ConcreteEdge();
      
      assertDeactivateFailure(e);
   }
   
   @Test
   public void testDeactivate2() throws InvocationTargetException
   {
      Edge<?> e = new ConcreteEdge();

      invokeMethod(e, "setStart", new ConcreteNode(), 0);
      
      assertDeactivateFailure(e);
   }
   
   @Test
   public void testDeactivate3() throws InvocationTargetException
   {
      Edge<?> e = new ConcreteEdge();
      
      invokeMethod(e, "setEnd", new ConcreteNode(), 0);
      
      assertDeactivateFailure(e);
   }
   
   private void assertDeactivateFailure(Edge<?> edge)
   {
      Throwable cause = null;
      try
      {
         invokeMethod(edge, "finishConstruction");
      }
      catch (InvocationTargetException e)
      {
         cause = e.getCause();
      }
      assertTrue(cause instanceof IllegalStateException);
   }
}
