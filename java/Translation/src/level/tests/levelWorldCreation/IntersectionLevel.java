package level.tests.levelWorldCreation;

import static level.tests.levelWorldCreation.BuildingTools.*;
import static level.Intersection.*;
import static level.Intersection.Kind.*;

import java.util.HashMap;
import java.util.Map;

import level.Board;
import level.Chute;
import level.Intersection;
import level.Level;

public class IntersectionLevel
{
   private static Map<String, Integer> nameToPortMap;
   static
   {
      nameToPortMap = new HashMap<String, Integer>();
      nameToPortMap.put("inputChutes", 0);
      nameToPortMap.put("inputChutes.elts", 1);
      nameToPortMap.put("outputChutes", 2);
      nameToPortMap.put("outputChutes.elts", 3);
   }
   
   public static Level makeLevel()
   {
      Level level = new Level();
      
      // Add static methods:
      addFactory(level);
      addSubnetworkFactory(level);
      addPadToLength(level);
      
      // Add instance methods:
      
      Map<String, Chute> fieldToChute = new HashMap<String, Chute>();
      
      addConstructor(level, fieldToChute);
      addSetInputChute(level, fieldToChute);
      addSetOutputChute(level, fieldToChute);
      addGetInputChute(level, fieldToChute);
      addGetOutputChute(level, fieldToChute);
      
      return level;
   }
   
   private static void addFactory(Level level)
   {
      Board factory = new Board();
      level.addBoard("Intersection.factory", factory);
      
      Intersection incoming = Intersection.factory(Kind.INCOMING);
      Intersection outgoing = Intersection.factory(Kind.OUTGOING);
      factory.addNode(incoming);
      factory.addNode(outgoing);
      
      Intersection startLeft = Intersection.factory(Kind.START_WHITE_BALL);
      Intersection startRight = Intersection.factory(Kind.START_WHITE_BALL);
      factory.addNode(startLeft);
      factory.addNode(startRight);
      
      Intersection merge = Intersection.factory(Kind.MERGE);
      factory.addNode(merge);
      
      Chute left = new Chute(null);
      Chute right = new Chute(null);
      Chute bottom = new Chute(null);
      
      factory.addEdge(startLeft, 0, merge, 0, left);
      factory.addEdge(startRight, 0, merge, 1, right);
      factory.addEdge(merge, 0, outgoing, 0, bottom);
   }
   
   private static void addSubnetworkFactory(Level level)
   {
      Board subFac = new Board();
      level.addBoard("Intersection.subnetworkFactory", subFac);
      
      Intersection incoming = Intersection.factory(Kind.INCOMING);
      Intersection outgoing = Intersection.factory(Kind.OUTGOING);
      subFac.addNode(incoming);
      subFac.addNode(outgoing);
      
      Intersection start = Intersection.factory(Kind.START_WHITE_BALL);
      subFac.addNode(start);
      
      Chute ret = new Chute(null);
      subFac.addEdge(start, 0, outgoing, 0, ret);
   }
   
   private static void addPadToLength(Level level)
   {
      Board pad = initializeBoard(level, "Intersection.padToLength");
      
      Intersection incoming = pad.getIncomingNode();
      Intersection outgoing = pad.getOutgoingNode();
      
      // list base chute:
      {
         Intersection end = factory(END);
         pad.addNode(end);
         
         Chute list = new Chute("list");
         list.setPinched(true);
         
         pad.addEdge(incoming, 0, end, 0, list);
      }
      
      // list aux chutes:
      {
         Intersection merge = Intersection.factory(Kind.MERGE);
         Intersection start = Intersection.factory(Kind.START_BLACK_BALL);
         pad.addNode(merge);
         pad.addNode(start);
         
         Chute top = new Chute("list.elts");
         Chute bottom = top.copy();
         
         pad.addEdge(incoming, 1, merge, 0, top);
         pad.addEdge(merge, 0, outgoing, 0, bottom);
         level.makeLinked(top, bottom);
         
         Chute add = new Chute(null);
         pad.addEdge(start, 0, merge, 1, add);
      }
   }
   
