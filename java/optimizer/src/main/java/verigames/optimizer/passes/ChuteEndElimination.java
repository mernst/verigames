package verigames.optimizer.passes;

import verigames.level.Intersection;
import verigames.optimizer.Util;
import verigames.optimizer.model.Edge;
import verigames.optimizer.model.EdgeData;
import verigames.optimizer.model.Node;
import verigames.optimizer.model.NodeGraph;
import verigames.optimizer.model.Port;
import verigames.optimizer.model.ReverseMapping;

import java.util.Collection;
import java.util.Set;

/**
 * Optimization pass that removes as many {@link Intersection.Kind#END}
 * nodes as possible.
 */
public class ChuteEndElimination extends AbstractIterativePass {

    @Override
    public boolean shouldRemove(NodeGraph g, Node node, Set<Node> alreadyRemoved) {
        Intersection i = node.getIntersection();
        Intersection.Kind kind = i.getIntersectionKind();

        // Remove end nodes when the incoming edge is conflict-free.
        if (kind == Intersection.Kind.END && Util.conflictFree(g, Util.first(g.incomingEdges(node)))) {
            return true;
        }

        // Remove a node if all of its outgoing chutes are conflict free and
        // all outgoing nodes are eliminated.
        // Intuition: if all outgoing chutes are wide and eliminated, then all
        // balls dropped out of this node will flow successfully to an END.
        Collection<Edge> outgoing = g.outgoingEdges(node);
        if (outgoing.size() > 0 && kind != Intersection.Kind.INCOMING) {
            boolean canEliminate = true;
            for (Edge e : outgoing) {
                if (!alreadyRemoved.contains(e.getDst()) || !Util.conflictFree(g, e)) {
                    canEliminate = false;
                    break;
                }
            }
            if (canEliminate) {
                return true;
            }
        }

        return false;
    }

    @Override
    public void fixup(NodeGraph g, Collection<Edge> brokenEdges, ReverseMapping mapping) {
        for (Edge e : brokenEdges) {
            Node src = e.getSrc();

            // for all removed mutable edges, force them to be wide
            if (e.getEdgeData().isEditable()) {
                mapping.forceWide(e);
            }

            // we should only have edges with missing targets, or something has gone very wrong
            assert g.getNodes().contains(src);
            assert !g.getNodes().contains(e.getDst());

            // Arbitrarily, create an immutable wide chute to drop into. We could just as easily
            // create a mutable narrow one or something, but immutable wide chutes are easier to
            // reason about.
            Node n = Util.newNodeOnSameBoard(src, Intersection.Kind.END);
            g.addNode(n);
            g.addEdge(e.getSrc(), e.getSrcPort(), n, Port.INPUT, EdgeData.WIDE);
        }
    }

}
