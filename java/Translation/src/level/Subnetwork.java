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
   
   /**
    * @return true iff kind is SUBNETWORK
    */
   @Override protected boolean checkIntersectionKind(Kind kind)
   {
      // This implementation supports only the SUBNETWORK kind
      return kind == Kind.SUBNETWORK;
   }
   
   /**
    * @return true to indicate that this is of kind SUBNETWORK
    */
   @Override public boolean isSubnetwork()
   {
      return true;
   }
   
   /**
    * @return this
    */
   @Override public Subnetwork asSubnetwork()
   {
      return this;
   }
   
   /**
    * @return the Name of the method that this subnetwork refers to
    */
   public Name getSubnetworkName()
   {
      throw new RuntimeException("Not yet implemented");
   }
}
