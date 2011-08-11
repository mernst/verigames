package graph.tests;

import static graph.tests.Reflect.invokeMethod;
import static junit.framework.Assert.assertEquals;
import static org.junit.Assert.*;
import graph.Edge;
import graph.Node;

import java.lang.reflect.InvocationTargetException;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.TreeMap;

import org.junit.Test;

public class NodeSpecTests
{
   /**
    * Tests that Node.deactivate does not fail when called on a new Node
    * 
    * @throws InvocationTargetException
    */
   @Test
   public void testSimpleDeactivate() throws InvocationTargetException
   {
      Node<?> n = new ConcreteNode();
      invokeMethod(n, "deactivate");
   }
   
   /**
    * Tests that Node.deactivate does not fail when called on a Node with some
    * ports filled
    * 
    * @throws InvocationTargetException
    */
   @Test
   public void testDeactivate() throws InvocationTargetException
   {
      Node<?> n = new ConcreteNode();
      invokeMethod(n, "setInput", new ConcreteEdge(), 1);
      invokeMethod(n, "setInput", new ConcreteEdge(), 0);
      invokeMethod(n, "setOutput", new ConcreteEdge(), 0);
      invokeMethod(n, "deactivate");
   }
   
   /**
    * Tests that setInput and getInput behave consistently
    * 
    * @throws InvocationTargetException
    */
   @Test
   public void testInput() throws InvocationTargetException
   {
      testInOrOut(true);
   }
   
   /**
    * Tests that setOutput and getOutput behave consistently
    * 
    * @throws InvocationTargetException
    */
   @Test
   public void testOutput() throws InvocationTargetException
   {
      testInOrOut(false);
   }
   
   /**
    * Implementation for testOutput and testInput. Shared because they're
    * basically the same.
    * 
    * @throws InvocationTargetException
    */
   private void testInOrOut(boolean input) throws InvocationTargetException
   {
      String setMethodName = input ? "setInput" : "setOutput";
      
      Node<?> n = new ConcreteNode();
      
      Map<Integer, Edge<?>> portToChute = new LinkedHashMap<Integer, Edge<?>>();
      portToChute.put(5, new ConcreteEdge());
      portToChute.put(2, new ConcreteEdge());
      portToChute.put(10, new ConcreteEdge());
      
      for (Map.Entry<Integer, Edge<?>> entry : portToChute.entrySet())
      {
         invokeMethod(n, setMethodName, entry.getValue(), entry.getKey());
      }
      
      for (int i = 0; i <= 10; i++)
      {
         Edge<?> e = input ? n.getInput(i) : n.getOutput(i);
         assertEquals(portToChute.get(i), e);
      }
   }
   
   /**
    * Tests that getInputs retur
    * 
    * @throws InvocationTargetException
    */
   @Test
   public void testGetInputs() throws InvocationTargetException
   {
      testGetXXXputs(true);
   }
   
   @Test
   public void testGetOutpus() throws InvocationTargetException
   {
      testGetXXXputs(false);
   }
   
   private void testGetXXXputs(boolean input) throws InvocationTargetException
   {
      String setMethodName = input ? "setInput" : "setOutput";
      
      Node<?> n = new ConcreteNode();
      
      // Tests that get___s() works with empty edge set
      assertTrue((input ? n.getInputs() : n.getOutputs()).isEmpty());
      
      Map<Integer, Edge<?>> portToChute = new HashMap<Integer, Edge<?>>();
      portToChute.put(3, new ConcreteEdge());
      portToChute.put(100, new ConcreteEdge());
      portToChute.put(0, new ConcreteEdge());
      
      for (Map.Entry<Integer, Edge<?>> entry : portToChute.entrySet())
         invokeMethod(n, setMethodName, entry.getValue(), entry.getKey());
      
      TreeMap<Integer, ? extends Edge<?>> inputs = input ? n.getInputs() : n.getOutputs();
      
      assertEquals(portToChute, inputs);
   }
}
