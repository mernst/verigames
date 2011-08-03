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
 * A mutable (until deactivated) structure representing a chute segment.<br/>
 * <br/>
 * Implements eternal equality because it is mutable, but must be used in
 * Collections<br/>
 * <br/>
 * Specification Field: name : Nullable String // The name of the variable
 * corresponding to this chute. Can be null if this chute does not correspond
 * directly to a variable, but all chutes connected to an incoming or outgoing
 * node, except for the return value, must either have a name or be an auxiliary
 * chute. This is because they represent fields, or, if their board is a
 * sub-board, variables declared within the method.<br/>
 * <br/>
 * Specification Field: auxiliaryChutes: List<Chute> // The list of chutes that
 * represents types auxiliary to the type that this chute represents. Only
 * includes chutes that are directly auxiliary to this. For example, if this
 * chute represented Map<String, Set<Integer>>, the auxiliary chutes would
 * represent String and Set. The Integer chute would be listed as an auxiliary
 * chute to Set, but not to this.<br/>
 * <br/>
 * This is useful because a reference to a single chute can serve as a complete
 * description of the relevant type information of a given type. <br/>
 * <br/>
 * Specification Field: start : Intersection // The starting point of this Chute<br/>
 * Specification Field: startPort: integer // The port from which this exits its
 * starting node<br/>
 * Specification Field: end : Intersection // The ending point of this Chute
 * Specification Field: endPort: integer // The port through which this enters
 * its ending node<br/>
 * <br/>
 * Specification Field: pinch : boolean // true iff there is a pinch-point in
 * this chute segment<br/>
 * Defaults to false<br/>
 * <br/>
 * Specification Field: narrow : boolean // true iff the chute is currently
 * narrow<br/>
 * <br/>
 * Specification Field: editable : boolean // true iff the player can edit the
 * width of the chute<br/>
 * <br/>
 * Specification Field: UID: integer // the unique identifier for this chute<br/>
 * <br/>
 * Specification Field: active : boolean // true iff this can be part of a
 * structure that is still under construction. once active is set to false, this
 * becomes immutable.<br/>
 * <br/>
 * Except in corner cases, pinch --> narrow. This is not, however, enforced.<br/>
 * <br/>
 * I toyed with the idea of requiring that editable is true to change things
 * like narrow or pinch, but editable really determines whether it can be
 * changed by the player in the game, and not whether this object is mutable or
 * not.
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
    * creates a new Chute object, with the given values for name, pinch, and
    * editable
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
    * Returns name, or null if none exists
    */
   @Pure
   public @Nullable String getName()
   {
      return name;
   }
   
   /**
    * Returns pinch<br/>
    * <br/>
    * Defaults to false
    */
   public boolean isPinched()
   {
      return pinch;
   }
   
   /**
    * Sets the specification field pinch to the value of the parameter<br/>
    * <br/>
    * Requires: active<br/>
    * <br/>
    * Modifies: this
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
    * Returns narrow
    */
   public boolean isNarrow()
   {
      return narrow;
   }
   
   /**
    * Sets the specification field narrow to parameter narrow<br/>
    * <br/>
    * Requires: active<br/>
    * <br/>
    * Modifies: this
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
    * Returns the auxiliary chutes associated with this Chute. Structural
    * changes to the returned list will not affect this object.
    */
   public List<Chute> getAuxiliaryChutes()
   {
      return new ArrayList<Chute>(auxiliaryChutes);
   }
   
   /**
    * Returns editable
    */
   public boolean isEditable()
   {
      return editable;
   }
   
   
   
   /**
    * Returns UID
    */
   public int getUID()
   {
      return UID;
   }
   
   /**
    * Returns a deep copy of this Chute.<br/>
    * <br/>
    * If this chute is attached to Intersections, that information will not be
    * copied.
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
    * Returns an iterator that performs a preorder traversal of the auxiliary
    * chutes tree. Does not include this.
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
