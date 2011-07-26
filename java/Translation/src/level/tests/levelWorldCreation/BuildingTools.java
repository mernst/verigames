package level.tests.levelWorldCreation;

import java.util.Arrays;
import java.util.HashSet;
import java.util.Map;

import level.Board;
import level.Chute;
import level.Level;

public class BuildingTools
{
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
