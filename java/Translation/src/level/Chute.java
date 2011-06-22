package level;

/**
 * @author: Nathaniel Mote
 * 
 * A mutable structure representing chute segments.
 * 
 * Implements eternal equality because it is mutable, but must be used in Collections
 * 
 * @specfield start : Intersection // The starting point of this Chute
 * @specfield startPort: integer // The port from which this exits its starting node
 * @specfield end : Intersection // The ending point of this Chute
 * @specfield endPort: integer // The port through which this enters its ending node
 * 
 * @specfield pinch : boolean // true iff there is a pinch-point in this chute
 * segment
 * 
 * @specfield narrow : boolean // true iff the chute is currently narrow
 * 
 * @specfield UID: integer // the unique odd identifier for this chute
 * 
 * Except in corner cases, pinch --> narrow
 * 
 */

public class Chute
{
   
   private /*@LazyNonNull*/ Intersection start;
   private /*@LazyNonNull*/ Intersection end;
   private final boolean pinch; // whether a chute has a pinch-point is a fact
                                // of the original code, and cannot be modified
                                // in-game
   private boolean narrow;
   
   /**
    * @effects creates a new Chute object. the specfield "pinch" will have the
    * same value as the argument
    */
   public Chute(boolean pinch)
   {
      throw new RuntimeException("Not yet implemented");
   }
   
   /**
    * @return pinch
    */
   public boolean isPinched()
   {
      throw new RuntimeException("Not yet implemented");
   }
   
   /**
    * @return narrow
    */
   public boolean isNarrow()
   {
      throw new RuntimeException("Not yet implemented");
   }
   
   /**
    * @modifies this
    * @effects sets the specfield narrow to the given boolean value
    */
   public void setNarrow(boolean narrow)
   {
      throw new RuntimeException("Not yet implemented");
   }
   
   /**
    * @return start, or null if end does not exist
    */
   public /*@Nullable*/ Intersection getStart()
   {
      throw new RuntimeException("Not yet implemented");
   }
   
   /**
    * @return end, or null if end does not exist
    */
   public /*@Nullable*/ Intersection getEnd()
   {
      throw new RuntimeException("Not yet implemented");
   }
   
   /**
    * @requires start != null; port is a valid port number for start
    * @modifies this
    * @effects sets "start" to the given Intersection, replacing the old one, if present
    */
   protected void setStart(Intersection start, int port)
   {
      throw new RuntimeException("Not yet implemented");
   }
   
   /**
    * @requires start != null; port is a valid port number for start
    * @modifies this
    * @effects sets "end" to the given Intersection, replacing the old one, if present
    */
   protected void setEnd(Intersection end, int port)
   {
      throw new RuntimeException("Not yet implemented");
   }
   
}
