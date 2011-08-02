package level.tests.levelWorldCreation;

import static level.Intersection.Kind.*;
import static level.Intersection.*;
import static level.tests.levelWorldCreation.BuildingTools.*;

import java.util.Collections;
import java.util.HashMap;
import java.util.Map;

import level.Board;
import level.Chute;
import level.Intersection;
import level.Level;
import level.NullTest;

public class LevelLevel
{
   private static final Map<String, Integer> nameToPortMap;
   static
   {
      Map<String, Integer> nameToPortLocal = new HashMap<String, Integer>();
      nameToPortLocal.put("linkedEdgeClasses", 0);
      nameToPortLocal.put("linkedEdgeClasses.elts", 1);
      nameToPortLocal.put("linkedEdgeClasses.elts.elts", 2);
      nameToPortLocal.put("boardNames", 3);
      nameToPortLocal.put("boardNames.keys", 4);
      nameToPortLocal.put("boardNames.values", 5);
      
      nameToPortMap = Collections.unmodifiableMap(nameToPortLocal);
   }
   
   public static Level makeLevel()
   {
      Level l = new Level();
      Map<String, Chute> fieldToChute = new HashMap<String, Chute>();
      
      addConstructor(l, fieldToChute);
      fieldToChute = Collections.unmodifiableMap(fieldToChute);
      
      addMakeLinked(l, fieldToChute);
      addAreLinked(l, fieldToChute);
      addAddBoard(l, fieldToChute);
      addBoards(l, fieldToChute);
      addGetBoard(l, fieldToChute);
      addOutputXML(l, fieldToChute);
      addOutputlinkedEdgeClasses(l, fieldToChute);
      addOutputBoardsMap(l, fieldToChute);
      addDeactivate(l, fieldToChute);
      
      return l;
   }
   
   private static void addConstructor(Level level,
         Map<String, Chute> fieldToChute)
   {
      Board constructor = initializeBoard(level, "Level.constructor");

      addField(constructor, fieldToChute, nameToPortMap, "linkedEdgeClasses", START_WHITE_BALL);
      addField(constructor, fieldToChute, nameToPortMap, "linkedEdgeClasses.elts", START_NO_BALL);
      addField(constructor, fieldToChute, nameToPortMap, "linkedEdgeClasses.elts.elts", START_NO_BALL);
      addField(constructor, fieldToChute, nameToPortMap, "boardNames", START_WHITE_BALL);
      addField(constructor, fieldToChute, nameToPortMap, "boardNames.keys", START_NO_BALL);
      addField(constructor, fieldToChute, nameToPortMap, "boardNames.values", START_NO_BALL);
      
   }
   
