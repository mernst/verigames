package verigames.optimizer.model;

/**
 * Thrown by {@link ReverseMapping#solutionForUnoptimized(NodeGraph, NodeGraph, Solution)}
 * when the mapping does not seem to describe the given worlds.
 */
public class MismatchException extends Exception {

    public MismatchException(String message) {
        super(message);
    }

}
