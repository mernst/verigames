package graph.tests;

import static graph.tests.Reflect.*;

import java.lang.reflect.InvocationTargetException;

import graph.Edge;

import org.junit.Test;

public class EdgeSpecTests
{
   @Test
   public void testDeactivate() throws InvocationTargetException
   {
      Edge<?> e = new ConcreteEdge();
      
      invokeMethod(e, "setStart", new ConcreteNode(), 0);
      invokeMethod(e, "setEnd", new ConcreteNode(), 0);
      invokeMethod(e, "deactivate");
   }
}
