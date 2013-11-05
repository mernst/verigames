package verigames.optimizer;

import verigames.level.World;
import verigames.optimizer.model.NodeGraph;
import verigames.optimizer.passes.BallDropElimination;
import verigames.optimizer.passes.ConnectorCompression;
import verigames.optimizer.passes.ImmutableComponentElimination;
import verigames.optimizer.passes.MergeElimination;

import java.util.Arrays;
import java.util.List;

public class Optimizer {

    public static final List<OptimizationPass> DEFAULT_PASSES = Arrays.asList(
            new BallDropElimination(),
            new MergeElimination(),
            new ConnectorCompression(),
            new ImmutableComponentElimination());

    public void optimize(NodeGraph g) {
        optimize(g, DEFAULT_PASSES);
    }

    public void optimize(NodeGraph g, List<OptimizationPass> passes) {
        for (OptimizationPass pass : passes) {
            pass.optimize(g);
        }
    }

    public World optimizeWorld(World source) {
        NodeGraph g = new NodeGraph(source);
        System.err.println("Starting optimization: " + g.getNodes().size() + " nodes, " + g.getEdges().size() + " edges");
        optimize(g);
        System.err.println("Finished optimization: " + g.getNodes().size() + " nodes, " + g.getEdges().size() + " edges");
        return g.toWorld();
    }

}
