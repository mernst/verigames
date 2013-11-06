package verigames.optimizer.passes;

import verigames.level.Chute;
import verigames.level.Intersection;
import verigames.optimizer.Util;
import verigames.optimizer.model.Node;
import verigames.optimizer.model.NodeGraph;
import verigames.optimizer.model.Port;

import java.util.Collection;
import java.util.Set;

/**
 * Small ball drops (and no-ball drops) are often useless to the user, since they
 * don't create jams. This pass removes as many as possible.
 *
 * In addition, this pass converts empty ball drops into small ball drops. These are
 * effectively equivalent (they never create jams) and are more fun to look at. This
 * also means that subsequent optimizations have one less node type to worry about.
 */
public class BallDropElimination extends AbstractIterativePass {

    @Override
    public boolean shouldRemove(NodeGraph g, Node node, Set<Node> alreadyRemoved) {
        Intersection i = node.getIntersection();
        Intersection.Kind kind = i.getIntersectionKind();

        // Remove small starts and no-ball starts.
        if (kind == Intersection.Kind.START_SMALL_BALL || kind == Intersection.Kind.START_NO_BALL) {
            return true;
        }

        // Remove a node if all of its incoming edges are eliminated.
        // Intuition: if all incoming edges are eliminated, then only small
        // balls could flow there, and there can't be any conflicts.
        Collection<NodeGraph.Edge> incoming = g.incomingEdges(node);
        if (incoming.size() > 0 && kind != Intersection.Kind.OUTGOING) {
            boolean allSourcesBeingRemoved = true;
            for (NodeGraph.Edge e : incoming) {
                if (!alreadyRemoved.contains(e.getSrc())) {
                    allSourcesBeingRemoved = false;
                    break;
                }
            }
            if (allSourcesBeingRemoved) {
                return true;
            }
        }

        return false;
    }

    @Override
    public void fixup(NodeGraph g, Collection<NodeGraph.Edge> brokenEdges) {
        for (NodeGraph.Edge e : brokenEdges) {
            Node dst = e.getDst();

            // we should only have edges with missing sources, or something has gone very wrong
            assert !g.getNodes().contains(e.getSrc());
            assert g.getNodes().contains(dst);

            // Arbitrarily, create an immutable wide chute to drop into. We could just as easily
            // create a mutable narrow one or something, but immutable wide chutes are easier to
            // reason about.
            Chute chute = new Chute();
            chute.setNarrow(false);
            chute.setEditable(false);
            Node n = Util.newNodeOnSameBoard(dst, Intersection.Kind.START_SMALL_BALL);
            g.addNode(n);
            g.addEdge(n, Port.OUTPUT, dst, e.getDstPort(), chute);
        }
    }

}
