package verigames.optimizer.passes;

import verigames.level.Chute;
import verigames.level.Intersection;
import verigames.optimizer.OptimizationPass;
import verigames.optimizer.Util;
import verigames.optimizer.model.Node;
import verigames.optimizer.model.NodeGraph;

import java.util.ArrayList;
import java.util.Collection;

/**
 * Remove useless one-input to one-output connectors in the graph.
 */
public class ConnectorCompression implements OptimizationPass {
    @Override
    public void optimize(NodeGraph g) {
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

                // if either edge belongs to an edge set, we can't merge them
                Collection<NodeGraph.Edge> iEdgeSet = g.edgeSet(incomingEdge);
                Collection<NodeGraph.Edge> oEdgeSet = g.edgeSet(outgoingEdge);
                if ((iEdgeSet.size() > 1 || oEdgeSet.size() > 1) &&
                        // however, if both edges are part of the same set, we can merge them!
                        !(incomingChute.getVariableID() == outgoingChute.getVariableID())) {
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
}
