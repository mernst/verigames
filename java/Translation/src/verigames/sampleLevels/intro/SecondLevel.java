package verigames.sampleLevels.intro;

import static verigames.level.Intersection.*;
import static verigames.level.Intersection.Kind.*;
import static verigames.utilities.BuildingTools.initializeBoard;

import java.util.HashMap;
import java.util.Map;

import verigames.level.Board;
import verigames.level.Chute;
import verigames.level.Intersection;
import verigames.level.Level;


public class SecondLevel
{  
  public static Level makeLevel()
  {
    Level l = new Level();
    Map<String, Chute> fieldToChute = new HashMap<String, Chute>();
    
    addConstructor(l, fieldToChute);
    
    addFirstBoard(l, fieldToChute);
    addSecondBoard(l, fieldToChute);
    
    return l;
  }
  
  private static void addConstructor(Level parent, Map<String, Chute> fieldToChute)
  {
    Board b = initializeBoard(parent, "Second.constructor");
    
    Intersection outgoing = b.getOutgoingNode();
    
    Chute field1 = new Chute();
    Chute field2 = new Chute();
    field1.setNarrow(true);
    field2.setNarrow(true);
    
    fieldToChute.put("field1", field1);
    fieldToChute.put("field2", field2);
    
    Intersection left = factory(START_WHITE_BALL);
    Intersection right = factory(START_NO_BALL);
    b.addNode(left);
    b.addNode(right);
    
    b.addEdge(left, 0, outgoing, 0, field1);
    b.addEdge(right, 0, outgoing, 1, field2);
  }
  
  private static void addFirstBoard(Level parent, Map<String, Chute> fieldToChute)
  {
    Board b = initializeBoard(parent, "Second.method1");
    
    Intersection incoming = b.getIncomingNode();
    Intersection outgoing = b.getOutgoingNode();
    
    {
      Chute field1 = new Chute();
      field1.setNarrow(true);
      field1.setPinched(true);
      b.addEdge(incoming, 0, outgoing, 0, field1);
      parent.makeLinked(field1, fieldToChute.get("field1"));
    }
    
    {
      Intersection merge = factory(MERGE);
      b.addNode(merge);
      
      Chute field2top = new Chute();
      field2top.setNarrow(true);
      Chute field2bottom = new Chute();
      field2bottom.setNarrow(true);
      
      b.addEdge(incoming, 1, merge, 0, field2top);
      b.addEdge(merge, 0, outgoing, 1, field2bottom);
      parent.makeLinked(field2top, field2bottom, fieldToChute.get("field2"));
      
      Chute arg = new Chute();
      arg.setNarrow(false);
      
      b.addEdge(incoming, 2, merge, 1, arg);
    }
  }
  
  private static void addSecondBoard(Level parent, Map<String, Chute> fieldToChute)
  {
    Board b = initializeBoard(parent, "Second.method2");
    
    Intersection incoming = b.getIncomingNode();
    Intersection outgoing = b.getOutgoingNode();
    
    {
      Chute field1 = new Chute();
      field1.setNarrow(true);
      field1.setPinched(true);
      b.addEdge(incoming, 0, outgoing, 0, field1);
      parent.makeLinked(field1, fieldToChute.get("field1"));
    }
    
    {
      Intersection split = factory(SPLIT);
      b.addNode(split);
      
      Chute field2top = new Chute();
      field2top.setNarrow(true);
      field2top.setPinched(true);
      Chute field2bottom = new Chute();
      field2bottom.setNarrow(true);
      
      b.addEdge(incoming, 1, split, 0, field2top);
      b.addEdge(split, 0, outgoing, 1, field2bottom);
      parent.makeLinked(field2top, field2bottom, fieldToChute.get("field2"));
      
      Chute ret = new Chute();
      ret.setNarrow(false);
      
      b.addEdge(split, 1, outgoing, 2, ret);
    }
  }
}