   private static void addConstructor(Level level, Map<String, Chute> fieldToChute)
   {
      Board constructor = initializeBoard(level, "Intersection.constructor");
      
      Intersection outgoing = constructor.getOutgoingNode();
      
      // Add inputChutes base chutes:
      {
         Intersection start = factory(START_WHITE_BALL);
         constructor.addNode(start);
         
         Chute chute = new Chute("inputChutes");
         fieldToChute.put(chute.getName(), chute);
         
         constructor.addEdge(start, 0, outgoing, 0, chute);
      }
      
      // Add inputChutes aux chutes:
      {
         Intersection start = factory(START_NO_BALL);
         constructor.addNode(start);
         
         Chute chute = new Chute("inputChutes.elts");
         fieldToChute.put(chute.getName(), chute);
         
         constructor.addEdge(start, 0, outgoing, 1, chute);
      }
      
      // Add outputChutes base chutes:
      {
         Intersection start = factory(START_WHITE_BALL);
         constructor.addNode(start);
         
         Chute chute = new Chute("outputChutes");
         fieldToChute.put(chute.getName(), chute);
         
         constructor.addEdge(start, 0, outgoing, 2, chute);
      }
      
      // Add outputChutes aux chutes:
      {
         Intersection start = factory(START_NO_BALL);
         constructor.addNode(start);
         
         Chute chute = new Chute("outputChutes.elts");
         fieldToChute.put(chute.getName(), chute);
         
         constructor.addEdge(start, 0, outgoing, 3, chute);
      }
   }
   
   private static void addSetInputChute(Level level,
         Map<String, Chute> fieldToChute)
   {
      Board setIn = initializeBoard(level, "Intersection.setInputChute");
      
      Intersection incoming = setIn.getIncomingNode();
      Intersection outgoing = setIn.getOutgoingNode();
      
      Intersection padSub = subnetworkFactory("Intersection.padToLength");
      setIn.addNode(padSub);
      
      // connect input base chutes:
      {
         Intersection split = factory(SPLIT);
         setIn.addNode(split);
         
         Chute top = new Chute("inputChutes");
         Chute bottom = top.copy();
         bottom.setPinched(true);
         setIn.addEdge(incoming, 0, split, 0, top);
         setIn.addEdge(split, 0, outgoing, 0, bottom);
         level.makeLinked(top, bottom, fieldToChute.get("inputChutes"));
         
         Chute middle = new Chute(null);
         setIn.addEdge(split, 1, padSub, 0, middle);
      }
      
      // connect input aux and argument chutes:
      {
         Intersection merge = factory(MERGE);
         setIn.addNode(merge);
         
         Chute top = new Chute("inputChutes.elts");
         Chute middle = top.copy();
         Chute bottom = top.copy();
         
         setIn.addEdge(incoming, 1, padSub, 1, top);
         setIn.addEdge(padSub, 0, merge, 0, middle);
         setIn.addEdge(merge, 0, outgoing, 1, bottom);
         level.makeLinked(top, middle, bottom, fieldToChute.get(top.getName()));
         
         Chute arg = new Chute(null);
         setIn.addEdge(incoming, 4, merge, 1, arg);
      }
      
      // connect other chutes:
      connectFields(setIn, level, fieldToChute, nameToPortMap, "outputChutes", "outputChutes.elts");
   }
   
