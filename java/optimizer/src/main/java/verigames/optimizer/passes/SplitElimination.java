package verigames.optimizer.passes;

import verigames.level.Intersection;
import verigames.optimizer.OptimizationPass;
import verigames.optimizer.Util;
import verigames.optimizer.model.Edge;
import verigames.optimizer.model.Node;
import verigames.optimizer.model.NodeGraph;
import verigames.optimizer.model.Port;
import verigames.optimizer.model.ReverseMapping;

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
    public void optimize(NodeGraph g, ReverseMapping mapping) {

        // wrap the nodes in a new array list to avoid concurrent modification
        // of a list we are iterating over
        for (Node n : new ArrayList<>(g.getNodes())) {
            if (n.getIntersection().getIntersectionKind() == Intersection.Kind.SPLIT) {
                List<Edge> outgoing = new ArrayList<>(g.outgoingEdges(n));

                // expect 2 outputs and 1 input
                Edge e1 = outgoing.get(0);
                Edge e2 = outgoing.get(1);
                Edge src = Util.first(g.incomingEdges(n));

                Node connector = Util.newNodeOnSameBoard(n, Intersection.Kind.CONNECT);

                int e1VarId = e1.getEdgeData().getVariableID();
                int e2VarId = e2.getEdgeData().getVariableID();
                int srcVarId = src.getEdgeData().getVariableID();

                // If either node is an END node, we can remove this
                // split and the END and place a connector instead.
                if (e1.getDst().getIntersection().getIntersectionKind() == Intersection.Kind.END &&
                        (Util.conflictFree(g, e1) || e1VarId == srcVarId)) {
                    g.removeNode(e1.getDst());
                    g.removeNode(n);
                    g.addNode(connector);
                    g.addEdge(src.getSrc(), src.getSrcPort(), connector, Port.INPUT, e2.getEdgeData());
                    g.addEdge(connector, Port.OUTPUT, e2.getDst(), e2.getDstPort(), e2.getEdgeData());

                    // If the removed edge belongs to the same edge set as the src, then
                    // we're ok. Otherwise it needs to be made wide.
                    if (e1VarId != srcVarId) {
                        mapping.forceWide(e1);
                    }
                } else if (e2.getDst().getIntersection().getIntersectionKind() == Intersection.Kind.END &&
                        (Util.conflictFree(g, e2) || e2VarId == srcVarId)) {
                    g.removeNode(e2.getDst());
                    g.removeNode(n);
                    g.addNode(connector);
                    g.addEdge(src.getSrc(), src.getSrcPort(), connector, Port.INPUT, e1.getEdgeData());
                    g.addEdge(connector, Port.OUTPUT, e1.getDst(), e1.getDstPort(), e1.getEdgeData());

                    // If the removed edge belongs to the same edge set as the src, then
                    // we're ok. Otherwise it needs to be made wide.
                    if (e2VarId != srcVarId) {
                        mapping.forceWide(e2);
                    }
                }
            }
        }

    }

}
