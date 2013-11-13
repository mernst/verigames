package verigames.optimizer.model;

import verigames.level.Board;
import verigames.level.Intersection;
import verigames.level.Level;

public class Node {

    private final String levelName;
    private final Level level;
    private final String boardName;
    private final Board board;
    private final Intersection intersection;
    private final BoardRef subboard;

    public Node(String levelName, Level level, String boardName, Board board, Intersection intersection) {
        this(levelName, level, boardName, board, intersection, null);
    }

    public Node(String levelName, Level level, String boardName, Board board, Intersection intersection, BoardRef subboard) {
        this.levelName = levelName;
        this.level = level;
        this.boardName = boardName;
        this.board = board;
        this.intersection = intersection;
        this.subboard = subboard;
    }

    public String getLevelName() {
        return levelName;
    }

    public Level getLevel() {
        return level;
    }

    public String getBoardName() {
        return boardName;
    }

    public Board getBoard() {
        return board;
    }

    public Intersection getIntersection() {
        return intersection;
    }

    /**
     * If this node is a subboard, then this returns
     * the board it references. The result is null if
     * the underlying {@link Intersection} is not a
     * {@link Intersection.Kind#SUBBOARD SUBBOARD}.
     *
     * <p>
     * For the name of the referenced board, use
     * {@code this.getIntersection().asSubboard().getSubnetworkName()}.
     * </p>
     */
    public BoardRef getBoardRef() {
        return subboard;
    }

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (o == null || getClass() != o.getClass()) return false;
        Node node = (Node) o;
        return intersection.equals(node.intersection);
    }

    @Override
    public int hashCode() {
        return intersection.hashCode();
    }

    @Override
    public String toString() {
        return intersection.getIntersectionKind().toString();
    }

}
