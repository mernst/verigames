package verigames.optimizer.passes;

import verigames.level.Intersection;
import verigames.optimizer.OptimizationPass;
import verigames.optimizer.Util;
import verigames.optimizer.model.Edge;
import verigames.optimizer.model.EdgeData;
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
                    g.addEdge(node, Port.OUTPUT, Util.newNodeOnSameBoard(node, Intersection.Kind.END), Port.INPUT, EdgeData.WIDE);
                }

                // for this node kind: one incoming edge, one outgoing edge
                Edge incomingEdge = Util.first(g.incomingEdges(node));
                Edge outgoingEdge = Util.first(g.outgoingEdges(node));

                compressChutes(node, incomingEdge, outgoingEdge, g, mapping);
            }
        }
    }

    /**
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
    public Edge compressChutes(Node connector, Edge incoming, Edge outgoing, NodeGraph g, ReverseMapping mapping) {
        EdgeData newChute = compressChutes(incoming, outgoing, g);
        if (newChute == null)
            return null;

        // remove the node
        assert outgoing.getSrc().equals(connector);
        assert connector.getIntersection().getIntersectionKind() == Intersection.Kind.CONNECT;
        g.removeNode(connector);

        // add an edge where it used to be
        Edge result = g.addEdge(
                incoming.getSrc(), incoming.getSrcPort(),
                outgoing.getDst(), outgoing.getDstPort(),
                newChute);

        // map the old chutes to the new one
        if (newChute.isEditable()) {
            mapping.mapEdge(incoming, result);
            mapping.mapEdge(outgoing, result);
        } else {
            // Delicate note: it IS IMPORTANT that we check these edges are
            // conflict free before mapping them. This is because narrow
            // immutable chutes always consume an edge, even if it is not
            // conflict free, and we do NOT want to force an entire edge
            // set to be narrow just because one of its edges was deemed
            // useless. Put another way, if an edge is not conflict free,
            // then we don't want to force its whole edge set to a particular
            // value. To remove it, we must have already shown that it can't
            // create any conflicts no matter what it is set to.
            if (Util.conflictFree(g, incoming))
                mapping.forceNarrow(incoming, newChute.isNarrow());
            if (Util.conflictFree(g, outgoing))
                mapping.forceNarrow(outgoing, newChute.isNarrow());
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
    public EdgeData compressChutes(Edge incomingChute, Edge outgoingChute, NodeGraph context) {
        if (context.areLinked(incomingChute, outgoingChute)) {
            return compressLinkedChutes(incomingChute, outgoingChute);
        }
        if (!incomingChute.isEditable() && !outgoingChute.isEditable()) {
            return EdgeData.createImmutable(incomingChute.isNarrow() || outgoingChute.isNarrow());
        }
        if (Util.forcedNarrow(incomingChute) || Util.forcedNarrow(outgoingChute)) {
            return EdgeData.NARROW;
        }
        boolean incConflictFree = Util.conflictFree(context, incomingChute);
        boolean outConflictFree = Util.conflictFree(context, outgoingChute);
        if (incConflictFree && outConflictFree) {
            return EdgeData.WIDE;
        } else if (incConflictFree || outConflictFree) {
            return compressChutes(incomingChute, outgoingChute, incConflictFree);
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
     * @return the data for the new edge
     */
    public EdgeData compressLinkedChutes(Edge incomingChute, Edge outgoingChute) {
        return EdgeData.createMutable(
                incomingChute.getVariableID(),
                "compressed chute");
    }

    /**
     * Construct a new chute by compressing two chutes into one.
     * <p>
     * Precondition: one of the chutes is conflict-free, and the other is mutable
     * @param incomingChute    flows into outgoingChute
     * @param outgoingChute    incomingChute flows into this
     * @param incConflictFree  true if the incoming chute is conflict-free, false if the outgoing chute is
     * @return the compressed chute
     */
    public EdgeData compressChutes(Edge incomingChute, Edge outgoingChute, boolean incConflictFree) {
        return EdgeData.createMutable(
                incConflictFree ? outgoingChute.getVariableID() : incomingChute.getVariableID(),
                "compressed chute");
    }

}
