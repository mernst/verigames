package level;

import java.util.ArrayList;
import java.util.List;

import checkers.nullness.quals.AssertNonNullAfter;
import checkers.nullness.quals.LazyNonNull;
import checkers.nullness.quals.Nullable;

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
 * <br/>
 * Specification Field: narrow : boolean // true iff the chute is currently
 * narrow<br/>
 * <br/>
 * Specification Field: editable : boolean // true iff the player can edit the
 * width of the chute<br/>
 * <br/>
 * Specification Field: UID: integer // the unique odd identifier for this chute<br/>
 * <br/>
 * The UID of a Chute is odd, while the UID of an Intersection is even. This is
 * to reduce confusion for humans reading the generated XML<br/>
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

public class Chute
{
   // TODO change String to whatever we end up using
   private final @Nullable String name;
   
   private List<Chute> auxiliaryChutes;
   
   private @LazyNonNull Intersection start;
   private int startPort = -1;
   private @LazyNonNull Intersection end;
   private int endPort = -1;
   
   private final boolean pinch; // whether a chute has a pinch-point is a fact
                                // of the original code, and cannot be modified
                                // in-game
   private boolean narrow;
   private final boolean editable;
   
   private boolean active = true;
   
   private final int UID;
   
   private static int nextUID = 1;
   
   /*
    * Representation Invariant:
    * 
    * If !active, start and end must be non-null, and startPort and endPort must
    * not equal -1
    */
   
   private static final boolean CHECK_REP_ENABLED = true;
   
   private void checkRep()
   {
      if (CHECK_REP_ENABLED)
      {
         if (!active)
         {
            ensure(start != null);
            ensure(end != null);
            ensure(startPort != -1);
            ensure(endPort != -1);
         }
      }
   }
   
   /**
    * Intended to be a substitute for assert, except I don't want to have to
    * make sure the -ea flag is turned on in order to get these checks.
    */
   private void ensure(boolean value)
   {
      if (!value)
         throw new AssertionError();
   }
   
   /**
    * creates a new Chute object, with the given values for name, pinch, and
    * editable
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
      checkRep();
   }
   
   /**
    * Returns name, or null if none exists
    */
   public @Nullable String getName()
   {
      return name;
   }
   
   /**
    * Returns pinch
    */
   public boolean isPinched()
   {
      return pinch;
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
      if (!active)
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
    * Returns start, or null if end does not exist
    */
   public @Nullable Intersection getStart()
   {
      return start;
   }
   
   /**
    * Returns startPort<br/>
    * <br/>
    * Requires:<br/>
    * this chute has a "start" intersection
    */
   public int getStartPort()
   {
      if (start == null)
         throw new IllegalStateException();
      return startPort;
   }
   
   /**
    * Returns end, or null if end does not exist
    */
   public @Nullable Intersection getEnd()
   {
      return end;
   }
   
   /**
    * Returns endPort<br/>
    * <br/>
    * Requires:<br/>
    * this chute has an "end" intersection
    */
   public int getEndPort()
   {
      if (end == null)
         throw new IllegalStateException();
      return endPort;
   }
   
   /**
    * Requires: start != null; port is a valid port number for start Modifies:
    * this sets "start" to the given Intersection, replacing the old one, if
    * present
    */
   @AssertNonNullAfter({ "start" }) protected void setStart(Intersection start,
         int port)
   {
      if (!active)
         throw new IllegalStateException("Mutation attempted on inactive Chute");
      if (start == null)
         throw new IllegalArgumentException(
               "Chute.setStart passed a null argument");
      
      this.start = start;
      this.startPort = port;
      checkRep();
   }
   
   /**
    * Requires: start != null; port is a valid port number for start Modifies:
    * this sets "end" to the given Intersection, replacing the old one, if
    * present
    */
   @AssertNonNullAfter({ "end" }) protected void setEnd(Intersection end,
         int port)
   {
      if (!active)
         throw new IllegalStateException("Mutation attempted on inactive Chute");
      if (end == null)
         throw new IllegalArgumentException(
               "Chute.setEnd passed a null argument");
      
      this.end = end;
      this.endPort = port;
      checkRep();
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
    * Requires:<br/>
    * start == null;<br/>
    * end == null (this cannot be attached to Intersections)
    */
   public Chute copy()
   {
      if (start != null || end != null)
         throw new IllegalStateException(
               "Chute must not be attached to Intersections to be copied");
      List<Chute> copyAuxChutes = new ArrayList<Chute>();
      for (Chute c : auxiliaryChutes)
      {
         copyAuxChutes.add(c.copy());
      }
      
      Chute copy = new Chute(name, pinch, editable, copyAuxChutes);
      copy.setNarrow(narrow);
      
      return copy;
   }
   
   /**
    * Returns active
    */
   public boolean isActive()
   {
      return active;
   }
   
   /**
    * Sets active to false<br/>
    * <br/>
    * Requires:<br/>active;<br/>start and end Intersections exist
    */
   public void deactivate()
   {
      if (!active)
         throw new IllegalStateException("Mutation attempted on inactive Chute");
      active = false;
      checkRep();
   }
   
}
