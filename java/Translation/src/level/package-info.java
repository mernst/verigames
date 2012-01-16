/**
 * Provides data structures for programmatically creating levels for Pipe Jam.
 *
 * <h4>Expected Use:</h4>
 * The expected use follows. The following model for translation is suited for a
 * line-by-line translation fo the code into the game. However, if a different
 * translation strategy is used, this model may not be ideal, and others may be
 * considered. For example, it may make sense to remove the one-to-one relation
 * between {@code Board}s and Java methods.
 * <p>
 * A {@link level.World World} represents a single game for Pipe Jam. No two
 * Worlds can be dependent on each other; any two worlds can be solved in
 * isolation. A {@code World} represents, typically, one Java project. 
 * <p>
 * Each {@code World} contains an arbitrary number of {@link level.Level
 * Level}s. {@code Level}s can be dependent on one another. Each level
 * represents a class in a Java project.
 * <p>
 * Each {@code Level} contains an arbitrary number of {@link level.Board}s.
 * {@code Board}s can be dependent both on other {@code Board}s in the same
 * {@code Level} and on {@code Board}s in other {@code Level}s in the same
 * {@code World}. A {@code Board} represents a method. A {@code Board} is
 * essentially a DAG with {@link level.Chute Chute}s as edges and {@link
 * level.Intersection Intersection}s.
 * <p>
 * A {@code Chute}, loosely, represents a type. The term "loosely" is used
 * because a single {@code Chute} can represent the type for more than one
 * variable, and the type of a single variable is also typically represented as
 * more than just one {@code Chute}.
 * <p>
 * An {@code Intersection} is the terminating point for a {@code Chute}.
 * Typically, it is no more than that, though in the cases of {@link
 * level.Subnetwork Subnetwork} and {@link level.NullTest NullTest}, more
 * meaning is carried.
 * <p>
 * Every {@code Board} has two special {@code Intersection}s: The incoming one
 * and the outgoing one.
 * <p>
 * The incoming node should be connected to chutes representing the types of all
 * of the fields and all of the parameters.
 * <br/>
 * Likewise, the outgoing node should be the ending node for the chutes
 * representing the types of the fields and the return type.
 */

package level;
