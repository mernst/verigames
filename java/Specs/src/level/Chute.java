package level;

/**
 * @author: Nathaniel Mote
 * 
 * A mutable structure representing chute segments.
 * 
 * @specfield start : Intersection // The starting point of this Chute
 * @specfield end : Intersection // The ending point of this Chute
 * 
 * @specfield pinch : boolean // true iff there is a pinch-point in this chute
 * segment
 * 
 * @specfield narrow : boolean // true iff the chute is currently narrow
 * 
 * Except in corner cases, pinch --> narrow
 * 
 */

public class Chute
{
   
   private Intersection start;
   private Intersection end;
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
    * @return start
    */
   public Intersection getStart()
   {
      throw new RuntimeException("Not yet implemented");
   }
   
   /**
    * @return end
    */
   public Intersection getEnd()
   {
      throw new RuntimeException("Not yet implemented");
   }
   
   /**
    * @modifies this
    * @effects sets "start" to the given Intersection
    */
   public void setStart(Intersection start)
   {
      throw new RuntimeException("Not yet implemented");
   }
   
   /**
    * @modifies this
    * @effects sets "end" to the given Intersection
    */
   public void setEnd(Intersection end)
   {
      throw new RuntimeException("Not yet implemented");
   }
   
}