   private static void addMakeLinked(Level level,
         Map<String, Chute> fieldToChute)
   {
      Board makeLinked = initializeBoard(level, "Level.makeLinked");
      
      Intersection incoming = makeLinked.getIncomingNode();
      Intersection outgoing = makeLinked.getOutgoingNode();
      
      // Connect linkedEdgeClasses.elts, linked base chutes, toRemove aux chutes, and
      // newEquivClass base chutes:
      {
         Intersection linkedSplit = factory(SPLIT);
         Intersection newEquivMerge = factory(MERGE);
         makeLinked.addNode(linkedSplit);
         makeLinked.addNode(newEquivMerge);
         
         // Connect linkedEdgeClasses.elts chutes:
         {
            Chute top = new Chute("linkedEdgeClasses.elts", true, null);
            Chute middle = top.copy();
            Chute bottom = top.copy();
            
            makeLinked.addEdge(incoming, 1, linkedSplit, 0, top);
            makeLinked.addEdge(linkedSplit, 0, newEquivMerge, 0, middle);
            makeLinked.addEdge(newEquivMerge, 0, outgoing, 1, bottom);
            level.makeLinked(top, middle, bottom,
                  fieldToChute.get(top.getName()));
         }
         
         // Connect linked and toRemove.elts
         {
            Intersection split = factory(SPLIT);
            Intersection linkedEnd = factory(END);
            Intersection merge = factory(MERGE);
            Intersection toRemoveEnd = factory(END);
            Intersection toRemoveStart = factory(START_NO_BALL);
            
            makeLinked.addNode(split);
            makeLinked.addNode(linkedEnd);
            makeLinked.addNode(merge);
            makeLinked.addNode(toRemoveEnd);
            makeLinked.addNode(toRemoveStart);
            
            // connect linked:
            {
               Chute linkedTop = new Chute("linked", true, null);
               Chute linkedBottom = linkedTop.copy();
               linkedTop.setPinched(true);
               linkedBottom.setPinched(true);
               
               makeLinked.addEdge(linkedSplit, 1, split, 0, linkedTop);
               makeLinked.addEdge(split, 0, linkedEnd, 0, linkedBottom);
               level.makeLinked(linkedTop, linkedBottom);
            }
            
            // connect toRemove:
            {
               Chute top = new Chute("toRemove", true, null);
               Chute bottom = top.copy();
               
               makeLinked.addEdge(toRemoveStart, 0, merge, 1, top);
               makeLinked.addEdge(merge, 0, toRemoveEnd, 0, bottom);
               level.makeLinked(top, bottom);
            }
            
            makeLinked.addEdge(split, 1, merge, 0, new Chute(null, true, null));
         }
         
         // connect newEquivClass base chutes:
         {
            Intersection start = factory(START_WHITE_BALL);
            Intersection split = factory(SPLIT);
            Intersection end = factory(END);
            
            makeLinked.addNode(start);
            makeLinked.addNode(split);
            makeLinked.addNode(end);
            
            Chute top = new Chute("newEquivClass", true, null);
            Chute bottom = top.copy();
            top.setPinched(true);
            
            makeLinked.addEdge(start, 0, split, 0, top);
            makeLinked.addEdge(split, 1, end, 0, bottom);
            level.makeLinked(top, bottom);
            
            makeLinked.addEdge(split, 0, newEquivMerge, 1, new Chute(null, true, null));
         }
      }
      
      // connect linkedEdgeClasses.elts.elts, toRemove.elts.elts, toLink.elts, and
      // newEquivClass.elts chutes:
      {
         Intersection toNewEquivSplit = factory(SPLIT);
         Intersection fromNewEquivMerge = factory(MERGE);
         Intersection fromToLinkSplit = factory(SPLIT);
         makeLinked.addNode(toNewEquivSplit);
         makeLinked.addNode(fromNewEquivMerge);
         makeLinked.addNode(fromToLinkSplit);
         
         // connect LinkedEdgeClasses.elts.elts and toRemove.elts.elts
         {
            Intersection merge = factory(MERGE);
            makeLinked.addNode(merge);
            
            Chute[] linkedEdgeClasses = new Chute[4];
            linkedEdgeClasses[0] = new Chute("linkedEdgeClasses.elts.elts", true, null);
            for (int i = 1; i < linkedEdgeClasses.length; i++)
               linkedEdgeClasses[i] = linkedEdgeClasses[0].copy();

            makeLinked.addEdge(incoming, 2, merge, 0, linkedEdgeClasses[0]);
            makeLinked.addEdge(merge, 0, toNewEquivSplit, 0, linkedEdgeClasses[1]);
            makeLinked.addEdge(toNewEquivSplit, 0, fromNewEquivMerge, 0, linkedEdgeClasses[2]);
            makeLinked.addEdge(fromNewEquivMerge, 0, outgoing, 2, linkedEdgeClasses[3]);
            level.makeLinked(linkedEdgeClasses);
            level.makeLinked(linkedEdgeClasses[0], fieldToChute.get(linkedEdgeClasses[0].getName()));
            
            Chute toRemove = new Chute("toRemove.elts.elts", true, null);
            Intersection start = factory(START_NO_BALL);
            makeLinked.addNode(start);
            makeLinked.addEdge(start, 0, merge, 1, toRemove);
            level.makeLinked(linkedEdgeClasses[0], toRemove);
         }
         
         // connect toLink.elts
         {
            Chute top = new Chute("toLink.elts", true, null);
            Chute bottom = top.copy();
            
            makeLinked.addEdge(incoming, 7, fromToLinkSplit, 0, top);
            makeLinked.addEdge(fromToLinkSplit, 0, outgoing, 6, bottom);
            
            level.makeLinked(top, bottom);
         }
         
         // connect newEquivClass.elts
         {
            Intersection merge = factory(MERGE);
            makeLinked.addNode(merge);
            
            Chute top = new Chute("newEquivClass.elts", true, null);
            Chute bottom = top.copy();
            
            makeLinked.addEdge(fromToLinkSplit, 1, merge, 1, top);
            makeLinked.addEdge(merge, 0, fromNewEquivMerge, 1, bottom);
            level.makeLinked(top, bottom);
            
            makeLinked.addEdge(toNewEquivSplit, 1, merge, 0, new Chute(null, true, null));
         }
      }
      
      // connect toRemove base chute:
      {
         Intersection start = factory(START_WHITE_BALL);
         Intersection end = factory(END);
         makeLinked.addNode(start);
         makeLinked.addNode(end);
         
         Chute toRemove = new Chute("toRemove", true, null);
         toRemove.setPinched(true);
         makeLinked.addEdge(start, 0, end, 0, toRemove);
      }
      
      // connect toLink (arg) base chute:
      {
         Intersection end = factory(END);
         makeLinked.addNode(end);
         
         Chute toLink = new Chute("toLink", true, null);
         toLink.setPinched(true);
         
         makeLinked.addEdge(incoming, 6, end, 0, toLink);
      }
      
      // connect other chutes:
      connectFields(makeLinked, level, fieldToChute, nameToPortMap,
            "linkedEdgeClasses", "boardNames", "boardNames.keys",
            "boardNames.values");
      
      // add pinchpoint to linkedEdgeClasses:
      {
         Chute c = incoming.getOutputChute(nameToPortMap
               .get("linkedEdgeClasses"));
         if (!c.getName().equals("linkedEdgeClasses"))
            throw new RuntimeException();
         c.setPinched(true);
      }
   }
   
