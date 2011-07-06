package levelBuilder;

import java.util.List;
import java.util.Set;

import level.Board;
import level.Chute;
import level.Intersection;

/**
 * @author Nathaniel Mote
 * 
 * A mutable class used for building a board from source code. Used to bridge
 * the gap between the Board structure and the information required by the
 * translation algorithm
 * 
 * @specfield board: Board // The board that this BoardBuilder is building
 * 
 * @specfield levelBuilder: LevelBuilder // The LevelBuilder that represents the
 * Level that "board" belongs in -- stores information global to the level that
 * is needed for construction, but not gameplay
 * 
 * @specfield varToFurthestEdge: Map<String, Chute> // For a given variable
 * name, return the base chute. its auxiliary chutes can be accessed through the
 * base chute
 * 
 * @specfield variables: Map<String, Chute> // For a given local variable name,
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
 */

/*
 * Notes:
 * 
 * - This class is currently a prototype. The interface may change at any time.
 */

// TODO add some set of variables, similar to the fields specfield in
// LevelBuilder

public class BoardBuilder
{
   
   /**
    * @effects creates a new BoardBuilder with the given LevelBuilder in the
    * levelBuilder specfield
    */
   // TODO does this need to be public? I think all creation could be taken care
   // of by the factory method in LevelBuilder
   public BoardBuilder(LevelBuilder lb)
   {
      throw new RuntimeException("Not yet implemented");
   }
   
   /**
    * @requires active; the named variable is not already present in this
    * BoardBuilder; startType must be able to have 0 input ports and 1 output
    * port
    * @effects adds the named variable to this BoardBuilder. More specifically,
    * creates a node of the given type
    */
   public void addVar(Chute var, Intersection.Kind startType)
   {
      throw new RuntimeException("Not yet implemented");
   }
   
   /**
    * @requires active; the named variable is present in this BoardBuilder
    * @effects
    */
   // TODO change String to whatever we end up using
   public void addPinchToVar(String var)
   {
      throw new RuntimeException("Not yet implemented");
   }
   
   /**
    * @requires active; bb's input and output ports all correspond to variables
    * in this board
    * @modifies this
    * @effects adds the given sub-boards to this. For each of the chutes, there
    * is a simple SPLIT at the top and a MERGE at the bottom.
    */
   public void addSubBoards(Set<BoardBuilder> bb)
   {
      throw new RuntimeException("Not yet implemented");
   }
   
   /**
    * @requires active; name is, or will be, a valid board name in levelBuilder;
    * all args and ret are valid variables in this.
    * @modifies this
    * @effects adds the given subnetwork, with the given args and return value,
    * to the board that this is building
    */
   public void addSubnetwork(String name, List<String> args, String ret)
   {
      throw new RuntimeException("Not yet implemented");
   }
   
   /**
    * @requires given variables are both present
    * @modifies this
    * @effects represents an assignment from "from" to "to." Specifically, puts
    * a split in the from chute and an end on the to chute, then merging one of
    * the branches of from with to.
    */
   public void assignment(String to, String from)
   {
      throw new RuntimeException("Not yet implemented");
   }
   
   /**
    * @requires given variable is present
    * @modifies this
    * @effects makes the chutes for the given variable flow into the return
    * output chute
    */
   // TODO determine what to do if client tries to modify this variable after
   public void returnVar(String var)
   {
      throw new RuntimeException("Not yet implemented");
   }
   
   /**
    * @requires active
    * @modifies this
    * @effects sets active to false
    * @return the board that this BoardBuilder is building
    */
   public Board getBoard()
   {
      throw new RuntimeException("Not yet implemented");
   }
}
