package verigames.optimizer;

import verigames.optimizer.model.NodeGraph;

/**
 * Used by the {@link Optimizer}. Each pass does one very specific
 * job. The builtin passes live in the {@link verigames.optimizer.passes}
 * package.
 */
public interface OptimizationPass {

    /**
     * Simplify the graph. There isn't much of a contract here, but the
     * simplification must NOT increase the number of nodes or edges.
     * Subclasses can assume that the graph represents a valid world, and
     * they must preserve that property.
     *
     * @param g the graph to simplify
     */
    public void optimize(NodeGraph g);

}
