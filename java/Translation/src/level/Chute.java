package level;

import javax.lang.model.element.Name;

/**
 * @author: Nathaniel Mote
 * 
 * A mutable structure representing chute segments.
 * 
 * Implements eternal equality because it is mutable, but must be used in
 * Collections
 * 
 * @specfield name : Name // The name of the variable corresponding to this
 * chute. Can be null if this chute does not correspond directly to a variable,
 * but all chutes connected to an incoming or outgoing node, except for the
 * arguments and the return value, must have a name. This is because they
 * represent fields, or, if their board is a sub-board, variables declared
 * within the method
 * 
 * @specfield auxiliaryChutes: List<Chute> // The list of chutes that represent
 * types auxiliary to the type that this chute represents
 * 
 * @specfield start : Intersection // The starting point of this Chute
 * @specfield startPort: integer // The port from which this exits its starting
 * node
 * @specfield end : Intersection // The ending point of this Chute
 * @specfield endPort: integer // The port through which this enters its ending
 * node
 * 
 * @specfield pinch : boolean // true iff there is a pinch-point in this chute
 * segment
 * 
 * @specfield narrow : boolean // true iff the chute is currently narrow
 * 
 * @specfield editable : boolean // true iff the player can edit the width of
 * the chute
 * 
 * @specfield UID: integer // the unique odd identifier for this chute
 * 
 * Except in corner cases, pinch --> narrow
 * 
 */

public class Chute
{
   
   private/* @LazyNonNull */Intersection start;
   private/* @LazyNonNull */Intersection end;
   private final boolean pinch; // whether a chute has a pinch-point is a fact
                                // of the original code, and cannot be modified
                                // in-game
   private boolean narrow;
   
   /**
    * @effects creates a new Chute object, with the given values for name and
    * pinch
    */
   public Chute(/* @Nullable */Name name, boolean pinch)
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
    * @return editable
    */
   public boolean isEditable()
   {
      throw new RuntimeException("Not yet implemented");
   }
   
   // public void setEditable
   
   /**
    * @return start, or null if end does not exist
    */
   public/* @Nullable */Intersection getStart()
   {
      throw new RuntimeException("Not yet implemented");
   }
   
   /**
    * @return end, or null if end does not exist
    */
   public/* @Nullable */Intersection getEnd()
   {
      throw new RuntimeException("Not yet implemented");
   }
   
   /**
    * @requires start != null; port is a valid port number for start
    * @modifies this
    * @effects sets "start" to the given Intersection, replacing the old one, if
    * present
    */
   protected void setStart(Intersection start, int port)
   {
      throw new RuntimeException("Not yet implemented");
   }
   
   /**
    * @requires start != null; port is a valid port number for start
    * @modifies this
    * @effects sets "end" to the given Intersection, replacing the old one, if
    * present
    */
   protected void setEnd(Intersection end, int port)
   {
      throw new RuntimeException("Not yet implemented");
   }
   
}
