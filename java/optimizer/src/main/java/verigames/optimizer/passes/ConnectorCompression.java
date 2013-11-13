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

                compressChutes(node, incomingEdge, outgoingEdge, g, mapping);
            }
        }
    }

    /**
     * The non-pure version of
     * {@link #compressChutes(verigames.level.Chute, verigames.level.Chute, verigames.optimizer.model.NodeGraph)}.
     * Modifies the given graph by actually compressing the edges and adds
     * appropriate mappings to the given {@link ReverseMapping}.
     *
     * <p>Precondition: incoming flows into connector node which flows
     * into outgoing.
     * @param connector the connector node
     * @param incoming  flows into the connector
     * @param outgoing  connector flows into this
     * @param g         [IN/OUT] the world representation
     * @param mapping   [OUT] the mapping to update
     * @return the new edge in g, or null if compression did not take place
     */
    public NodeGraph.Edge compressChutes(Node connector, NodeGraph.Edge incoming, NodeGraph.Edge outgoing, NodeGraph g, ReverseMapping mapping) {
        Chute newChute = compressChutes(incoming.getEdgeData(), outgoing.getEdgeData(), g);
        if (newChute == null)
            return null;

        // remove the node
        assert outgoing.getSrc().equals(connector);
        assert connector.getIntersection().getIntersectionKind() == Intersection.Kind.CONNECT;
        g.removeNode(connector);

        // add an edge where it used to be
        NodeGraph.Edge result = g.addEdge(
                incoming.getSrc(), incoming.getSrcPort(),
                outgoing.getDst(), outgoing.getDstPort(),
                newChute);

        // map the old chutes to the new one
        if (newChute.isEditable()) {
            assert newChute.getVariableID() >= 0;
            mapping.mapEdge(incoming.getEdgeData(), newChute);
            mapping.mapEdge(outgoing.getEdgeData(), newChute);
        } else {
            mapping.forceNarrow(incoming.getEdgeData(), newChute.isNarrow());
            mapping.forceNarrow(outgoing.getEdgeData(), newChute.isNarrow());
        }

        return result;
    }

    /**
     * Construct a new chute by compressing the given chutes in the given
     * graph and return the new chute (or null if the chutes could not be
     * compressed).
     * @param incomingChute flows into outgoingChute
     * @param outgoingChute incomingChute flows into this
     * @param context       the world representation
     * @return the compressed chute, or null if they could not be compressed
     */
    public Chute compressChutes(Chute incomingChute, Chute outgoingChute, NodeGraph context) {
        if (context.areLinked(incomingChute.getVariableID(), outgoingChute.getVariableID())) {
            return compressLinkedChutes(incomingChute, outgoingChute);
        }
        boolean incConflictFree = Util.conflictFree(context, incomingChute);
        boolean outConflictFree = Util.conflictFree(context, outgoingChute);
        if (incConflictFree && outConflictFree) {
            return compressUnconstrainedChutes(incomingChute, outgoingChute);
        } else if (incConflictFree || outConflictFree) {
            return compressChutes(incomingChute, outgoingChute, incConflictFree);
        } else if (Util.forcedNarrow(incomingChute) || Util.forcedNarrow(outgoingChute)) {
            Chute result = new Chute(-1, "compressed chute");
            result.setNarrow(true);
            result.setEditable(false);
            result.setBuzzsaw(incomingChute.hasBuzzsaw() || outgoingChute.hasBuzzsaw());
            return result;
        }
        return null;
    }

    /**
     * Construct a new chute by compressing two linked chutes into one.
     * <p>
     * Precondition: both chutes belong to the same edge set. (Which implies
     * that they must both be the same width and editable-ness.)
     * @param incomingChute flows into outgoingChute
     * @param outgoingChute incomingChute flows into this
     * @return the compressed chute
     */
    public Chute compressLinkedChutes(Chute incomingChute, Chute outgoingChute) {
        Chute result = incomingChute.copy(incomingChute.getVariableID(), "compressed chute");
        result.setBuzzsaw(incomingChute.hasBuzzsaw() || outgoingChute.hasBuzzsaw());
        return result;
    }

    /**
     * Construct a new chute by compressing two unconstrained chutes into one.
     * <p>
     * Precondition: both chutes are conflict-free.
     * @param incomingChute flows into outgoingChute
     * @param outgoingChute incomingChute flows into this
     * @return the compressed chute
     */
    public Chute compressUnconstrainedChutes(Chute incomingChute, Chute outgoingChute) {
        Chute result = new Chute(-1, "compressed chute");
        result.setEditable(false);
        result.setNarrow(false);
        result.setBuzzsaw(incomingChute.hasBuzzsaw() || outgoingChute.hasBuzzsaw());
        return result;
    }

    /**
     * Construct a new chute by compressing two chutes into one.
     * <p>
     * Precondition: one of the chutes is conflict-free
     * @param incomingChute    flows into outgoingChute
     * @param outgoingChute    incomingChute flows into this
     * @param incConflictFree  true if the incoming chute is conflict-free, false if the outgoing chute is
     * @return the compressed chute
     */
    public Chute compressChutes(Chute incomingChute, Chute outgoingChute, boolean incConflictFree) {
        Chute result = incConflictFree ?
                outgoingChute.copy(outgoingChute.getVariableID(), "compressed chute") :
                incomingChute.copy(incomingChute.getVariableID(), "compressed chute");
        result.setBuzzsaw(incomingChute.hasBuzzsaw() || outgoingChute.hasBuzzsaw());
        return result;
    }

}
