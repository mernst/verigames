package verigames.level;

import static verigames.utilities.Misc.ensure;

import java.util.*;

/*>>>
import checkers.nullness.quals.*;
*/

/**
 * A mutable level for Pipe Jam. A {@code Level} consists of any number of
 * {@link Board}s, each associated with a unique name.  * <p>
 *
 * A {@code Level} also keeps track of which {@link Chute}s in the contained
 * {@code Board}s are linked (see below).  * <p>
 *
 * Specification Field: {@code linkedEdgeClasses} : {@code Set<Set<Chute>>} //
 * Contains equivalence classes of {@code Chute}s, as defined by the following
 * equivalence relation * <p>
 *
 * Let R be the maximal equivalence relation on the set of all {@code Chute}s
 * such that:<br/> aRb --> a and b necessarily have the same width. That is,
 * when a changes width, b must follow, and vice-versa.  * <p>
 *
 * Specification Field: {@code boards} : {@code Set<Board>} // represents the
 * set of all boards in this level * <p>
 *
 * Specification Field: {@code boardNames} : {@code Map<String, Board>} // maps
 * the name of a method to its {@code Board} * <p>
 *
 * Specification Field: {@code underConstruction} : {@code boolean} // {@code
 * true} iff {@code this} can still be modified. Once {@code underConstruction}
 * is set to {@code false}, {@code this} becomes immutable.
 *
 * @author Nathaniel Mote
 */

public class Level
{
  /**
   * Deprecated. This functionality will be represented implicitly by the
   * variableID of chutes, the linked chute sets will be generated upon XML
   * printing.<p>
   *
   * Now that makeLinked is removed, we should consider updating the
   * implementation to not include this.
   */
  @Deprecated
  private final Set<Set<Chute>> linkedEdgeClasses;

  /**
   * Stores linked varIDs. All {@link Chute}s with varIDs listed in the same
   * {@code Set} will be linked, meaning that in the game they must change width
   * together.
   */
  private final Set<Set<Integer>> linkedVarIDs;

  private final Map<String, Board> boardNames;
  private final Map<String, StubBoard> stubBoardNames;

  /**
   * Contains information about which pipes can be stamped with the colors of
   * which other pipes in the game. It is a map from variableID to a set of
   * variableIDs with which it can be stamped.<p>
   *
   * This is for map.get in the nullness type system. For any given pipe, this
   * indicates which other pipes it can be stamped with. This is equivalent to
   * saying that for any given variable, this indicates what variables could
   * potentially be keys for it. Obviously, only when the key is a variableID
   * belonging to a Map object will the corresponding set be non-empty.
   */
  private final Map<Integer, Set<Integer>> stampSets;

  private boolean underConstruction = true;

  private static final boolean CHECK_REP_ENABLED =
      verigames.utilities.Misc.CHECK_REP_ENABLED;

  /**
   * Enforces the Representation Invariant
   */
  private void checkRep()
  {
    // Representation Invariant:
    if (!CHECK_REP_ENABLED)
      return;

    Set<Chute> encountered = new HashSet<Chute>();
    for (Set<Chute> s : linkedEdgeClasses)
    {
      /*
       * No set in linkedEdgeClasses may be empty
       *
       * No set in linkedEdgeClasses may have size 1 (the fact that a chute
       * is linked to itself need not be represented)
       */
      ensure(s.size() > 1, "(internal error) linked edge set exists of size 1");

      // No chute can be contained in more than one set in
      // linkedEdgeClasses
      for (Chute c : s)
      {
        ensure(!encountered.contains(c), "(internal error) Chute " + c +
            " is present in multiple linked edge sets");
        encountered.add(c);
      }
    }

    /*
     * If this is constructed, all chutes contained in sets contained in
     * linkedEdgeClasses must also be contained by some Board in
     * boardNames.values()
     */
    if (!this.underConstruction())
    {
      Set<Chute> containedInBoards = new HashSet<Chute>();
      for (Board b : boardNames.values())
      {
        for (Chute c : b.getEdges())
          containedInBoards.add(c);
      }

      // make sure that the chutes in linkedEdgeClasses are a subset of the
      // chutes in boardNames
      ensure(containedInBoards.containsAll(encountered),
          "A Chute in a linked edge set is not contained in any Board" +
          " in this level");
    }
  }

  /**
   * Creates a new {@code Level} with an empty {@code linkedEdgeClasses},
   * {@code boards}, and {@code boardNames}
   */
  public Level()
  {
    linkedEdgeClasses = new LinkedHashSet<Set<Chute>>();
    linkedVarIDs = new LinkedHashSet<Set<Integer>>();
    boardNames = new LinkedHashMap<String, Board>();
    stubBoardNames = new LinkedHashMap<String, StubBoard>();
    stampSets = new LinkedHashMap<Integer, Set<Integer>>();
    checkRep();
  }

