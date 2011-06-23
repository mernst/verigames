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
 * @specfield varToFurthestEdge: map from Name to Chute // For a given 
 * 
 * @specfield active: boolean // indicates whether this BoardBuilder represents
 * an unfinished Board
 * 
 */

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
    * @requires The given node must have only a single input port and a single
    * output port. Otherwise the state of the other ports would be undefined.
    * @modifies this
    * @effects Adds the given node to the given variable
    */
   public void addNodeToVar(Name var, Intersection node)
   {
      throw new RuntimeException("Not yet implemented");
   }
   
   /**
    * 
    */
   public void addVar(Name var)
   {
      throw new RuntimeException("Not yet implemented");
   }
   
   /**
    * @requires
    */
   public void addPinchToVar(Name var)
   {
      throw new RuntimeException("Not yet implemented");
   }
   
   /**
    * @requires bb's input and output ports all correspond to variables in this
    * board
    * @modifies this
    * @effects adds the given sub-boards to this. For each of the chutes, there
    * is a simple SPLIT at the top and a MERGE at the bottom.
    */
   public void addSubBoards(Set<BoardBuilder> bb)
   {
      throw new RuntimeException("Not yet implemented");
   }
}