   private static void addAreLinked(Level level, Map<String, Chute> fieldToChute)
   {
      Board areLinked = initializeBoard(level, "Level.areLinked");
      
      Intersection incoming = areLinked.getIncomingNode();
      Intersection outgoing = areLinked.getOutgoingNode();
      
      // connect linkedEdgeClasses.elts chutes:
      {
         Intersection split = factory(SPLIT);
         areLinked.addNode(split);
         
         Chute top = new Chute("linkedEdgeClasses.elts", true, null);
         Chute bottom = top.copy();
         areLinked.addEdge(incoming, 1, split, 0, top);
         areLinked.addEdge(split, 0, outgoing, 1, bottom);
         level.makeLinked(top, bottom, fieldToChute.get(top.getName()));
         
         Intersection end = factory(END);
         areLinked.addNode(end);
         
         Chute branch = new Chute(null, true, null);
         branch.setPinched(true);
         areLinked.addEdge(split, 1, end, 0, branch);
      }
      
      // connect argument base chute:
      {
         Intersection end = factory(END);
         areLinked.addNode(end);
         
         Chute arg = new Chute("chutes", true, null);
         arg.setPinched(true);
         
         areLinked.addEdge(incoming, 6, end, 0, arg);
      }
      
      // connect argument aux chute
      areLinked.addEdge(incoming, 7, outgoing, 6, new Chute("chutes.elts",
            true, null));
      
      // connect other chutes:
      connectFields(areLinked, level, fieldToChute, nameToPortMap,
            "linkedEdgeClasses", "linkedEdgeClasses.elts.elts", "boardNames",
            "boardNames.keys", "boardNames.values");
      
      // add pinch-point to linkedEdgeClasses
      {
         Chute linkedEdgeClasses = incoming.getOutputChute(0);
         if (!linkedEdgeClasses.getName().equals("linkedEdgeClasses"))
            throw new RuntimeException();
         
         linkedEdgeClasses.setPinched(true);
      }
   }
   
   private static void addAddBoard(Level level, Map<String, Chute> fieldToChute)
   {
      Board addBoard = initializeBoard(level, "Level.addBoard");
      
      Intersection incoming = addBoard.getIncomingNode();
      Intersection outgoing = addBoard.getOutgoingNode();
      
      // connect name (arg) and boardNames.keys chutes
      {
         Intersection merge = factory(MERGE);
         addBoard.addNode(merge);
         
         Chute top = new Chute("boardNames.keys", true, null);
         Chute bottom = top.copy();
         addBoard.addEdge(incoming, nameToPortMap.get(top.getName()), merge, 0,
               top);
         addBoard.addEdge(merge, 0, outgoing, nameToPortMap.get(top.getName()),
               bottom);
         level.makeLinked(top, bottom, fieldToChute.get(top.getName()));
         
         Chute name = new Chute("name", true, null);
         addBoard.addEdge(incoming, 6, merge, 1, name);
      }
      
      // connect b (arg) and boardNames.values chutes
      {
         Intersection merge = factory(MERGE);
         addBoard.addNode(merge);
         
         Chute top = new Chute("boardNames.values", true, null);
         Chute bottom = top.copy();
         addBoard.addEdge(incoming, nameToPortMap.get(top.getName()), merge, 0,
               top);
         addBoard.addEdge(merge, 0, outgoing, nameToPortMap.get(top.getName()),
               bottom);
         level.makeLinked(top, bottom, fieldToChute.get(top.getName()));
         
         Chute name = new Chute("b", true, null);
         addBoard.addEdge(incoming, 7, merge, 1, name);
      }
      
      // connect other chutes:
      connectFields(addBoard, level, fieldToChute, nameToPortMap, "boardNames",
            "linkedEdgeClasses", "linkedEdgeClasses.elts",
            "linkedEdgeClasses.elts.elts");
      
      // add pinch-point to boardNames
      {
         Chute boardNames = incoming.getOutputChute(nameToPortMap
               .get("boardNames"));
         if (!boardNames.getName().equals("boardNames"))
            throw new RuntimeException();
         
         boardNames.setPinched(true);
      }
   }
   
