package layout;

import level.Board;
import level.Level;
import level.World;

/**
 * Adds layout information to a {@link level.World World} using Graphviz.
 * 
 * @author Nathaniel Mote
 */
public class WorldLayout
{
   public void layout(World w)
   {
      BoardLayout layout = BoardLayout.factory();

      for (Level l : w.getLevels().values())
      {
         for (Board b : l.boards().values())
         {
            layout.layout(b);
         }
      }
   }
}
