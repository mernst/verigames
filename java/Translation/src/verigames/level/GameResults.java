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

    ChuteNormalizer norm = new ChuteNormalizer(chutes);
    return Collections.unmodifiableMap(norm.getWidths());
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
}