   private static void addBoards(Level level, Map<String, Chute> fieldToChute)
   {
      Board boards = initializeBoard(level, "Level.boards");
      
      Intersection incoming = boards.getIncomingNode();
      Intersection outgoing = boards.getOutgoingNode();
      
      // add boardNames.values and return aux chutes
      {
         Intersection split = factory(SPLIT);
         boards.addNode(split);
         
         Chute top = new Chute("boardNames.values", true, null);
         Chute bottom = top.copy();
         boards.addEdge(incoming, nameToPortMap.get(top.getName()), split, 0,
               top);
         boards.addEdge(split, 0, outgoing, nameToPortMap.get(top.getName()),
               bottom);
         level.makeLinked(top, bottom, fieldToChute.get(top.getName()));
         
         Chute retAux = new Chute(null, true, null);
         boards.addEdge(split, 1, outgoing, 7, retAux);
      }
      
      // add return base chute:
      {
         Intersection start = factory(START_WHITE_BALL);
         boards.addNode(start);
         
         boards.addEdge(start, 0, outgoing, 6, new Chute(null, true, null));
      }
      
      // add other chutes:
      connectFields(boards, level, fieldToChute, nameToPortMap,
            "linkedEdgeClasses", "linkedEdgeClasses.elts",
            "linkedEdgeClasses.elts.elts", "boardNames", "boardNames.keys");
      
      // add pinch to boardNames
      {
         Chute boardNames = incoming.getOutputChute(nameToPortMap.get("boardNames"));
         if (!boardNames.getName().equals("boardNames"))
            throw new RuntimeException();
         boardNames.setPinched(true);
      }
   }
   
   private static void addGetBoard(Level level, Map<String, Chute> fieldToChute)
   {
      Board getBoard = initializeBoard(level, "Level.getBoard");
      
      Intersection incoming = getBoard.getIncomingNode();
      Intersection outgoing = getBoard.getOutgoingNode();
      
      // add boardNames.values and return value chutes
      {
         Intersection split = factory(SPLIT);
         Intersection merge = factory(MERGE);
         Intersection start = factory(START_BLACK_BALL);
         getBoard.addNode(split);
         getBoard.addNode(merge);
         getBoard.addNode(start);
         
         Chute top = new Chute("boardNames.values", true, null);
         Chute bottom = top.copy();
         getBoard.addEdge(incoming, nameToPortMap.get(top.getName()), split, 0,
               top);
         getBoard.addEdge(split, 0, outgoing, nameToPortMap.get(top.getName()),
               bottom);
         level.makeLinked(top, bottom, fieldToChute.get(top.getName()));
         
         getBoard.addEdge(merge, 0, outgoing, 6, new Chute(null, true, null));
         getBoard.addEdge(split, 1, merge, 0, new Chute(null, true, null));
         getBoard.addEdge(start, 0, merge, 1, new Chute(null, true, null));
      }
      
      // add incoming chute
      {
         Intersection end = factory(END);
         getBoard.addNode(end);
         
         getBoard.addEdge(incoming, 6, end, 0, new Chute("name", true, null));
      }
      
      // add other chutes:
      connectFields(getBoard, level, fieldToChute, nameToPortMap,
            "linkedEdgeClasses", "linkedEdgeClasses.elts",
            "linkedEdgeClasses.elts.elts", "boardNames", "boardNames.keys");
      
      // add pinch to boardNames chute:
      {
         Chute boardNames = incoming.getOutputChute(nameToPortMap
               .get("boardNames"));
         if (!boardNames.getName().equals("boardNames"))
            throw new RuntimeException();
         boardNames.setPinched(true);
      }
   }
   
