package level;

import checkers.nullness.quals.Nullable;
import checkers.nullness.quals.Pure;

/**
 * A mutable chute segment for use in a {@link Board}. Once {@link #isActive()
 * this.isActive()} is false, {@code this} is immutable.<br/>
 * <br/>
 * Implements eternal equality because it is mutable, but must be used in
 * {@code Collection}s<br/>
 * <br/>
 * Specification Field: {@code name} : {@code @Nullable String}
 * // The name of the variable corresponding to this chute. {@code null} if this
 * chute has no name<br/>
 * <br/>
 * Specification Field: {@code pinch} : {@code boolean} // {@code true} iff
 * there is a pinch-point in this chute segment<br/>
 * {@code false} by default.<br/>
 * <br/>
 * Specification Field: {@code narrow} : {@code boolean} // {@code true} iff the
 * chute is currently narrow<br/>
 * <br/>
 * Specification Field: {@code editable} : {@code boolean} // {@code true} iff
 * the player can edit the width of the chute<br/>
 * <br/>
 * Specification Field: {@code UID} : integer // the unique identifier for this
 * chute<br/>
 * <br/>
 * Except in corner cases, {@code pinch} --> {@code narrow}. This is not,
 * however, enforced.<br/>
 * 
 * @author Nathaniel Mote
 */

public class Chute extends graph.Edge<Intersection>
{
   // TODO change String to whatever we end up using
   private final @Nullable String name;
   
   private boolean pinch;
   
   private boolean narrow;
   private boolean editable;
   
   private final int UID;
   
   private static int nextUID = 1;
   
   /**
    * Creates a new {@code Chute} object, with the given value for {@code name}.
    * 
    * @param name
    */
   @Deprecated
   public Chute(@Nullable String name)
   {
      this.name = name;
      this.editable = true;
      
      narrow = false;
      pinch = false;
      
      UID = nextUID;
      nextUID += 1;
      checkRep();
   }
   
   public Chute()
   {
      this.name = null;
      this.editable = true;
      
      narrow = false;
      pinch = false;
      
      UID = nextUID;
      nextUID += 1;
      checkRep();
   }
   
   /**
    * Returns {@code name}, or {@code null} if none exists
    */
   @Pure
   public @Nullable String getName()
   {
      return name;
   }
   
   /**
    * Returns {@code pinch}<br/>
    * <br/>
    * Defaults to {@code false}
    */
   public boolean isPinched()
   {
      return pinch;
   }
   
   /**
    * Sets {@code pinch} to the value of the parameter<br/>
    * <br/>
    * Requires: {@link #isActive() this.isActive()}<br/>
    * <br/>
    * Modifies: {@code this}
    * 
    * @param pinched
    */
   public void setPinched(boolean pinched)
   {
      if (!isActive())
         throw new IllegalStateException("Mutation attempted on inactive Chute");
      this.pinch = pinched;
      checkRep();
   }
   
   /**
    * Returns {@code narrow}
    */
   public boolean isNarrow()
   {
      return narrow;
   }
   
   /**
    * Sets the specification field {@code narrow} to the value of the parameter
    * {@code narrow}<br/>
    * <br/>
    * Requires: {@link #isActive() this.isActive()}<br/>
    * <br/>
    * Modifies: {@code this}
    * 
    * @param narrow
    */
   public void setNarrow(boolean narrow)
   {
      if (!isActive())
         throw new IllegalStateException("Mutation attempted on inactive Chute");
      this.narrow = narrow;
      checkRep();
   }
   
   /**
    * Returns {@code editable}
    */
   public boolean isEditable()
   {
      return editable;
   }
   
   /**
    * Sets the specification field {@code editable} to the value of the
    * parameter {@code editable}<br/>
    * <br/>
    * Requires: {@link #isActive() this.isActive()}<br/>
    * <br/>
    * Modifies: {@code this}
    * 
    * @param editable
    */
   public void setEditable(boolean editable)
   {
      if (!isActive())
         throw new IllegalStateException("Mutation attempted on inactive Chute");
      
      this.editable = editable;
      checkRep();
   }
   
   /**
    * Returns {@code UID}
    */
   public int getUID()
   {
      return UID;
   }
   
   /**
    * Returns a deep copy of {@code this}.<br/>
    * <br/>
    * If this chute has {@code start} or {@code end} nodes, that information
    * will not be copied.
    */
   public Chute copy()
   {
      Chute copy = new Chute(name);
      copy.setNarrow(narrow);
      copy.setPinched(pinch);
      copy.setEditable(editable);
      
      return copy;
   }
}
