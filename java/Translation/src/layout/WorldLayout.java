package layout;

import level.Board;
import level.Level;
import level.World;

/**
 * Adds layout information to a {@link level.World World} using Graphviz.
 * <p>
 * This class does not represent an object -- it simply encapsulates the {@link
 * #layout(level.World) layout(World)} method. As such, it is not instantiable.
 *
 * @see BoardLayout
 * 
 * @author Nathaniel Mote
 */
public class WorldLayout
{
   /**
    * Should not be called. WorldLayout is simply a collection of static
    * methods.
    */
   private WorldLayout()
   {
      throw new RuntimeException("Uninstantiable");
   }

   /**
    * Adds layout information to all of the {@link level.Board Board}s contained
    * in {@code w} using {@link BoardLayout#layout(level.Board)
    * BoardLayout.layout(Board)}
    * <p>
    * Modifies: {@code w}
    *
    * @param w
    * The {@link level.World} to lay out.
    *
    * @see BoardLayout#layout(level.Board) BoardLayout.layout(Board)
    */
   public static void layout(World w)
   {
      for (Level l : w.getLevels().values())
      {
         for (Board b : l.boards().values())
         {
            BoardLayout.layout(b);
         }
      }
   }
}
