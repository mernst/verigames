package levelBuilder;

import level.Board;
import level.Chute;
import level.Level;

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
 * @specfield active: boolean // indicates whether this LevelBuilder is
 * currently constructing a Level. If false, no changes are allowed to the
 * contained Level. Active is set to false as soon as the contained Level is
 * returned. This is for the following reasons:
 * 
 * It only makes sense for a client to want the Level once it is complete, so
 * this does no harm.
 * 
 * Once a reference to the Level is returned, it could be modified externally.
 * That means that this class can no longer provide any guarantees about its
 * contents, so it is safer to just stop construction.
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
    * @modifies active
    * @effects adds the given board, with the given name, to the level that is
    * being created.
    */
   public void addBoard(String name, Board b)
   {
      throw new RuntimeException("Not yet implemented");
   }
   
   /**
    * @requires active; chute.name is not already a key in fields; the given
    * chute is not, and will not, be used as part of a board.
    * @effects adds a field with name and type information specified by the
    * given chute
    */
   public void addField(Chute chute)
   {
      throw new RuntimeException("Not yet implemented");
   }
   
   /**
    * @return a new BoardBuilder that is a template for a method in the class
    * represented by level. It will 
    */
   public BoardBuilder getTemplateBoardBuilder()
   {
      throw new RuntimeException("Not yet implemented");
   }
   
   /**
    * @modifies this
    * @effects sets active to false
    * @return level
    */
   public Level getLevel()
   {
      throw new RuntimeException("Not yet implemented");
   }
   
}
