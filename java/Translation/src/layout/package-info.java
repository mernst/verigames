/**
 * Contains classes that add layout information to a board using Graphviz.
 * <p>
 * The layout tools all require that Graphviz be installed on the system. In
 * particular, the "dot" tool (one of Graphviz's layout algorithms) must be
 * invokable from the command line.
 * <p>
 * On a modern machine, the layout tool should be able to lay out a moderately
 * sized world (~50 boards) in no more than a second. This time should increase
 * linearly with the number of boards, because laying out each board is a
 * discrete task.
 * <p>
 * If the layout tool hangs, it could mean that dot is not exiting properly.
 * <p>
 * If it is necessary to tweak the way the layout algorithm performs, there are
 * several places where it is possible:
 * <p>
 * The first is through the input that dot is given. This is controlled by
 * {@link DotPrinter}. What it prints can drastically change the layout. The
 * attributes that can be included are described <a
 * href="http://www.graphviz.org/content/attrs">here</a>.
 * <p>
 * The second is to change what is done with dot's output. This can either
 * happen in {@link DotParser} or in {@link BoardLayout}.
 */

package layout;
