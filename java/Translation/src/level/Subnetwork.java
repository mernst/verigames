package level;

/**
 * An Intersection subclass that creates only subnetworks. Because subnetworks
 * need more information than regular intersections, they are implemented
 * separately<br/>
 * <br/>
 * Specification Field: subnetwork: String // The name referring to this
 * subnetwork<br/>
 * 
 * @author Nathaniel Mote
 */

public class Subnetwork extends Intersection
{
   /**
    * creates a new Intersection object of type SUBNETWORK, with the specific
    * subnetwork defined by the argument<br/>
    * <br/>
    * Requires: methodName represents a valid subnetwork
    * 
    */
   public Subnetwork(String methodName)
   {
      super(Kind.SUBNETWORK);
   }
   
   /**
    * Returns true iff kind is SUBNETWORK
    */
   @Override protected boolean checkIntersectionKind(Kind kind)
   {
      // This implementation supports only the SUBNETWORK kind
      return kind == Kind.SUBNETWORK;
   }
   
   /**
    * Returns true to indicate that this is of kind SUBNETWORK
    */
   @Override public boolean isSubnetwork()
   {
      return true;
   }
   
   /**
    * Returns this
    */
   @Override public Subnetwork asSubnetwork()
   {
      return this;
   }
   
   /**
    * Returns the name of the method that this subnetwork refers to
    */
   public String getSubnetworkName()
   {
      throw new RuntimeException("Not yet implemented");
   }
}
