package verigames.sampleLevels.level;

import static verigames.level.Intersection.*;
import static verigames.level.Intersection.Kind.*;
import static verigames.utilities.BuildingTools.*;
import verigames.level.Board;
import verigames.level.Chute;
import verigames.level.Intersection;
import verigames.level.Level;



public class NullTestLevel
{
  public static Level makeLevel()
  {
    Level l = new Level();
    
    addGet(l, true);
    addGet(l, false);
    
    addSet(l, true);
    addSet(l, false);
    
    return l;
  }
  
  /**
   * Adds the board for getNullChute if nullChute is true, otherwise adds the
   * board for getNonNullChute. This is done because they are basically
   * identical.
   * 
   * @param nullChute
   */
  private static void addGet(Level level, boolean nullChute)
  {
    Board getChute = initializeBoard(level, nullChute ? "NullTest.getNullChute"
        : "NullTest.getNonNullChute");
    
    Intersection outgoing = getChute.getOutgoingNode();
    
    Intersection getOut = subnetworkFactory("Intersection.getOutputChute");
    getChute.addNode(getOut);
    getChute.addEdge(getOut, 0, outgoing, 0, new Chute());
  }
  
  /**
   * Adds the board for setNullChute if nullChute is true, otherwise adds the
   * bard for setNonNullChute. This is done because they are basically
   * identical.
   * 
   * @param nullChute
   */
  private static void addSet(Level level, boolean nullChute)
  {
    Board setChute = initializeBoard(level, nullChute ? "NullTest.setNullChute"
        : "NullTest.setNonNullChute");
    
    Intersection incoming = setChute.getIncomingNode();
    
    Intersection setOut = subnetworkFactory("Intersection.setOutputChute");
    Intersection split = factory(SPLIT);
    Intersection end = factory(END);
    setChute.addNode(setOut);
    setChute.addNode(split);
    setChute.addNode(end);
    
    Chute top = new Chute();
    Chute bottom = top.copy();
    String name = "chute";
    
    setChute.addEdge(incoming, 0, split, 0, top);
    setChute.addEdge(split, 1, end, 0, bottom);
    setChute.addChuteName(top, name);
    setChute.addChuteName(bottom, name);
    level.makeLinked(top, bottom);
    
    setChute.addEdge(split, 0, setOut, 0, new Chute());
  }
}
