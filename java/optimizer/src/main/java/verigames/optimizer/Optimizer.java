package verigames.optimizer;

import verigames.level.World;
import verigames.optimizer.model.NodeGraph;
import verigames.optimizer.passes.BallDropElimination;
import verigames.optimizer.passes.ChuteEndElimination;
import verigames.optimizer.passes.ConnectorCompression;
import verigames.optimizer.passes.ImmutableComponentElimination;
import verigames.optimizer.passes.MergeElimination;
import verigames.optimizer.passes.SplitElimination;

import java.util.Arrays;
import java.util.List;

public class Optimizer {

    // This ordering is based on some knowledge of what passes help others,
    // as well as a good deal of trial and error.
    public static final List<OptimizationPass> DEFAULT_PASSES = Arrays.asList(
            new BallDropElimination(),
            new MergeElimination(),
            new ChuteEndElimination(),
            new SplitElimination(),
            new ConnectorCompression(),
            new ImmutableComponentElimination());

    public static final int DEFAULT_MAX_ITERATIONS = 20;

    public void optimize(NodeGraph g) {
        optimize(g, DEFAULT_PASSES);
    }

    public void optimize(NodeGraph g, List<OptimizationPass> passes) {
        optimize(g, passes, DEFAULT_MAX_ITERATIONS);
    }

    public void optimize(NodeGraph g, List<OptimizationPass> passes, int maxIterations) {
        int nodes = g.getNodes().size();
        int edges = g.getEdges().size();
        for (int i = 0; i < maxIterations; ++i) {
            for (OptimizationPass pass : passes) {
                pass.optimize(g);
            }
            // stop early when we stop making progress
            if (g.getNodes().size() >= nodes && g.getEdges().size() >= edges)
                break;
            nodes = g.getNodes().size();
            edges = g.getEdges().size();
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
