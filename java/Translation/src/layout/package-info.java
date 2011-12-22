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
 * <h2>Implementation notes:</h2>
 * <p>
 * <h3>Units:</h3>
 * <p>
 * There are three different units used to represent coordinates and distances
 * in this package. The first unit is the "game unit." This is the unit used in
 * the game, and the origin is at the top-left of the board, with y coordinates
 * growing downward.
 * <p>
 * The second is the inch. Graphviz uses inches for some measurements, and for
 * convenience, this package equates a game unit with an inch. However, a
 * measurement expressed in inches typically has the origin at the bottom-left
 * of the board, with y coordinates growing upward, reflecting the style of
 * Graphviz.
 * <p>
 * The third is the typographical point, which is equal to 1/72nd of an inch.
 * For some reason, Graphviz uses points in some places and inches in others.
 * For example, dimensions are expressed in inches, while positions are
 * expressed in points. Typically, positions in points also have the origin at
 * the bottom-left, with y coordinates growing upward.
 * <p>
 * <h3>Layout algorithm:</h3>
 * <p>
 * The layout is performed in a somewhat unusual way, due to the specific
 * requirements of this problem, which are documented in world.dtd at the top
 * level of this repository.
 * <p>
 * The algorithm makes two layout passes -- one where the nodes are assigned
 * coordinates, and one where the edge paths are found.
 * <p>
 * The reason for this is the way the code enforces the game's requirement that
 * nodes be a certain distance apart. Graphviz does not have a way to express
 * this requirement directly, so instead the first layout pass uses unnaturally
 * large nodes, where the width and height of a node encode the minimum distance
 * to the right and to the bottom, respectively, that another node can be from
 * it. The top left corner is then considered the node's position. This produces
 * a node layout that satisfies the game's requirements, but the resulting
 * layout has essentially garbage edge paths. This is because there is a
 * requirement that nodes be a certain distance from each other, depending on
 * the type of the node. The most precise way to express this requirement is to
 * simply represent each node as a rectangle.
 * <p>
 * However, in the game, most nodes are discrete points. They simply indicate
 * where one or more edges terminate, and typically have no graphical
 * representation beyond that (some nodes are an exception to this, but they are
 * less common). Edges must start and end exactly at the positions of their
 * nodes. However, in the layout above, edges start and end at the edges of the
 * rectangles (it is also possible to make them start and end at the center of
 * the rectangles, but that doesn't solve the problem -- the node coordinates
 * are considered to be the top left).
 * <p>
 * Because of this, we run Graphviz a second time. This time, the node positions
 * from the first pass are used, and Graphviz is instructed not to change them.
 * Most nodes are effectively discrete points (though they are not always
 * represented that way -- see {@link layout.NodeLayoutPrinter} for details),
 * with edges going from node to node. So, given the node positions, Graphviz
 * simply lays out the edges, and the spline control points are harvested.
 * <p>
 * <h3>Making changes:</h3>
 * <p>
 * If it is necessary to tweak the way the layout algorithm performs, there are
 * two ways to do so.
 * <p>
 * <ol>
 * <li>
 * The first is through the input that Graphviz is given. This is controlled by
 * {@link layout.GraphvizPrinter}, and its subclasses {@link
 * layout.EdgeLayoutPrinter} and {@link layout.NodeLayoutPrinter}. What it
 * prints can drastically change the layout, as this determines the behavior of
 * Graphviz itself.
 * <p>
 * The attributes that can be included are described <a
 * href="http://www.graphviz.org/content/attrs">here</a>.
 * </li>
 * <p>
 * <li>
 * The second is to change what is done with Graphviz's output. This is done in
 * {@link layout.BoardLayout}.
 * <p>
 * If more information is needed from the Graphviz output, three things must be
 * done. First, {@link layout.GraphInformation} must be updated to store the
 * required data. Second, {@link layout.DotParser} must be updated to parse the
 * required information and store it to {@code GraphInformation}. Then, {@link
 * layout.BoardLayout} must be updated to use the new information.
 * </li>
 * </ol>
 */

package layout;
