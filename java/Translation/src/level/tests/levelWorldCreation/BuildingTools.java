package level.tests.levelWorldCreation;

import static level.Intersection.factory;

import java.util.Map;

import level.Board;
import level.Chute;
import level.Intersection;
import level.Intersection.Kind;
import level.Level;

public class BuildingTools
{
   
   /**
    * Makes a new Board, adds it to level with the given name, adds incoming and
    * outgoing nodes to it.
    */
   protected static Board initializeBoard(Level level, String name)
   {
      Board b = new Board();
      level.addBoard(name, b);
      
      b.addNode(Intersection.factory(Kind.INCOMING));
      b.addNode(Intersection.factory(Kind.OUTGOING));
      
      return b;
   }
   
   protected static void addField(Board b, Map<String, Chute> fieldToChute, Map<String, Integer> nameToPortMap, String name, Kind kind)
   {
      Intersection start = factory(kind);
      b.addNode(start);
      
      Chute chute = new Chute();
      b.addEdge(start, 0, b.getOutgoingNode(), nameToPortMap.get(name), chute);
      b.addChuteName(chute, name);
      fieldToChute.put(name, chute);
   }
   
   protected static void connectFields(Board b, Level level, Map<String, Chute> fieldToChute, Map<String, Integer> nameToPort, String... fieldNames)
   {  
      for (String name : fieldNames)
         connectField(b, nameToPort.get(name), name, level, fieldToChute);
   }
   
   private static void connectField(Board b, int port, String name, Level level, Map<String, Chute> fieldToChute)
   {
      Chute newChute = fieldToChute.get(name).copy();
      
      b.addEdge(b.getIncomingNode(), port, b.getOutgoingNode(), port, newChute);
      b.addChuteName(newChute, name);
      
      level.makeLinked(fieldToChute.get(name), newChute);
   }
}
