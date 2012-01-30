package verigames.level;

/**
 * An {@link Intersection} subclass that represents a
 * {@link Intersection.Kind#SUBNETWORK SUBNETWORK}. Because {@code SUBNETWORK}s
 * represent more information than other {@code Intersection}s, they are
 * implemented separately.<br/>
 * <br/>
 * Specification Field: {@code subnetworkName}: {@code String}
 * // The name of the method to which {@code this} represents a call.<br/>
 * 
 * @author Nathaniel Mote
 */

public class Subnetwork extends Intersection
{
   private final String subnetworkName;
   
   /**
    * Creates a new {@link Intersection} with {@link Intersection.Kind Kind}
    * {@link Intersection.Kind#SUBNETWORK SUBNETWORK}.<br/>
    * <br/>
    * {@code this} represents a call to the method with name {@code methodName}.
    * @param methodName
    * The name of the method to which {@code this} refers.
    */
   protected Subnetwork(String methodName)
   {
      super(Kind.SUBNETWORK);
      subnetworkName = methodName;
   }
   
   /**
    * Returns {@code true} iff {@code kind} is
    * {@link Intersection.Kind#SUBNETWORK SUBNETWORK}, indicating that this
    * implementation supports only {@code SUBNETWORK}s<br/>
    * 
    * @param kind
    */
   @Override protected boolean checkIntersectionKind(Kind kind) /*@Raw*/
   {
      // This implementation supports only the SUBNETWORK kind
      return kind == Kind.SUBNETWORK;
   }
   
   /**
    * Returns {@code true} to indicate that {@code this} is a
    * {@link Intersection.Kind#SUBNETWORK SUBNETWORK}.
    */
   @Override public boolean isSubnetwork()
   {
      return true;
   }
   
   /**
    * Returns {@code this}
    */
   @Override public Subnetwork asSubnetwork()
   {
      return this;
   }
   
   /**
    * Returns {@code subnetworkName}
    */
   public String getSubnetworkName()
   {
      return subnetworkName;
   }
}
