package level.tests.levelWorldCreation;

import static level.tests.levelWorldCreation.BuildingTools.*;
import static level.Intersection.Kind.*;
import static level.Intersection.*;

import java.util.HashMap;
import java.util.Map;

import level.Board;
import level.Chute;
import level.Intersection;
import level.Level;

public class BoardLevel
{
   private static final Map<String, Integer> nameToPortMap;
   static
   {
      nameToPortMap = new HashMap<String, Integer>();
      nameToPortMap.put("incomingNode", 0);
      nameToPortMap.put("outgoingNode", 1);
      nameToPortMap.put("nodes", 2);
      nameToPortMap.put("nodes.elts", 3);
      nameToPortMap.put("edges", 4);
      nameToPortMap.put("edges.elts", 5);
   }
   
   public static Level makeLevel()
   {
      Level l = new Level();
      Map<String, Chute> fieldToChute = new HashMap<String, Chute>();
      
      addConstructor(l, fieldToChute);
      addAddEdge(l, fieldToChute);
      addNodesSize(l, fieldToChute);
      addEdgesSize(l, fieldToChute);
      addGetNodes(l, fieldToChute);
      addGetEdges(l, fieldToChute);
      addGetIncomingNode(l, fieldToChute);
      addGetOutgoingNode(l, fieldToChute);
      addContains(l, fieldToChute);
      addDeactivate(l, fieldToChute);
      
      return l;
   }

   private static void addConstructor(Level level,
         Map<String, Chute> fieldToChute)
   {
      Board constructor = initializeBoard(level, "Board.constructor");
      
      // incomingNode chute:
      addField(constructor, fieldToChute, nameToPortMap, "incomingNode", START_BLACK_BALL);
      
      // outgoingNode chute:
      addField(constructor, fieldToChute, nameToPortMap, "outgoingNode", START_BLACK_BALL);
      
      // nodes base chute:
      addField(constructor, fieldToChute, nameToPortMap, "nodes", START_WHITE_BALL);
      
      // nodes aux chute:
      addField(constructor, fieldToChute, nameToPortMap, "nodes.elts", START_NO_BALL);
      
      // edges base chute:
      addField(constructor, fieldToChute, nameToPortMap, "edges", START_WHITE_BALL);
      
      // edges aux chute:
      addField(constructor, fieldToChute, nameToPortMap, "edges.elts", START_NO_BALL);
   }
   
   private static void addAddEdge(Level level, Map<String, Chute> fieldToChute)
   {
      
   }
   
   private static void addNodesSize(Level level, Map<String, Chute> fieldToChute)
   {
      
   }
   
   private static void addEdgesSize(Level level, Map<String, Chute> fieldToChute)
   {
      
   }
   
   private static void addGetNodes(Level level, Map<String, Chute> fieldToChute)
   {
      
   }
   
   private static void addGetEdges(Level level, Map<String, Chute> fieldToChute)
   {
      
   }
   
   private static void addGetIncomingNode(Level level,
         Map<String, Chute> fieldToChute)
   {
      
   }
   
   private static void addGetOutgoingNode(Level level,
         Map<String, Chute> fieldToChute)
   {
      
   }
   
   private static void addContains(Level level, Map<String, Chute> fieldToChute)
   {
      
   }
   
   private static void addDeactivate(Level level,
         Map<String, Chute> fieldToChute)
   {
      
   }
}
