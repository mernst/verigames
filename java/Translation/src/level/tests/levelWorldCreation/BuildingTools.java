package level.tests.levelWorldCreation;

import java.util.Arrays;
import java.util.HashSet;
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
   
   protected static void connectFields(Board b, Level level, Map<String, Chute> fieldToChute, Map<String, Integer> nameToPort, String... fieldNames)
   {  
      for (String name : fieldNames)
         connectField(b, nameToPort.get(name), name, level, fieldToChute);
   }
   
   private static void connectField(Board b, int port, String name, Level level, Map<String, Chute> fieldToChute)
   {
      Chute newChute = fieldToChute.get(name).copy();
      
      b.addEdge(b.getIncomingNode(), port, b.getOutgoingNode(), port, newChute);
      
      level.makeLinked(new HashSet<Chute>(Arrays.asList(fieldToChute.get(name), newChute)));
   }
}
