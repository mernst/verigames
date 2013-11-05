package verigames.level;

import verigames.utilities.Misc;

import java.io.*;
import java.util.*;

/**
 * Provides a high level method that takes a {@link World} object and returns a
 * mapping from variable ID to a boolean indicating whether that chute is
 * narrow.
 * <p>
 * Once the game is played, this allows the information about chute width (and
 * therefore the associated type annotations) to be extracted.
 *
 * @author Nathaniel Mote
 */
public class GameResults {

  /**
   * @see #chuteWidth(World)
   */
  public static Map<Integer, Boolean> chuteWidth( final InputStream in ) {
    final World w = new WorldXMLParser().parse(in);
    return chuteWidth(w);
  }

  /**
   * Processes the given {@link World} and returns information about the widths
   * of {@code Chute}s.
   *
   * @param w
   * The {@code World} to process. All chutes with a given variableID in {@code
   * w} must have the same width.
   *
   * @return
   * {@code Map<Integer, Boolean>}, where the {@code Integer} is the variableID
   * associated with some number of {@code Chute}s, and the {@code Boolean} is
   * {@code true} if the chutes with that variableID are <b>narrow</b>.
   */
  public static Map<Integer, Boolean> chuteWidth(World w) {
    Set<Chute> chutes = getChutes(w);

    final Map<Integer, ForcedWidths> widths = new LinkedHashMap<Integer, ForcedWidths>();

    for (final Chute chute : chutes) {
      int varID = chute.getVariableID();
      boolean isNarrow = chute.isNarrow();

      if (varID >= 0)  {
        // if this variableID is already in the mapping, just check that it's
        // not contradictory
        final ForcedWidths width;
        if (widths.containsKey(varID)) {
          width = widths.get( varID );
          //throw new IllegalArgumentException(String.format("Chutes with variableID %d have conflicting widths", varID));
        }
        // else, add it to the mapping
        else {
          width = new ForcedWidths( varID );
          widths.put(varID, width);
        }

        width.addChute( chute );
      }
    }

    boolean conflicted = false;
    for(final Map.Entry<Integer, ForcedWidths> idToFw : widths.entrySet() ) {
      if( idToFw.getValue().isWidthConflicted() ) {
        conflicted = true;
        System.out.println( idToFw.getValue() );
      }
    }

    if( Misc.CHECK_REP_STRICT && conflicted ) {
      throw new RuntimeException( "There are variables with conflictingWidths." );
    }

    final Map<Integer, Boolean> idToWidth = new HashMap<Integer, Boolean>();
    for(final Map.Entry<Integer, ForcedWidths> idToFw : widths.entrySet() ) {
      idToWidth.put( idToFw.getKey(), idToFw.getValue().isNarrow() );
    }

    return Collections.unmodifiableMap(idToWidth);
  }

  private static Set<Chute> getChutes(World w) {
    final Set<Chute> chutes = new LinkedHashSet<Chute>();

    for (Level l : w.getLevels().values()) {
      for (Board b : l.getBoards().values()) {
        chutes.addAll(b.getEdges());
      }
    }

    return Collections.unmodifiableSet(chutes);
  }

  /**
   * A class for keeping track of whether or not for a single variable there are conflicts between
   * chutes that represent that variable.
   */
  static class ForcedWidths {

    /**
     * Variable id for this width
     */
    private final int id;

    /**
     * Does the given variable have an EDITABLE chute that is wide
     */
    private boolean wide;

    /**
     * Does the given variable have an editable chute that is narrow
     */
    private boolean narrow;


    /**
     * Does the given variable have an UNEDITABLE chute that is wide
     */
    private boolean forcedNarrow;

    /**
     * Does the given variable have an UNEDITABLE chute that is narrow
     */
    private boolean forcedWide;

    public ForcedWidths( final int id ) {
      this.id = id;
      forcedNarrow = false;
      forcedWide   = false;
      wide   = false;
      narrow = false;
    }

    /**
     * Whether there is a conflict between UNEDITABLE chutes
     * @return
     */
    public boolean isForceConflicted() {
      return forcedNarrow && forcedWide;
    }

    /**
     * Whether there is a conflict between EDITABLE chutes
     * @return
     */
    private boolean isConflicted() {
      return wide && narrow;
    }

    /**
     * Whether there are ANY conflicts between editable/uneditable widths
     * @return
     */
    private boolean isWidthConflicted() {
      return ( wide && forcedNarrow ) || ( narrow && forcedWide ) || isForceConflicted() || isConflicted();
    }

    /**
     * Return the preferred width even if there are conflicts.
     * @return
     */
    public boolean isNarrow() {
      final boolean isNarrow;
      if( isForceConflicted() ) {
        isNarrow = false;
      } else if( isConflicted() ) {
        if( forcedWide ) {
          isNarrow = false;
        } else if( forcedNarrow ) {
          isNarrow = true;
        } else {
          isNarrow = false;
        }
      } else {
        isNarrow = narrow;
      }

      return isNarrow;
    }

    /**
     * Update this ForcedWidth with the information from the given chute.
     * @param chute
     */
    public void addChute( final Chute chute ) {
      if( chute.isEditable() ) {
        if( chute.isNarrow() ) {
          narrow = true;
        } else {
          wide = true;
        }
      } else {
        if( chute.isNarrow() ) {
          forcedNarrow = true;
        } else {
          forcedWide = true;
        }
      }
    }

    @Override
    public String toString() {
      return ( isWidthConflicted() ? "Conflicted " : "" ) +
          "ForcedWidths( id=" + id + " narrow=" + narrow + " wide=" + wide +
          " forcedNarrow=" + forcedNarrow + " forcedWide=" + forcedWide + " )";
    }
  }
}
