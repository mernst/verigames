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
 * Prints fully constructed {@link level.Board Board} objects in Graphviz's <a
 * href="http://en.wikipedia.org/wiki/DOT_language">DOT format</a>.
 * <p>
 * The UIDs of the nodes are used to identify them. Other than that, the
 * specifics of how a graph is represented are determined by the implementation.
 * 
 * @author Nathaniel Mote
 */
abstract class GraphvizPrinter extends Printer<Board, Void>
{
   private final Printer<Intersection, Board> nodePrinter;
   private final Printer<Chute, Board> edgePrinter;

   /**
    * Constructs a new GraphvizPrinter.
    *
    * @param nodePrinter
    * The {@link utilities.Printer} used to output nodes
    *
    * @param edgePrinter
    * The {@link utilities.Printer} used to output edges
    */
   protected GraphvizPrinter(Printer<Intersection, Board> nodePrinter, Printer<Chute, Board> edgePrinter)
   {
      this.nodePrinter = nodePrinter;
      this.edgePrinter = edgePrinter;
   }

   private boolean isDigraph;

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

      this.isDigraph = isDigraph(b);
      
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
      out.println((isDigraph ? "digraph" : "graph") + " {");
      
      out.println("node [" + nodeSettings(b) + "];");

      out.println("edge [" + edgeSettings(b) + "];");

      out.println("graph [" + graphSettings(b) + "];");
   }

   /**
    * Returns {@code true} iff the {@link level.Board Board} should be printed
    * as a directed graph.
    */
   // Note -- this should not be called directly. Instead, the field isDigraph
   // should be used. It is updated every time print is called. Using this
   // ensures consistent results, even if the subclass's implementation of
   // isDigraph is inconsistent (i.e. returns different values for the same
   // {@code Board}).
   protected abstract boolean isDigraph(Board b);

   /**
    * Returns the {@code String} listing the default settings for a node in the
    * printed graph, or an empty {@code String} if no settings are to be defined.
    */
   protected abstract String nodeSettings(Board b);

   /**
    * Returns the {@code String} listing the default settings for a edge in the
    * printed graph, or an empty {@code String} if no settings are to be defined.
    */
   protected abstract String edgeSettings(Board b);

   /**
    * Returns the {@code String} listing the settings for the printed graph, or
    * an empty {@code String} if no settings are to be defined.
    */
   protected abstract String graphSettings(Board b);
   
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
   }
   
   /**
    * Prints {@code b}'s nodes to {@code out} in the DOT language
    * 
    * @param b
    * @param out
    */
   private void printNodes(Board b, PrintStream out)
   {
      for (Intersection n : b.getNodes())
      {
         nodePrinter.print(n, out, b);
      }
   }

   /**
    * Prints {@code b}'s edges to {@code out} in the DOT language
    * 
    * @param b
    * {@link level.Board#isActive() b.isActive()} must be false.
    * @param out
    */
   private void printEdges(Board b, PrintStream out)
   {
      for (Chute e : b.getEdges())
      {
         edgePrinter.print(e, out, b);
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
}
