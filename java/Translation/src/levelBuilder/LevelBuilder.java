package levelBuilder;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;

import level.Chute;
import level.Level;

/**
 * 
 * 
 * @specfield fieldToChutes: Map<String, Set<Chute>> // mapping from name of
 * field to the set of all base chutes in this level representing that field.
 * the auxiliary chutes are accessible through the returned chutes themselves.
 * To reiterate, this map should not contain any auxiliary chutes.
 * 
 * @specfield fields: List<Chute> // Contains a list of base chutes representing
 * the fields in this class, in the order that they appear in the incoming and
 * outgoing nodes in Boards. The chute objects contained in this Map will not be
 * part of the Level. They will, rather, be used to create template Boards.
 * 
 * @specfield level: Level // the level that this LevelBuilder is creating
 * 
 * @specfield activeBoards: Set<BoardBuilder> // boards that have been created
 * by the getTemplateBoardBuilder but have not yet been finished and added to
 * the level
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
 * @author Nathaniel Mote
 */

/*
 * Notes:
 * 
 * - This class is currently a prototype. The interface may change at any time.
 */

public class LevelBuilder
{
   
   private Map<String, Set<Chute>> fieldToChutes;
   
   private List<Chute> fields;
   
   private Level level;
   
   private Map<BoardBuilder, String> activeBoards;
   
   boolean active;
   
   /**
    *  creates a new LevelBuilder, ready to be used
    */
   public LevelBuilder()
   {
      active = true;
      
      fieldToChutes = new HashMap<String, Set<Chute>>();
      
      level = new Level();
      
      activeBoards = new HashMap<BoardBuilder, String>();
   }
   
   /**
    * Requires active, b.active, b was made by a call to this Level's
    * getTemplateBoardBuilder
    * @modifies this, b
    *  sets b.active to false by calling b.getBoard. adds the given
    * board, with the given name, to the level that is being built.
    */
   public void finishBoardBuilder(BoardBuilder b)
   {
      if (!active)
         throw new IllegalStateException("Level must be active");
      if (!b.isActive())
         throw new IllegalArgumentException("Given BoardBuilder must be active");
      if (!activeBoards.containsKey(b))
         throw new IllegalArgumentException(
               "Given BoardBuilder must have been created by this LevelBuilder");
      
      level.addBoard(activeBoards.get(b), b.getBoard());
      activeBoards.remove(b);
   }
   
   /**
    * Requires active; chute.name is not already a key in fields; the given
    * chute is not, and will not, be used as part of a board.
    *  adds a field with name and type information specified by the
    * given chute
    */
   public void addField(Chute chute)
   {
      fields.add(chute);
   }
   
   /**
    * Returns a new BoardBuilder that is a template for a method in the class
    * represented by level.
    */
   // TODO should keep track of all BoardBuilders made by this
   public BoardBuilder getTemplateBoardBuilder(String name)
   {
      BoardBuilder b = new BoardBuilder(this);
      activeBoards.put(b, name);
      return b;
   }
   
   /**
    * Requires active
    * @modifies this
    *  sets active to false
    * Returns level
    */
   public Level getLevel()
   {
      if (!active)
         throw new IllegalStateException(
               "getLevel requires that this LevelBuilder is active");
      active = false;
      return level;
   }
   
   /**
    * Returns active
    */
   public boolean isActive()
   {
      return active;
   }
   
}
