package level;

import java.util.ArrayList;
import java.util.Collections;
import java.util.Iterator;
import java.util.LinkedList;
import java.util.List;
import java.util.Queue;

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
 * Specification Field: {@code auxiliaryChutes} : {@code List<Chute>}
 * // The list of chutes that represents types auxiliary to the type that this
 * chute represents. Only includes chutes that are directly auxiliary to this.
 * For example, if this chute represented {@code Map<String, Set<Integer>>}, the
 * auxiliary chutes would represent {@code String} and {@code Set}. The
 * {@code Integer} chute would be listed as an auxiliary chute to the
 * {@code Set} chute, but not to {@code this}.<br/>
 * <br/>
 * This is useful because a reference to a single chute can serve as a complete
 * description of the relevant type information of a given type. <br/>
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
   
   private List<Chute> auxiliaryChutes;
   
   private boolean pinch;
   
   private boolean narrow;
   private final boolean editable;
   
   private final int UID;
   
   private static int nextUID = 1;
   
   /*
    * Representation Invariant:
    * 
    * If !active, start and end must be non-null, and startPort and endPort must
    * not equal -1
    */

   
   /**
    * Creates a new {@code Chute} object, with the given values for name, pinch, and
    * editable
    * 
    * @param name
    * @param editable
    * @param aux
    */
   public Chute(@Nullable String name, boolean editable, @Nullable List<Chute> aux)
   {
      this.name = name;
      this.editable = editable;
      
      narrow = false;
      pinch = false;
      
      auxiliaryChutes = aux == null ? new ArrayList<Chute>()
            : new ArrayList<Chute>(aux);
      
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
    * Returns the {@code Chute}s auxiliary to {@code this}. Structural changes
    * to the returned list will not affect {@code this}.
    */
   public List<Chute> getAuxiliaryChutes()
   {
      return new ArrayList<Chute>(auxiliaryChutes);
   }
   
   /**
    * Returns {@code editable}
    */
   public boolean isEditable()
   {
      return editable;
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
      List<Chute> copyAuxChutes = new ArrayList<Chute>();
      for (Chute c : auxiliaryChutes)
      {
         copyAuxChutes.add(c.copy());
      }
      
      Chute copy = new Chute(name, editable, copyAuxChutes);
      copy.setNarrow(narrow);
      copy.setPinched(pinch);
      
      return copy;
   }
   
   /**
    * Returns an {@code Iterator<Chute>} that performs a preorder traversal of
    * the auxiliary chutes tree. Does not include {@code this}.
    */
   public Iterator<Chute> traverseAuxChutes()
   {
      Queue<Chute> allAuxChuteTraversals = new LinkedList<Chute>();
      for (Chute aux : this.getAuxiliaryChutes())
      {
         // Add aux
         allAuxChuteTraversals.add(aux);
         // Perform a traversal of the chutes in aux and add all of them, too
         Iterator<Chute> auxTraversal = aux.traverseAuxChutes();
         while (auxTraversal.hasNext())
            allAuxChuteTraversals.add(auxTraversal.next());
      }
      // wrapped as unmodifiable so that iterator remove operations fail
      // (otherwise they would succeed, but not do anything)
      return Collections.unmodifiableCollection(allAuxChuteTraversals).iterator();
   }
}
