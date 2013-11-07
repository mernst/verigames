package verigames.optimizer.passes;

import verigames.level.Chute;
import verigames.level.Intersection;
import verigames.optimizer.OptimizationPass;
import verigames.optimizer.Util;
import verigames.optimizer.model.Node;
import verigames.optimizer.model.NodeGraph;
import verigames.optimizer.model.Port;
import verigames.optimizer.model.ReverseMapping;

import java.util.ArrayList;
import java.util.Collection;

/**
 * Remove useless one-input to one-output connectors in the graph.
 */
public class ConnectorCompression implements OptimizationPass {

    @Override
    public void optimize(NodeGraph g, ReverseMapping mapping) {
        // remove a lot of "connect" intersections
        // Note: the new ArrayList is because we remove nodes from the graph as we go,
        // and getNodes just returns a view of the nodes in the graph. We want to
        // avoid concurrent modifications.
        for (Node node : new ArrayList<>(g.getNodes())) {
            if (node.getIntersection().getIntersectionKind() == Intersection.Kind.CONNECT) {

                // HACK: fixes boards with dangling connectors
                if (g.outgoingEdges(node).size() == 0) {
                    Chute c = Util.immutableChute();
                    c.setNarrow(false);
                    g.addEdge(node, Port.OUTPUT, Util.newNodeOnSameBoard(node, Intersection.Kind.END), Port.INPUT, c);
                }

                // for this node kind: one incoming edge, one outgoing edge
                NodeGraph.Edge incomingEdge = Util.first(g.incomingEdges(node));
                NodeGraph.Target outgoingEdge = Util.first(g.outgoingEdges(node).values());

                Chute incomingChute = incomingEdge.getEdgeData();
                Chute outgoingChute = outgoingEdge.getEdgeData();
                Chute newChute = compressChutes(incomingChute, outgoingChute, g);
                if (newChute == null)
                    continue;

                // remove the node
                g.removeNode(node);

                // add an edge where it used to be
                g.addEdge(
                        incomingEdge.getSrc(), incomingEdge.getSrcPort(),
                        outgoingEdge.getDst(), outgoingEdge.getDstPort(),
                        newChute);

                // map the old chutes to the new one
                mapping.mapEdge(incomingChute, newChute);
                mapping.mapEdge(outgoingChute, newChute);
            }
        }
    }

    /**
     * Just like {@link #compressChutes(verigames.level.Chute, verigames.level.Chute)},
     * but returns null if the preconditions are not met in the given graph.
     * @param incomingChute flows into outgoingChute
     * @param outgoingChute incomingChute flows into this
     * @param context       the world representation
     * @return the compressed chute, or null if they could not be compressed
     */
    public Chute compressChutes(Chute incomingChute, Chute outgoingChute, NodeGraph context) {
        if (incomingChute.getVariableID() == outgoingChute.getVariableID())
            return compressChutes(incomingChute, outgoingChute);
        Collection<NodeGraph.Edge> iEdgeSet = context.edgeSet(incomingChute.getVariableID());
        Collection<NodeGraph.Edge> oEdgeSet = context.edgeSet(outgoingChute.getVariableID());
        if (iEdgeSet.size() <= 1 && oEdgeSet.size() <= 1)
            return compressChutes(incomingChute, outgoingChute);
        return null;
    }

    /**
     * Compress two chutes into one. (NOTE: the variable ID for the resulting
     * chute will be -1 and it will have no description).
     * <p>
     * Precondition: one of the following must hold:
     * <ul>
     *     <li>both chutes belong to the same edge set or</li>
     *     <li>both chutes are the sole members of their respective edge sets</li>
     * </ul>
     * @param incomingChute flows into outgoingChute
     * @param outgoingChute incomingChute flows into this
     * @return the compressed chute
     */
    public Chute compressChutes(Chute incomingChute, Chute outgoingChute) {

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
                narrow = true;                       //     ... then make it narrow (push conflict up a level)
        }

        // The result is editable if both are editable, or if one is editable and the other is wide.
        boolean editable =
                (incomingChute.isEditable() && outgoingChute.isEditable()) ||
                (incomingChute.isEditable() && !outgoingChute.isNarrow()) ||
                (outgoingChute.isEditable() && !incomingChute.isNarrow());

        Chute newChute = new Chute();
        newChute.setBuzzsaw(incomingChute.hasBuzzsaw() || outgoingChute.hasBuzzsaw());
        if (outgoingChute.getLayout() != null)
            newChute.setLayout(outgoingChute.getLayout());
        newChute.setNarrow(narrow);
        newChute.setEditable(editable);

        // The result is pinched if either incoming chute was pinched and it
        // makes sense to pinch this chute. (It makes no sense to pinch a
        // narrow immutable edge).
        boolean pinched = (incomingChute.isPinched() || outgoingChute.isPinched()) && !(narrow && !editable);
        newChute.setPinched(pinched);

        return newChute;

    }

}
