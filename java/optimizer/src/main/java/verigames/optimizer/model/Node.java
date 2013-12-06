package verigames.optimizer.model;

import verigames.level.Intersection;

public class Node {

    private final String levelName;
    private final String boardName;
    private final Intersection.Kind kind;
    private final BoardRef subboard;

    public Node(String levelName, String boardName, Intersection.Kind kind) {
        this(levelName, boardName, kind, null);
    }

    public Node(String levelName, String boardName, Intersection.Kind kind, BoardRef subboard) {
        this.levelName = levelName;
        this.boardName = boardName;
        this.kind = kind;
        this.subboard = subboard;
    }

    public String getLevelName() {
        return levelName;
    }

    public String getBoardName() {
        return boardName;
    }

    public Intersection.Kind getKind() {
        return kind;
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
    public String toString() {
        return "Node(" + hashCode() + ", " + getKind() + ")";
    }

}
