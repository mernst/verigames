package level;

import javax.lang.model.element.Name;

/**
 * @author Nathaniel Mote
 * 
 * 
 *
 */

public class Subnetwork extends Intersection
{
   /**
    * @requires methodName represents a valid subnetwork
    * @effects creates a new Intersection object of type SUBNETWORK, with the
    * specific subnetwork defined by the argument
    * 
    */
   public Subnetwork(Name methodName)
   {
      super(Type.SUBNETWORK);
   }
   
   @Override
   protected boolean checkIntersectionType(Type type)
   {
      // This implementation supports only the SUBNETWORK type
      return type == Type.SUBNETWORK;
   }
}
