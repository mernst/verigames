package verigames.optimizer.passes;

import verigames.level.Intersection;
import verigames.optimizer.OptimizationPass;
import verigames.optimizer.Util;
import verigames.optimizer.model.Node;
import verigames.optimizer.model.NodeGraph;
import verigames.optimizer.model.Subgraph;

/**
 * Remove isolated, immutable components from the graph. If
 * every chute in a component is immutable, then the user
 * probably doesn't care about it.
 */
public class ImmutableComponentElimination implements OptimizationPass {
    @Override
    public void optimize(NodeGraph g) {
        for (Subgraph subgraph : g.getComponents()) {
            boolean mutable = false;
            for (NodeGraph.Edge edge : subgraph.getEdges()) {
                mutable = edge.getEdgeData().isEditable();
                if (mutable)
                    break;
            }
            boolean hasFixedNode = false;
            for (Node node : subgraph.getNodes()) {
                Intersection.Kind kind = node.getIntersection().getIntersectionKind();
                hasFixedNode = (kind == Intersection.Kind.INCOMING || kind == Intersection.Kind.OUTGOING);
                if (hasFixedNode)
                    break;
            }
            if (!mutable && !hasFixedNode) {
                Util.logVerbose("*** REMOVING IMMUTABLE SUBGRAPH (" + subgraph.getNodes().size() + " nodes, " + subgraph.getEdges().size() + " edges)");
                g.removeSubgraph(subgraph);
            }
        }
    }
}
