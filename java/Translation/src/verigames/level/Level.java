package verigames.level;

import static verigames.utilities.Misc.ensure;

import java.io.PrintStream;
import java.util.Arrays;
import java.util.Collections;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
import java.util.Map;
import java.util.Set;

import verigames.level.Intersection.Kind;


/**
 * A mutable level for Pipe Jam. A {@code Level} consists of any number of
 * {@link Board}s, each associated with a unique name.
 * <p>
 * A {@code Level} also keeps track of which {@link Chute}s in the contained
 * {@code Board}s are linked (see below).
 * <p>
 * Specification Field: {@code linkedEdgeClasses} : {@code Set<Set<Chute>>}
 * // Contains equivalence classes of {@code Chute}s, as defined by the
 * following equivalence relation
 * <p>
 * Let R be the maximal equivalence relation on the set of all {@code Chute}s
 * such that:<br/>
 * aRb --> a and b necessarily have the same width. That is, when a changes
 * width, b must follow, and vice-versa.
 * <p>
 * Specification Field: {@code boards} : {@code Set<Board>}
 * // represents the set of all boards in this level
 * <p>
 * Specification Field: {@code boardNames} : {@code Map<String, Board>}
 * // maps the name of a method to its {@code Board}
 * <p>
 * Specification Field: {@code underConstruction} : {@code boolean} // {@code true} iff
 * {@code this} can still be modified. Once {@code underConstruction} is set to
 * {@code false}, {@code this} becomes immutable.
 *
 * @author Nathaniel Mote
 */

public class Level
{
  private final Set<Set<Chute>> linkedEdgeClasses;

  // TODO change String, if necessary, to whatever we end up using
  private final Map<String, Board> boardNames;

  private boolean underConstruction = true;

  private static final boolean CHECK_REP_ENABLED = verigames.utilities.Misc.CHECK_REP_ENABLED;

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
      ensure(s.size() > 1);


      // No chute can be contained in more than one set in
      // linkedEdgeClasses
      for (Chute c : s)
      {
        ensure(!encountered.contains(c));
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
      ensure(containedInBoards.containsAll(encountered));
    }

  }

  /**
   * Creates a new {@code Level} with an empty {@code linkedEdgeClasses},
   * {@code boards}, and {@code boardNames}
   */
  public Level()
  {
    linkedEdgeClasses = new LinkedHashSet<Set<Chute>>();
    boardNames = new LinkedHashMap<String, Board>();
    checkRep();
  }

  private boolean makeLinkedCalled = false;

  /**
   * Makes it so that the given {@link Chute}s are equivalent under the
   * relation R defined for {@code linkedEdgeClasses}. In other words, for all
   * a, b in {@code toLink}, aRb<br/>
   * <br/>
   * Requires: every {@code Chute} in {@code toLink} must be contained in a
   * {@link Board} in {@code boards}<br/>
   * <br/>
   * Modifies: {@code this}<br/>
   * <br/>
   * Runs in O(m*n) time, where m is {@code linkedEdgeClasses.size()} and n is
   * {@code toLink.length}
   *
   * @param toLink
   * The {@code Chute}s to make equivalent under the equivalence relation R
   *
   * @see #makeLinked(Set)
   */
  @Deprecated
  public void makeLinked(Chute... toLink)
  {
    makeLinkedCalled = true;
    if (toLink.length > 1)
    {
      /*
       * Contains the sets that should be removed from linkedEdgeClasses
       * because they will be deprecated by the newly created equivalence
       * class
       */
      Set<Set<Chute>> toRemove = new LinkedHashSet<Set<Chute>>();

      /*
       * The new equivalence class to be added to linkedEdgeClasses. It will
       * at least have all of the elements in toLink.
       */
      Set<Chute> newEquivClass = new LinkedHashSet<Chute>(
          Arrays.asList(toLink));

      for (Set<Chute> linked : linkedEdgeClasses)
      {
        for (Chute c : toLink)
        {
          if (linked.contains(c))
          {
            toRemove.add(linked);
            newEquivClass.addAll(linked);
          }
        }
      }

      linkedEdgeClasses.removeAll(toRemove);

      linkedEdgeClasses.add(newEquivClass);
      checkRep();
    }
  }

  /**
   * Functions identically to {@link #makeLinked(Chute...)}, except the
   * elements to link are specified by a {@code Set} instead of an array
   *
   * @param toLink
   * @see #makeLinked(Chute...)
   */
  @Deprecated
  public void makeLinked(Set<Chute> toLink)
  {
    makeLinked(toLink.toArray(new Chute[0]));
  }

  /**
   * Returns {@code true} iff all of the {@code Chute}s in {@code chutes} are linked.
   * @param chutes
   */
  @Deprecated
  public boolean areLinked(Set<Chute> chutes)
  {
    // A single chute is always linked to itself
    if (chutes.size() == 1)
      return true;

    for (Set<Chute> s : linkedEdgeClasses)
    {
      if (s.containsAll(chutes))
        return true;
    }
    return false;
  }

  /**
   * Returns a copy of {@code linkedEdgeClasses}. Structurally modifying the
   * returned {@code Set}, or any of the {@code Set}s it contains, will have
   * no effect on {@code this}.
   */
  // protected because most clients shouldn't need this -- areLinked should be
  // adequate. However, if this turns out to be untrue, access may be
  // increased.
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
    if (boardNames.containsKey(name))
      throw new IllegalArgumentException("name \"" + name + "\" already in use");
    if (boardNames.containsValue(b))
      throw new IllegalArgumentException("Board " + b + " already contained");
    boardNames.put(name, b);
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

    /* TODO THIS IS A HACK -- FIX IT. Really, makeLinked should be deprecated or
     * removed, and a different data structure should be used.*/
    linkChutesWithSameID();

    underConstruction = false;
    for (Board b : boardNames.values())
      b.finishConstruction();

    /* Make sure that all chutes that are linked to each other have the same
     * width. */
    for (Set<Chute> linkedChutes : linkedEdgeClasses)
    {
      Boolean isNarrow = null;

      /* This is kept so that a detailed error message explaining which chutes
       * differ can be printed if there is an error. */
      Chute initialChute = null;
      for (Chute c : linkedChutes)
      {
        if (isNarrow == null)
        {
          isNarrow = c.isNarrow();
          initialChute = c;
        }

        if (c.isNarrow() != isNarrow)
          throw new IllegalStateException(
              "Two linked chutes have different widths: " +
              initialChute + " and " + c);
      }
    }
  }

  /**
   * Links all chutes with the same ID, as long as makeLinked has not been
   * called (if there are chutes already linked, it is assumed that the user
   * wants to manually link the chutes, so nothing is done).
   */
  private void linkChutesWithSameID()
  {
    if (makeLinkedCalled)
      return;

    Set<Chute> chutes = getAllChutes();

    // map from variable id to chute
    Map<Integer, Set<Chute>> IDMap = new LinkedHashMap<Integer, Set<Chute>>();
    for (Chute c : chutes)
    {
      int varID = c.getVariableID();
      if (IDMap.containsKey(varID))
        IDMap.get(varID).add(c);
      else
      {
        Set<Chute> set = new LinkedHashSet<Chute>();
        set.add(c);
        IDMap.put(c.getVariableID(), set);
      }
    }

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