  /**
   * Links all {@link Chute}s with the given variable IDs.<p>
   */
  // TODO should this be varargs or take a set? Or is linking two at once good
  // enough?
  public void linkByVarID(int var1, int var2)
  {
    link(linkedVarIDs, new LinkedHashSet<Integer>(Arrays.asList(var1, var2)));
  }

  public boolean areVarIDsLinked(int var1, int var2)
  {
    if (var1 == var2)
      return true;

    for (Set<Integer> s : linkedVarIDs)
    {
      if (s.contains(var1) && s.contains(var2))
        return true;
    }
    return false;
  }

  private static <T> void link(Set<Set<T>> linkedClasses, Set<T> toLink)
  {
    if (toLink.size() > 1)
    {
      /*
       * Contains the sets that should be removed from linkedClasses
       * because they will be deprecated by the newly created equivalence
       * class
       */
      Set<Set<T>> toRemove = new LinkedHashSet<Set<T>>();

      /*
       * The new equivalence class to be added to linkedClasses. It will
       * at least have all of the elements in toLink.
       */
      Set<T> newEquivClass = new LinkedHashSet<T>(toLink);

      for (Set<T> linked : linkedClasses)
      {
        for (T c : toLink)
        {
          if (linked.contains(c))
          {
            toRemove.add(linked);
            newEquivClass.addAll(linked);
          }
        }
      }

      linkedClasses.removeAll(toRemove);

      linkedClasses.add(newEquivClass);
    }
  }

  /**
   * Adds the pipe identified by {@code stamp} to the list of "colors" with
   * which the pipe identified by {@code pipe} can be stamped.<p>
   *
   * It is extremely important not to mix up the order of the parameters. To be
   * clear, the first pipe will be able to be stamped by the color belonging to
   * the second pipe. The first receives the {@code @KeyFor} annotation in the
   * nullness type system.
   */
  public void addPossibleStamping(int pipe, int stamp)
  {
    if (stampSets.containsKey(pipe))
    {
      stampSets.get(pipe).add(stamp);
    }
    else
    {
      Set<Integer> set = new LinkedHashSet<Integer>();
      set.add(stamp);
      stampSets.put(pipe, set);
    }
  }

  /**
   * Returns a copy of {@code linkedEdgeClasses}. Structurally modifying the
   * returned {@code Set}, or any of the {@code Set}s it contains, will have
   * no effect on {@code this}.<p>
   *
   * @deprecated This has been replaced by an implicit representation of chute
   * links. Now, any chutes with the same variableID are considered linked, and
   * a client can figure this out without an explicit representation.
   */
  // protected because most clients shouldn't need this -- areLinked should be
  // adequate. However, if this turns out to be untrue, access may be
  // increased.
  @Deprecated
  protected Set<Set<Chute>> linkedEdgeClasses()
  {
    final Set<Set<Chute>> copy = new LinkedHashSet<Set<Chute>>();

    for (Set<Chute> linkedChutes : linkedEdgeClasses)
    {
      copy.add(new LinkedHashSet<Chute>(linkedChutes));
    }

    return copy;
  }


  /**
   * Adds {@code b} to {@code boards}, and adds the mapping from {@code name}
   * to {@code b} to {@code boardNames}<br/>
   * <br/>
   * Modifies: {@code this}<br/>
   *
   * @param b
   * The {@link Board} to add to {@code boards}. Must not be contained in
   * {@code boards}
   * @param name
   * The name to associate with {@code b}. Must not be contained in
   * {@code boardNames.keySet()}
   */
  public void addBoard(String name, Board b)
  {
    if (this.contains(name))
      throw new IllegalArgumentException("name \"" + name + "\" already in use");
    // the following check is pretty expensive, but probably worth it.
    if (boardNames.containsValue(b))
      throw new IllegalArgumentException("Board " + b + " already contained");
    boardNames.put(name, b);
    checkRep();
  }

  public void addStubBoard(String name, StubBoard b)
  {
    if (this.contains(name))
      throw new IllegalArgumentException("name \"" + name + "\" already in use");
    if (stubBoardNames.containsValue(b))
      throw new IllegalArgumentException("StubBoard " + b + " already contained");
    stubBoardNames.put(name, b);
    checkRep();
  }

  /**
   * Return an unmodifiable {@code Map} view on {@code boardNames}. The
   * returned {@code Map} is backed by {@code this}, so changes in {@code
   * this} will be reflected in the returned {@code Map}.
   */
  public Map<String, Board> getBoards()
  {
    return Collections.unmodifiableMap(boardNames);
  }

  /**
   * Returns the {@code Board} to which {@code name} maps in {@code
   * boardNames}, or {@code null} if it maps to nothing
   */
  public/* @Nullable */Board getBoard(String name)
  {
    return boardNames.get(name);
  }

  public Map<String, StubBoard> getStubBoards()
  {
    return Collections.unmodifiableMap(stubBoardNames);
  }

