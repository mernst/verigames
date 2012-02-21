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


@SuppressWarnings("deprecation")
public class ThirdLevel
{
  public static Level makeLevel()
  {
    Level l = new Level();
    
    Map<String, Chute> fieldToChute = new HashMap<String, Chute>();
    
    addConstructor(l, fieldToChute);
    
    addFoo(l, fieldToChute);
    addBar(l, fieldToChute);
    addBaz(l, fieldToChute);
    
    return l;
  }
  
  private static void addConstructor(Level parent,
      Map<String, Chute> fieldToChute)
  {
    Board b = initializeBoard(parent, "Third.constructor");
    
    Intersection incoming = b.getIncomingNode();
    Intersection outgoing = b.getOutgoingNode();
    
    Chute field1 = new Chute();
    Chute field2 = new Chute();
    Chute field3 = new Chute();
    fieldToChute.put("field1", field1);
    fieldToChute.put("field2", field2);
    fieldToChute.put("field3", field3);
    
    field1.setNarrow(false);
    field2.setNarrow(true);
    field3.setNarrow(false);
    
    b.addEdge(incoming, 0, outgoing, 0, field1);
    b.addEdge(incoming, 1, outgoing, 1, field2);
    b.addEdge(incoming, 2, outgoing, 2, field3);
  }
  
  private static void addFoo(Level parent, Map<String, Chute> fieldToChute)
  {
    Board b = initializeBoard(parent, "Third.foo");
    
    Intersection incoming = b.getIncomingNode();
    Intersection outgoing = b.getOutgoingNode();
    
    // Add field1 chutes:
    {
      Intersection end = factory(END);
      b.addNode(end);
      
      Chute top = new Chute();
      b.addEdge(incoming, 0, end, 0, top);
      
      Intersection start = factory(START_BLACK_BALL);
      b.addNode(start);
      
      Chute bottom = new Chute();
      b.addEdge(start, 0, outgoing, 0, bottom);
      
      parent.makeLinked(top, bottom, fieldToChute.get("field1"));
    }
    
    // Add field2 chutes:
    {
      Intersection split = factory(SPLIT);
      b.addNode(split);
      
      Chute top = new Chute();
      Chute bottom = new Chute();
      Chute right = new Chute();
      top.setNarrow(true);
      bottom.setNarrow(true);
      right.setNarrow(true);
      
      b.addEdge(incoming, 1, split, 0, top);
      b.addEdge(split, 0, outgoing, 1, bottom);
      b.addEdge(split, 1, outgoing, 4, right);
      
      parent.makeLinked(top, bottom, right, fieldToChute.get("field2"));
    }
    
    // Add field3 chutes:
    {
      Intersection split = factory(SPLIT);
      b.addNode(split);
      
      Chute top = new Chute();
      Chute bottom = new Chute();
      Chute right = new Chute();
      top.setNarrow(false);
      bottom.setNarrow(false);
      right.setNarrow(false);
      
      b.addEdge(incoming, 2, split, 0, top);
      b.addEdge(split, 0, outgoing, 2, bottom);
      b.addEdge(split, 1, outgoing, 5, right);
      
      parent.makeLinked(top, bottom, right, fieldToChute.get("field3"));
    }
    
    // Add return value chute:
    {
      Intersection start = factory(START_WHITE_BALL);
      b.addNode(start);
      
      b.addEdge(start, 0, outgoing, 3, new Chute());
    }
  }
  
