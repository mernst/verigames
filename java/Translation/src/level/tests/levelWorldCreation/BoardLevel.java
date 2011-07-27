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
      addAddNode(l, fieldToChute);
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
   
   private static void addAddNode(Level level, Map<String, Chute> fieldToChute)
   {
      Board addNode = initializeBoard(level, "Board.addNode");
      
      Intersection incoming = addNode.getIncomingNode();
      Intersection outgoing = addNode.getOutgoingNode();
      
      // Intersections that must be shared between different variables:
      Intersection inMerge = factory(MERGE);
      Intersection outMerge = factory(MERGE);
      Intersection contains = subnetworkFactory("Board.contains");
      Intersection nodesEltsMerge = factory(MERGE);
      addNode.addNode(inMerge);
      addNode.addNode(outMerge);
      addNode.addNode(contains);
      addNode.addNode(nodesEltsMerge);
      
      // incomingNode chutes:
      {
         Chute top = new Chute("incomingNode", true, null);
         Chute middle = top.copy();
         Chute bottom = top.copy();
         
         addNode.addEdge(incoming, 0, contains, 0, top);
         addNode.addEdge(contains, 0, inMerge, 0, middle);
         addNode.addEdge(inMerge, 0, outgoing, 0, bottom);
         level.makeLinked(top, middle, bottom, fieldToChute.get(top.getName()));
      }
      
      // outgoingNode chutes:
      {
         Chute top = new Chute("outgoingNode", true, null);
         Chute middle = top.copy();
         Chute bottom = top.copy();
         
         addNode.addEdge(incoming, 1, contains, 1, top);
         addNode.addEdge(contains, 1, outMerge, 0, middle);
         addNode.addEdge(outMerge, 0, outgoing, 1, bottom);
         level.makeLinked(top, middle, bottom, fieldToChute.get(top.getName()));
      }
      
      // nodes base chutes:
      {
         Chute top = new Chute("nodes", true, null);
         Chute bottom = top.copy();
         
         addNode.addEdge(incoming, 2, contains, 2, top);
         addNode.addEdge(contains, 2, outgoing, 2, bottom);
         level.makeLinked(top, bottom, fieldToChute.get(top.getName()));
      }
      
      // nodes aux chutes:
      {
         Chute top = new Chute("nodes.elts", true, null);
         Chute middle = top.copy();
         Chute bottom = top.copy();
         
         addNode.addEdge(incoming, 3, contains, 3, top);
         addNode.addEdge(contains, 3, nodesEltsMerge, 0, middle);
         addNode.addEdge(nodesEltsMerge, 0, outgoing, 3, bottom);
         level.makeLinked(top, middle, bottom, fieldToChute.get(top.getName()));
      }
      
      // edges base chutes:
      {
         Chute top = new Chute("edges", true, null);
         Chute bottom = top.copy();
         
         addNode.addEdge(incoming, 4, contains, 4, top);
         addNode.addEdge(contains, 4, outgoing, 4, bottom);
         level.makeLinked(top, bottom, fieldToChute.get(top.getName()));
      }
      
      // edges aux chutes:
      {
         Chute top = new Chute("edges.elts", true, null);
         Chute bottom = top.copy();
         
         addNode.addEdge(incoming, 5, contains, 5, top);
         addNode.addEdge(contains, 5, outgoing, 5, bottom);
         level.makeLinked(top, bottom, fieldToChute.get(top.getName()));
      }
      
      // node (arg) chutes:
      {
         Intersection containsSplit = factory(SPLIT);
         Intersection ifSplit = factory(SPLIT);
         Intersection inSplit = factory(SPLIT);
         Intersection outSplit = factory(SPLIT);
         Intersection ifMerge = factory(MERGE);
         Intersection nodesEltsSplit = factory(SPLIT);
         Intersection end = factory(END);
         
         addNode.addNode(containsSplit);
         addNode.addNode(ifSplit);
         addNode.addNode(inSplit);
         addNode.addNode(outSplit);
         addNode.addNode(ifMerge);
         addNode.addNode(nodesEltsSplit);
         addNode.addNode(end);
         
         Chute top = new Chute("node", true, null);
         Chute second = top.copy();
         Chute ifLeftTop = top.copy();
         Chute ifLeftBottom = top.copy();
         Chute ifRightTop = top.copy();
         Chute ifRightBottom = top.copy();
         Chute third = top.copy();
         Chute bottom = top.copy();
         
         top.setPinched(true);
         second.setPinched(true);
         ifRightTop.setPinched(true);
         
         addNode.addEdge(incoming, 6, containsSplit, 0, top);
         addNode.addEdge(containsSplit, 1, ifSplit, 0, second);
         
         addNode.addEdge(ifSplit, 0, inSplit, 0, ifLeftTop);
         addNode.addEdge(inSplit, 1, ifMerge, 0, ifLeftBottom);
         
         addNode.addEdge(ifSplit, 1, outSplit, 0, ifRightTop);
         addNode.addEdge(outSplit, 1, ifMerge, 1, ifRightBottom);
         
         addNode.addEdge(ifMerge, 0, nodesEltsSplit, 0, third);
         addNode.addEdge(nodesEltsSplit, 1, end, 0, bottom);
         
         Chute toContains = new Chute(null, true, null);
         addNode.addEdge(containsSplit, 0, contains, 6, toContains);
         
         Chute toIn = new Chute(null, true, null);
         addNode.addEdge(inSplit, 0, inMerge, 1, toIn);
         
         Chute toOut = new Chute(null, true, null);
         addNode.addEdge(outSplit, 0, outMerge, 1, toOut);
         
         Chute toNodesElts = new Chute(null, true, null);
         addNode.addEdge(nodesEltsSplit, 0, nodesEltsMerge, 1, toNodesElts);
      }
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
      Board contains = initializeBoard(level, "Board.contains");
      
      // attach all fields
      connectFields(contains, level, fieldToChute, nameToPortMap, nameToPortMap.keySet().toArray(new String[0]));
      
      // add pinchpoints to nodes and edges:
      Intersection incoming = contains.getIncomingNode();
      Chute nodes = incoming.getOutputChute(2);
      Chute edges = incoming.getOutputChute(4);
      
      nodes.setPinched(true);
      edges.setPinched(true);
      
      // add argument chute:
      Intersection end = factory(END);
      contains.addNode(end);
      
      contains.addEdge(incoming, 6, end, 0, new Chute("elt", true, null));
   }
   
   private static void addDeactivate(Level level,
         Map<String, Chute> fieldToChute)
   {
      
   }
}