  public /* @Nullable */ StubBoard getStubBoard(String name)
  {
    return stubBoardNames.get(name);
  }

  /**
   * Returns {@code true} if and only if this {@code Level} contains a {@link
   * Board} or a {@link StubBoard} by the given name.
   */
  public boolean contains(String name)
  {
    return boardNames.containsKey(name) || stubBoardNames.containsKey(name);
  }

  /**
   * Returns {@code underConstruction}
   */
  public boolean underConstruction()
  {
    return underConstruction;
  }

  /**
   * Sets {@code underConstruction} to {@code false}, finishes construction on
   * all contained {@link Board}s<br/>
   * <br/>
   * Requires:<br/>
   * - {@link #underConstruction() this.underConstruction()}<br/>
   * - all {@code Board}s in {@code boards} are in a state in which they can
   *   finish construction
   * - All chutes that have been linked must have the same width.
   */
  public void finishConstruction()
  {
    if (!underConstruction)
      throw new IllegalStateException("Mutation attempted on constructed Level");

    linkChutesWithLinkedID();

    underConstruction = false;

    /* Make sure that all chutes that are linked to each other have the same
     * width.
     *
     * If one chute is uneditable, all will become uneditable.
     *
     */
    for (Set<Chute> linkedChutes : linkedEdgeClasses)
    {
        Boolean isNarrow = null;
        boolean fixedNarrow = false;
        boolean fixedWide   = false;
        boolean conflictingChutes = false;

        for (Chute c : linkedChutes)
        {
            if (isNarrow == null)
            {
                isNarrow = c.isNarrow();
            }

            if( !c.isEditable() ) {
                if( c.isNarrow() ) {
                    fixedNarrow = true;
                } else {
                    fixedWide   = true;
                }
            }

            if (fixedNarrow && fixedWide) {
                conflictingChutes = true;
                break;
            }
        }

        if( conflictingChutes ) {
            if( verigames.utilities.Misc.CHECK_REP_STRICT ) {
                String chutes = "";
                for( Chute c : linkedChutes ) {
                    chutes += c + ", ";
                }
                throw new RuntimeException("Linked chutes with conflicting widths: " + chutes);
            }
        }

        if( fixedNarrow || !fixedWide ) {
            for( Chute c : linkedChutes ) {
                c.setNarrow( true );
                if (fixedNarrow) {
                    c.setEditable(false);
                }
            }
        } else {
            for( Chute c : linkedChutes ) {
                c.setNarrow( false );
                if (fixedWide) {
                    c.setEditable(false);
                }
            }
        }
    }

    for (Board b : boardNames.values()) {
        b.finishConstruction();
    }
  }

  /**
   * Links all chutes with the same ID, as long as makeLinked has not been
   * called (if there are chutes already linked, it is assumed that the user
   * wants to manually link the chutes, so nothing is done).<p>
   *
   * Also links any chutes whose varIDs are linked (through linkByVarID).
   */
  private void linkChutesWithLinkedID()
  {
    Set<Chute> chutes = getAllChutes();

    // map from variable id to chutes with that variable ID
    Map<Integer, Set<Chute>> IDMap = new LinkedHashMap<Integer, Set<Chute>>();
    for (Chute c : chutes)
    {
      int varID = c.getVariableID();
      if (varID >= 0)
      {
        // Chutes with negative ID are special and should never be linked.
        if (IDMap.containsKey(varID))
        {
          IDMap.get(varID).add(c);
        }
        else
        {
          Set<Chute> set = new LinkedHashSet<Chute>();
          set.add(c);
          IDMap.put(c.getVariableID(), set);
        }
      }
    }

    // link all chutes that have had their variableIDs explicitly linked
    for (Set<Integer> linkedVarIDSet : linkedVarIDs)
    {
      Set<Chute> linkedChutes = new LinkedHashSet<>();
      for (int varID : linkedVarIDSet)
      {
        //TODO JB: IDENTIFY WHY THIS RETURNS NULL
        final Set<Chute> toLink = IDMap.get(varID);
        if( toLink != null ) {
          linkedChutes.addAll( toLink );
        }

        // we don't want to add this later
        IDMap.remove(varID);
      }

      linkedEdgeClasses.add(linkedChutes);
    }

    // link the remaining chutes (those that have not had their variableIDs
    // explicitly linked)
    for (Map.Entry<Integer, Set<Chute>> entry : IDMap.entrySet())
    {
      linkedEdgeClasses.add(entry.getValue());
    }
  }

  private Set<Chute> getAllChutes()
  {
    Set<Chute> chutes = new LinkedHashSet<Chute>();
    for (Board b : boardNames.values())
      chutes.addAll(b.getEdges());
    return chutes;
  }

  @Override
  public String toString()
  {
    return "Level: " + getBoards().keySet().toString();
  }
}