   private static void addSetOutputChute(Level level,
         Map<String, Chute> fieldToChute)
   {
      Board setOut = initializeBoard(level, "Intersection.setOutputChute");
      
      Intersection incoming = setOut.getIncomingNode();
      Intersection outgoing = setOut.getOutgoingNode();
      
      Intersection padSub = subnetworkFactory("Intersection.padToLength");
      setOut.addNode(padSub);
      
      // connect output base chutes:
      {
         Intersection split = factory(SPLIT);
         setOut.addNode(split);
         
         Chute top = new Chute("outputChutes");
         Chute bottom = top.copy();
         bottom.setPinched(true);
         setOut.addEdge(incoming, 2, split, 0, top);
         setOut.addEdge(split, 0, outgoing, 2, bottom);
         level.makeLinked(top, bottom, fieldToChute.get("outputChutes"));
         
         Chute middle = new Chute(null);
         setOut.addEdge(split, 1, padSub, 0, middle);
      }
      
      // connect output aux and argument chutes:
      {
         Intersection merge = factory(MERGE);
         setOut.addNode(merge);
         
         Chute top = new Chute("outputChutes.elts");
         Chute middle = top.copy();
         Chute bottom = top.copy();
         
         setOut.addEdge(incoming, 3, padSub, 1, top);
         setOut.addEdge(padSub, 0, merge, 0, middle);
         setOut.addEdge(merge, 0, outgoing, 3, bottom);
         level.makeLinked(top, middle, bottom, fieldToChute.get(top.getName()));
         
         Chute arg = new Chute(null);
         setOut.addEdge(incoming, 4, merge, 1, arg);
      }
      
      // connect other chutes:
      connectFields(setOut, level, fieldToChute, nameToPortMap, "inputChutes",
            "inputChutes.elts");
   }
   
   // TODO add pinchpoints to getInputChute and getOutputChute
   private static void addGetInputChute(Level level,
         Map<String, Chute> fieldToChute)
   {
      Board getIn = initializeBoard(level, "Intersection.getInputChute");
      
      Intersection incoming = getIn.getIncomingNode();
      Intersection outgoing = getIn.getOutgoingNode();
      
      // connect input aux and return value chutes
      {
         Intersection split = factory(SPLIT);
         Intersection merge = factory(MERGE);
         getIn.addNode(split);
         getIn.addNode(merge);
         
         Chute top = new Chute("inputChutes.elts");
         Chute bottom = top.copy();
         
         getIn.addEdge(incoming, 1, split, 0, top);
         getIn.addEdge(split, 0, outgoing, 1, bottom);
         level.makeLinked(top, bottom, fieldToChute.get(top.getName()));
         
         Intersection start = factory(START_BLACK_BALL);
         getIn.addNode(start);
         
         Chute inBetween = new Chute(null);
         Chute right = new Chute(null);
         Chute ret = new Chute(null);
         
         getIn.addEdge(split, 1, merge, 0, inBetween);
         getIn.addEdge(start, 0, merge, 1, right);
         getIn.addEdge(merge, 0, outgoing, 4, ret);
      }
      
      // connect other chutes:
      connectFields(getIn, level, fieldToChute, nameToPortMap, "inputChutes",
            "outputChutes", "outputChutes.elts");
   }
   
   private static void addGetOutputChute(Level level,
         Map<String, Chute> fieldToChute)
   {
      Board getOut = initializeBoard(level, "Intersection.getOutputChute");
      
      Intersection incoming = getOut.getIncomingNode();
      Intersection outgoing = getOut.getOutgoingNode();
      
      // connect input aux and return value chutes
      {
         Intersection split = factory(SPLIT);
         Intersection merge = factory(MERGE);
         getOut.addNode(split);
         getOut.addNode(merge);
         
         Chute top = new Chute("outputChutes.elts");
         Chute bottom = top.copy();
         
         getOut.addEdge(incoming, 3, split, 0, top);
         getOut.addEdge(split, 0, outgoing, 3, bottom);
         level.makeLinked(top, bottom, fieldToChute.get(top.getName()));
         
         Intersection start = factory(START_BLACK_BALL);
         getOut.addNode(start);
         
         Chute inBetween = new Chute(null);
         Chute right = new Chute(null);
         Chute ret = new Chute(null);
         
         getOut.addEdge(split, 1, merge, 0, inBetween);
         getOut.addEdge(start, 0, merge, 1, right);
         getOut.addEdge(merge, 0, outgoing, 4, ret);
      }
      
      // connect other chutes:
      connectFields(getOut, level, fieldToChute, nameToPortMap, "outputChutes",
            "inputChutes", "inputChutes.elts");
   }
}
