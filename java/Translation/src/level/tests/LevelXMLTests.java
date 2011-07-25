package level.tests;

import java.io.File;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.PrintStream;
import java.util.Arrays;
import java.util.HashMap;
import java.util.HashSet;
import java.util.LinkedHashSet;
import java.util.Map;
import java.util.Set;

import level.Board;
import level.Chute;
import level.Intersection;
import level.Intersection.Kind;
import level.Level;
import level.World;

import org.junit.Test;

public class LevelXMLTests
{
   
   /**
    * Generates the XML for TestClass (below)
    * 
    * class TestClass
    * {
    *    String s;
    *    
    *    public TestClass()
    *    {
    *       s = null;
    *    }
    * 
    *    public void method()
    *    {
    *       s = new String("asdf");
    *    }   
    * }
    */
   @Test public void TestClassXML() throws FileNotFoundException
   {
      Level l = new Level();
      
      Board constructor = new Board();
      constructor.addNode(Intersection.factory(Kind.INCOMING));
      Intersection start = Intersection
            .factory(Kind.START_BLACK_BALL);
      constructor.addNode(start);
      Intersection outgoing = Intersection.factory(Kind.OUTGOING);
      constructor.addNode(outgoing);
      Chute c = new Chute("s", true, null);
      c.setNarrow(false);
      constructor.addEdge(start, 0, outgoing, 0, c);
      
      l.addBoard("constructor", constructor);
      
      Intersection incoming = Intersection.factory(Kind.INCOMING);
      Intersection end = Intersection.factory(Kind.END);
      Intersection restart = Intersection
            .factory(Kind.START_WHITE_BALL);
      Intersection out = Intersection.factory(Kind.OUTGOING);
      
      Board method = new Board();
      method.addNode(incoming);
      method.addNode(end);
      method.addNode(restart);
      method.addNode(out);
      
      Chute c2 = new Chute("s", true, null);
      Chute c3 = new Chute("s", true, null);
      
      method.addEdge(incoming, 0, end, 0, c2);
      method.addEdge(restart, 0, out, 0, c3);
      
      l.addBoard("method", method);
      
      Set<Chute> linked = new HashSet<Chute>();
      linked.add(c);
      linked.add(c2);
      linked.add(c3);
      
      l.makeLinked(linked);

      l.deactivate();
      
      World w = new World();
      w.add(l);
      
      PrintStream p = new PrintStream(new FileOutputStream(new File(
            "TestClass.actual.xml")));
      w.outputXML(p);
      p.close();
   }
   
   /**
    * Outputs the xml for the level package to the file level.actual.xml<br/>
    * <br/>
    * Based on the code at changeset bd5bd18a57ca<br/>
    * <br/>
    * Contains some optimizations, such as removing checkRep() calls
    */
   @Test public void levelXML() throws FileNotFoundException
   {
      World levelWorld = new World();
      
      ChuteLevel cl = new ChuteLevel();
      Level chuteLevel = cl.getLevel();
      chuteLevel.deactivate();
      levelWorld.add(chuteLevel);
      
      PrintStream p = new PrintStream(new FileOutputStream(new File(
            "level.actual.xml")));
      levelWorld.outputXML(p);
      p.close();
   }
   
   private static class ChuteLevel
   {
      private Map<String, Chute> fieldToChute;
      
      private Level l;
      
      private ChuteLevel()
      {
         l = new Level();
         fieldToChute = new HashMap<String, Chute>();
         makeLevel();
      }
      
      private Level getLevel()
      {
         return l;
      }
      
      private void makeLevel()
      {
         addConstructor();
         addGetName();
         addSetStart();
         addGetStart();
         addSetEnd();
         addGetEnd();
         addCopy();
         addGetAuxiliaryChutes();
         addTraverseAuxChutes();
      }

