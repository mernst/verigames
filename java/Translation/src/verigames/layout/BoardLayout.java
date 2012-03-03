package verigames.layout;

import static verigames.utilities.Misc.ensure;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

import verigames.level.Board;
import verigames.level.Chute;
import verigames.level.Intersection;
import verigames.utilities.Pair;

/**
 * Adds layout information to a {@link verigames.level.Board Board} using Graphviz.
 * <p>
 * This class does not represent an object -- it simply encapsulates the {@link
 * #layout(verigames.level.Board) layout(Board)} method. As such, it is not instantiable.
 *
 * @see WorldLayout
 * 
 * @author Nathaniel Mote
 */
// TODO document all variables with error-prone units using the units checker
public class BoardLayout
{
  /**
   * Should not be called. BoardLayout is simply a collection of static
   * methods.
   */
  private BoardLayout()
  {
    throw new RuntimeException("Uninstantiable");
  }
  
  /**
   * Adds layout information to {@code b} using Graphviz.
   * <p>
   * Modifies: {@code b}
   * 
   * @param b
   * The {@link verigames.level.Board} to lay out.
   *
   * @see WorldLayout#layout(verigames.level.World) WorldLayout.layout(World)
   */
  public static void layout(Board b)
  {
    GraphInformation info;
    
    // These variables are all just for clarity, so putting them in a block
    // avoids cluttering the namespace
    {
      AbstractDotPrinter printer = new DotPrinter();
      String command = "dot";
      GraphvizRunner runner = new GraphvizRunner(printer, command);
      info = runner.run(b);
    }
    
    // the height of the board is needed when the origin is moved from the
    // bottom left to the top left.
    int boardHeight = info.getGraphAttributes().getHeight();
    
    for (Intersection n : b.getNodes())
    {
      int UID = n.getUID();
      
      GraphInformation.NodeAttributes nodeAttrs;
      try
      {
        // throws IllegalArgumentException if the node is not present. This
        // should not happen, but if, somehow, Graphviz's output does not
        // include a node that is in the Board, the resulting, cryptic error
        // should not escape to the client.
        nodeAttrs = info.getNodeAttributes(Integer.toString(UID));
      }
      catch (IllegalArgumentException e)
      {
        throw new RuntimeException(
            "Internal error -- node in Board not present in Graphviz output", e);
      }
      
      // gives the location of the center of the node in hundredths of
      // points, using the top left corner of the board as the origin
      int xIn = nodeAttrs.getX();
      int yIn = boardHeight - nodeAttrs.getY();
      
      // gives the width and height of the node in hundredths of points
      int width = nodeAttrs.getWidth();
      int height = nodeAttrs.getHeight();
      
      // gives the upper left hand corner of the node in hundredths of points.
      int xCorner = xIn - (width / 2);
      int yCorner = yIn - (height / 2);
      
      n.setX(((double) xCorner) / 7200d);
      n.setY(((double) yCorner) / 7200d);
    }

    for (Chute c : b.getEdges())
    {
      String startUID = Integer.toString(c.getStart().getUID());
      String endUID = Integer.toString(c.getEnd().getUID());
      
      GraphInformation.EdgeAttributes edgeAttrs; 
      
      boolean reversed;
      
      if (info.containsEdge(startUID, endUID))
      {
        edgeAttrs = info.getEdgeAttributes(startUID, endUID);
        reversed = false;
      }
      else
      {
        edgeAttrs = info.getEdgeAttributes(endUID, startUID);
        reversed = true;
      }
      
      List<Pair<Double, Double>> layout = new ArrayList<Pair<Double, Double>>();
      
      for (int i = 0; i < edgeAttrs.controlPointCount(); i++)
      {
        Pair<Double, Double> rawCoords = hundredthsOfPointsToGameUnits(edgeAttrs.getX(i), edgeAttrs.getY(i), boardHeight);
        
        Pair<Double, Double> coords = new Pair<Double, Double>
        (rawCoords.getFirst(), rawCoords.getSecond());
        
        layout.add(coords);
      }
      
      if (reversed)
        Collections.reverse(layout);
      
      c.setLayout(layout);
    }
  }
  
  /**
   * Converts coordinates from hundredths of points, using the bottom left as
   * the origin, to game units using the top left as the origin.
   */
  private static Pair<Double, Double> hundredthsOfPointsToGameUnits(int x, int y, int boardHeight)
  {
    y = boardHeight - y;
    
    double xResult = ((double) x / 7200d);
    double yResult = ((double) y / 7200d);
    
    return new Pair<Double, Double>(xResult, yResult);
  }
}
