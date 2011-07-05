package level;

import java.util.ArrayList;
import java.util.List;

import checkers.nullness.quals.AssertNonNullAfter;
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
 * @specfield name : String // The name of the variable corresponding to this
 * chute. Can be null if this chute does not correspond directly to a variable,
 * but all chutes connected to an incoming or outgoing node, except for the
 * return value, must either have a name or be an auxiliary chute. This is
 * because they represent fields, or, if their board is a sub-board, variables
 * declared within the method.
 * 
 * @specfield auxiliaryChutes: List<Chute> // The list of chutes that represents
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
 * I toyed with the idea of requiring that editable is true to change things
 * like narrow or pinch, but editable really determines whether it can be
 * changed by the player in the game, and not whether this object is mutable or
 * not.
 * 
 */

public class Chute
{
   // TODO change String to whatever we end up using
   private final @Nullable String name;
   
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
   public Chute(@Nullable String name, boolean pinch, boolean editable,
         @Nullable List<Chute> aux)
   {
      this.name = name;
      this.pinch = pinch;
      this.editable = editable;
      
      narrow = false;
      
      auxiliaryChutes = aux == null ? new ArrayList<Chute>()
            : new ArrayList<Chute>(aux);
      
      UID = nextUID;
      nextUID += 2;
   }
   
   /**
    * @returns name, or null if none exists
    */
   public @Nullable String getName()
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
    * @return the auxiliary chutes associated with this Chute. Structural
    * changes to the returned list will not affect this object.
    */
   public List<Chute> getAuxiliaryChutes()
   {
      throw new RuntimeException("Not yet implemented");
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
    * @require this chute has a "start" intersection
    * @return startPort
    */
   public int getStartPort()
   {
      if (start == null)
         throw new IllegalStateException();
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
    * @require this chute has an "end" intersection
    * @return endPort
    */
   public int getEndPort()
   {
      if (end == null)
         throw new IllegalStateException();
      return endPort;
   }
   
   /**
    * @requires start != null; port is a valid port number for start
    * @modifies this
    * @effects sets "start" to the given Intersection, replacing the old one, if
    * present
    */
   @AssertNonNullAfter({ "start" }) protected void setStart(Intersection start,
         int port)
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
   @AssertNonNullAfter({ "end" }) protected void setEnd(Intersection end,
         int port)
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