      private void addConstructor()
      {
         Board constructor = new Board();
         
         l.addBoard("constructor", constructor);
         
         Intersection incoming = Intersection.factory(Kind.INCOMING);
         constructor.addNode(incoming);
         
         Intersection outgoing = Intersection.factory(Kind.OUTGOING);
         constructor.addNode(outgoing);
         
         // Construct name chutes:
         {
            Chute name = new Chute("name", true, null);
            fieldToChute.put("name", name);
            constructor.addEdge(incoming, 0, outgoing, 0, name);
         }
         
         // Construct aux (the argument) base chutes:
         {
            Chute auxArg = new Chute("aux", true, null);
            
            Intersection nullTest = Intersection.factory(Kind.NULL_TEST);
            constructor.addNode(nullTest);
            constructor.addEdge(incoming, 1, nullTest, 0, auxArg);
            
            Chute auxNullBranch = new Chute("aux", false, null);
            auxNullBranch.setNarrow(false);
            
            Intersection merge = Intersection.factory(Kind.MERGE);
            constructor.addNode(merge);
            
            constructor.addEdge(nullTest, 1, merge, 1, auxNullBranch);
            
            Intersection end = Intersection.factory(Kind.END);
            constructor.addNode(end);
            
            Chute auxArg2 = new Chute("aux", true, null);
            constructor.addEdge(merge, 0, end, 0, auxArg2);
            
            l.makeLinked(new HashSet<Chute>(Arrays.asList(auxArg, auxArg2)));
            
            Chute auxNotNullBranch = new Chute("aux", false, null);
            auxNotNullBranch.setNarrow(true);
            
            Intersection split = Intersection.factory(Kind.SPLIT);
            constructor.addNode(split);
            
            constructor.addEdge(nullTest, 0, split, 0, auxNotNullBranch);
            
            Intersection otherEnd = Intersection.factory(Kind.END);
            constructor.addNode(otherEnd);
            
            Chute auxNotNullBranch2 = auxNotNullBranch.copy();
            auxNotNullBranch2.setPinched(true);
            constructor.addEdge(split, 1, otherEnd, 0, auxNotNullBranch2);
            
            Chute auxNotNullBranch3 = auxNotNullBranch.copy();
            constructor.addEdge(split, 0, merge, 0, auxNotNullBranch3);
         }
         
         // Construct aux (the argument) auxiliary chutes:
         Intersection auxSplit;
         
         {
            Chute start = new Chute("aux.elts", true, null);
            
            Intersection split = Intersection.factory(Kind.SPLIT);
            constructor.addNode(split);
            
            constructor.addEdge(incoming, 2, split, 0, start);
            
            Intersection merge = Intersection.factory(Kind.MERGE);
            constructor.addNode(merge);
            
            Chute leftBranch = start.copy();
            
            constructor.addEdge(split, 0, merge, 0, leftBranch);
            
            auxSplit = Intersection.factory(Kind.SPLIT);
            constructor.addNode(auxSplit);
            
            Chute rightBranchStart = start.copy();
            
            constructor.addEdge(split, 1, auxSplit, 0, rightBranchStart);
            
            Chute rightBranchEnd = start.copy();
            
            constructor.addEdge(auxSplit, 1, merge, 1, rightBranchEnd);
            
            Chute end = start.copy();
            
            constructor.addEdge(merge, 0, outgoing, 5, end);
            
            l.makeLinked(new HashSet<Chute>(Arrays.asList(start, leftBranch, rightBranchStart, rightBranchEnd, end)));
         }
         
         // Construct start and end chutes
         {
            Intersection startStart = Intersection
                  .factory(Kind.START_BLACK_BALL);
            Intersection endStart = Intersection.factory(Kind.START_BLACK_BALL);
            constructor.addNode(startStart);
            constructor.addNode(endStart);
            
            Chute start = new Chute("start", true, null);
            Chute end = new Chute("end", true, null);
            
            constructor.addEdge(startStart, 0, outgoing, 3, start);
            constructor.addEdge(endStart, 0, outgoing, 4, end);
            
            fieldToChute.put("start", start);
            fieldToChute.put("end", end);
         }
         
         // Construct auxiliaryChutes (the field) base chutes
         {
            Intersection startLeft = Intersection.factory(Kind.START_WHITE_BALL);
            Intersection startRight = Intersection.factory(Kind.START_WHITE_BALL);
            constructor.addNode(startLeft);
            constructor.addNode(startRight);
            
            Intersection merge = Intersection.factory(Kind.MERGE);
            constructor.addNode(merge);
            
            Chute auxChutesLeft = new Chute("auxiliaryChutes", true, null);
            Chute auxChutesRight = auxChutesLeft.copy();
            
            Chute auxChutesEnd = auxChutesLeft.copy();
            
            constructor.addEdge(startLeft, 0, merge, 0, auxChutesLeft);
            constructor.addEdge(startRight, 0, merge, 1, auxChutesRight);
            constructor.addEdge(merge, 0, outgoing, 1, auxChutesEnd);
            
            l.makeLinked(new HashSet<Chute>(Arrays.asList(auxChutesLeft, auxChutesRight, auxChutesEnd)));
            fieldToChute.put("auxiliaryChutes", auxChutesEnd);
         }
         
         // Construct auxiliaryChutes (the field) aux chutes
         {
            Intersection startLeft = Intersection.factory(Kind.START_NO_BALL);
            constructor.addNode(startLeft);
            
            Intersection merge = Intersection.factory(Kind.MERGE);
            constructor.addNode(merge);
            
            Chute left = new Chute("auxiliaryChutes.elts", true, null);
            constructor.addEdge(startLeft, 0, merge, 0, left);
            Chute end = new Chute("auxiliaryChutes.elts", true, null);
            constructor.addEdge(merge, 0, outgoing, 2, end);
            Chute right = new Chute("auxiliaryChutes.elts", true, null);
            constructor.addEdge(auxSplit, 0, merge, 1, right);
            
            l.makeLinked(new HashSet<Chute>(Arrays.asList(left, right, end)));
            
            l.makeLinked(new HashSet<Chute>(Arrays.asList(right, auxSplit.getInputChute(0))));
            
            fieldToChute.put("auxiliaryChutes.elts", end);
         }
      }
      