   private static void addOutputXML(Level level, Map<String, Chute> fieldToChute)
   {
      Board outXML = initializeBoard(level, "Level.outputXML");
      
      Intersection incoming = outXML.getIncomingNode();
      Intersection outgoing = outXML.getOutgoingNode();
      
      Intersection linkedOut = subnetworkFactory("Level.outputLinkedEdgeClasses");
      Intersection boardsOut = subnetworkFactory("Level.outputBoardsMap");
      outXML.addNode(linkedOut);
      outXML.addNode(boardsOut);
      
      // connect field chutes through the two subnetwork calls
      for (Map.Entry<String, Integer> entry : nameToPortMap.entrySet())
      {
         int port = entry.getValue();
         String fieldName = entry.getKey();
         
         Chute[] chutes = new Chute[3];
         chutes[0] = new Chute(fieldName, true, null);
         chutes[1] = chutes[0].copy();
         chutes[2] = chutes[0].copy();
         
         outXML.addEdge(incoming, port, linkedOut, port, chutes[0]);
         outXML.addEdge(linkedOut, port, boardsOut, port, chutes[1]);
         outXML.addEdge(boardsOut, port, outgoing, port, chutes[2]);
         
         level.makeLinked(chutes);
         level.makeLinked(chutes[0], fieldToChute.get(fieldName));
      }
      
      // connect out (arg) chutes:
      {
         Chute[] outChutes = new Chute[3];
         outChutes[0] = new Chute("out", true, null);
         outChutes[1] = outChutes[0].copy();
         outChutes[2] = outChutes[0].copy();
         
         outChutes[0].setPinched(true);
         outChutes[2].setPinched(true);
         
         Intersection split1 = factory(SPLIT);
         Intersection split2 = factory(SPLIT);
         Intersection end = factory(END);
         
         outXML.addNode(split1);
         outXML.addNode(split2);
         outXML.addNode(end);

         outXML.addEdge(incoming, 6, split1, 0, outChutes[0]);
         outXML.addEdge(split1, 1, split2, 0, outChutes[1]);
         outXML.addEdge(split2, 1, end, 0, outChutes[2]);
         level.makeLinked(outChutes);

         outXML.addEdge(split1, 0, linkedOut, 6, new Chute(null, true, null));
         outXML.addEdge(split2, 0, boardsOut, 6, new Chute(null, true, null));
      }
   }
   
