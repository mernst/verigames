package verigames.optimizer.passes;

import verigames.level.Board;
import verigames.level.Intersection;
import verigames.level.Level;
import verigames.optimizer.OptimizationPass;
import verigames.optimizer.Util;
import verigames.optimizer.model.Node;
import verigames.optimizer.model.NodeGraph;
import verigames.optimizer.model.Port;

import java.util.ArrayList;
import java.util.List;

/**
 * Eliminates split nodes in the following form:
 *
 * <pre>
 *     |             |
 *     |             |
 *     ^    ----->   O
 *   /   \           |
 * END    \          |
 * </pre>
 *
 * Where "^" is a split node, "O" is a connector, and the chute connecting to
 * the END node is either (1) immutable wide or (2) mutable and the sole
 * member of its edge set or (3) in the same edge set as the incoming edge.
 *
 * This happens occasionally in real worlds, but is also a relatively common
 * output case from the {@link ChuteEndElimination} optimization pass.
 */
public class SplitElimination implements OptimizationPass {
    @Override
    public void optimize(NodeGraph g) {

        // wrap the nodes in a new array list to avoid concurrent modification
        // of a list we are iterating over
        for (Node n : new ArrayList<>(g.getNodes())) {
            if (n.getIntersection().getIntersectionKind() == Intersection.Kind.SPLIT) {
                List<NodeGraph.Target> outgoing = new ArrayList<>(g.outgoingEdges(n).values());

                // expect 2 outputs and 1 input
                NodeGraph.Target e1 = outgoing.get(0);
                NodeGraph.Target e2 = outgoing.get(1);
                NodeGraph.Edge src = Util.first(g.incomingEdges(n));

                String levelName = n.getLevelName();
                Level level = n.getLevel();
                String boardName = n.getBoardName();
                Board board = n.getBoard();
                Intersection i = Intersection.factory(Intersection.Kind.CONNECT);
                Node connector = new Node(levelName, level, boardName, board, i);

                int e1VarID = e1.getEdgeData().getVariableID();
                int e2VarId = e2.getEdgeData().getVariableID();
                int srcVarId = src.getEdgeData().getVariableID();

                // If either node was a small ball drop, we need to remove this
                // merge and the drop and place a connector instead.
                if (e1.getDst().getIntersection().getIntersectionKind() == Intersection.Kind.END &&
                        (Util.conflictFree(g, e1) || e1VarID == srcVarId)) {
                    g.removeNode(e1.getDst());
                    g.removeNode(n);
                    g.addNode(connector);
                    g.addEdge(src.getSrc(), src.getSrcPort(), connector, Port.INPUT, e2.getEdgeData());
                    g.addEdge(connector, Port.OUTPUT, e2.getDst(), e2.getDstPort(), e2.getEdgeData());
                } else if (e2.getDst().getIntersection().getIntersectionKind() == Intersection.Kind.END &&
                        (Util.conflictFree(g, e2) || e2VarId == srcVarId)) {
                    g.removeNode(e2.getDst());
                    g.removeNode(n);
                    g.addNode(connector);
                    g.addEdge(src.getSrc(), src.getSrcPort(), connector, Port.INPUT, e1.getEdgeData());
                    g.addEdge(connector, Port.OUTPUT, e1.getDst(), e1.getDstPort(), e1.getEdgeData());
                }
            }
        }

    }

}
