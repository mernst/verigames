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
                NodeGraph.Edge outgoingEdge = Util.first(g.outgoingEdges(node));

                compressChutes(incomingEdge, outgoingEdge, g, mapping);
            }
        }
    }

    /**
     * The non-pure version of
     * {@link #compressChutes(verigames.level.Chute, verigames.level.Chute, verigames.optimizer.model.NodeGraph)}.
     * Modifies the given graph by actually compressing the edges and adds
     * appropriate mappings to the given {@link ReverseMapping}.
     *
     * <p>Precondition: incoming flows into a connector node which flows
     * into outgoing.
     * @param incoming  flows into outgoingChute
     * @param outgoing  incomingChute flows into this
     * @param g         [IN/OUT] the world representation
     * @param mapping   [OUT] the mapping to update
     * @return the new edge in g, or null if compression did not take place
     */
    public NodeGraph.Edge compressChutes(NodeGraph.Edge incoming, NodeGraph.Edge outgoing, NodeGraph g, ReverseMapping mapping) {
        Chute newChute = compressChutes(incoming.getEdgeData(), outgoing.getEdgeData(), g);
        if (newChute == null)
            return null;

        // remove the node
        Node connector = incoming.getDst();
        assert outgoing.getSrc().equals(connector);
        assert connector.getIntersection().getIntersectionKind() == Intersection.Kind.CONNECT;
        g.removeNode(connector);

        // add an edge where it used to be
        NodeGraph.Edge result = g.addEdge(
                incoming.getSrc(), incoming.getSrcPort(),
                outgoing.getDst(), outgoing.getDstPort(),
                newChute);

        // map the old chutes to the new one
        mapping.mapEdge(incoming.getEdgeData(), newChute);
        mapping.mapEdge(outgoing.getEdgeData(), newChute);

        return result;
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
     * Compress two chutes into one.
     * <p>
     * Precondition: one of the following must hold:
     * <ul>
     *     <li>both chutes belong to the same edge set or</li>
     *     <li>both chutes are the sole members of their respective edge sets</li>
     * </ul>
     * (Note that if an edge is immutable, it is considered to be the sole
     * member of its edge set.)
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

        int varID = incomingChute.isEditable() ? incomingChute.getVariableID() : outgoingChute.getVariableID();
        Chute newChute = new Chute(varID, "compressed chute");
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
