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
 * If the layout tool hangs, it most likely means that dot is not exiting
 * properly.
 * <hr/>
 * Implementation notes:
 * <p>
 * The layout is performed in a somewhat unusual way, due to the specific
 * requirements of this problem.
 * <p>
 * The algorithm makes two layout passes -- one where the nodes are assigned
 * coordinates, and one where the edge paths are found.
 * <p>
 * The reason for this is essentially that when the node layout requirements are
 * expressed in the DOT language, the resulting layout has essentially garbage
 * edge paths. This is because there is a requirement that nodes are a certain
 * distance from each other, depending on the type of the node. The most precise
 * way to express htis requirement is to simply represent each node as a
 * rectangle. The top left corner is then considered the node's position. The
 * width and height encode the minimum distance to the right and to the bottom,
 * respectively, that another node can be from it.
 * <p>
 * However, in the game, nodes are essentially discrete points. Edges must start
 * and end exactly at the positions of their nodes. However, in the layout
 * above, edges start and end at the edges of the rectangles (it is also
 * possible to make them start and end at the center of the rectangles, but that
 * doesn't solve the problem -- the node coordinates are considered to be the
 * top left). Because of this, we use the node positions determined in the first
 * pass and run Graphviz again, expressing the nodes differently. Then, we
 * harvest the edge spline control points.
 * <p>
 * If it is necessary to tweak the way the layout algorithm performs, there are
 * several places where it is possible:
 * <p>
 * The first is through the input that dot is given. This is controlled by
 * {@link GraphvizPrinter}, and its subclasses {@link EdgeLayoutPrinter} and
 * {@link NodeLayoutPrinter}. What it prints can drastically change the layout,
 * as this determines the behavior of Graphviz itself.
 * <p>
 * The attributes that can be included are described <a
 * href="http://www.graphviz.org/content/attrs">here</a>.
 * <p>
 * The second is to change what is done with dot's output. This is done in
 * {@link layout.BoardLayout}.
 * <p>
 * If more information is needed from the Graphviz output, three things must be
 * done. First, {@link GraphInformation} must be updated to store the required
 * data. Second, {@link DotParser} must be updated to parse the required
 * information and store it to {@code GraphInformation}. Then, {@link
 * BoardLayout} must be updated to use the new information.
 */

package layout;
