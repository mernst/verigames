package verigames.optimizer;

import verigames.level.World;
import verigames.optimizer.model.Node;
import verigames.optimizer.model.NodeGraph;
import verigames.optimizer.model.Port;

import java.util.HashSet;
import java.util.Map;
import java.util.Set;

public class Optimizer {

    public void optimize(NodeGraph g) {
        // TODO: optimization 1: remove immutable getComponents
//        for (Subgraph subgraph : g.getComponents()) {
//            boolean mutable = false;
//            for (NodeGraph.Edge edge : subgraph.getEdges()) {
//                mutable = edge.getEdgeData().isEditable();
//                if (mutable)
//                    break;
//            }
//            if (!mutable) {
//                g.removeSubgraph(subgraph);
//            }
//        }

        // TODO: optimization 2: remove all small ball drops
//        Collection<Node> smallBallStarts = new ArrayList<>();
//        for (Node node : g.getNodes()) {
//            if (node.getIntersection().getIntersectionKind() == Intersection.Kind.START_SMALL_BALL) {
//                smallBallStarts.add(node);
//            }
//        }
//
//        for (Node node : smallBallStarts) {
//            Collection<Node> toRemove = removeSource(g, node);
//            if (toRemove != null) {
//                g.removeNodes(toRemove);
//            }
//        }
    }

    private Set<Node> removeSource(NodeGraph g, Node node) {
        Set<Node> toRemove = new HashSet<>();
        toRemove.add(node);
        // for each outgoing edge
        for (Map.Entry<Port, NodeGraph.Target> edge : g.outgoingEdges(node).entrySet()) {
            Port port = edge.getKey();
            NodeGraph.Target target = edge.getValue();
            if (target.getDst().getIntersection().getIntersectionKind().getNumberOfInputPorts() == 1) {
                // EITHER the edge connects to a single-input node which we can also remove
                Set<Node> subNodes = removeSource(g, target.getDst());
                if (subNodes != null)
                    toRemove.addAll(subNodes);
                else
                    return null;
            } else if (target.getDst().getIntersection().getIntersectionKind().getNumberOfInputPorts() < 0) {
                // OR it connects to a variable-input node and we can remove the edge
                // TODO: remove the edge
            } else {
                return null;
            }
        }
        return toRemove;
    }

    public World optimizeWorld(World source) {
        NodeGraph g = new NodeGraph(source);
        System.out.println("Starting optimization: " + g.getNodes().size() + " nodes, " + g.getEdges().size() + " edges");
        optimize(g);
        System.out.println("Finished optimization: " + g.getNodes().size() + " nodes, " + g.getEdges().size() + " edges");
        return g.toWorld();
    }

}
