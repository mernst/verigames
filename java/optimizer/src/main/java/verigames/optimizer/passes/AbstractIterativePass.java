package verigames.optimizer.passes;

import verigames.optimizer.OptimizationPass;
import verigames.optimizer.model.Node;
import verigames.optimizer.model.NodeGraph;
import verigames.optimizer.model.ReverseMapping;

import java.util.ArrayList;
import java.util.Collection;
import java.util.Collections;
import java.util.HashSet;
import java.util.Set;

/**
 * Abstract class for passes that collect a number of nodes to eliminate and
 * iterate until they reach a fixed point.
 */
public abstract class AbstractIterativePass implements OptimizationPass {

    /**
     * Determine whether a particular node should be marked for removal on
     * this iteration.
     * @param g     the graph
     * @param node  the node to be considered
     * @param alreadyRemoved the set of nodes already marked for removal
     * @return      true to mark the given node for removal
     */
    public abstract boolean shouldRemove(NodeGraph g, Node node, Set<Node> alreadyRemoved);

    /**
     * Called after all nodes are removed from the graph. The graph may now
     * require some fixing to make it legal again.
     * @param g           the graph to fix
     * @param brokenEdges the edges from the original graph where one node was removed but not the other
     * @param mapping     the reverse mapping to update
     */
    public void fixup(NodeGraph g, Collection<NodeGraph.Edge> brokenEdges, ReverseMapping mapping) { }

    @Override
    public void optimize(NodeGraph g, ReverseMapping mapping) {

        Set<Node> toRemove = Collections.emptySet();

        boolean shouldContinue;

        do {
            Set<Node> toRemove2 = new HashSet<>();

            for (Node n : g.getNodes()) {
                if (toRemove.contains(n)) {
                    toRemove2.add(n);
                    continue;
                }
                if (shouldRemove(g, n, toRemove)) {
                    toRemove2.add(n);
                }
            }

            shouldContinue = !toRemove.equals(toRemove2);
            toRemove = toRemove2;
        } while (shouldContinue);

        Collection<NodeGraph.Edge> brokenEdges = new ArrayList<>();
        for (NodeGraph.Edge e : g.getEdges()) {
            if (toRemove.contains(e.getSrc()) != toRemove.contains(e.getDst()))
                brokenEdges.add(e);
        }

        g.removeNodes(toRemove);
        fixup(g, brokenEdges, mapping);
    }
}
