package verigames.layout;


import java.io.PrintStream;

import verigames.graph.Node;
import verigames.level.Board;
import verigames.level.Chute;
import verigames.level.Intersection;
import verigames.level.Intersection.Kind;
import verigames.utilities.Printer;

/**
 * Prints fully constructed {@link verigames.level.Board Board} objects in Graphviz's <a
 * href="http://en.wikipedia.org/wiki/DOT_language">DOT format</a>.
 * <p>
 * This {@link verigames.utilities.Printer Printer} prints for the node layout phase of
 * the layout -- thus the name {@code NodeLayoutPrinter}. This is the first
 * phase in the layout process -- the second is laying out the edges.
 * <p>
 * This {@code Printer} expresses the node layout requirements to Graphviz.
 * These are, for the most part, straightforward. However, the height and width
 * of the nodes mean something slightly different from what one might
 * expect.<br/>
 * The node is considered to be located in the top-left corner of the rectangle
 * that represents it. The width, then, is the amount of empty space it needs to
 * its right, and the height is the amount of empty space it needs below it, as
 * described in world.dtd.<br/>
 * Sometimes, a node must be, for example, 3 units above one particular node,
 * and 2 units above others. Unfortunately, there is no way to express this to
 * Graphviz, so its height is set to 3, restricting it to be 3 units above
 * <b>all</b> nodes. This expresses the requirement imprecisely, but it is the
 * best that Graphviz can do.
 * 
 * @author Nathaniel Mote
 */
class NodeLayoutPrinter extends GraphvizPrinter
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
         // units, while the height of INCOMING and END nodes is 1.  The height
         // of an OUTGOING node is unspecified and irrelevant, as it has no
         // nodes below it, so it is set to 1 as well, simply so that it doesn't
         // take up too much space when an image rendered by Graphviz is viewed
         // for debugging purposes.
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

   /**
    * Constructs a new {@code NodeLayoutPrinter}
    */
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
      // Do the regular printing, then print the invisible edges
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
    * {@link verigames.level.Board#underConstruction() b.underConstruction()} must be false.
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
