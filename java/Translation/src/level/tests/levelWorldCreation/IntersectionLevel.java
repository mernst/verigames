package level.tests.levelWorldCreation;

import static level.Intersection.factory;
import static level.Intersection.subnetworkFactory;
import static level.Intersection.Kind.END;
import static level.Intersection.Kind.MERGE;
import static level.Intersection.Kind.SPLIT;
import static level.Intersection.Kind.START_BLACK_BALL;
import static level.Intersection.Kind.START_NO_BALL;
import static level.Intersection.Kind.START_WHITE_BALL;
import static level.tests.levelWorldCreation.BuildingTools.connectFields;
import static level.tests.levelWorldCreation.BuildingTools.initializeBoard;

import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.Map;

import level.Board;
import level.Chute;
import level.Intersection;
import level.Intersection.Kind;
import level.Level;

public class IntersectionLevel
{
   private static Map<String, Integer> nameToPortMap;
   static
   {
      nameToPortMap = new LinkedHashMap<String, Integer>();
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
      
      Chute left = new Chute();
      Chute right = new Chute();
      Chute bottom = new Chute();
      
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
      
      Chute ret = new Chute();
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
         
         Chute list = new Chute();
         list.setPinched(true);
         String name = "list";
         
         pad.addEdge(incoming, 0, end, 0, list);
         pad.addChuteName(list, name);
      }
      
      // list aux chutes:
      {
         Intersection merge = Intersection.factory(Kind.MERGE);
         Intersection start = Intersection.factory(Kind.START_BLACK_BALL);
         pad.addNode(merge);
         pad.addNode(start);
         
         Chute top = new Chute();
         Chute bottom = top.copy();
         String name = "list.elts";
         
         pad.addEdge(incoming, 1, merge, 0, top);
         pad.addEdge(merge, 0, outgoing, 0, bottom);
         pad.addChuteName(top, name);
         pad.addChuteName(bottom, name);
         level.makeLinked(top, bottom);
         
         Chute add = new Chute();
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
         
         String name = "inputChutes";
         Chute chute = new Chute();
         fieldToChute.put(name, chute);
         
         constructor.addEdge(start, 0, outgoing, 0, chute);
         constructor.addChuteName(chute, name);
      }
      
      // Add inputChutes aux chutes:
      {
         Intersection start = factory(START_NO_BALL);
         constructor.addNode(start);
         
         String name = "inputChutes.elts";
         Chute chute = new Chute();
         fieldToChute.put(name, chute);
         
         constructor.addEdge(start, 0, outgoing, 1, chute);
         constructor.addChuteName(chute, name);
      }
      
      // Add outputChutes base chutes:
      {
         Intersection start = factory(START_WHITE_BALL);
         constructor.addNode(start);
         
         String name = "outputChutes";
         Chute chute = new Chute();
         fieldToChute.put(name, chute);
         
         constructor.addEdge(start, 0, outgoing, 2, chute);
         constructor.addChuteName(chute, name);
      }
      
      // Add outputChutes aux chutes:
      {
         Intersection start = factory(START_NO_BALL);
         constructor.addNode(start);
         
         String name = "outputChutes.elts";
         Chute chute = new Chute();
         fieldToChute.put(name, chute);
         
         constructor.addEdge(start, 0, outgoing, 3, chute);
         constructor.addChuteName(chute, name);
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
         
         String name = "inputChutes";
         Chute top = new Chute();
         Chute bottom = top.copy();
         bottom.setPinched(true);
         setIn.addEdge(incoming, 0, split, 0, top);
         setIn.addEdge(split, 0, outgoing, 0, bottom);
         setIn.addChuteName(top, name);
         setIn.addChuteName(bottom, name);
         level.makeLinked(top, bottom, fieldToChute.get(name));
         
         Chute middle = new Chute();
         setIn.addEdge(split, 1, padSub, 0, middle);
      }
      
      // connect input aux and argument chutes:
      {
         Intersection merge = factory(MERGE);
         setIn.addNode(merge);
         
         String name = "inputChutes.elts";
         Chute top = new Chute();
         Chute middle = top.copy();
         Chute bottom = top.copy();
         
         setIn.addEdge(incoming, 1, padSub, 1, top);
         setIn.addEdge(padSub, 0, merge, 0, middle);
         setIn.addEdge(merge, 0, outgoing, 1, bottom);
         setIn.addChuteName(top, name);
         setIn.addChuteName(middle, name);
         setIn.addChuteName(bottom, name);
         level.makeLinked(top, middle, bottom, fieldToChute.get(name));
         
         Chute arg = new Chute();
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
         
         String name = "outputChutes";
         Chute top = new Chute();
         Chute bottom = top.copy();
         bottom.setPinched(true);
         setOut.addEdge(incoming, 2, split, 0, top);
         setOut.addEdge(split, 0, outgoing, 2, bottom);
         setOut.addChuteName(top, name);
         setOut.addChuteName(bottom, name);
         level.makeLinked(top, bottom, fieldToChute.get(name));
         
         Chute middle = new Chute();
         setOut.addEdge(split, 1, padSub, 0, middle);
      }
      
      // connect output aux and argument chutes:
      {
         Intersection merge = factory(MERGE);
         setOut.addNode(merge);
         
         String name = "outputChutes.elts";
         Chute top = new Chute();
         Chute middle = top.copy();
         Chute bottom = top.copy();
         
         setOut.addEdge(incoming, 3, padSub, 1, top);
         setOut.addEdge(padSub, 0, merge, 0, middle);
         setOut.addEdge(merge, 0, outgoing, 3, bottom);
         setOut.addChuteName(top, name);
         setOut.addChuteName(middle, name);
         setOut.addChuteName(bottom, name);
         level.makeLinked(top, middle, bottom, fieldToChute.get(name));
         
         Chute arg = new Chute();
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
         
         String name = "inputChutes.elts";
         Chute top = new Chute();
         Chute bottom = top.copy();
         
         getIn.addEdge(incoming, 1, split, 0, top);
         getIn.addEdge(split, 0, outgoing, 1, bottom);
         getIn.addChuteName(top, name);
         getIn.addChuteName(bottom, name);
         level.makeLinked(top, bottom, fieldToChute.get(name));
         
         Intersection start = factory(START_BLACK_BALL);
         getIn.addNode(start);
         
         Chute inBetween = new Chute();
         Chute right = new Chute();
         Chute ret = new Chute();
         
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
         
         String name = "outputChutes.elts";
         Chute top = new Chute();
         Chute bottom = top.copy();
         
         getOut.addEdge(incoming, 3, split, 0, top);
         getOut.addEdge(split, 0, outgoing, 3, bottom);
         getOut.addChuteName(top, name);
         getOut.addChuteName(bottom, name);
         level.makeLinked(top, bottom, fieldToChute.get(name));
         
         Intersection start = factory(START_BLACK_BALL);
         getOut.addNode(start);
         
         Chute inBetween = new Chute();
         Chute right = new Chute();
         Chute ret = new Chute();
         
         getOut.addEdge(split, 1, merge, 0, inBetween);
         getOut.addEdge(start, 0, merge, 1, right);
         getOut.addEdge(merge, 0, outgoing, 4, ret);
      }
      
      // connect other chutes:
      connectFields(getOut, level, fieldToChute, nameToPortMap, "outputChutes",
            "inputChutes", "inputChutes.elts");
   }
}
