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
         connectFields(getName, "auxiliaryChutes", "auxiliaryChutes.elts",
               "start", "end");
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
         connectFields(setStart, "name", "auxiliaryChutes",
               "auxiliaryChutes.elts", "end");
      }
      
      private void addGetStart()
      {
         Board getStart = new Board();
         l.addBoard("getStart", getStart);
         
         Intersection incoming = Intersection.factory(Kind.INCOMING);
         Intersection outgoing = Intersection.factory(Kind.OUTGOING);
         getStart.addNode(incoming);
         getStart.addNode(outgoing);
         
         // Add start chutes:
         {
            Intersection split = Intersection.factory(Kind.SPLIT);
            getStart.addNode(split);
            
            Chute start = new Chute("start", true, null);
            Chute end = start.copy();
            Chute ret = new Chute(null, true, null);
            
            getStart.addEdge(incoming, 3, split, 0, start);
            getStart.addEdge(split, 0, outgoing, 3, end);
            getStart.addEdge(split, 1, outgoing, 5, ret);
            l.makeLinked(new HashSet<Chute>(Arrays.asList(start, end, ret,
                  fieldToChute.get("start"))));
         }
         
         // Add other chutes:
         connectFields(getStart, "name", "auxiliaryChutes",
               "auxiliaryChutes.elts", "end");
         
      }
      
      private void addSetEnd()
      {
         Board setEnd = new Board();
         l.addBoard("setEnd", setEnd);
         
         Intersection incoming = Intersection.factory(Kind.INCOMING);
         Intersection outgoing = Intersection.factory(Kind.OUTGOING);
         setEnd.addNode(incoming);
         setEnd.addNode(outgoing);
         
         // Add end chutes:
         {
            Intersection split = Intersection.factory(Kind.SPLIT);
            Intersection merge = Intersection.factory(Kind.MERGE);
            Intersection end = Intersection.factory(Kind.END);
            setEnd.addNode(split);
            setEnd.addNode(merge);
            setEnd.addNode(end);
            
            Chute arg = new Chute(null, true, null);
            Chute argEnd = arg.copy();
            
            Chute inBetween = arg.copy();
            
            Chute firstStart = new Chute("end", true, null);
            Chute lastStart = firstStart.copy();
            
            setEnd.addEdge(incoming, 4, merge, 0, firstStart);
            setEnd.addEdge(merge, 0, outgoing, 4, lastStart);
            l.makeLinked(new HashSet<Chute>(Arrays.asList(firstStart,
                  lastStart, fieldToChute.get("end"))));
            
            setEnd.addEdge(incoming, 5, split, 0, arg);
            setEnd.addEdge(split, 0, merge, 1, inBetween);
            setEnd.addEdge(split, 1, end, 0, argEnd);
            l.makeLinked(new HashSet<Chute>(Arrays.asList(arg, argEnd,
                  inBetween)));
         }
         
         // Add other chutes:
         connectFields(setEnd, "name", "auxiliaryChutes",
               "auxiliaryChutes.elts", "start");
         
      }
      
      private void addGetEnd()
      {
         Board getEnd = new Board();
         l.addBoard("getEnd", getEnd);
         
         Intersection incoming = Intersection.factory(Kind.INCOMING);
         Intersection outgoing = Intersection.factory(Kind.OUTGOING);
         getEnd.addNode(incoming);
         getEnd.addNode(outgoing);
         
         // Add End chutes:
         {
            Intersection split = Intersection.factory(Kind.SPLIT);
            getEnd.addNode(split);
            
            Chute start = new Chute("end", true, null);
            Chute end = start.copy();
            Chute ret = new Chute(null, true, null);
            
            getEnd.addEdge(incoming, 4, split, 0, start);
            getEnd.addEdge(split, 0, outgoing, 4, end);
            getEnd.addEdge(split, 1, outgoing, 5, ret);
            l.makeLinked(new HashSet<Chute>(Arrays.asList(start, end, ret,
                  fieldToChute.get("end"))));
         }
         
         // Add other chutes:
         connectFields(getEnd, "name", "auxiliaryChutes",
               "auxiliaryChutes.elts", "start");
      }
      
      private void addCopy()
      {
         Board copy = new Board();
         l.addBoard("copy", copy);
         
         Intersection incoming = Intersection.factory(Kind.INCOMING);
         Intersection outgoing = Intersection.factory(Kind.OUTGOING);
         copy.addNode(incoming);
         copy.addNode(outgoing);
         
         Intersection copySub = Intersection.subnetworkFactory("copy");
         Intersection constructorSub = Intersection
               .subnetworkFactory("constructor");
         copy.addNode(copySub);
         copy.addNode(constructorSub);
         
         // Add name chutes:
         {
            Intersection split = Intersection.factory(Kind.SPLIT);
            copy.addNode(split);
            
            Chute top = new Chute("name", true, null);
            Chute middle = top.copy();
            Chute bottom = top.copy();
            
            copy.addEdge(incoming, 0, copySub, 0, top);
            copy.addEdge(copySub, 0, split, 0, middle);
            copy.addEdge(split, 0, outgoing, 0, bottom);
            
            Chute inBetween = new Chute(null, true, null);
            copy.addEdge(split, 1, constructorSub, 0, inBetween);
            
            l.makeLinked(new HashSet<Chute>(Arrays.asList(top, middle, bottom,
                  inBetween, fieldToChute.get("name"))));
         }
         
         // Add auxiliaryChutes base chutes:
         {
            Chute top = new Chute("auxiliaryChutes", true, null);
            Chute bottom = top.copy();
            
            copy.addEdge(incoming, 1, copySub, 1, top);
            copy.addEdge(copySub, 1, outgoing, 1, bottom);
            
            l.makeLinked(new HashSet<Chute>(Arrays.asList(top, bottom,
                  fieldToChute.get("auxiliaryChutes"))));
         }
         
         // Add auxiliaryChutes aux chutes:
         {
            Chute top = new Chute("auxiliaryChutes.elts", true, null);
            Chute bottom = top.copy();
            top.setPinched(true);
            
            copy.addEdge(incoming, 2, copySub, 2, top);
            copy.addEdge(copySub, 2, outgoing, 2, bottom);
            
            l.makeLinked(new HashSet<Chute>(Arrays.asList(top, bottom,
                  fieldToChute.get("auxiliaryChutes.elts"))));
         }
         
         // Add start chutes:
         {
            Chute top = new Chute("start", true, null);
            Chute bottom = top.copy();
            
            copy.addEdge(incoming, 3, copySub, 3, top);
            copy.addEdge(copySub, 3, outgoing, 3, bottom);
            
            l.makeLinked(new HashSet<Chute>(Arrays.asList(top, bottom,
                  fieldToChute.get("start"))));
         }
         
         // Add end chutes:
         {
            Chute top = new Chute("start", true, null);
            Chute bottom = top.copy();
            
            copy.addEdge(incoming, 4, copySub, 4, top);
            copy.addEdge(copySub, 4, outgoing, 4, bottom);
            
            l.makeLinked(top, bottom, fieldToChute.get("start"));
         }
         
         // Add copyAuxChutes base chute:
         {
            Intersection start = Intersection.factory(Kind.START_WHITE_BALL);
            copy.addNode(start);
            
            Chute copyAux = new Chute("copyAuxChutes", true, null);
            copy.addEdge(start, 0, constructorSub, 1, copyAux);
         }
         
         // Add copyAuxChutes aux chutes:
         {
            Intersection start = Intersection.factory(Kind.START_NO_BALL);
            copy.addNode(start);
            
            Intersection merge = Intersection.factory(Kind.MERGE);
            copy.addNode(merge);
            
            Chute top = new Chute("auxiliaryChutes", true, null);
            Chute bottom = top.copy();
            Chute inBetween = new Chute(null, true, null);
            
            copy.addEdge(start, 0, merge, 1, top);
            copy.addEdge(copySub, 5, merge, 0, inBetween);
            copy.addEdge(merge, 0, constructorSub, 2, bottom);
         }
         
         // Add return value:
         {
            Intersection start = Intersection.factory(Kind.START_WHITE_BALL);
            copy.addNode(start);
            
            Chute ret = new Chute(null, true, null);
            copy.addEdge(start, 0, outgoing, 5, ret);
         }
      }
      
      private void addGetAuxiliaryChutes()
      {
         Board getAux = new Board();
         l.addBoard("getAuxiliaryChutes", getAux);
         
         Intersection incoming = Intersection.factory(Kind.INCOMING);
         Intersection outgoing = Intersection.factory(Kind.OUTGOING);
         getAux.addNode(incoming);
         getAux.addNode(outgoing);
         
         // Connect auxiliaryChutes base chutes:
         {
            Intersection split = Intersection.factory(Kind.SPLIT);
            Intersection end = Intersection.factory(Kind.END);
            getAux.addNode(split);
            getAux.addNode(end);
            
            Chute top = new Chute("auxiliaryChutes", true, null);
            Chute bottom = top.copy();
            getAux.addEdge(incoming, 1, split, 0, top);
            getAux.addEdge(split, 0, outgoing, 1, bottom);
            l.makeLinked(top, bottom, fieldToChute.get("auxiliaryChutes"));
            
            Chute inBetween = new Chute(null, true, null);
            inBetween.setPinched(true);
            getAux.addEdge(split, 1, end, 0, inBetween);
         }
         
         // Connect auxiliaryChutes aux chutes and return value aux chute:
         {
            Intersection split = Intersection.factory(Kind.SPLIT);
            getAux.addNode(split);
            
            Chute top = new Chute("auxiliaryChutes.elts", true, null);
            Chute bottom = top.copy();
            
            getAux.addEdge(incoming, 2, split, 0, top);
            getAux.addEdge(split, 0, outgoing, 2, bottom);
            l.makeLinked(top, bottom, fieldToChute.get("auxiliaryChutes.elts"));
            
            Chute ret = new Chute(null, true, null);
            getAux.addEdge(split, 1, outgoing, 6, ret);
         }
         
         // Connect return value base chute
         {
            Intersection start = Intersection.factory(Kind.START_WHITE_BALL);
            getAux.addNode(start);
            
            Chute ret = new Chute(null, true, null);
            getAux.addEdge(start, 0, outgoing, 5, ret);
         }
         
         // Connect other Chutes:
         connectFields(getAux, "name", "start", "end");
      }
      
      private void addTraverseAuxChutes()
      {
         Board travAux = new Board();
         l.addBoard("traverseAuxChutes", travAux);
         
         Intersection incoming = Intersection.factory(Kind.INCOMING);
         Intersection outgoing = Intersection.factory(Kind.OUTGOING);
         travAux.addNode(incoming);
         travAux.addNode(outgoing);
         
         Intersection auxChutesSub = Intersection.subnetworkFactory("getAuxiliaryChutes");
         Intersection travSub = Intersection.subnetworkFactory("traverseAuxChutes");
         travAux.addNode(auxChutesSub);
         travAux.addNode(travSub);
         
         // name chutes:
         {
            Chute top = new Chute("name", true, null);
            Chute middle = top.copy();
            Chute bottom = top.copy();
            
            travAux.addEdge(incoming, 0, auxChutesSub, 0, top);
            travAux.addEdge(auxChutesSub, 0, travSub, 0, middle);
            travAux.addEdge(travSub, 0, outgoing, 0, bottom);
            l.makeLinked(top, middle, bottom, fieldToChute.get("name"));
         }
         
         // auxiliaryChutes base chutes:
         {
            Chute top = new Chute("auxiliaryChutes", true, null);
            Chute middle = top.copy();
            Chute bottom = top.copy();
            
            travAux.addEdge(incoming, 1, auxChutesSub, 1, top);
            travAux.addEdge(auxChutesSub, 1, travSub, 1, middle);
            travAux.addEdge(travSub, 1, outgoing, 1, bottom);
            l.makeLinked(top, middle, bottom, fieldToChute.get("auxiliaryChutes"));
         }
         
         // auxiliaryChutes aux chutes:
         {
            Chute top = new Chute("auxiliaryChutes.elts", true, null);
            Chute middle = top.copy();
            Chute bottom = top.copy();
            
            travAux.addEdge(incoming, 2, auxChutesSub, 2, top);
            travAux.addEdge(auxChutesSub, 2, travSub, 2, middle);
            travAux.addEdge(travSub, 2, outgoing, 2, bottom);
            l.makeLinked(top, middle, bottom, fieldToChute.get("auxiliaryChutes.elts"));
         }
         
         // start chutes:
         {
            Chute top = new Chute("start", true, null);
            Chute middle = top.copy();
            Chute bottom = top.copy();
            
            travAux.addEdge(incoming, 3, auxChutesSub, 3, top);
            travAux.addEdge(auxChutesSub, 3, travSub, 3, middle);
            travAux.addEdge(travSub, 3, outgoing, 3, bottom);
            l.makeLinked(top, middle, bottom, fieldToChute.get("start"));
         }
         
         // end chutes:
         {
            Chute top = new Chute("end", true, null);
            Chute middle = top.copy();
            Chute bottom = top.copy();
            
            travAux.addEdge(incoming, 4, auxChutesSub, 4, top);
            travAux.addEdge(auxChutesSub, 4, travSub, 4, middle);
            travAux.addEdge(travSub, 4, outgoing, 4, bottom);
            l.makeLinked(top, middle, bottom, fieldToChute.get("end"));
         }
         
         // allAuxChuteTraversals base chute:
         {
            Intersection start = Intersection.factory(Kind.START_WHITE_BALL);
            Intersection end = Intersection.factory(Kind.END);
            travAux.addNode(start);
            travAux.addNode(end);
            
            Chute chute = new Chute("allAuxChuteTraversals", true, null);
            travAux.addEdge(start, 0, end, 0, chute);
         }
         
         // allAuxChuteTraversals aux chutes:
         Intersection getAuxMerge = Intersection.factory(Kind.MERGE);
         Intersection traverseAuxMerge = Intersection.factory(Kind.MERGE);
         travAux.addNode(getAuxMerge);
         travAux.addNode(traverseAuxMerge);
         {
            Intersection start = Intersection.factory(Kind.START_NO_BALL);
            Intersection end = Intersection.factory(Kind.END);
            Intersection split = Intersection.factory(Kind.SPLIT);
            travAux.addNode(start);
            travAux.addNode(end);
            travAux.addNode(split);
            
            Chute top = new Chute("allAuxChuteTraversals.elts", true, null);
            Chute second = top.copy();
            Chute third = top.copy();
            Chute bottom = top.copy();
            
            travAux.addEdge(start, 0, getAuxMerge, 1, top);
            travAux.addEdge(getAuxMerge, 0, traverseAuxMerge, 1, second);
            travAux.addEdge(traverseAuxMerge, 0, split, 0, third);
            travAux.addEdge(split, 0, end, 0, bottom);

            Chute ret = new Chute(null, true, null);
            
            travAux.addEdge(split, 1, outgoing, 6, ret);
            
            l.makeLinked(top, second, third, bottom);
         }
         
         // getAuxiliaryChutes return value base chute:
         {
            Intersection end = Intersection.factory(Kind.END);
            travAux.addNode(end);
            
            Chute chute = new Chute(null, true, null);
            travAux.addEdge(auxChutesSub, 5, end, 0, chute);
         }
         
         // traverseAuxChutes return value base chute:
         {
            Intersection end = Intersection.factory(Kind.END);
            travAux.addNode(end);
            
            Chute chute = new Chute(null, true, null);
            chute.setPinched(true);
            travAux.addEdge(travSub, 5, end, 0, chute);
         }
         
         // return value base chute:
         {
            Intersection start = Intersection.factory(Kind.START_WHITE_BALL);
            travAux.addNode(start);
            
            Chute ret = new Chute(null, true, null);
            travAux.addEdge(start, 0, outgoing, 5, ret);
         }
         
         // getAuxiliaryChutes return value aux chutes:
         {
            Intersection split1 = Intersection.factory(Kind.SPLIT);
            Intersection split2 = Intersection.factory(Kind.SPLIT);
            Intersection end1 = Intersection.factory(Kind.END);
            Intersection end2 = Intersection.factory(Kind.END);
            travAux.addNode(split1);
            travAux.addNode(split2);
            travAux.addNode(end1);
            travAux.addNode(end2);
            
            Chute retAux1 = new Chute(null, true, null);
            Chute retAux2 = retAux1.copy();
            travAux.addEdge(auxChutesSub, 6, split1, 0, retAux1);
            travAux.addEdge(split1, 0, end1, 0, retAux2);
            l.makeLinked(retAux1, retAux2);
            
            Chute aux1 = new Chute("aux", true, null);
            Chute aux2 = aux1.copy();
            aux2.setPinched(true);
            travAux.addEdge(split1, 1, split2, 0, aux1);
            travAux.addEdge(split2, 0, end2, 0, aux2);
            l.makeLinked(aux1, aux2);
            
            Chute inBetween = new Chute(null, true, null);
            travAux.addEdge(split2, 1, getAuxMerge, 0, inBetween);
         }
         
         // traverseAuxChutes return value aux chutes:
         {
            Intersection split = Intersection.factory(Kind.SPLIT);
            Intersection end = Intersection.factory(Kind.END);
            travAux.addNode(split);
            travAux.addNode(end);
            
            Chute ret1 = new Chute(null, true, null);
            Chute ret2 = ret1.copy();
            travAux.addEdge(travSub, 6, split, 0, ret1);
            travAux.addEdge(split, 0, end, 0, ret2);
            l.makeLinked(ret1, ret2);
            
            Chute inBetween = new Chute(null, true, null);
            travAux.addEdge(split, 1, traverseAuxMerge, 0, inBetween);
         }
      }
      
      private void connectFields(Board b, String... fieldNames)
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
