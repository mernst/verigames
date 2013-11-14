package verigames.optimizer.model;

import verigames.level.Intersection;

public class Node {

    private final String levelName;
    private final String boardName;
    private final Intersection intersection;
    private final BoardRef subboard;

    public Node(String levelName, String boardName, Intersection intersection) {
        this(levelName, boardName, intersection, null);
    }

    public Node(String levelName, String boardName, Intersection intersection, BoardRef subboard) {
        this.levelName = levelName;
        this.boardName = boardName;
        this.intersection = intersection;
        this.subboard = subboard;
    }

    public String getLevelName() {
        return levelName;
    }

    public String getBoardName() {
        return boardName;
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
