package verigames.optimizer;

import verigames.level.Chute;
import verigames.level.Intersection;
import verigames.level.World;
import verigames.optimizer.model.Node;
import verigames.optimizer.model.NodeGraph;
import verigames.optimizer.model.Port;
import verigames.optimizer.model.Subgraph;

import java.util.ArrayList;
import java.util.HashSet;
import java.util.Map;
import java.util.Set;

public class Optimizer {

    public void optimize(NodeGraph g) {
        removeIsolatedComponents(g);
        compressConnectors(g);

        // TODO: remove all small ball drops?
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

    /**
     * Remove isolated, immutable components from the graph. If
     * every chute in a component is immutable, then the user
     * probably doesn't care about it.
     * @param g the graph to modify
     */
    public void removeIsolatedComponents(NodeGraph g) {
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

    /**
     * Remove useless one-input to one-output connectors in the
     * graph.
     * @param g the graph to modify
     */
    public void compressConnectors(NodeGraph g) {
        // remove a lot of "connect" intersections
        // Note: the new ArrayList is because we remove nodes from the graph as we go,
        // and getNodes just returns a view of the nodes in the graph. We want to
        // avoid concurrent modifications.
        for (Node node : new ArrayList<>(g.getNodes())) {
            if (node.getIntersection().getIntersectionKind() == Intersection.Kind.CONNECT) {
                // for this node kind: one incoming edge, one outgoing edge
                NodeGraph.Edge incomingEdge = Util.first(g.incomingEdges(node));
                NodeGraph.Target outgoingEdge = Util.first(g.outgoingEdges(node).values());

                Chute incomingChute = incomingEdge.getEdgeData();
                Chute outgoingChute = outgoingEdge.getEdgeData();

                // if either edge belongs to an edge set, we can't remove this
                if (g.edgeSet(incomingEdge).size() > 1 || g.edgeSet(outgoingEdge).size() > 1) {
                    continue;
                }

                // if the edges are different widths, we have to think really hard about how to merge them
                boolean narrow = incomingChute.isNarrow();
                if (incomingChute.isNarrow() != outgoingChute.isNarrow()) {
                    if (incomingChute.isEditable())          // if we can edit the incoming chute...
                        narrow = outgoingChute.isNarrow();   //     ... then make it match the outgoing one
                    else if (outgoingChute.isEditable())     // if we can edit the outgoing chute...
                        narrow = incomingChute.isNarrow();   //     ... then make it match the incoming one
                    else if (incomingChute.isNarrow() && !outgoingChute.isNarrow()) // if the edges are immutable and narrow flows to wide
                        narrow = true;                       //     ... then make it narrow
                    else                                     // if the edges are immutable and wide flows to narrow
                        continue;                            //     ... then we're out of luck
                }

                Util.logVerbose("*** REMOVING USELESS CONNECTOR");

                // remove the node
                g.removeNode(node);

                // add an edge where it used to be
                Chute newChute = new Chute(outgoingChute.getVariableID(), outgoingChute.getDescription());
                newChute.setBuzzsaw(incomingChute.hasBuzzsaw() || outgoingChute.hasBuzzsaw());
                if (outgoingChute.getLayout() != null)
                    newChute.setLayout(outgoingChute.getLayout());
                newChute.setNarrow(narrow);
                newChute.setEditable(incomingChute.isEditable() && outgoingChute.isEditable());
                newChute.setPinched(incomingChute.isPinched() || outgoingChute.isPinched());
                g.addEdge(
                        incomingEdge.getSrc(), incomingEdge.getSrcPort(),
                        outgoingEdge.getDst(), outgoingEdge.getDstPort(),
                        newChute);
            }
        }
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
        System.err.println("Starting optimization: " + g.getNodes().size() + " nodes, " + g.getEdges().size() + " edges");
        optimize(g);
        System.err.println("Finished optimization: " + g.getNodes().size() + " nodes, " + g.getEdges().size() + " edges");
        return g.toWorld();
    }

}
