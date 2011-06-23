package levelBuilder;

import javax.lang.model.element.Name;
import level.Board;

/**
 * 
 * @author Nathaniel Mote
 * 
 * @specfield fieldToChutes: Map<Name, Set<Chute>> // mapping from Name of field
 * to the set of all base chutes in this level representing that field. the
 * auxiliary chutes are accessible through the returned chutes themselves. to
 * reiterate, this map should not contain any auxiliary chutes.
 * 
 * @specfield
 * 
 * @specfield level: Level // the level that this LevelBuilder is creating
 * 
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
   
   //public void addField()
   
}
