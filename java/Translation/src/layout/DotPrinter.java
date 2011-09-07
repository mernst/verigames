package layout;

import graph.Edge;
import graph.Node;

import java.io.PrintStream;

import level.Board;
import level.Chute;
import level.Intersection;
import level.Intersection.Kind;
import utilities.Printer;

/**
 * Prints fully constructed Board objects in Graphviz's <a
 * href="http://en.wikipedia.org/wiki/DOT_language">DOT format</a>.
 * 
 * @author Nathaniel Mote
 */
class DotPrinter extends Printer<Board, Void>
{
   /**
    * {@inheritDoc}
    * 
    * @param b
    * {@link level.Board#isActive() b.isActive()} must be false.
    */
   @Override
   public void print(Board b, PrintStream out, Void data)
   {
      if (b.isActive())
         throw new IllegalArgumentException("b.isActive()");
      
      super.print(b, out, data);
   }
   
   /**
    * {@inheritDoc}
    * 
    * @param b
    * {@link level.Board#isActive() b.isActive()} must be false.
    */
   @Override
   protected void printIntro(Board b, PrintStream out, Void data)
   {
      out.println("digraph {");
      
      // Make nodes rectangular, and don't allow Graphviz to resize them.
      out.println("node [shape=box, fixedsize=true];");
      
      // Make both the vertical and horizontal separation between nodes 0.
      out.println("nodesep=0;");
      out.println("ranksep=0;");
   }
   
   /**
    * {@inheritDoc}
    * 
    * @param b
    * {@link level.Board#isActive() b.isActive()} must be false.
    */
   @Override
   protected void printMiddle(Board b, PrintStream out, Void data)
   {
      printNodes(b, out);
      
      printEdges(b, out);
      
      printInvisibleEdges(b, out);
   }
   
   /**
    * Prints {@code b}'s nodes to {@code out} in the DOT language
    * 
    * @param b
    * @param out
    */
   private static void printNodes(Board b, PrintStream out)
   {
      for (Intersection n : b.getNodes())
      {
         int width = getMaxPorts(n);
         
         int height;
         if (n.getIntersectionKind() == Kind.INCOMING
               || n.getIntersectionKind() == Kind.OUTGOING)
            height = 1;
         else
            height = 2;
         
         String label = n.getIntersectionKind().toString() + n.getUID();
         
         {
            boolean pinchOut = false;
            for (Chute c : n.getOutputs().values())
            {
               if (c.isPinched())
                  pinchOut = true;
            }
            if (pinchOut)
               height++;
         }
         
         out.println("" + n.getUID() + " [width = " + width + ", height="
               + height + ", label=\"" + label + "\"];");
      }
   }
   
   /**
    * Prints {@code b}'s edges to {@code out} in the DOT language
    * 
    * @param b
    * {@link level.Board#isActive() b.isActive()} must be false.
    * @param out
    */
   private static void printEdges(Board b, PrintStream out)
   {
      for (Edge<Intersection> e : b.getEdges())
      {
         out.println("" + e.getStart().getUID() + " -> " + e.getEnd().getUID()
               + ";");
      }
   }
   
   /**
    * Prints invisible, weight 0 edges from the incoming node to every other
    * node, and to the outgoing node from every other node.
    * <p>
    * This keeps the incoming nodes at the top.
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
   
   /**
    * {@inheritDoc}
    * 
    * @param b
    * {@link level.Board#isActive() b.isActive()} must be false.
    */
   @Override
   protected void printOutro(Board b, PrintStream out, Void data)
   {
      out.println("}");
   }
   
   /**
    * Returns max(number of input ports, number of output ports) for {@code n}
    * 
    * @param n
    */
   private static int getMaxPorts(Node<?> n)
   {
      return Math.max(n.getInputs().size(), n.getOutputs().size());
   }
}
