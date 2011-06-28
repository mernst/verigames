package levelBuilder;

import javax.lang.model.element.Name;
import level.Board;
import level.Chute;

/**
 * 
 * @author Nathaniel Mote
 * 
 * @specfield fieldToChutes: Map<Name, Set<Chute>> // mapping from Name of field
 * to the set of all base chutes in this level representing that field. the
 * auxiliary chutes are accessible through the returned chutes themselves. to
 * reiterate, this map should not contain any auxiliary chutes.
 * 
 * @specfield fields: Map<Name, Chute> // contains a mapping from the Name of a
 * field to a prototypical base chute associated with it. The chute objects
 * contained in this Map will not be put part of the Level. They will, rather,
 * be used to create template Boards.
 * 
 * @specfield level: Level // the level that this LevelBuilder is creating
 * 
 * @specfield active: boolean // indicates whether this is currently in the
 * process of building a level
 * 
 */

public class LevelBuilder
{
   
   /**
    * @effects creates a new LevelBuilder, ready to be used
    */
   public LevelBuilder()
   {
      throw new RuntimeException("Not yet implemented");
   }
   
   /**
    * @modifies this
    * @effects adds the given board, with the given name, to the level that is
    * being created.
    */
   public void addBoard(Name name, Board b)
   {
      throw new RuntimeException("Not yet implemented");
   }
   
   /**
    * @requires chute.name is not already a key in fields; the given chute is
    * not, and will not, be used as part of a board.
    * @effects adds a field with name and type information specified by the
    * given chute
    */
   public void addField(Chute chute)
   {
      throw new RuntimeException("Not yet implemented");
   }
   
}
