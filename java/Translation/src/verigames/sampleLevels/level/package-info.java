/**
 * Contains code that generates a {@link verigames.level.World World}
 * hand-translated from the source in the {@link verigames.level} package.
 * <p>
 * Based on the code at changeset 594f3ec9f9d4
 * <p>
 * This translation does not keep with our current translation strategy. Since
 * this translation was made, we have made the following changes to the way we
 * represent code in game:
 *
 * <ul>
 * <li>
 * We will have a chute for {@code this}. For the nullness game, the chute can
 * be implicit -- it is always nonnull. However, for some other games, {@code
 * this}'s type may be changeable.
 * </li>
 * <li>
 * We will represent field accesses as accessor calls, and auto-generate
 * accessor boards for every non-private field. When I made this translation,
 * field accesses were a little bit hand-wavy, and their translation sometimes
 * involved some reasoning. This will fix that problem.
 * </li>
 * <li>
 * Because of the previous point, all dereferences are now represented as method
 * calls. Therefore, since all dereferences are coupled with a subnetwork, we
 * can simply encode the requirement that the receiver be non-null the same as
 * we would with any other method argument. Any large ball in the receiver chute
 * flowing into a method call will get blocked because the method call will
 * require that the ball be small. This will result in the removal of all pinch
 * points (at least in the nullness game)
 * </li>
 * </ul>
 *
 * @author Nathaniel Mote
 */

package verigames.sampleLevels.level;
