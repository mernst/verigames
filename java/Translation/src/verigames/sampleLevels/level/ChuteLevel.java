package verigames.sampleLevels.level;

import java.util.LinkedHashMap;
import java.util.Map;

import verigames.level.Board;
import verigames.level.Chute;
import verigames.level.Intersection;
import verigames.level.Level;
import verigames.level.Intersection.Kind;
import verigames.utilities.BuildingTools;


@SuppressWarnings("deprecation")
public class ChuteLevel
{
  private static final Map<String, Integer> nameToPortMap;
  static
  {
    nameToPortMap = new LinkedHashMap<String, Integer>();
    nameToPortMap.put("name", 0);
    nameToPortMap.put("auxiliaryChutes", 1);
    nameToPortMap.put("auxiliaryChutes.elts", 2);
    nameToPortMap.put("start", 3);
    nameToPortMap.put("end", 4);
  }
  
  public static Level makeLevel()
  {
    Level l = new Level();
    Map<String, Chute> fieldToChute = new LinkedHashMap<String, Chute>();
    
    addConstructor(l, fieldToChute);
    addGetName(l, fieldToChute);
    addSetStart(l, fieldToChute);
    addGetStart(l, fieldToChute);
    addSetEnd(l, fieldToChute);
    addGetEnd(l, fieldToChute);
    addCopy(l, fieldToChute);
    addGetAuxiliaryChutes(l, fieldToChute);
    addTraverseAuxChutes(l, fieldToChute);
    
    return l;
  }
  