   private static void addOutputlinkedEdgeClasses(Level level,
         Map<String, Chute> fieldToChute)
   {
      Board outLinked = initializeBoard(level, "Level.outputLinkedEdgeClasses");
      
      Intersection incoming = outLinked.getIncomingNode();
      Intersection outgoing = outLinked.getOutgoingNode();
      
      Intersection boards = subnetworkFactory("Level.boards");
      outLinked.addNode(boards);
      
      // connect all boardNames chutes
      for (String name : new String[] { "boardNames", "boardNames.keys",
            "boardNames.values" })
      {
         int port = nameToPortMap.get(name);
         
         Chute top = new Chute(name, true, null);
         Chute bottom = top.copy();
         
         outLinked.addEdge(incoming, port, boards, port, top);
         outLinked.addEdge(boards, port, outgoing, port, bottom);
         
         level.makeLinked(top, bottom, fieldToChute.get(name));
      }
      
      // connect linkedEdges base chutes:
      {
         Chute top = new Chute("linkedEdgeClasses", true, null);
         Chute bottom = top.copy();
         top.setPinched(true);
         
         outLinked.addEdge(incoming, 0, boards, 0, top);
         outLinked.addEdge(boards, 0, outgoing, 0, bottom);
         
         level.makeLinked(top, bottom, fieldToChute.get(top.getName()));
      }
      
      // connect linkedEdges.elts chutes:
      {
         Intersection split = factory(SPLIT);
         Intersection end = factory(END);
         outLinked.addNode(split);
         outLinked.addNode(end);
         
         Chute top = new Chute("linkedEdgeClasses.elts", true, null);
         Chute middle = top.copy();
         Chute bottom = top.copy();
         
         outLinked.addEdge(incoming, 1, split, 0, top);
         outLinked.addEdge(split, 0, boards, 1, middle);
         outLinked.addEdge(boards, 1, outgoing, 1, bottom);
         level.makeLinked(top, middle, bottom, fieldToChute.get(top.getName()));
         
         Chute set = new Chute("set", true, null);
         set.setPinched(true);
         
         outLinked.addEdge(split, 1, end, 0, set);
      }
      
      // connect linkedEdges.elts.elts and alreadyPrintedEdges.elts
      {
         Intersection split = factory(SPLIT);
         outLinked.addNode(split);
         
         // connect linkedEdges.elts.elts and c chutes
         {
            Intersection cSplit = factory(SPLIT);
            outLinked.addNode(cSplit);
            
            Chute top = new Chute("linkedEdgeClasses.elts.elts", true, null);
            Chute middle = top.copy();
            Chute bottom = top.copy();
            
            outLinked.addEdge(incoming, 2, cSplit, 0, top);
            outLinked.addEdge(cSplit, 0, boards, 2, middle);
            outLinked.addEdge(boards, 2, outgoing, 2, bottom);
            level.makeLinked(top, bottom, middle,
                  fieldToChute.get(top.getName()));
            
            Intersection end = factory(END);
            outLinked.addNode(end);
            
            Chute cTop = new Chute("c", true, null);
            Chute cBottom = cTop.copy();
            cTop.setPinched(true);
            
            outLinked.addEdge(cSplit, 1, split, 0, cTop);
            outLinked.addEdge(split, 0, end, 0, cBottom);
            
            level.makeLinked(cTop, cBottom);
         }
         
         // connect alreadyPrintedEdges.elts
         {
            Intersection start = factory(START_NO_BALL);
            Intersection end = factory(END);
            Intersection merge = factory(MERGE);
            
            outLinked.addNode(start);
            outLinked.addNode(end);
            outLinked.addNode(merge);
            
            Chute top = new Chute("alreadyPrintedEdges.elts", true, null);
            Chute bottom = top.copy();
            
            outLinked.addEdge(start, 0, merge, 1, top);
            outLinked.addEdge(merge, 0, end, 0, bottom);
            level.makeLinked(top, bottom);
            
            outLinked.addEdge(split, 1, merge, 0, new Chute(null, true, null));
         }
      }
      
      // connect alreadyPrintedEdges base chutes:
      {
         Chute alreadyPrinted = new Chute("alreadyPrintedEdges", true, null);
         alreadyPrinted.setPinched(true);
         
         Intersection start = factory(START_WHITE_BALL);
         Intersection end = factory(END);
         outLinked.addNode(start);
         outLinked.addNode(end);
         
         outLinked.addEdge(start, 0, end, 0, alreadyPrinted);
      }
      
      // connect boards retval base chute:
      {
         Intersection end = factory(END);
         outLinked.addNode(end);
         
         Chute ret = new Chute(null, true, null);
         ret.setPinched(true);
         
         outLinked.addEdge(boards, 6, end, 0, ret);
      }
      
      // connect boards retval aux chutes:
      {
         Intersection split = factory(SPLIT);
         Intersection end1 = factory(END);
         Intersection end2 = factory(END);
         
         outLinked.addNode(split);
         outLinked.addNode(end1);
         outLinked.addNode(end2);
         
         Chute start = new Chute(null, true, null);
         Chute left = start.copy();
         Chute right = new Chute("b", true, null);
         right.setPinched(true);
         
         outLinked.addEdge(boards, 7, split, 0, start);
         outLinked.addEdge(split, 0, end1, 0, left);
         outLinked.addEdge(split, 1, end2, 0, right);
         
         level.makeLinked(start, left);
      }
      
      // connect out (arg)
      {
         Chute out = new Chute("out", true, null);
         out.setPinched(true);
         
         Intersection end = factory(END);
         outLinked.addNode(end);
         
         outLinked.addEdge(incoming, 6, end, 0, out);
      }
      
      // connect Board.getEdges subnetwork and its return values
      {
         Intersection getEdges = subnetworkFactory("Board.getEdges");
         outLinked.addNode(getEdges);
         
         // connect base chute:
         {
            Intersection end = factory(END);
            outLinked.addNode(end);
            
            Chute ret = new Chute(null, true, null);
            ret.setPinched(true);
            
            outLinked.addEdge(getEdges, 0, end, 0, ret);
         }
         
         // connect aux chutes:
         {
            Intersection split = factory(SPLIT);
            Intersection end1 = factory(END);
            Intersection end2 = factory(END);
            
            outLinked.addNode(split);
            outLinked.addNode(end1);
            outLinked.addNode(end2);
            
            Chute start = new Chute(null, true, null);
            Chute left = start.copy();
            Chute right = new Chute("c", true, null);
            right.setPinched(true);
            
            outLinked.addEdge(getEdges, 1, split, 0, start);
            outLinked.addEdge(split, 0, end1, 0, left);
            outLinked.addEdge(split, 1, end2, 0, right);
            
            level.makeLinked(start, left);
         }
      }
   }
   