      private void addGetName()
      {
         Board getName = new Board();
         
         l.addBoard("getName", getName);
         
         Intersection incoming = Intersection.factory(Kind.INCOMING);
         Intersection outgoing = Intersection.factory(Kind.OUTGOING);
         getName.addNode(incoming);
         getName.addNode(outgoing);
         
         // Add name chute:
         {
            Intersection split = Intersection.factory(Kind.SPLIT);
            getName.addNode(split);
            
            Chute start = new Chute("name", true, null);
            getName.addEdge(incoming, 0, split, 0, start);
            
            Chute ret = start.copy();
            Chute end = start.copy();
            
            getName.addEdge(split, 0, outgoing, 0, end);
            getName.addEdge(split, 1, outgoing, 5, ret);
            
            l.makeLinked(new HashSet<Chute>(Arrays.asList(
                  fieldToChute.get("name"), start, end, ret)));
         }
         
         // Add other chutes
         connectFields(
               getName,
               new LinkedHashSet<String>(Arrays.asList("auxiliaryChutes",
                     "auxiliaryChutes.elts", "start", "end")));
      }
      
      private void addSetStart()
      {
         Board setStart = new Board();
         
         l.addBoard("setStart", setStart);
         
         Intersection incoming = Intersection.factory(Kind.INCOMING);
         Intersection outgoing = Intersection.factory(Kind.OUTGOING);
         setStart.addNode(incoming);
         setStart.addNode(outgoing);
         
         // Add start chutes:
         {
            Intersection split = Intersection.factory(Kind.SPLIT);
            Intersection merge = Intersection.factory(Kind.MERGE);
            Intersection end = Intersection.factory(Kind.END);
            setStart.addNode(split);
            setStart.addNode(merge);
            setStart.addNode(end);
            
            Chute arg = new Chute(null, true, null);
            Chute argEnd = arg.copy();
            
            Chute inBetween = arg.copy();
            
            Chute firstStart = new Chute("start", true, null);
            Chute lastStart = firstStart.copy();
            
            setStart.addEdge(incoming, 3, merge, 0, firstStart);
            setStart.addEdge(merge, 0, outgoing, 3, lastStart);
            l.makeLinked(new HashSet<Chute>(Arrays.asList(firstStart,
                  lastStart, fieldToChute.get("start"))));
            
            setStart.addEdge(incoming, 5, split, 0, arg);
            setStart.addEdge(split, 0, merge, 1, inBetween);
            setStart.addEdge(split, 1, end, 0, argEnd);
            l.makeLinked(new HashSet<Chute>(Arrays.asList(arg, argEnd,
                  inBetween)));
         }
         
         // Add other chutes
         connectFields(
               setStart,
               new LinkedHashSet<String>(Arrays.asList("name",
                     "auxiliaryChutes", "auxiliaryChutes.elts", "end")));
      }
      
      private void addGetStart() {}
      
      private void addSetEnd() {}
      
      private void addGetEnd() {}
      
      private void addCopy() {}
      
      private void addGetAuxiliaryChutes() {}
      
      private void addTraverseAuxChutes() {}
      
      private void connectFields(Board b, Set<String> fieldNames)
      {
         Map<String, Integer> nameToPort = new HashMap<String, Integer>();
         nameToPort.put("name", 0);
         nameToPort.put("auxiliaryChutes", 1);
         nameToPort.put("auxiliaryChutes.elts", 2);
         nameToPort.put("start", 3);
         nameToPort.put("end", 4);
         
         for (String name : fieldNames)
            connectField(b, nameToPort.get(name), name);
      }
      
      private void connectField(Board b, int port, String name)
      {
         Chute newChute = fieldToChute.get(name).copy();
         
         b.addEdge(b.getIncomingNode(), port, b.getOutgoingNode(), port, newChute);
         
         l.makeLinked(new HashSet<Chute>(Arrays.asList(fieldToChute.get(name), newChute)));
      }
   }
}
