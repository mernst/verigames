package levelBuilder;

import java.util.Set;

import javax.lang.model.element.Name;

import level.*;

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
 * @specfield varToFurthestEdge: map from Name to Chute // For a given variable
 * name, return the base chute. its auxiliary chutes can be accessed through the
 * base chute
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

// TODO add some set of variables, similar to the fields specfield in
// LevelBuilder

public class BoardBuilder
{
   
   /**
    * @effects creates a new BoardBuilder with the given LevelBuilder in the
    * levelBuilder specfield
    */
   public BoardBuilder(LevelBuilder lb)
   {
      throw new RuntimeException("Not yet implemented");
   }
   
   /**
    * @requires active; The given node must have only a single input port and a
    * single output port. Otherwise the state of the other ports would be
    * undefined.
    * @modifies this
    * @effects Adds the given node to the given variable
    */
   public void addNodeToVar(Name var, Intersection node)
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
   public void addPinchToVar(Name var)
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
    * @modifies this
    * @effects sets active to false
    * @return the board that this
    */
   public Board getBoard()
   {
      throw new RuntimeException("Not yet implemented");
   }
}
