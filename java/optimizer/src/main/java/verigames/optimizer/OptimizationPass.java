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
     * simplification should hopefully reduce the complexity of the graph in
     * some way. It can assume that the graph represents a valid world, and it
     * should always continue to be a valid world after optimization.
     *
     * @param g the graph to simplify
     */
    public void optimize(NodeGraph g);

}
