package verigames.layout;

import verigames.level.*;
import verigames.level.Intersection.Kind;

/**
 * A class containing miscellaneous methods useful for layout.
 */
class Misc
{
  // TODO add documentation and add support for GET nodes
  protected static double getIntersectionHeight(Kind kind)
  {
    if (!usesPorts(kind))
      return 0;
    else if (kind == Kind.SUBBOARD)
      return 1.46;
    else if (kind == Kind.INCOMING || kind == Kind.OUTGOING)
      return 0;
    else
      return 1;
  }

  /**
   * Returns true iff the given {@link Kind} of {@link Intersection} has its
   * ports represented explicitly when it is printed to DOT.
   * <p>
   * Most {@code Intersection}s don't need the port information expressed,
   * because they are essentially points. However, some are larger, and need to
   * have chutes connected to different parts of them, so they have their ports
   * represented explicitly.
   */
  protected static boolean usesPorts(Kind k)
  {
    return k == Kind.INCOMING || k == Kind.OUTGOING || k == Kind.SUBBOARD;
  }
}