  private static void addConstructor(Level level, Map<String, Chute> fieldToChute)
  {
    Board constructor = new Board();
    
    level.addBoard("Chute.constructor", constructor);
    
    Intersection incoming = Intersection.factory(Kind.INCOMING);
    constructor.addNode(incoming);
    
    Intersection outgoing = Intersection.factory(Kind.OUTGOING);
    constructor.addNode(outgoing);
    
    // Construct name chutes:
    {
      Chute nameChute = new Chute();
      String name = "name";
      fieldToChute.put(name, nameChute);
      constructor.addEdge(incoming, 0, outgoing, 0, nameChute);
      constructor.addChuteName(nameChute, name);
    }
    
    // Construct aux (the argument) base chutes:
    {
      String name = "aux";
      Chute auxArg = new Chute();
      
      Intersection nullTest = Intersection.factory(Kind.NULL_TEST);
      constructor.addNode(nullTest);
      constructor.addEdge(incoming, 1, nullTest, 0, auxArg);
      constructor.addChuteName(auxArg, name);
      
      Chute auxNullBranch = new Chute();
      auxNullBranch.setNarrow(false);
      auxNullBranch.setEditable(false);
      
      Intersection merge = Intersection.factory(Kind.MERGE);
      constructor.addNode(merge);
      
      constructor.addEdge(nullTest, 1, merge, 1, auxNullBranch);
      constructor.addChuteName(auxNullBranch, name);
      
      Intersection end = Intersection.factory(Kind.END);
      constructor.addNode(end);
      
      Chute auxArg2 = new Chute();
      constructor.addEdge(merge, 0, end, 0, auxArg2);
      constructor.addChuteName(auxArg2, name);
      
      level.makeLinked(auxArg, auxArg2);
      
      Chute auxNotNullBranch = new Chute();
      auxNotNullBranch.setNarrow(true);
      auxNotNullBranch.setEditable(false);
      
      Intersection split = Intersection.factory(Kind.SPLIT);
      constructor.addNode(split);
      
      constructor.addEdge(nullTest, 0, split, 0, auxNotNullBranch);
      constructor.addChuteName(auxNotNullBranch, name);
      
      Intersection otherEnd = Intersection.factory(Kind.END);
      constructor.addNode(otherEnd);
      
      Chute auxNotNullBranch2 = auxNotNullBranch.copy();
      auxNotNullBranch2.setPinched(true);
      constructor.addEdge(split, 1, otherEnd, 0, auxNotNullBranch2);
      constructor.addChuteName(auxNotNullBranch2, name);
      
      Chute auxNotNullBranch3 = auxNotNullBranch.copy();
      constructor.addEdge(split, 0, merge, 0, auxNotNullBranch3);
      constructor.addChuteName(auxNotNullBranch3, name);
    }
    
    // Construct aux (the argument) auxiliary chutes:
    Intersection auxSplit;
    
    {
      String name = "aux.elts";
      Chute start = new Chute();
      
      Intersection split = Intersection.factory(Kind.SPLIT);
      constructor.addNode(split);
      
      constructor.addEdge(incoming, 2, split, 0, start);
      constructor.addChuteName(start, name);
      
      Intersection merge = Intersection.factory(Kind.MERGE);
      constructor.addNode(merge);
      
      Chute leftBranch = start.copy();
      
      constructor.addEdge(split, 0, merge, 0, leftBranch);
      constructor.addChuteName(leftBranch, name);
      
      auxSplit = Intersection.factory(Kind.SPLIT);
      constructor.addNode(auxSplit);
      
      Chute rightBranchStart = start.copy();
      
      constructor.addEdge(split, 1, auxSplit, 0, rightBranchStart);
      constructor.addChuteName(rightBranchStart, name);
      
      Chute rightBranchEnd = start.copy();
      
      constructor.addEdge(auxSplit, 1, merge, 1, rightBranchEnd);
      constructor.addChuteName(rightBranchEnd, name);
      
      Chute end = start.copy();
      
      constructor.addEdge(merge, 0, outgoing, 5, end);
      constructor.addChuteName(end, name);
      
      level.makeLinked(start, leftBranch, rightBranchStart, rightBranchEnd, end);
    }
    
    // Construct start and end chutes
    {
      Intersection startStart = Intersection
          .factory(Kind.START_BLACK_BALL);
      Intersection endStart = Intersection.factory(Kind.START_BLACK_BALL);
      constructor.addNode(startStart);
      constructor.addNode(endStart);
      
      Chute start = new Chute();
      Chute end = new Chute();
      
      constructor.addEdge(startStart, 0, outgoing, 3, start);
      constructor.addEdge(endStart, 0, outgoing, 4, end);
      constructor.addChuteName(start, "start");
      constructor.addChuteName(end, "end");
      
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
      
      Chute auxChutesLeft = new Chute();
      Chute auxChutesRight = auxChutesLeft.copy();
      
      Chute auxChutesEnd = auxChutesLeft.copy();
      String name = "auxiliaryChutes";
      
      constructor.addEdge(startLeft, 0, merge, 0, auxChutesLeft);
      constructor.addEdge(startRight, 0, merge, 1, auxChutesRight);
      constructor.addEdge(merge, 0, outgoing, 1, auxChutesEnd);
      
      constructor.addChuteName(auxChutesLeft, name);
      constructor.addChuteName(auxChutesRight, name);
      constructor.addChuteName(auxChutesEnd, name);
      
      level.makeLinked(auxChutesLeft, auxChutesRight, auxChutesEnd);
      fieldToChute.put(name, auxChutesEnd);
    }
    
    // Construct auxiliaryChutes (the field) aux chutes
    {
      Intersection startLeft = Intersection.factory(Kind.START_NO_BALL);
      constructor.addNode(startLeft);
      
      Intersection merge = Intersection.factory(Kind.MERGE);
      constructor.addNode(merge);
      
      String name = "auxiliaryChutes.elts";
      Chute left = new Chute();
      Chute end = new Chute();
      Chute right = new Chute();
      
      constructor.addEdge(startLeft, 0, merge, 0, left);
      constructor.addEdge(merge, 0, outgoing, 2, end);
      constructor.addEdge(auxSplit, 0, merge, 1, right);
      
      constructor.addChuteName(left, name);
      constructor.addChuteName(end, name);
      constructor.addChuteName(right, name);
      
      level.makeLinked(left, right, end);
      
      level.makeLinked(right, auxSplit.getInput(0));
      
      fieldToChute.put("auxiliaryChutes.elts", end);
    }
  }
  
