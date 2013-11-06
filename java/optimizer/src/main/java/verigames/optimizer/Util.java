package verigames.optimizer;

import verigames.level.Board;
import verigames.level.Chute;
import verigames.level.Intersection;
import verigames.level.Level;
import verigames.optimizer.model.Node;
import verigames.optimizer.model.NodeGraph;

public class Util {

    /////////// Config
    private static boolean verbose = false;

    /**
     * Pick out the first element from a collection. On unordered collections
     * like HashSets, the result might be any element.
     * @param collection  the collection to pick from
     * @param <T>         the type of element in the collection
     * @throws java.util.NoSuchElementException if the collection is empty
     * @return            the first element of the collection
     */
    public static <T> T first(Iterable<T> collection) {
        return collection.iterator().next();
    }

    /**
     * Enable or disable the output of {@link #logVerbose(Object)}
     * @param v true to enable verbose logging, false to disable
     */
    public static void setVerbose(boolean v) {
        verbose = v;
    }

    /**
     * Log a message, but only if verbose mode is enabled
     * @param o the object to log
     * @see #setVerbose(boolean)
     */
    public static void logVerbose(Object o) {
        if (verbose)
            System.err.println(o);
    }

    public static Chute immutableChute() {
        Chute result = new Chute();
        result.setEditable(false);
        return result;
    }

    public static Chute mutableChute() {
        Chute result = new Chute();
        result.setEditable(true);
        return result;
    }

    /**
     * Determine if an edge is "conflict free" meaning that it cannot
     * contribute a conflict to the board. Specifically, an edge is
     * conflict free if it either (1) is immutable and wide or (2) is
     * mutable and the only member of its edge set.
     * @param g the graph containing the edge
     * @param chute the edge to consider
     * @return true if the edge is conflict free, or false otherwise
     */
    public static boolean conflictFree(NodeGraph g, Chute chute) {
        return (!chute.isEditable() && !chute.isNarrow()) || (chute.isEditable() && g.edgeSet(chute.getVariableID()).size() <= 1);
    }

    /**
     * Create a new node on the same board as "n". Note that this method does
     * NOT add the new node to any {@link NodeGraph} "n" belongs to.
     * @param n the node
     * @param kind any kind except {@link verigames.level.Intersection.Kind#SUBBOARD}.
     * @return a new node
     */
    public static Node newNodeOnSameBoard(Node n, Intersection.Kind kind) {
        String levelName = n.getLevelName();
        Level level = n.getLevel();
        String boardName = n.getBoardName();
        Board board = n.getBoard();
        Intersection i = Intersection.factory(kind);
        return new Node(levelName, level, boardName, board, i);
    }

}
