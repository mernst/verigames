package layout;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

import level.Board;
import level.Chute;
import level.Intersection;
import utilities.Pair;

/**
 * Adds layout information to a {@link level.Board Board} using Graphviz.
 * <p>
 * This class does not represent an object -- it simply encapsulates the {@link
 * #layout(level.Board) layout(Board)} method. As such, it is not instantiable.
 *
 * @see WorldLayout
 * 
 * @author Nathaniel Mote
 */
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
    * The {@link level.Board} to lay out.
    *
    * @see WorldLayout#layout(level.World) WorldLayout.layout(World)
    */
   public static void layout(Board b)
   {
      nodeLayoutPass(b);
      edgeLayoutPass(b);
   }

   /**
    * Adds node layout information to the nodes in {@code b}.
    * <p>
    * Modifies: {@code b}
    *
    * @param b
    */
   private static void nodeLayoutPass(Board b)
   {
      GraphInformation info;

      // These variables are all just for clarity, so putting them in a block
      // avoids cluttering the namespace
      {
         GraphvizPrinter printer = new NodeLayoutPrinter();
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
   }

   /**
    * Adds edge layout information to the edges in {@code b}, without changing
    * existing node layout information.
    * <p>
    * Modifies: {@code b}
    *
    * @param b
    * Must already have layout information for its nodes.
    */
   private static void edgeLayoutPass(Board b)
   {
      GraphInformation info;

      // These variables are all just for clarity, so putting them in a block
      // avoids cluttering the namespace
      {
         GraphvizPrinter printer = new EdgeLayoutPrinter();
         String command = "neato -n";
         GraphvizRunner runner = new GraphvizRunner(printer, command);
         info = runner.run(b);
      }

      // the height of the board is needed when the origin is moved from the
      // bottom left to the top left.
      int boardHeight = info.getGraphAttributes().getHeight();

      for (Chute c : b.getEdges())
      {
         String startUID = Integer.toString(c.getStart().getUID());
         String endUID = Integer.toString(c.getEnd().getUID());

         // because Graphviz, when using "neato -n" only guarantees that nodes
         // stay in the same locations *relative to each other* and not
         // absolutely, we need to find what the offset is between the original
         // node location and its laid-out counterpart.
         double xOffset;
         double yOffset;
         {
            GraphInformation.NodeAttributes startAttrs = info.getNodeAttributes(startUID);

            // gives the coordinates of the start node in game units, with the
            // top left as the origin.
            Pair<Double, Double> startCoords = convertCoords(startAttrs.getX(), startAttrs.getY(), boardHeight);

            // finds the difference between what the node coordinates originally
            // were and what they are now according to Graphviz
            xOffset = c.getStart().getX() - startCoords.getFirst();
            yOffset = c.getStart().getY() - startCoords.getSecond();
         }

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
            Pair<Double, Double> rawCoords = convertCoords(edgeAttrs.getX(i), edgeAttrs.getY(i), boardHeight);

            Pair<Double, Double> coords = new Pair<Double, Double>
                  (rawCoords.getFirst() + xOffset, rawCoords.getSecond() + yOffset);

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
   private static Pair<Double, Double> convertCoords(int x, int y, int boardHeight)
   {
      y = boardHeight - y;

      double xResult = ((double) x / 7200d);
      double yResult = ((double) y / 7200d);

      return new Pair<Double, Double>(xResult, yResult);
   }
}