  private static void addGetName(Level level, Map<String, Chute> fieldToChute)
  {
    Board getName = new Board();
    
    level.addBoard("Chute.getName", getName);
    
    Intersection incoming = Intersection.factory(Kind.INCOMING);
    Intersection outgoing = Intersection.factory(Kind.OUTGOING);
    getName.addNode(incoming);
    getName.addNode(outgoing);
    
    // Add name chute:
    {
      Intersection split = Intersection.factory(Kind.SPLIT);
      getName.addNode(split);
      
      Chute start = new Chute();
      String name = "name";
      
      getName.addEdge(incoming, 0, split, 0, start);
      getName.addChuteName(start, name);
      
      Chute ret = start.copy();
      Chute end = start.copy();
      
      getName.addEdge(split, 0, outgoing, 0, end);
      getName.addEdge(split, 1, outgoing, 5, ret);
      getName.addChuteName(end, name);
      getName.addChuteName(ret, name);
      
      level.makeLinked(fieldToChute.get(name), start, end, ret);
    }
    
    // Add other chutes
    BuildingTools.connectFields(getName, level, fieldToChute,
        nameToPortMap, "auxiliaryChutes", "auxiliaryChutes.elts", "start", "end");
  }
  
  private static void addSetStart(Level level, Map<String, Chute> fieldToChute)
  {
    Board setStart = new Board();
    
    level.addBoard("Chute.setStart", setStart);
    
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
      
      Chute arg = new Chute();
      Chute argEnd = arg.copy();
      
      Chute inBetween = arg.copy();
      
      Chute firstStart = new Chute();
      Chute lastStart = firstStart.copy();
      String name = "start";
      
      setStart.addEdge(incoming, 3, merge, 0, firstStart);
      setStart.addEdge(merge, 0, outgoing, 3, lastStart);
      setStart.addChuteName(firstStart, name);
      setStart.addChuteName(lastStart, name);
      level.makeLinked(firstStart, lastStart, fieldToChute.get(name));
      
      setStart.addEdge(incoming, 5, split, 0, arg);
      setStart.addEdge(split, 0, merge, 1, inBetween);
      setStart.addEdge(split, 1, end, 0, argEnd);
      level.makeLinked(arg, argEnd, inBetween);
    }
    
