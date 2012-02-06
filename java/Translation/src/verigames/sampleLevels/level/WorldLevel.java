package verigames.sampleLevels.level;

import static verigames.level.Intersection.factory;
import static verigames.level.Intersection.subnetworkFactory;
import static verigames.level.Intersection.Kind.END;
import static verigames.level.Intersection.Kind.MERGE;
import static verigames.level.Intersection.Kind.SPLIT;
import static verigames.level.Intersection.Kind.START_NO_BALL;
import static verigames.level.Intersection.Kind.START_WHITE_BALL;
import static verigames.utilities.BuildingTools.addField;
import static verigames.utilities.BuildingTools.connectFields;
import static verigames.utilities.BuildingTools.initializeBoard;

import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.Map;

import verigames.level.Board;
import verigames.level.Chute;
import verigames.level.Intersection;
import verigames.level.Level;


/*
 * I'm aware that having both WorldLevel and LevelWorld is pretty much a
 * disaster, but bear with me until I figure out good names
 */

public class WorldLevel
{
  private static final Map<String, Integer> nameToPortMap;
  static
  {
    nameToPortMap = new LinkedHashMap<String, Integer>();
    nameToPortMap.put("nameToLevel", 0);
    nameToPortMap.put("nameToLevel.keys", 1);
    nameToPortMap.put("nameToLevel.values", 2);
  }
  
  public static Level makeLevel()
  {
    Level l = new Level();
    
    Map<String, Chute> fieldToChute = new HashMap<String, Chute>();
    
    addConstructor(l, fieldToChute);
    addAddLevel(l, fieldToChute);
    addOutputXML(l, fieldToChute);
    
    return l;
  }
  
  private static void addConstructor(Level level,
      Map<String, Chute> fieldToChute)
  {
    Board constructor = initializeBoard(level, "World.constructor");
    
    addField(constructor, fieldToChute, nameToPortMap, "nameToLevel", START_WHITE_BALL);
    addField(constructor, fieldToChute, nameToPortMap, "nameToLevel.keys", START_NO_BALL);
    addField(constructor, fieldToChute, nameToPortMap, "nameToLevel.values", START_NO_BALL);
  }
  
  private static void addAddLevel(Level level, Map<String, Chute> fieldToChute)
  {
    Board addLevel = initializeBoard(level, "World.addLevel");
    
    Intersection incoming = addLevel.getIncomingNode();
    Intersection outgoing = addLevel.getOutgoingNode();
    
    // Add nameToLevel base chutes
    {
      Chute nameToLevel = new Chute();
      String nameToLevelName = "nameToLevel";
      nameToLevel.setPinched(true);
      addLevel.addEdge(incoming, 0, outgoing, 0, nameToLevel);
      addLevel.addChuteName(nameToLevel, nameToLevelName);
      
      level.makeLinked(nameToLevel, fieldToChute.get(nameToLevelName));
    }
    
    // Add nameToLevel.keys and name (arg) chutes:
    {
      Intersection merge = factory(MERGE);
      addLevel.addNode(merge);
      
      Chute top = new Chute();
      Chute bottom = top.copy();
      String chuteName = "nameToLevel.keys";
      
      addLevel.addEdge(incoming, 1, merge, 0, top);
      addLevel.addEdge(merge, 0, outgoing, 1, bottom);
      addLevel.addChuteName(top, chuteName);
      addLevel.addChuteName(bottom, chuteName);
      level.makeLinked(top, bottom, fieldToChute.get(chuteName));
      
      Chute name = new Chute();
      addLevel.addEdge(incoming, 3, merge, 1, name);
      addLevel.addChuteName(name, "name");
    }
    
    // Add nameToLevel.values and level (arg) chutes:
    {
      Intersection merge = factory(MERGE);
      addLevel.addNode(merge);
      
      Chute top = new Chute();
      Chute bottom = top.copy();
      String chuteName = "nameToLevel.values";
      
      addLevel.addEdge(incoming, 2, merge, 0, top);
      addLevel.addEdge(merge, 0, outgoing, 2, bottom);
      addLevel.addChuteName(top, chuteName);
      addLevel.addChuteName(bottom, chuteName);
      level.makeLinked(top, bottom, fieldToChute.get(chuteName));
      
      Chute name = new Chute();
      addLevel.addEdge(incoming, 4, merge, 1, name);
      addLevel.addChuteName(name, "level");
    }
  }
  
  private static void addOutputXML(Level level, Map<String, Chute> fieldToChute)
  {
    Board output = initializeBoard(level, "World.outputXML");
    
    Intersection incoming = output.getIncomingNode();
    Intersection outgoing = output.getOutgoingNode();
    
    // connect nameToLevel and nameToLevel.keys chutes:
    connectFields(output, level, fieldToChute, nameToPortMap, "nameToLevel",
        "nameToLevel.keys");
    
    // add pinch to nameToLevel
    {
      Chute nameToLevel = incoming.getOutput(0);
      if (!output.getChuteNames(nameToLevel).iterator().next().equals("nameToLevel"))
        throw new RuntimeException();
      nameToLevel.setPinched(true);
    }
    
    // make chute representing nameToLevel.values() return value
    {
      Intersection start = factory(START_WHITE_BALL);
      Intersection end = factory(END);
      output.addNode(start);
      output.addNode(end);
      
      Chute values = new Chute();
      values.setPinched(true);
      
      output.addEdge(start, 0, end, 0, values);
    }
    
    // connect nameToLevel.values chutes:
    {
      Intersection split = factory(SPLIT);
      output.addNode(split);
      
      Chute top = new Chute();
      Chute bottom = top.copy();
      String name = "nameToLevel.values";
      
      output.addEdge(incoming, 2, split, 0, top);
      output.addEdge(split, 0, outgoing, 2, bottom);
      output.addChuteName(top, name);
      output.addChuteName(bottom, name);
      level.makeLinked(top, bottom, fieldToChute.get(name));
      
      Intersection end = factory(END);
      output.addNode(end);
      
      Chute right = new Chute();
      right.setPinched(true);
      output.addEdge(split, 1, end, 0, right);
    }
    
    // Add out (arg) chutes
    {
      Intersection split = factory(SPLIT);
      Intersection end = factory(END);
      Intersection out = subnetworkFactory("Level.outputXML");
      output.addNode(split);
      output.addNode(end);
      output.addNode(out);
      
      Chute top = new Chute();
      Chute bottom = top.copy();
      String name = "out";
      
      output.addEdge(incoming, 3, split, 0, top);
      output.addEdge(split, 1, end, 0, bottom);
      output.addChuteName(top, name);
      output.addChuteName(bottom, name);
      
      level.makeLinked(top, bottom);
      
      Chute toOut = new Chute();
      output.addEdge(split, 0, out, 0, toOut);
    }
  }
}