   private static void addOutputBoardsMap(Level level,
         Map<String, Chute> fieldToChute)
   {
      Board boardsOut = initializeBoard(level, "Level.outputBoardsMap");
      
      Intersection incoming = boardsOut.getIncomingNode();
      Intersection outgoing = boardsOut.getOutgoingNode();
      
      // connect linkedEdgeClasses chutes
      connectFields(boardsOut, level, fieldToChute, nameToPortMap,
            "linkedEdgeClasses", "linkedEdgeClasses.elts",
            "linkedEdgeClasses.elts.elts");
      
      // connect boardNames base chute:
      {
         Chute boardNames = new Chute("boardNames", true, null);
         boardNames.setPinched(true);
         
         boardsOut.addEdge(incoming, 3, outgoing, 3, boardNames);
         
         level.makeLinked(boardNames, fieldToChute.get(boardNames.getName()));
      }
      
      // connect keySet chute:
      {
         Intersection start = factory(START_WHITE_BALL);
         Intersection end = factory(END);
         boardsOut.addNode(start);
         boardsOut.addNode(end);
         
         Chute keySet = new Chute(null, true, null);
         keySet.setPinched(true);
         
         boardsOut.addEdge(start, 0, end, 0, keySet);
      }
      
      // connect boardNames.keys and name chutes:
      {
         Intersection split = factory(SPLIT);
         Intersection end = factory(END);
         boardsOut.addNode(split);
         boardsOut.addNode(end);
         
         Chute top = new Chute("boardNames.keys", true, null);
         Chute bottom = top.copy();
         
         boardsOut.addEdge(incoming, 4, split, 0, top);
         boardsOut.addEdge(split, 0, outgoing, 4, bottom);
         level.makeLinked(top, bottom, fieldToChute.get(top.getName()));
         
         boardsOut.addEdge(split, 1, end, 0, new Chute("name", true, null));
      }
      
      // connect boardNames.values and board chutes:
      {
         Intersection split = factory(SPLIT);
         Intersection start = factory(START_BLACK_BALL);
         Intersection merge = factory(MERGE);
         Intersection end = factory(END);
         boardsOut.addNode(split);
         boardsOut.addNode(start);
         boardsOut.addNode(merge);
         boardsOut.addNode(end);
         
         Chute top = new Chute("boardNames.values", true, null);
         Chute bottom = top.copy();
         
         boardsOut.addEdge(incoming, 5, split, 0, top);
         boardsOut.addEdge(split, 0, outgoing, 5, bottom);
         level.makeLinked(top, bottom, fieldToChute.get(top.getName()));
         
         Chute board = new Chute("board", true, null);
         Chute right = new Chute(null, true, null);
         Chute left = new Chute(null, true, null);
         
         board.setPinched(true);
         
         boardsOut.addEdge(split, 1, merge, 0, left);
         boardsOut.addEdge(start, 0, merge, 1, right);
         boardsOut.addEdge(merge, 0, end, 0, board);
      }
      
      // connect out (arg) chute:
      {
         Chute out = new Chute("out", true, null);
         out.setPinched(true);
         
         Intersection end = factory(END);
         boardsOut.addNode(end);
         
         boardsOut.addEdge(incoming, 6, end, 0, out);
      }
      
      // connect getNodes and getEdges calls:
      for (String subnetworkName : new String[] { "Board.getNodes",
            "Board.getEdges" })
      {
         Intersection sub = subnetworkFactory(subnetworkName);
         boardsOut.addNode(sub);
         
         // connect base chutes:
         {
            Intersection end = factory(END);
            boardsOut.addNode(end);
            
            Chute base = new Chute(null, true, null);
            base.setPinched(true);
            
            boardsOut.addEdge(sub, 0, end, 0, base);
         }
         
         // connect auxiliary chutes:
         {
            Intersection endLeft = factory(END);
            Intersection endRight = factory(END);
            Intersection split = factory(SPLIT);
            boardsOut.addNode(endLeft);
            boardsOut.addNode(endRight);
            boardsOut.addNode(split);
            
            Chute top = new Chute(null, true, null);
            Chute bottom = top.copy();
            boardsOut.addEdge(sub, 1, split, 0, top);
            boardsOut.addEdge(split, 0, endLeft, 0, bottom);
            level.makeLinked(top, bottom);
            
            Chute right = new Chute(
                  subnetworkName.equals("Board.getNodes") ? "node" : "edge",
                  true, null);
            boardsOut.addEdge(split, 1, endRight, 0, right);
         }
      }
      
      // connect getInputChute and getOutputChute calls:
      for (String subnetworkName : new String[] { "Intersection.getInputChute",
            "Intersection.getOutputChute" })
      {
         String varName = subnetworkName.equals("Intersection.getInputChute") ? "input" : "output";
         
         Intersection topSubnetwork = subnetworkFactory(subnetworkName);
         Intersection bottomSubnetwork = subnetworkFactory(subnetworkName);
         boardsOut.addNode(topSubnetwork);
         boardsOut.addNode(bottomSubnetwork);
         
         NullTest split = factory(NULL_TEST).asNullTest();
         Intersection endLeft = factory(END);
         Intersection end = factory(END);
         Intersection merge = factory(MERGE);
         boardsOut.addNode(split);
         boardsOut.addNode(endLeft);
         boardsOut.addNode(end);
         boardsOut.addNode(merge);
         
         Chute top = new Chute(varName, true, null);
         Chute right = new Chute(varName, false, null);
         right.setNarrow(false);
         Chute bottom = top.copy();
         Chute leftTop = new Chute(varName, false, null);
         leftTop.setPinched(true);
         leftTop.setNarrow(true);
         Chute leftBottom = new Chute(varName, true, null);
         
         boardsOut.addEdge(topSubnetwork, 0, split, 0, top);
         boardsOut.addEdge(split, 1, merge, 1, right);
         boardsOut.addEdge(split, 0, endLeft, 0, leftTop);
         boardsOut.addEdge(bottomSubnetwork, 0, merge, 0, leftBottom);
         boardsOut.addEdge(merge, 0, end, 0, bottom);
      }
      
      // connect getStart and getEnd calls:
      for (String subnetworkName : new String[] {"Chute.getStart", "Chute.getEnd"})
      {
         Intersection sub = subnetworkFactory(subnetworkName);
         Intersection end = factory(END);
         boardsOut.addNode(sub);
         boardsOut.addNode(end);
         
         Chute c = new Chute(null, true, null);
         c.setPinched(true);
         boardsOut.addEdge(sub, 0, end, 0, c);
      }
   }
   
