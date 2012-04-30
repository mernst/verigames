package verigames.layout;

import verigames.level.Board;
import verigames.level.Level;
import verigames.level.World;

/**
 * Adds layout information to a {@link verigames.level.World World} using Graphviz.
 * <p>
 * This class does not represent an object -- it simply encapsulates the {@link
 * #layout(verigames.level.World) layout(World)} method. As such, it is not instantiable.
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
   * Adds layout information to all of the {@link verigames.level.Board Board}s contained
   * in {@code w} using {@link BoardLayout#layout(verigames.level.Board)
   * BoardLayout.layout(Board)}
   * <p>
   * Modifies: {@code w}
   *
   * @param w
   * The {@link verigames.level.World} to lay out.
   *
   * @see BoardLayout#layout(verigames.level.Board) BoardLayout.layout(Board)
   */
  // TODO docuemnt that all levels in w must not be under construction
  public static void layout(World w)
  {
    for (Level l : w.getLevels().values())
    {
      for (Board b : l.getBoards().values())
      {
        BoardLayout.layout(b);
      }
    }
  }
}
