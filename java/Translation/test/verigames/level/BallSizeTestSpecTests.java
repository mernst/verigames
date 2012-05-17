package verigames.level;

import static org.junit.Assert.assertEquals;

import java.lang.reflect.InvocationTargetException;
import java.lang.reflect.Method;


import org.junit.Test;

import verigames.level.*;
import verigames.level.Intersection.Kind;

public class BallSizeTestSpecTests
{
  /**
   * Tests that the custom accessors access the right output port, as defined
   * in the class spec
   */
  @Test public void testNullChuteAccessors() throws IllegalAccessException, InvocationTargetException
  {
    BallSizeTest nt = Intersection.factory(Kind.BALL_SIZE_TEST).asBallSizeTest();
    
    Chute nullable = new Chute();
    nullable.setNarrow(false);
    nullable.setEditable(false);
    Chute nonNull = new Chute();
    nonNull.setNarrow(true);
    nonNull.setEditable(false);
    
    nt.setNarrowChute(nonNull);
    
    nt.setWideChute(nullable);
    
    assertEquals(nt.getNarrowChute(), nonNull);
    assertEquals(nt.getWideChute(), nullable);
    
    assertEquals(nt.getOutput(0), nonNull);
    assertEquals(nt.getOutput(1), nullable);
  }
}
