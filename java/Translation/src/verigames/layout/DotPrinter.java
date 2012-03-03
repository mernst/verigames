package verigames.layout;

import java.io.PrintStream;
import java.lang.ref.WeakReference;

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
 * This {@link verigames.utilities.Printer Printer} prints DOT output for use in
 * laying out game boards.
 * 
 * @author Nathaniel Mote
 *
 * @see verigames.layout
 */
class DotPrinter extends AbstractDotPrinter
{
  /**
   * A class that prints {@link verigames.level.Intersection Intersection}
   * objects to Graphviz's DOT format.
   */
  private static class NodePrinter extends Printer<Intersection, Board>
  {
    @Override
    protected void printMiddle(Intersection n, PrintStream out, Board b)
    {
      /* contains extra options, particularly the extra information needed for a
       * node with ports. */
      final String optionsString;
      {
        if (usesPorts(n.getIntersectionKind()))
        {
          final int maxPorts = AbstractDotPrinter.getMaxPorts(n);
          final int width = maxPorts;
          final double height = getIntersectionHeight(n.getIntersectionKind());

          /* in a "record" shape node, the labels have special meaning, and
           * define ports. The curly braces control the layout. */
          String label = "{{"
              + generatePortList("i",maxPorts) + "}|{"
              + generatePortList("o",maxPorts) + "}}";

          optionsString = String.format("[shape=record, width=%d, height=%f, label=\"%s\"]",
                                        width, height, label);
        }
        else
          optionsString = "";
      }
      
      out.printf("%d %s;\n", n.getUID(),  optionsString);
    }

    private static double getIntersectionHeight(Intersection.Kind kind)
    {
      if (!usesPorts(kind))
        return 0;
      else if (kind == Intersection.Kind.SUBNETWORK)
        return 1.46;
      else
        return 1;
    }

    /**
     * Generates a list of ports from 0 to (n-1) for use in a label for a
     * Graphviz record node.
     *
     * @param prefix
     * The string with which to prefix each port number
     *
     * @param n
     * The number of ports to generate
     */
    private String generatePortList(String prefix, int n)
    {
      String result = "";
      for (int i = 0; i < n; i++)
      {
        result += "<" + prefix + i + ">";
        if (i != n - 1)
          result += "|";
      }
      return result;
    }
  }
  
  /**
   * An {@code Object} that prints {@link verigames.level.Chute Chute} objects to
   * Graphviz's DOT format, with attributes tailored to the edge layout pass.
   */
  private static final Printer<Chute, Board> edgePrinter = new Printer<Chute, Board>()
  {
    @Override
    protected void printMiddle(Chute e, PrintStream out, Board b)
    {
      String start = getNodeString(e.getStart(), "o", e.getStartPort());
      String end = getNodeString(e.getEnd(), "i", e.getEndPort());

      /* TODO for some reason, if this is a directed graph, there are some weird
       * gaps between subnetworks and the chutes flowing into them. Investigate
       * this and fix it, because this really should be a directed graph */
      out.println(start + " -- " + end + ";");
    }

    /**
     * Returns a {@code String} representing the given node and, if the node is
     * represented to Graphviz as having ports, the port number is included,
     * preceded by the given prefix.
     *
     * @param n
     * The {@link level.Intersection Intersection} to create a {@code String}
     * representation for.
     *
     * @param portPrefix
     * The text with which to prefix the port number, if a port number needs to
     * be used. This is to distinguish incoming ports from outgoing ports.
     *
     * @param port
     * The port number for {@code n}
     */
    /* This method should be static, but can't be because it's part of an
     * anonymous class. This should, perhaps, be changed. */
    private String getNodeString(Intersection n, String portPrefix, int port)
    {
      String result = "";
      result += n.getUID();
      if (usesPorts(n.getIntersectionKind()))
        result += ":" + portPrefix + port;
      return result;
    }
  };

  /**
   * Constructs a new {@code EdgeLayoutPrinter}
   */
  public DotPrinter()
  {
    super(new NodePrinter(), edgePrinter);
  }

  /**
   * Returns true iff the given {@link Kind} of {@link Intersection} has its
   * ports represented explicitly when it is printed to DOT.
   * <p>
   * Most {@code Intersection}s don't need the port information expressed,
   * because they are essentially points. However, some are larger, and need to
   * have chutes connected to different parts of them, so they have their ports
   * represented explicitly.
   */
  private static boolean usesPorts(Kind k)
  {
    return k == Kind.INCOMING || k == Kind.OUTGOING || k == Kind.SUBNETWORK;
  }

  @Override
  protected boolean isDigraph(Board b)
  {
    return false;
  }

  @Override
  protected String nodeSettings(Board b)
  {
    // shape=circle: makes the nodes circular so that edges avoid them.
    //
    // width=1: makes the nodes have a radius of 0.5 inches so that edges stay
    // that far away from them.
    return "shape=circle, width=1";
  }

  @Override
  protected String edgeSettings(Board b)
  {
    // dirtype=none: Remove the drawings of arrows on the edges. Doing this
    // gives more regular spline information.
    //
    // headclip,tailclip=false: draw edges to the centers of nodes, instead of
    // stopping at their edges. Important because the nodes are circles, not
    // points. For an explanation, see nodeSettings.
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