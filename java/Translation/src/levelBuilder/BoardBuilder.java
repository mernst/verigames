package levelBuilder;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;

import level.Board;
import level.Chute;
import level.Intersection;
import level.Intersection.Kind;

/**
 * 
 * A mutable class used for building a board from source code. Used to bridge
 * the gap between the Board structure and the information required by the
 * translation algorithm.
 * 
 * Implements eternal equality.
 * 
 * @specfield board: Board // The board that this BoardBuilder is building
 * 
 * @specfield levelBuilder: LevelBuilder // The LevelBuilder that represents the
 * Level that "board" belongs in -- stores information global to the level that
 * is needed for construction, but not gameplay
 * 
 * @specfield varToCurrentEdge: Map<String, Chute> // For a given variable name,
 * maps to a prototypical base Chute for its type. The chute objects contained
 * in this Map will not be part of the Board. They are simply used to keep track
 * of type information for variables.
 * 
 * "return" is always a key in this Map. Other variables can merge into it,
 * indicating that they can be the return value for this method.
 * 
 * @specfield active: boolean // indicates whether this BoardBuilder is
 * currently constructing a Board. If false, no changes are allowed to the
 * contained Board. Active is set to false as soon as the contained Board is
 * returned. This is for the following reasons:
 * 
 * It only makes sense for a client to want the Board once it is complete, so
 * this does no harm.
 * 
 * Once a reference to the Board is returned, it could be modified externally.
 * That means that this class can no longer provide any guarantees about its
 * contents, so it is safer to just stop construction.
 * 
 * @author Nathaniel Mote
 */

/*
 * Notes:
 * 
 * - This class is currently a prototype. The interface may change at any time.
 */

public class BoardBuilder
{
   private final Board board;
   
   private final LevelBuilder levelBuilder;
   
   private Map<String, Chute> varToCurrentEdge;
   
   /*
    * Maps a Chute object to the Intersection and port number that it will
    * attach to.
    */
   private Map<Chute, Intersection> chuteToFurthestNode;
   private Map<Chute, Integer> chuteToNodePort;
   
   private boolean active;
   
   /*
    * Representation Invariant:
    * 
    * -
    */
   
   /**
    *  creates a new BoardBuilder with the given LevelBuilder as
    * levelBuilder and the given Board as board
    */
   protected BoardBuilder(LevelBuilder lb)
   {
      active = true;
      
      levelBuilder = lb;
      board = new Board();
      Intersection incoming = new Intersection(Kind.INCOMING);
      board.addNode(incoming);
      
      // TODO finish constructor
      
      varToCurrentEdge = new HashMap<String, Chute>();
   }
   
   /**
    * Requires active; the named variable is not already present in this
    * BoardBuilder; startType must be able to have 0 input ports and 1 output
    * port
    *  adds the named variable to this BoardBuilder. More specifically,
    * creates a node of the given type
    */
   public void addVar(Chute var, Intersection.Kind startType)
   {
      throw new RuntimeException("Not yet implemented");
   }
   
   /**
    * Requires active; the named variable is present in this BoardBuilder
    *  adds a pinch point on the furthest chute associated with var
    */
   // TODO change String to whatever we end up using
   public void addPinchToVar(String var)
   {
      throw new RuntimeException("Not yet implemented");
   }
   
   /**
    * Requires active; bb's input and output ports all correspond to variables
    * in this board
    * @modifies this
    *  adds the given sub-boards to this. For each of the chutes, there
    * is a simple SPLIT at the top and a MERGE at the bottom.
    */
   public void addSubBoards(Set<BoardBuilder> bb)
   {
      throw new RuntimeException("Not yet implemented");
   }
   
   /**
    * Requires active; name is, or will be, a valid board name in levelBuilder;
    * all args and ret are valid variables in this.
    * @modifies this
    *  adds the given subnetwork, with the given args and return value,
    * to the board that this is building
    */
   public void addSubnetwork(String name, List<String> args, String ret)
   {
      throw new RuntimeException("Not yet implemented");
   }
   
   /**
    * Requires given variables are both present
    * @modifies this
    *  represents an assignment from "from" to "to." Specifically, puts
    * a split in the from chute and an end on the to chute, then merging one of
    * the branches of from with to.
    */
   public void assignment(String to, String from)
   {
      throw new RuntimeException("Not yet implemented");
   }
   
   /**
    * Requires given variable is present
    * @modifies this
    *  makes the chutes for the given variable flow into the return
    * output chute
    */
   // TODO determine what to do if client tries to modify this variable after
   public void returnVar(String var)
   {
      throw new RuntimeException("Not yet implemented");
   }
   
   /**
    * Requires active
    * @modifies this
    *  sets active to false
    * Returns the board that this BoardBuilder is building
    */
   protected Board getBoard()
   {
      throw new RuntimeException("Not yet implemented");
   }
   
   /**
    * Returns levelBuilder
    */
   public LevelBuilder getLevelBuilder()
   {
      throw new RuntimeException("Not yet implemented");
   }
   
   /**
    * Returns active
    */
   public boolean isActive()
   {
      return active;
   }
}
