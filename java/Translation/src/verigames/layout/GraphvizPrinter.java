package verigames.layout;


import java.io.PrintStream;

import verigames.graph.Edge;
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
 * The UIDs of the nodes are used to identify them. Other than that, the
 * specifics of how a graph is represented are determined by the implementation.
 * <p>
 * To provide an implementation of a {@code GraphvizPrinter}, subclasses must do
 * the following:
 * <ul>
 * <li>
 * Implement {@link #isDigraph(Board)}, {@link #nodeSettings(Board)}, {@link
 * #edgeSettings(Board)}, {@link #graphSettings(Board)}.
 * </li>
 * <li>
 * Call the constructor with a {@link verigames.utilities.Printer Printer} for
 * {@code Intersection}s and a {@code Printer} for {@code Chute}s.
 * </li>
 * </ul>
 * 
 * @author Nathaniel Mote
 */
abstract class GraphvizPrinter extends Printer<Board, Void>
{

  /**
   * Returns max(number of input ports, number of output ports) for {@code n}.
   * <p>
   * Included for use in subclasses
   *
   * 
   * @param n
   */
  protected static int getMaxPorts(Node<?> n)
  {
    return Math.max(n.getInputs().size(), n.getOutputs().size());
  }
    
  private final Printer<Intersection, Board> nodePrinter;
  private final Printer<Chute, Board> edgePrinter;
  
  /**
   * Constructs a new GraphvizPrinter.
   *
   * @param nodePrinter
   * The {@link verigames.utilities.Printer} used to output nodes. Must use an {@link
   * verigames.level.Intersection}'s {@code UID} as the node identifier for Graphviz.
   *
   * @param edgePrinter
   * The {@link verigames.utilities.Printer} used to output edges
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
   * {@link verigames.level.Board#underConstruction() b.underConstruction()} must be false.
   */
  @Override
  public void print(Board b, PrintStream out, Void data)
  {
    if (b.underConstruction())
      throw new IllegalArgumentException("b.underConstruction()");
    
    this.isDigraph = isDigraph(b);
    
    super.print(b, out, data);
  }
  
  /**
   * {@inheritDoc}
   * 
   * @param b
   * {@link verigames.level.Board#underConstruction() b.underConstruction()} must be false.
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
   * Returns {@code true} iff the {@link verigames.level.Board Board} should be printed
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
   * {@link verigames.level.Board#underConstruction() b.underConstruction()} must be false.
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
   * {@link verigames.level.Board#underConstruction() b.underConstruction()} must be false.
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
   * {@link verigames.level.Board#underConstruction() b.underConstruction()} must be false.
   */
  @Override
  protected void printOutro(Board b, PrintStream out, Void data)
  {
    out.println("}");
  }
}