    // Add other chutes
    BuildingTools.connectFields(setStart, level, fieldToChute,
        nameToPortMap, "name", "auxiliaryChutes", "auxiliaryChutes.elts", "end");
  }
  
  private static void addGetStart(Level level, Map<String, Chute> fieldToChute)
  {
    Board getStart = new Board();
    level.addBoard("Chute.getStart", getStart);
    
    Intersection incoming = Intersection.factory(Kind.INCOMING);
    Intersection outgoing = Intersection.factory(Kind.OUTGOING);
    getStart.addNode(incoming);
    getStart.addNode(outgoing);
    
    // Add start chutes:
    {
      Intersection split = Intersection.factory(Kind.SPLIT);
      getStart.addNode(split);
      
      Chute start = new Chute();
      Chute end = start.copy();
      String name = "start";
      
      Chute ret = new Chute();
      
      getStart.addEdge(incoming, 3, split, 0, start);
      getStart.addEdge(split, 0, outgoing, 3, end);
      getStart.addChuteName(start, name);
      getStart.addChuteName(end, name);
      getStart.addEdge(split, 1, outgoing, 5, ret);
      level.makeLinked(start, end, ret, fieldToChute.get(name));
    }
    
    // Add other chutes:
    BuildingTools.connectFields(getStart, level, fieldToChute,
        nameToPortMap, "name", "auxiliaryChutes", "auxiliaryChutes.elts", "end");
    
  }
  
  private static void addSetEnd(Level level, Map<String, Chute> fieldToChute)
  {
    Board setEnd = new Board();
    level.addBoard("Chute.setEnd", setEnd);
    
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
      
      Chute arg = new Chute();
      Chute argEnd = arg.copy();
      
      Chute inBetween = arg.copy();
      
      Chute firstStart = new Chute();
      Chute lastStart = firstStart.copy();
      String name = "end";
      
      setEnd.addEdge(incoming, 4, merge, 0, firstStart);
      setEnd.addEdge(merge, 0, outgoing, 4, lastStart);
      setEnd.addChuteName(firstStart, name);
      setEnd.addChuteName(lastStart, name);
      level.makeLinked(firstStart, lastStart, fieldToChute.get(name));
      
      setEnd.addEdge(incoming, 5, split, 0, arg);
      setEnd.addEdge(split, 0, merge, 1, inBetween);
      setEnd.addEdge(split, 1, end, 0, argEnd);
      level.makeLinked(arg, argEnd, inBetween);
    }
    
    // Add other chutes:
    BuildingTools.connectFields(setEnd, level, fieldToChute,
        nameToPortMap, "name", "auxiliaryChutes", "auxiliaryChutes.elts", "start");
    
  }
  
  private static void addGetEnd(Level level, Map<String, Chute> fieldToChute)
  {
    Board getEnd = new Board();
    level.addBoard("Chute.getEnd", getEnd);
    
    Intersection incoming = Intersection.factory(Kind.INCOMING);
    Intersection outgoing = Intersection.factory(Kind.OUTGOING);
    getEnd.addNode(incoming);
    getEnd.addNode(outgoing);
    
    // Add End chutes:
    {
      Intersection split = Intersection.factory(Kind.SPLIT);
      getEnd.addNode(split);
      
      Chute start = new Chute();
      Chute end = start.copy();
      String name = "end";
      
      Chute ret = new Chute();
      
      getEnd.addEdge(incoming, 4, split, 0, start);
      getEnd.addEdge(split, 0, outgoing, 4, end);
      getEnd.addChuteName(start, name);
      getEnd.addChuteName(end, name);
      getEnd.addEdge(split, 1, outgoing, 5, ret);
      level.makeLinked(start, end, ret, fieldToChute.get(name));
    }
    
    // Add other chutes:
    BuildingTools.connectFields(getEnd, level, fieldToChute,
        nameToPortMap, "name", "auxiliaryChutes", "auxiliaryChutes.elts", "start");
  }
  
  private static void addCopy(Level level, Map<String, Chute> fieldToChute)
  {
    Board copy = new Board();
    level.addBoard("Chute.copy", copy);
    
    Intersection incoming = Intersection.factory(Kind.INCOMING);
    Intersection outgoing = Intersection.factory(Kind.OUTGOING);
    copy.addNode(incoming);
    copy.addNode(outgoing);
    
    Intersection copySub = Intersection.subnetworkFactory("Chute.copy");
    Intersection constructorSub = Intersection
        .subnetworkFactory("Chute.constructor");
    copy.addNode(copySub);
    copy.addNode(constructorSub);
    
    // Add name chutes:
    {
      Intersection split = Intersection.factory(Kind.SPLIT);
      copy.addNode(split);
      
      Chute top = new Chute();
      Chute middle = top.copy();
      Chute bottom = top.copy();
      String name = "name";
      
      copy.addEdge(incoming, 0, copySub, 0, top);
      copy.addEdge(copySub, 0, split, 0, middle);
      copy.addEdge(split, 0, outgoing, 0, bottom);
      copy.addChuteName(top, name);
      copy.addChuteName(middle, name);
      copy.addChuteName(bottom, name);
      
      Chute inBetween = new Chute();
      copy.addEdge(split, 1, constructorSub, 0, inBetween);
      
      level.makeLinked(top, middle, bottom, inBetween, fieldToChute.get(name));
    }
    
    // Add auxiliaryChutes base chutes:
    {
      Chute top = new Chute();
      Chute bottom = top.copy();
      String name = "auxiliaryChutes";
      
      copy.addEdge(incoming, 1, copySub, 1, top);
      copy.addEdge(copySub, 1, outgoing, 1, bottom);
      copy.addChuteName(top, name);
      copy.addChuteName(bottom, name);
      
      level.makeLinked(top, bottom, fieldToChute.get(name));
    }
    
    // Add auxiliaryChutes aux chutes:
    {
      Chute top = new Chute();
      Chute bottom = top.copy();
      String name = "auxiliaryChutes.elts";
      top.setPinched(true);
      
      copy.addEdge(incoming, 2, copySub, 2, top);
      copy.addEdge(copySub, 2, outgoing, 2, bottom);
      copy.addChuteName(top, name);
      copy.addChuteName(bottom, name);
      
      level.makeLinked(top, bottom, fieldToChute.get(name));
    }
    
    // Add start chutes:
    {
      Chute top = new Chute();
      Chute bottom = top.copy();
      String name = "start";
      
      copy.addEdge(incoming, 3, copySub, 3, top);
      copy.addEdge(copySub, 3, outgoing, 3, bottom);
      copy.addChuteName(top, name);
      copy.addChuteName(bottom, name);
      
      level.makeLinked(top, bottom, fieldToChute.get(name));
    }
    
    // Add end chutes:
    {
      Chute top = new Chute();
      Chute bottom = top.copy();
      String name = "start";
      
      copy.addEdge(incoming, 4, copySub, 4, top);
      copy.addEdge(copySub, 4, outgoing, 4, bottom);
      copy.addChuteName(top, name);
      copy.addChuteName(bottom, name);
      
      level.makeLinked(top, bottom, fieldToChute.get(name));
    }
    
    // Add copyAuxChutes base chute:
    {
      Intersection start = Intersection.factory(Kind.START_WHITE_BALL);
      copy.addNode(start);
      
      Chute copyAux = new Chute();
      String name = "copyAuxChutes";
      copy.addEdge(start, 0, constructorSub, 1, copyAux);
      copy.addChuteName(copyAux, name);
    }
    
    // Add copyAuxChutes aux chutes:
    {
      Intersection start = Intersection.factory(Kind.START_NO_BALL);
      copy.addNode(start);
      
      Intersection merge = Intersection.factory(Kind.MERGE);
      copy.addNode(merge);
      
      Chute top = new Chute();
      Chute bottom = top.copy();
      String name = "auxiliaryChutes";
      Chute inBetween = new Chute();
      
      copy.addEdge(start, 0, merge, 1, top);
      copy.addEdge(copySub, 5, merge, 0, inBetween);
      copy.addEdge(merge, 0, constructorSub, 2, bottom);
      copy.addChuteName(top, name);
      copy.addChuteName(bottom, name);
    }
    
    // Add return value:
    {
      Intersection start = Intersection.factory(Kind.START_WHITE_BALL);
      copy.addNode(start);
      
      Chute ret = new Chute();
      copy.addEdge(start, 0, outgoing, 5, ret);
    }
  }
  
  private static void addGetAuxiliaryChutes(Level level, Map<String, Chute> fieldToChute)
  {
    Board getAux = new Board();
    level.addBoard("Chute.getAuxiliaryChutes", getAux);
    
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
      
      Chute top = new Chute();
      Chute bottom = top.copy();
      String name = "auxiliaryChutes";
      
      getAux.addEdge(incoming, 1, split, 0, top);
      getAux.addEdge(split, 0, outgoing, 1, bottom);
      getAux.addChuteName(top, name);
      getAux.addChuteName(bottom, name);
      level.makeLinked(top, bottom, fieldToChute.get(name));
      
      Chute inBetween = new Chute();
      inBetween.setPinched(true);
      getAux.addEdge(split, 1, end, 0, inBetween);
    }
    
    // Connect auxiliaryChutes aux chutes and return value aux chute:
    {
      Intersection split = Intersection.factory(Kind.SPLIT);
      getAux.addNode(split);
      
      Chute top = new Chute();
      Chute bottom = top.copy();
      String name = "auxiliaryChutes.elts";
      
      getAux.addEdge(incoming, 2, split, 0, top);
      getAux.addEdge(split, 0, outgoing, 2, bottom);
      getAux.addChuteName(top, name);
      getAux.addChuteName(bottom, name);
      level.makeLinked(top, bottom, fieldToChute.get(name));
      
      Chute ret = new Chute();
      getAux.addEdge(split, 1, outgoing, 6, ret);
    }
    
    // Connect return value base chute
    {
      Intersection start = Intersection.factory(Kind.START_WHITE_BALL);
      getAux.addNode(start);
      
      Chute ret = new Chute();
      getAux.addEdge(start, 0, outgoing, 5, ret);
    }
    
    // Connect other Chutes:
    BuildingTools.connectFields(getAux, level, fieldToChute, nameToPortMap, "name", "start", "end");
  }
  
  private static void addTraverseAuxChutes(Level level, Map<String, Chute> fieldToChute)
  {
    Board travAux = new Board();
    level.addBoard("Chute.traverseAuxChutes", travAux);
    
    Intersection incoming = Intersection.factory(Kind.INCOMING);
    Intersection outgoing = Intersection.factory(Kind.OUTGOING);
    travAux.addNode(incoming);
    travAux.addNode(outgoing);
    
    Intersection auxChutesSub = Intersection.subnetworkFactory("Chute.getAuxiliaryChutes");
    Intersection travSub = Intersection.subnetworkFactory("Chute.traverseAuxChutes");
    travAux.addNode(auxChutesSub);
    travAux.addNode(travSub);
    
    // name chutes:
    {
      Chute top = new Chute();
      Chute middle = top.copy();
      Chute bottom = top.copy();
      String name = "name";
      
      travAux.addEdge(incoming, 0, auxChutesSub, 0, top);
      travAux.addEdge(auxChutesSub, 0, travSub, 0, middle);
      travAux.addEdge(travSub, 0, outgoing, 0, bottom);
      travAux.addChuteName(top, name);
      travAux.addChuteName(middle, name);
      travAux.addChuteName(bottom, name);
      level.makeLinked(top, middle, bottom, fieldToChute.get(name));
    }
    
    // auxiliaryChutes base chutes:
    {
      Chute top = new Chute();
      Chute middle = top.copy();
      Chute bottom = top.copy();
      String name = "auxiliaryChutes";
      
      travAux.addEdge(incoming, 1, auxChutesSub, 1, top);
      travAux.addEdge(auxChutesSub, 1, travSub, 1, middle);
      travAux.addEdge(travSub, 1, outgoing, 1, bottom);
      travAux.addChuteName(top, name);
      travAux.addChuteName(middle, name);
      travAux.addChuteName(bottom, name);
      level.makeLinked(top, middle, bottom, fieldToChute.get(name));
    }
    
    // auxiliaryChutes aux chutes:
    {
      Chute top = new Chute();
      Chute middle = top.copy();
      Chute bottom = top.copy();
      String name = "auxiliaryChutes.elts";
      
      travAux.addEdge(incoming, 2, auxChutesSub, 2, top);
      travAux.addEdge(auxChutesSub, 2, travSub, 2, middle);
      travAux.addEdge(travSub, 2, outgoing, 2, bottom);
      travAux.addChuteName(top, name);
      travAux.addChuteName(middle, name);
      travAux.addChuteName(bottom, name);
      level.makeLinked(top, middle, bottom, fieldToChute.get(name));
    }
    
    // start chutes:
    {
      Chute top = new Chute();
      Chute middle = top.copy();
      Chute bottom = top.copy();
      String name = "start";
      
      travAux.addEdge(incoming, 3, auxChutesSub, 3, top);
      travAux.addEdge(auxChutesSub, 3, travSub, 3, middle);
      travAux.addEdge(travSub, 3, outgoing, 3, bottom);
      travAux.addChuteName(top, name);
      travAux.addChuteName(middle, name);
      travAux.addChuteName(bottom, name);
      level.makeLinked(top, middle, bottom, fieldToChute.get(name));
    }
    
    // end chutes:
    {
      Chute top = new Chute();
      Chute middle = top.copy();
      Chute bottom = top.copy();
      String name = "end";
      
      travAux.addEdge(incoming, 4, auxChutesSub, 4, top);
      travAux.addEdge(auxChutesSub, 4, travSub, 4, middle);
      travAux.addEdge(travSub, 4, outgoing, 4, bottom);
      travAux.addChuteName(top, name);
      travAux.addChuteName(middle, name);
      travAux.addChuteName(bottom, name);
      level.makeLinked(top, middle, bottom, fieldToChute.get(name));
    }
    
    // allAuxChuteTraversals base chute:
    {
      Intersection start = Intersection.factory(Kind.START_WHITE_BALL);
      Intersection end = Intersection.factory(Kind.END);
      travAux.addNode(start);
      travAux.addNode(end);
      
      Chute chute = new Chute();
      String name = "allAuxChuteTraversals";
      travAux.addEdge(start, 0, end, 0, chute);
      travAux.addChuteName(chute, name);
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
      
      Chute top = new Chute();
      Chute second = top.copy();
      Chute third = top.copy();
      Chute bottom = top.copy();
      String name = "allAuxChuteTraversals.elts";
      
      travAux.addEdge(start, 0, getAuxMerge, 1, top);
      travAux.addEdge(getAuxMerge, 0, traverseAuxMerge, 1, second);
      travAux.addEdge(traverseAuxMerge, 0, split, 0, third);
      travAux.addEdge(split, 0, end, 0, bottom);
      
      travAux.addChuteName(top, name);
      travAux.addChuteName(second, name);
      travAux.addChuteName(third, name);
      travAux.addChuteName(bottom, name);
      
      Chute ret = new Chute();
      
      travAux.addEdge(split, 1, outgoing, 6, ret);
      
      level.makeLinked(top, second, third, bottom);
    }
    
    // getAuxiliaryChutes return value base chute:
    {
      Intersection end = Intersection.factory(Kind.END);
      travAux.addNode(end);
      
      Chute chute = new Chute();
      travAux.addEdge(auxChutesSub, 5, end, 0, chute);
    }
    
    // traverseAuxChutes return value base chute:
    {
      Intersection end = Intersection.factory(Kind.END);
      travAux.addNode(end);
      
      Chute chute = new Chute();
      chute.setPinched(true);
      travAux.addEdge(travSub, 5, end, 0, chute);
    }
    
    // return value base chute:
    {
      Intersection start = Intersection.factory(Kind.START_WHITE_BALL);
      travAux.addNode(start);
      
      Chute ret = new Chute();
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
      
      Chute retAux1 = new Chute();
      Chute retAux2 = retAux1.copy();
      travAux.addEdge(auxChutesSub, 6, split1, 0, retAux1);
      travAux.addEdge(split1, 0, end1, 0, retAux2);
      level.makeLinked(retAux1, retAux2);
      
      Chute aux1 = new Chute();
      Chute aux2 = aux1.copy();
      aux2.setPinched(true);
      String name = "aux";
      
      travAux.addEdge(split1, 1, split2, 0, aux1);
      travAux.addEdge(split2, 0, end2, 0, aux2);
      
      travAux.addChuteName(aux1, name);
      travAux.addChuteName(aux2, name);
      level.makeLinked(aux1, aux2);
      
      Chute inBetween = new Chute();
      travAux.addEdge(split2, 1, getAuxMerge, 0, inBetween);
    }
    
    // traverseAuxChutes return value aux chutes:
    {
      Intersection split = Intersection.factory(Kind.SPLIT);
      Intersection end = Intersection.factory(Kind.END);
      travAux.addNode(split);
      travAux.addNode(end);
      
      Chute ret1 = new Chute();
      Chute ret2 = ret1.copy();
      travAux.addEdge(travSub, 6, split, 0, ret1);
      travAux.addEdge(split, 0, end, 0, ret2);
      level.makeLinked(ret1, ret2);
      
      Chute inBetween = new Chute();
      travAux.addEdge(split, 1, traverseAuxMerge, 0, inBetween);
    }
  }
}
