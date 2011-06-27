package level;

import javax.lang.model.element.Name;


/**
 * @author Nathaniel Mote
 * 
 * An Intersection subclass that creates only subnetworks. Because subnetworks
 * need more information than regular intersections, they are implemented
 * separately
 * 
 * @specfield subnetwork: Name // The name referring to this subnetwork
 * 
 */

/*
 * Notes:
 * 
 * - There still must be a way for client code to retrieve information about the
 * Subnetwork. If they are all referred to as Intersections, this could be
 * problematic. Perhaps subclassing is not the best design.
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
      super(Kind.SUBNETWORK);
   }
   
   @Override protected boolean checkIntersectionKind(Kind kind)
   {
      // This implementation supports only the SUBNETWORK type
      return kind == Kind.SUBNETWORK;
   }
   
   @Override public boolean isSubnetwork()
   {
      return true;
   }
   
   @Override public Subnetwork asSubnetwork()
   {
      return this;
   }
   
   public Name getSubnetworkName()
   {
      throw new RuntimeException("Not yet implemented");
   }
}