  private static void addBar(Level parent, Map<String, Chute> fieldToChute)
  {
    Board b = initializeBoard(parent, "Third.bar");
    
    Intersection incoming = b.getIncomingNode();
    Intersection outgoing = b.getOutgoingNode();
    
    Intersection foo = subnetworkFactory("Third.foo");
    b.addNode(foo);
    
    // Add field1 chutes:
    {
      Chute top = new Chute();
      Chute bottom = new Chute();
      
      top.setNarrow(false);
      bottom.setNarrow(false);
      
      b.addEdge(incoming, 0, foo, 0, top);
      b.addEdge(foo, 0, outgoing, 0, bottom);
      
      parent.makeLinked(top, bottom, fieldToChute.get("field1"));
    }
    
    // Add field2 chutes:
    {
      Chute top = new Chute();
      Chute bottom = new Chute();
      
      top.setNarrow(true);
      bottom.setNarrow(true);
      
      b.addEdge(incoming, 1, foo, 1, top);
      b.addEdge(foo, 1, outgoing, 1, bottom);
      
      parent.makeLinked(top, bottom, fieldToChute.get("field2"));
    }
    
    // Add field3 chutes:
    {
      Chute top = new Chute();
      Chute bottom = new Chute();
      
      top.setNarrow(false);
      bottom.setNarrow(false);
      
      b.addEdge(incoming, 2, foo, 2, top);
      b.addEdge(foo, 2, outgoing, 2, bottom);
      
      parent.makeLinked(top, bottom, fieldToChute.get("field3"));
    }
    
    // Add first foo return value chute:
    {
      Intersection end = factory(END);
      b.addNode(end);
      
      Chute chute = new Chute();
      chute.setNarrow(true);
      
      chute.setPinched(true);
      
      b.addEdge(foo, 3, end, 0, chute);
    }
    
    // Add second foo return value chute and first argument chute:
    {
      Intersection merge = factory(MERGE);
      Intersection end = factory(END);
      b.addNode(end);
      b.addNode(merge);
      
      Chute top = new Chute();
      Chute bottom = new Chute();
      
      top.setNarrow(true);
      bottom.setNarrow(true);
      
      b.addEdge(foo, 4, merge, 0, top);
      b.addEdge(merge, 0, end, 0, bottom);
      
      parent.makeLinked(top, bottom);
      
      Chute arg = new Chute();
      arg.setNarrow(false);
      
      b.addEdge(incoming, 3, merge, 1, arg);
    }
    
    // Add third foo return value chute, second argument chute, and return
    // value chute:
    {
      Intersection merge = factory(MERGE);
      Intersection split = factory(SPLIT);
      Intersection end = factory(END);
      b.addNode(merge);
      b.addNode(split);
      b.addNode(end);
      
      Chute top = new Chute();
      Chute middle = new Chute();
      Chute bottom = new Chute();
      
      top.setNarrow(false);
      middle.setNarrow(false);
      bottom.setNarrow(false);
      
      b.addEdge(foo, 5, merge, 0, top);
      b.addEdge(merge, 0, split, 0, middle);
      b.addEdge(split, 0, end, 0, bottom);
      
      parent.makeLinked(top, bottom, middle);
      
      Chute arg = new Chute();
      arg.setNarrow(true);
      b.addEdge(incoming, 4, merge, 1, arg);
      
      Chute ret = new Chute();
      ret.setNarrow(false);
      ret.setPinched(true);
      b.addEdge(split, 1, outgoing, 3, ret);
    }
  }
  
  private static void addBaz(Level parent, Map<String, Chute> fieldToChute)
  {
    Board b = initializeBoard(parent, "Third.baz");
    
    Intersection incoming = b.getIncomingNode();
    Intersection outgoing = b.getOutgoingNode();
    
    Intersection bar = subnetworkFactory("Third.bar");
    b.addNode(bar);
    
    // Add field1 chutes:
    {
      Chute top = new Chute();
      Chute bottom = new Chute();
      
      top.setNarrow(false);
      bottom.setNarrow(false);
      
      b.addEdge(incoming, 0, bar, 0, top);
      b.addEdge(bar, 0, outgoing, 0, bottom);
      
      parent.makeLinked(top, bottom, fieldToChute.get("field1"));
    }
    
    // Add field2 chutes:
    {
      Chute top = new Chute();
      Chute bottom = new Chute();
      
      top.setNarrow(true);
      bottom.setNarrow(true);
      
      b.addEdge(incoming, 1, bar, 1, top);
      b.addEdge(bar, 1, outgoing, 1, bottom);
      
      parent.makeLinked(top, bottom, fieldToChute.get("field2"));
    }
    
    // Add field3 chutes:
    {
      Chute top = new Chute();
      Chute bottom = new Chute();
      
      top.setNarrow(false);
      bottom.setNarrow(false);
      
      b.addEdge(incoming, 2, bar, 2, top);
      b.addEdge(bar, 2, outgoing, 2, bottom);
      
      parent.makeLinked(top, bottom, fieldToChute.get("field3"));
    }
    
    // Add first bar argument:
    {
      Intersection start = factory(START_BLACK_BALL);
      b.addNode(start);
      
      Chute c = new Chute();
      c.setNarrow(false);
      
      b.addEdge(start, 0, bar, 3, c);
    }
    
    // Add second bar argument:
    {
      Intersection start = factory(START_WHITE_BALL);
      b.addNode(start);
      
      Chute c = new Chute();
      c.setNarrow(true);
      
      b.addEdge(start, 0, bar, 4, c);
    }
    
    // Add return value:
    {
      Chute c = new Chute();
      c.setNarrow(false);
      
      b.addEdge(bar, 3, outgoing, 3, c);
    }
  }
}