   private static void addDeactivate(Level level,
         Map<String, Chute> fieldToChute)
   {
      Board deactivate = initializeBoard(level, "Level.deactivate");
      
      Intersection incoming = deactivate.getIncomingNode();
      Intersection outgoing = deactivate.getOutgoingNode();
      
      // boardNames.values chutes:
      {
         Intersection split = factory(SPLIT);
         Intersection end = factory(END);
         deactivate.addNode(split);
         deactivate.addNode(end);
         
         Chute top = new Chute("boardNames.values", true, null);
         Chute bottom = top.copy();
         
         deactivate.addEdge(incoming, nameToPortMap.get(top.getName()), split,
               0, top);
         deactivate.addEdge(split, 0, outgoing,
               nameToPortMap.get(top.getName()), bottom);
         level.makeLinked(top, bottom, fieldToChute.get(top.getName()));
         
         Chute branch = new Chute(null, true, null);
         branch.setPinched(true);
         deactivate.addEdge(split, 1, end, 0, branch);
      }
      
      // add other chutes:
      connectFields(deactivate, level, fieldToChute, nameToPortMap,
            "linkedEdgeClasses", "linkedEdgeClasses.elts",
            "linkedEdgeClasses.elts.elts", "boardNames", "boardNames.keys");
      
      // pinch boardNames
      {
         Chute boardNames = incoming.getOutputChute(nameToPortMap
               .get("boardNames"));
         if (!boardNames.getName().equals("boardNames"))
            throw new RuntimeException();
         boardNames.setPinched(true);
      }
   }
}
