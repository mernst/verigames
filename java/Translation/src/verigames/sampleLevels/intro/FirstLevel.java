package verigames.sampleLevels.intro;

import verigames.level.Board;
import verigames.level.Chute;
import verigames.level.Intersection;
import verigames.level.Level;

import static verigames.level.Intersection.*;
import static verigames.level.Intersection.Kind.*;
import static verigames.utilities.BuildingTools.*;


public class FirstLevel
{
  public static Level makeLevel()
  {
    Level l = new Level();
    
    addBoard(l);
    
    return l;
  }
  
  private static void addBoard(Level parent)
  {
    Board b = initializeBoard(parent, "First.constructor");
    
    Intersection outgoing = b.getOutgoingNode();
    
    Intersection startLeft = factory(START_WHITE_BALL);
    Intersection startRight = factory(START_NO_BALL);
    b.addNode(startLeft);
    b.addNode(startRight);
    
    Intersection split = factory(SPLIT);
    Intersection merge = factory(MERGE);
    b.addNode(split);
    b.addNode(merge);
    
    Chute topLeft = new Chute();
    Chute bottomLeft = new Chute();
    Chute topRight = new Chute();
    Chute bottomRight = new Chute();
    
    topLeft.setNarrow(true);
    bottomLeft.setNarrow(true);
    topRight.setNarrow(false);
    bottomRight.setNarrow(false);
    
    bottomLeft.setPinched(true);
    bottomRight.setPinched(true);
    
    b.addEdge(startLeft, 0, split, 0, topLeft);
    b.addEdge(split, 0, outgoing, 0, bottomLeft);
    b.addEdge(split, 1, merge, 0, new Chute());
    b.addEdge(startRight, 0, merge, 1, topRight);
    b.addEdge(merge, 0, outgoing, 1, bottomRight);
    
    parent.makeLinked(topLeft, bottomLeft);
    parent.makeLinked(topRight, bottomRight);
  }
}
