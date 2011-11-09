package layout;

import java.io.PrintStream;
import java.lang.ref.WeakReference;

import graph.Node;
import level.Board;
import level.Chute;
import level.Intersection.Kind;
import level.Intersection;
import utilities.Printer;

/**
 * Prints fully constructed {@link level.Board Board} objects in Graphviz's <a
 * href="http://en.wikipedia.org/wiki/DOT_language">DOT format</a>.
 * <p>
 * This printer prints for the edge layout phase of the layout -- thus the name
 * {@code EdgeLayoutPrinter}. This is the second phase in the layout process --
 * the first is laying out the nodes.
 * <p>
 * IMPORTANT: In order for a {@link level.Board Board} to be printed with this
 * printer, it must have complete node layout information.
 * 
 * @author Nathaniel Mote
 */
class EdgeLayoutPrinter extends GraphvizPrinter
{
   private static class NodePrinter extends Printer<Intersection, Board>
   {
      /**
       * The height of the current board, in typographical units. This is needed
       * for the conversion between coordinate systems, because we have y
       * growing downards, and Graphviz has y growing upwards. This must be
       * precalculated, because at any given time, the total height of a board
       * cannot be determined quickly.
       */
      double boardHeight = -1d;

      /**
       * Used to determine when the boardHeight should be updated. If the {@code
       * Board} being printed is different from the one referred to here, then
       * boardHeight must be recalculated.
       * <p>
       * Maintained as a weak reference because this reference is only needed to
       * compare identity, and a reference held here and nowhere else would be
       * useless, so garbage collection should be allowed.
       */
      private WeakReference<Board> currentBoard = new WeakReference<Board>(null);
      @Override
      protected void printMiddle(Intersection n, PrintStream out, Board b)
      {
         // if the board referred to has been garbage collected,
         // currentBoard.get() will return null
         if (b != currentBoard.get())
            updateBoardHeight(b);
         
         double xInches = n.getX();
         double yInches = boardHeight - n.getY();

         double xPoints = xInches * 72d;
         double yPoints = yInches * 72d;
         
         out.printf("%d [pos=\"%f,%f\"];\n", n.getUID(), xPoints, yPoints);
      }

      /**
       * Updates the boardHeight and currentBoard fields to reflect data from
       * the given Board.
       */
      private void updateBoardHeight(Board b)
      {
         double minY = Double.MAX_VALUE;
         double maxY = Double.MIN_VALUE;
         for (Intersection n : b.getNodes())
         {
            double currentY = n.getY();
            if (currentY < minY)
               minY = currentY;
            if (currentY > maxY)
               maxY = currentY;
         }
         boardHeight = maxY - minY;
         currentBoard = new WeakReference<Board>(b);
      }
   }

   private static final Printer<Chute, Board> edgePrinter = new Printer<Chute, Board>()
   {
      @Override
      protected void printMiddle(Chute e, PrintStream out, Board b)
      {
         out.println("" + e.getStart().getUID() + " -- " + e.getEnd().getUID()
               + ";");
      }
   };

   public EdgeLayoutPrinter()
   {
      super(new NodePrinter(), edgePrinter);
   }

   @Override
   protected boolean isDigraph(Board b)
   {
      return false;
   }

   @Override
   protected String nodeSettings(Board b)
   {
      // makes the nodes circular so that edges avoid them.
      return "shape=circle";
   }

   @Override
   protected String edgeSettings(Board b)
   {
      // dirtype=none: Remove the drawings of arrows on the edges. Doing this
      // gives better layout information.
      //
      // headclip,tailclip=false: draw edges to the centers of nodes, instead of
      // stopping at their edges
      return "dirtype=none, headclip=false, tailclip=false";
   }

   @Override
   protected String graphSettings(Board b)
   {
      // splines=true: allows neato to draw curved edges, instead of the default
      // behavior where all lines are straight.
      return "splines=true";
   }
}
