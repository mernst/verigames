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
         Chute top = new Chute("incomingNode");
         Chute middle = top.copy();
         Chute bottom = top.copy();
         
         addNode.addEdge(incoming, 0, contains, 0, top);
         addNode.addEdge(contains, 0, inMerge, 0, middle);
         addNode.addEdge(inMerge, 0, outgoing, 0, bottom);
         level.makeLinked(top, middle, bottom, fieldToChute.get(top.getName()));
      }
      
      // outgoingNode chutes:
      {
         Chute top = new Chute("outgoingNode");
         Chute middle = top.copy();
         Chute bottom = top.copy();
         
         addNode.addEdge(incoming, 1, contains, 1, top);
         addNode.addEdge(contains, 1, outMerge, 0, middle);
         addNode.addEdge(outMerge, 0, outgoing, 1, bottom);
         level.makeLinked(top, middle, bottom, fieldToChute.get(top.getName()));
      }
      
      // nodes base chutes:
      {
         Chute top = new Chute("nodes");
         Chute bottom = top.copy();
         
         addNode.addEdge(incoming, 2, contains, 2, top);
         addNode.addEdge(contains, 2, outgoing, 2, bottom);
         level.makeLinked(top, bottom, fieldToChute.get(top.getName()));
      }
      
      // nodes aux chutes:
      {
         Chute top = new Chute("nodes.elts");
         Chute middle = top.copy();
         Chute bottom = top.copy();
         
         addNode.addEdge(incoming, 3, contains, 3, top);
         addNode.addEdge(contains, 3, nodesEltsMerge, 0, middle);
         addNode.addEdge(nodesEltsMerge, 0, outgoing, 3, bottom);
         level.makeLinked(top, middle, bottom, fieldToChute.get(top.getName()));
      }
      
      // edges base chutes:
      {
         Chute top = new Chute("edges");
         Chute bottom = top.copy();
         
         addNode.addEdge(incoming, 4, contains, 4, top);
         addNode.addEdge(contains, 4, outgoing, 4, bottom);
         level.makeLinked(top, bottom, fieldToChute.get(top.getName()));
      }
      
      // edges aux chutes:
      {
         Chute top = new Chute("edges.elts");
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
         
         Chute top = new Chute("node");
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
         
         Chute toContains = new Chute(null);
         addNode.addEdge(containsSplit, 0, contains, 6, toContains);
         
         Chute toIn = new Chute(null);
         addNode.addEdge(inSplit, 0, inMerge, 1, toIn);
         
         Chute toOut = new Chute(null);
         addNode.addEdge(outSplit, 0, outMerge, 1, toOut);
         
         Chute toNodesElts = new Chute(null);
         addNode.addEdge(nodesEltsSplit, 0, nodesEltsMerge, 1, toNodesElts);
      }
   }
   
   private static void addAddEdge(final Level level,
         final Map<String, Chute> fieldToChute)
   {
      final Board addEdge = initializeBoard(level, "Board.addEdge");
      
      final Intersection incoming = addEdge.getIncomingNode();
      final Intersection outgoing = addEdge.getOutgoingNode();
      
      final Intersection containsStart = subnetworkFactory("Board.contains");
      final Intersection containsEnd = subnetworkFactory("Board.contains");
      final Intersection containsEdge = subnetworkFactory("Board.contains");
      Intersection mergeElts = factory(MERGE);
      addEdge.addNode(containsStart);
      addEdge.addNode(containsEnd);
      addEdge.addNode(containsEdge);
      addEdge.addNode(mergeElts);
      
      // Because Java needs closures:
      class Connecter
      {
         /**
          * Connects the given chute from the incoming node to containsStart,
          * then copies it to connect from containsEnd to containsEdge to
          * outgoing, all on the given port. Also links the chute with the field
          * of the same name
          */
         private void connect(Chute first, int port)
         {
            Chute[] chutes = new Chute[4];
            chutes[0] = first;
            for (int i = 1; i < 4; i++)
               chutes[i] = chutes[0].copy();
            
            addEdge.addEdge(incoming, port, containsStart, port, chutes[0]);
            addEdge.addEdge(containsStart, port, containsEnd, port, chutes[1]);
            addEdge.addEdge(containsEnd, port, containsEdge, port, chutes[2]);
            addEdge.addEdge(containsEdge, port, outgoing, port, chutes[3]);
            level.makeLinked(chutes);
            level.makeLinked(chutes[0], fieldToChute.get(chutes[0].getName()));
         }
      }
      
      Connecter c = new Connecter();
      
      // Add incomingNode chutes:
      c.connect(new Chute("incomingNode"), 0);
      
      // Add outgoingNode chutes:
      c.connect(new Chute("outgoingNode"), 1);
      
      // Add nodes base chutes:
      c.connect(new Chute("nodes"), 2);
      
      // Add nodes aux chutes:
      c.connect(new Chute("nodes.elts"), 3);
      
      // Add edges base chutes:
      {
         c.connect(new Chute("edges"), 4);
         outgoing.getInput(4).setPinched(true);
      }
      
      // Add edges aux chutes:
      {
         Chute[] edgesElts = new Chute[5];
         edgesElts[0] = new Chute("edges.elts");
         for (int i = 1; i < 5; i++)
            edgesElts[i] = edgesElts[0].copy();
         
         addEdge.addEdge(incoming, 5, containsStart, 5, edgesElts[0]);
         addEdge.addEdge(containsStart, 5, containsEnd, 5, edgesElts[1]);
         addEdge.addEdge(containsEnd, 5, containsEdge, 5, edgesElts[2]);
         addEdge.addEdge(containsEdge, 5, mergeElts, 0, edgesElts[3]);
         addEdge.addEdge(mergeElts, 0, outgoing, 5, edgesElts[4]);
      }
      
      // Add start chutes:
      {
         Intersection containsSplit = factory(SPLIT);
         Intersection setStartSplit = factory(SPLIT);
         Intersection setStart = subnetworkFactory("Chute.setStart");
         Intersection end = factory(END);
         
         addEdge.addNode(containsSplit);
         addEdge.addNode(setStartSplit);
         addEdge.addNode(setStart);
         addEdge.addNode(end);
         
         Chute top = new Chute("start");
         Chute middle = top.copy();
         Chute bottom = top.copy();
         middle.setPinched(true);
         addEdge.addEdge(incoming, 6, containsSplit, 0, top);
         addEdge.addEdge(containsSplit, 1, setStartSplit, 0, middle);
         addEdge.addEdge(setStartSplit, 0, end, 0, bottom);
         
         Chute toContains = new Chute(null);
         addEdge.addEdge(containsSplit, 0, containsStart, 6, toContains);
         
         Chute toSetStart = new Chute(null);
         addEdge.addEdge(setStartSplit, 1, setStart, 0, toSetStart);
      }
      
      // Add end chutes:
      {
         Intersection containsSplit = factory(SPLIT);
         Intersection setStartSplit = factory(SPLIT);
         Intersection setStart = subnetworkFactory("Chute.setEnd");
         Intersection end = factory(END);
         
         addEdge.addNode(containsSplit);
         addEdge.addNode(setStartSplit);
         addEdge.addNode(setStart);
         addEdge.addNode(end);
         
         Chute top = new Chute("end");
         Chute middle = top.copy();
         Chute bottom = top.copy();
         middle.setPinched(true);
         addEdge.addEdge(incoming, 7, containsSplit, 0, top);
         addEdge.addEdge(containsSplit, 1, setStartSplit, 0, middle);
         addEdge.addEdge(setStartSplit, 0, end, 0, bottom);
         
         Chute toContains = new Chute(null);
         addEdge.addEdge(containsSplit, 0, containsEnd, 6, toContains);
         
         Chute toSetStart = new Chute(null);
         addEdge.addEdge(setStartSplit, 1, setStart, 0, toSetStart);
      }
      
      // Add edge chutes:
      {
         Intersection containsSplit = factory(SPLIT);
         Intersection eltsSplit = factory(SPLIT);
         Intersection setOutSplit = factory(SPLIT);
         Intersection setInSplit = factory(SPLIT);
         Intersection end = factory(END);
         
         addEdge.addNode(containsSplit);
         addEdge.addNode(eltsSplit);
         addEdge.addNode(setOutSplit);
         addEdge.addNode(setInSplit);
         addEdge.addNode(end);
         
         Intersection setOut = subnetworkFactory("Intersection.setOutputChute");
         Intersection setIn = subnetworkFactory("Intersection.setInputChute");
         addEdge.addNode(setOut);
         addEdge.addNode(setIn);
         
         Chute[] edgeChutes = new Chute[5];
         edgeChutes[0] = new Chute("edges");
         for (int i = 0; i < 5; i++)
            edgeChutes[i] = edgeChutes[0].copy();
         
         edgeChutes[0].setPinched(true);
         edgeChutes[1].setPinched(true);
         edgeChutes[4].setPinched(true);

         addEdge.addEdge(incoming, 8, containsSplit, 0, edgeChutes[0]);
         addEdge.addEdge(containsSplit, 1, eltsSplit, 0, edgeChutes[1]);
         addEdge.addEdge(eltsSplit, 1, setOutSplit, 0, edgeChutes[2]);
         addEdge.addEdge(setOutSplit, 1, setInSplit, 0, edgeChutes[3]);
         addEdge.addEdge(setInSplit, 1, end, 0, edgeChutes[4]);
         level.makeLinked(edgeChutes);
         level.makeLinked(edgeChutes[0], fieldToChute.get(edgeChutes[0].getName()));
         
         addEdge.addEdge(containsSplit, 0, containsEdge, 6, new Chute(null));
         addEdge.addEdge(eltsSplit, 0, mergeElts, 1, new Chute(null));
         addEdge.addEdge(setOutSplit, 0, setOut, 0, new Chute(null));
         addEdge.addEdge(setInSplit, 0, setIn, 0, new Chute(null));
      }
   }
   
   private static void addNodesSize(Level level, Map<String, Chute> fieldToChute)
   {
      Board nodesSize = initializeBoard(level, "Board.nodesSize");
      
      // connect all fields
      connectFields(nodesSize, level, fieldToChute, nameToPortMap,
            nameToPortMap.keySet().toArray(new String[0]));
      
      Intersection incoming = nodesSize.getIncomingNode();
      
      Chute nodes = incoming.getOutput(2);
      if (!nodes.getName().equals("nodes"))
         throw new RuntimeException();
      nodes.setPinched(true);
   }
   
   private static void addEdgesSize(Level level, Map<String, Chute> fieldToChute)
   {
      Board edgesSize = initializeBoard(level, "Board.edgesSize");
      
      // connect all fields
      connectFields(edgesSize, level, fieldToChute, nameToPortMap,
            nameToPortMap.keySet().toArray(new String[0]));
      
      Intersection incoming = edgesSize.getIncomingNode();
      
      Chute edges = incoming.getOutput(4);
      if (!edges.getName().equals("edges"))
         throw new RuntimeException();
      edges.setPinched(true);
   }
   
   private static void addGetNodes(Level level, Map<String, Chute> fieldToChute)
   {
      Board getNodes = initializeBoard(level, "Board.getNodes");
      
      Intersection incoming = getNodes.getIncomingNode();
      Intersection outgoing = getNodes.getOutgoingNode();
      
      // connect nodes chutes:
      {
         Intersection split = factory(SPLIT);
         Intersection end = factory(END);
         getNodes.addNode(split);
         getNodes.addNode(end);
         
         Chute top = new Chute("nodes");
         Chute bottom = top.copy();
         getNodes.addEdge(incoming, 2, split, 0, top);
         getNodes.addEdge(split, 0, outgoing, 2, bottom);
         level.makeLinked(top, bottom, fieldToChute.get(top.getName()));
         
         Chute right = new Chute(null);
         right.setPinched(true);
         getNodes.addEdge(split, 1, end, 0, right);
      }
      
      // connect nodes.elts chutes and return value aux:
      {
         Intersection split = factory(SPLIT);
         getNodes.addNode(split);
         
         Chute top = new Chute("nodes.elts");
         Chute bottom = top.copy();
         
         getNodes.addEdge(incoming, 3, split, 0, top);
         getNodes.addEdge(split, 0, outgoing, 3, bottom);
         level.makeLinked(top, bottom, fieldToChute.get(top.getName()));
         
         Chute retAux = new Chute(null);
         getNodes.addEdge(split, 1, outgoing, 7, retAux);
      }
      
      // connect return value:
      {
         Intersection start = factory(START_WHITE_BALL);
         getNodes.addNode(start);
         
         Chute ret = new Chute(null);
         getNodes.addEdge(start, 0, outgoing, 6, ret);
      }
      
      // connect other chutes:
      connectFields(getNodes, level, fieldToChute, nameToPortMap,
            "incomingNode", "outgoingNode", "edges", "edges.elts");
   }
   
   private static void addGetEdges(Level level, Map<String, Chute> fieldToChute)
   {
      Board getEdges = initializeBoard(level, "Board.getEdges");
      
      Intersection incoming = getEdges.getIncomingNode();
      Intersection outgoing = getEdges.getOutgoingNode();
      
      // connect nodes chutes:
      {
         Intersection split = factory(SPLIT);
         Intersection end = factory(END);
         getEdges.addNode(split);
         getEdges.addNode(end);
         
         Chute top = new Chute("edges");
         Chute bottom = top.copy();
         getEdges.addEdge(incoming, 4, split, 0, top);
         getEdges.addEdge(split, 0, outgoing, 4, bottom);
         level.makeLinked(top, bottom, fieldToChute.get(top.getName()));
         
         Chute right = new Chute(null);
         right.setPinched(true);
         getEdges.addEdge(split, 1, end, 0, right);
      }
      
      // connect nodes.elts chutes and return value aux:
      {
         Intersection split = factory(SPLIT);
         getEdges.addNode(split);
         
         Chute top = new Chute("edges.elts");
         Chute bottom = top.copy();
         
         getEdges.addEdge(incoming, 5, split, 0, top);
         getEdges.addEdge(split, 0, outgoing, 5, bottom);
         level.makeLinked(top, bottom, fieldToChute.get(top.getName()));
         
         Chute retAux = new Chute(null);
         getEdges.addEdge(split, 1, outgoing, 7, retAux);
      }
      
      // connect return value:
      {
         Intersection start = factory(START_WHITE_BALL);
         getEdges.addNode(start);
         
         Chute ret = new Chute(null);
         getEdges.addEdge(start, 0, outgoing, 6, ret);
      }
      
      // connect other chutes:
      connectFields(getEdges, level, fieldToChute, nameToPortMap,
            "incomingNode", "outgoingNode", "nodes", "nodes.elts");
   }
   
   private static void addGetIncomingNode(Level level,
         Map<String, Chute> fieldToChute)
   {
      Board getIn = initializeBoard(level, "Board.getIncomingNode");
      
      Intersection incoming = getIn.getIncomingNode();
      Intersection outgoing = getIn.getOutgoingNode();
      
      // connect incomingNode and return value:
      {
         Intersection split = factory(SPLIT);
         getIn.addNode(split);
         
         Chute top = new Chute("incomingNode");
         Chute bottom = top.copy();
         
         Chute ret = new Chute(null);
         
         getIn.addEdge(incoming, 0, split, 0, top);
         getIn.addEdge(split, 0, outgoing, 0, bottom);
         level.makeLinked(top, bottom, fieldToChute.get(top.getName()));
         
         getIn.addEdge(split, 1, outgoing, 6, ret);
      }
      
      // connect other fields
      connectFields(getIn, level, fieldToChute, nameToPortMap, "outgoingNode",
            "nodes", "nodes.elts", "edges", "edges.elts");
   }
   
   private static void addGetOutgoingNode(Level level,
         Map<String, Chute> fieldToChute)
   {
      Board getOut = initializeBoard(level, "Board.getOutgoingNode");
      
      Intersection incoming = getOut.getIncomingNode();
      Intersection outgoing = getOut.getOutgoingNode();
      
      // connect incomingNode and return value:
      {
         Intersection split = factory(SPLIT);
         getOut.addNode(split);
         
         Chute top = new Chute("outgoingNode");
         Chute bottom = top.copy();
         
         Chute ret = new Chute(null);
         
         getOut.addEdge(incoming, 1, split, 0, top);
         getOut.addEdge(split, 0, outgoing, 1, bottom);
         level.makeLinked(top, bottom, fieldToChute.get(top.getName()));
         
         getOut.addEdge(split, 1, outgoing, 6, ret);
      }
      
      // connect other fields
      connectFields(getOut, level, fieldToChute, nameToPortMap, "incomingNode",
            "nodes", "nodes.elts", "edges", "edges.elts");
   }
   
   private static void addContains(Level level, Map<String, Chute> fieldToChute)
   {
      Board contains = initializeBoard(level, "Board.contains");
      
      // attach all fields
      connectFields(contains, level, fieldToChute, nameToPortMap, nameToPortMap.keySet().toArray(new String[0]));
      
      // add pinchpoints to nodes and edges:
      Intersection incoming = contains.getIncomingNode();
      Chute nodes = incoming.getOutput(2);
      Chute edges = incoming.getOutput(4);
      
      nodes.setPinched(true);
      edges.setPinched(true);
      
      // add argument chute:
      Intersection end = factory(END);
      contains.addNode(end);
      
      contains.addEdge(incoming, 6, end, 0, new Chute("elt"));
   }
   
   private static void addDeactivate(Level level,
         Map<String, Chute> fieldToChute)
   {
      Board deactivate = initializeBoard(level, "Board.deactivate");

      Intersection incoming = deactivate.getIncomingNode();
      Intersection outgoing = deactivate.getOutgoingNode();
            
      //connect fields:
      connectFields(deactivate, level, fieldToChute, nameToPortMap, "incomingNode", "outgoingNode", "nodes", "edges");
      
      // add pinch points to nodes and edges:
      Chute nodes = incoming.getOutput(2);
      Chute edges = incoming.getOutput(4);
      if(!nodes.getName().equals("nodes") || !edges.getName().equals("edges"))
         throw new RuntimeException();
      nodes.setPinched(true);
      edges.setPinched(true);
      
      // add nodes aux chutes:
      {
         Intersection split = factory(SPLIT);
         Intersection end = factory(END);
         deactivate.addNode(split);
         deactivate.addNode(end);
         
         Chute top = new Chute("nodes.elts");
         Chute bottom = top.copy();
         deactivate.addEdge(incoming, 3, split, 0, top);
         deactivate.addEdge(split, 0, outgoing, 3, bottom);
         level.makeLinked(top, bottom, fieldToChute.get(top.getName()));
         
         Chute right = new Chute(null);
         right.setPinched(true);
         deactivate.addEdge(split, 1, end, 0, right);
      }
      
      // add edges aux chutes:
      {
         Intersection split = factory(SPLIT);
         Intersection end = factory(END);
         deactivate.addNode(split);
         deactivate.addNode(end);
         
         Chute top = new Chute("edges.elts");
         Chute bottom = top.copy();
         deactivate.addEdge(incoming, 5, split, 0, top);
         deactivate.addEdge(split, 0, outgoing, 5, bottom);
         level.makeLinked(top, bottom, fieldToChute.get(top.getName()));
         
         Chute right = new Chute(null);
         right.setPinched(true);
         deactivate.addEdge(split, 1, end, 0, right);
      }
   }
}
