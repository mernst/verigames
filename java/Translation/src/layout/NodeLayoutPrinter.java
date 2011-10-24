package layout;

import graph.Node;

import java.io.PrintStream;

import level.Board;
import level.Chute;
import level.Intersection;
import level.Intersection.Kind;
import utilities.Printer;

/**
 * Prints fully constructed {@link level.Board Board} objects in Graphviz's <a
 * href="http://en.wikipedia.org/wiki/DOT_language">DOT format</a>.
 * 
 * @author Nathaniel Mote
 */
class NodeLayoutPrinter extends DotPrinter
{
   private static final Printer<Intersection, Board> nodePrinter = new Printer<Intersection, Board>()
   {
      @Override
      protected void printMiddle(Intersection n, PrintStream out, Board b)
      {
         // sets the width to be max(#input ports, #output ports), as required
         // by the game
         int width = getMaxPorts(n);
         
         // As described in world.dtd, the height of an ordinary node is 2
         // units, while the height of INCOMING and END nodes are of height 1.
         // The height of an OUTGOING node is unspecified and irrelevant, as
         // it has no nodes below it, so it is set to 1 as well.
         int height;
         // TODO set height of END node to 1
         if (n.getIntersectionKind() == Kind.INCOMING
               || n.getIntersectionKind() == Kind.OUTGOING)
            height = 1;
         else
            height = 2;
         
         {
            // As described in world.dtd, nodes connected by a pinched edge
            // must have an additional y coordinate between them. Because this
            // requirement can't be represented to GraphViz directly, the
            // height of the node itself is increased by one. This increases
            // the distance it can be from *any* node, not just the one it's
            // connected to by a pinched edge.
            boolean pinchOut = false;
            for (Chute c : n.getOutputs().values())
            {
               if (c.isPinched())
                  pinchOut = true;
            }
            if (pinchOut)
               height++;
         }
         
         String label = n.getIntersectionKind().toString() + n.getUID();
         
         out.println("" + n.getUID() + " [width = " + width + ", height="
               + height + ", label=\"" + label + "\"];");
      }

      /**
       * Returns max(number of input ports, number of output ports) for {@code n}
       * 
       * @param n
       */
      private int getMaxPorts(Node<?> n)
      {
         return Math.max(n.getInputs().size(), n.getOutputs().size());
      }
   };

   private static final Printer<Chute, Board> edgePrinter = new Printer<Chute, Board>()
   {
      @Override
      protected void printMiddle(Chute e, PrintStream out, Board b)
      {
         out.println("" + e.getStart().getUID() + " -> " + e.getEnd().getUID()
               + ";");
      }
   };

   public NodeLayoutPrinter()
   {
      super(nodePrinter, edgePrinter);
   }

   @Override
   protected boolean isDigraph(Board b)
   {
      return true;
   }

   @Override
   protected String nodeSettings(Board b)
   {
      // Make nodes rectangular, and don't allow Graphviz to resize them.
      return "shape=box, fixedsize=true";
   }

   @Override
   protected String edgeSettings(Board b)
   {
      return "";
   }

   @Override
   protected String graphSettings(Board b)
   {
      // Make both the vertical and horizontal separation between nodes 0.
      return "nodesep=0, ranksep=0";
   }
   
   @Override
   protected void printMiddle(Board b, PrintStream out, Void data)
   {
      super.printMiddle(b, out, data);

      printInvisibleEdges(b, out);
   }
   
   /**
    * Prints invisible, weight 0 edges from the incoming node to every other
    * node, and to the outgoing node from every other node.
    * <p>
    * This keeps the incoming node at the top and the outgoing node at the
    * bottom.
    * 
    * @param b
    * {@link level.Board#isActive() b.isActive()} must be false.
    * @param out
    */
   private static void printInvisibleEdges(Board b, PrintStream out)
   {
      Intersection incoming = b.getIncomingNode();
      Intersection outgoing = b.getOutgoingNode();
      out.println("edge [style=invis, weight=0];");
      out.println("" + incoming.getUID() + " -> " + outgoing.getUID());
      for (Intersection n : b.getNodes())
      {
         if (n != incoming && n != outgoing)
            out.println("" + incoming.getUID() + " -> " + n.getUID() + " -> "
                  + outgoing.getUID());
      }
   }
}
