package layout;

import level.Board;
import level.Intersection;

/**
 * Adds layout information to a {@link level.Board Board} using Graphviz.
 * 
 * @author Nathaniel Mote
 */
public class BoardLayout
{
   private static final BoardLayout layout;
   static
   {
      layout = new BoardLayout();
   }
   
   /**
    * Returns a {@code BoardLayout} object.
    */
   public static BoardLayout factory()
   {
      return layout;
   }
   
   /**
    * Adds layout information to {@code b} using Graphviz.
    * 
    * @param b
    */
   public static void staticLayout(Board b)
   {
      factory().layout(b);
   }
   
   /**
    * Creates a new BoardLayout object.
    */
   protected BoardLayout()
   {
      
   }
   
   /**
    * Adds layout information to {@code b} using Graphviz.
    * 
    * @param b
    */
   public void layout(Board b)
   {
      GraphInformation info = (new DotRunner()).run(b);
      
      int boardHeight = info.getGraphAttributes().getHeight();
      
      for (Intersection n : b.getNodes())
      {
         int UID = n.getUID();
         
         GraphInformation.NodeAttributes nodeAttrs = info.getNodeAttributes(Integer.toString(UID));
         
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
}
