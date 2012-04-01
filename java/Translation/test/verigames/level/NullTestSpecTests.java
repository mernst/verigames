package verigames.level;

import static org.junit.Assert.assertEquals;

import java.lang.reflect.InvocationTargetException;
import java.lang.reflect.Method;


import org.junit.Test;

import verigames.level.Chute;
import verigames.level.Intersection;
import verigames.level.NullTest;
import verigames.level.Intersection.Kind;

public class NullTestSpecTests
{
  /**
   * Tests that the custom accessors access the right output port, as defined
   * in the class spec
   */
  @Test public void testNullChuteAccessors() throws IllegalAccessException, InvocationTargetException
  {
    NullTest nt = Intersection.factory(Kind.BALL_SIZE_TEST).asBallSizeTest();
    
    Chute nullable = new Chute();
    nullable.setNarrow(false);
    nullable.setEditable(false);
    Chute nonNull = new Chute();
    nonNull.setNarrow(true);
    nonNull.setEditable(false);
    
    Method[] ntMethods = NullTest.class.getDeclaredMethods();
    
    // nt.setNonNullChute(nonNull);
    for (Method m : ntMethods)
    {
      if (m.getName().equals("setNonNullChute"))
      {
        m.setAccessible(true);
        m.invoke(nt, new Object[] {nonNull});
      }
    }
    
    // nt.setNullChute(nullable);
    for (Method m : ntMethods)
    {
      if (m.getName().equals("setNullChute"))
      {
        m.setAccessible(true);
        m.invoke(nt, new Object[] {nullable});
      }
    }
    
    assertEquals(nt.getNonNullChute(), nonNull);
    assertEquals(nt.getNullChute(), nullable);
    
    assertEquals(nt.getOutput(0), nonNull);
    assertEquals(nt.getOutput(1), nullable);
  }
}
