package verigames.graph;

import static org.junit.Assert.*;
import static verigames.utilities.Reflect.invokeMethod;

import java.lang.reflect.InvocationTargetException;

import org.junit.Test;

import verigames.graph.Node;

public class NodeImpTests
{
  
  /**
   * Tests that finishConstruction fails when there are empty input ports with index
   * less than the highest one
   */
  @Test
  public void testDeactivate1() throws InvocationTargetException
  {
    testDeactivate(true);
  }
  
  /**
   * Tests that finishConstruction fails when there are empty output ports with index
   * less than the highest one.
   * 
   * @throws InvocationTargetException
   */
  @Test
  public void testDeactivate() throws InvocationTargetException
  {
    testDeactivate(false);
  }
  
  private void testDeactivate(boolean input) throws InvocationTargetException
  {
    Node<?> n = new ConcreteNode();
    
    // n.setInput(new ConcreteEdge(), 1);
    invokeMethod(n, input ? "setInput" : "setOutput", new ConcreteEdge(), 1);
    
    boolean expectedExceptionThrown = false;
    try
    {
      // n.finishConstruction();
      invokeMethod(n, "finishConstruction");
    }
    catch (InvocationTargetException e)
    {
      Throwable t = e.getCause();
      if (t instanceof IllegalStateException)
        expectedExceptionThrown = true;
    }
    
    assertTrue(expectedExceptionThrown);
  }
  
  /**
   * Tests that Node.getInput returns null on a negative port.
   */
  @Test(expected=IndexOutOfBoundsException.class)
  public void testGetNegativeInput()
  {
    new ConcreteNode().getInput(-1);
  }
}
