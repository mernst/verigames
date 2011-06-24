package level;

import java.util.List;

import javax.lang.model.element.Name;

import checkers.nullness.quals.LazyNonNull;
import checkers.nullness.quals.Nullable;

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
 * types auxiliary to the type that this chute represents. Only includes chutes
 * that are directly auxiliary to this. For example, if this chute represented
 * Map<String, Set<Integer>>, the auxiliary chutes would represent String and
 * Set. The Integer chute would be listed as an auxiliary chute to Set, but not
 * to this.
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
 * Except in corner cases, pinch --> narrow. This is not, however, enforced.
 * 
 */

public class Chute
{
   private final @Nullable Name name;
   
   private List<Chute> auxiliaryChutes;
   
   private @LazyNonNull Intersection start;
   private int startPort;
   private @LazyNonNull Intersection end;
   private int endPort;
   
   private final boolean pinch; // whether a chute has a pinch-point is a fact
                                // of the original code, and cannot be modified
                                // in-game
   private boolean narrow;
   private final boolean editable;
   private final int UID;
   
   private static int nextUID = 1;
   
   /**
    * @effects creates a new Chute object, with the given values for name,
    * pinch, and editable
    */
   public Chute(@Nullable Name name, boolean pinch, boolean editable)
   {
      this.name = name;
      this.pinch = pinch;
      this.editable = editable;
      
      UID = nextUID;
      nextUID += 2;
   }
   
   /**
    * @returns name, or null if none exists
    */
   public @Nullable Name getName()
   {
      return name;
   }
   
   /**
    * @return pinch
    */
   public boolean isPinched()
   {
      return pinch;
   }
   
   /**
    * @return narrow
    */
   public boolean isNarrow()
   {
      return narrow;
   }
   
   /**
    * @modifies this
    * @effects sets the specfield narrow to the given boolean value
    * 
    * Note: this can be called even if editable is false, because it may be
    * necessary (or at least easier) for construction
    */
   public void setNarrow(boolean narrow)
   {
      this.narrow = narrow;
   }
   
   /**
    * @return editable
    */
   public boolean isEditable()
   {
      return editable;
   }
   
   /**
    * @return start, or null if end does not exist
    */
   public @Nullable Intersection getStart()
   {
      return start;
   }
   
   /**
    * @return startPort
    */
   public int getStartPort()
   {
      return startPort;
   }
   
   /**
    * @return end, or null if end does not exist
    */
   public @Nullable Intersection getEnd()
   {
      return end;
   }
   
   /**
    * @return endPort
    */
   public int getEndPort()
   {
      return endPort;
   }
   
   /**
    * @requires start != null; port is a valid port number for start
    * @modifies this
    * @effects sets "start" to the given Intersection, replacing the old one, if
    * present
    */
   protected void setStart(Intersection start, int port)
   {
      if (start == null)
         throw new IllegalArgumentException(
               "Chute.setStart passed a null argument");
      
      this.start = start;
      this.startPort = port;
   }
   
   /**
    * @requires start != null; port is a valid port number for start
    * @modifies this
    * @effects sets "end" to the given Intersection, replacing the old one, if
    * present
    */
   protected void setEnd(Intersection end, int port)
   {
      if (end == null)
         throw new IllegalArgumentException(
               "Chute.setEnd passed a null argument");
      
      this.end = end;
      this.endPort = port;
   }
   
   /**
    * @return UID
    */
   public int getUID()
   {
      return UID;
   }
   
}
