package verigames.optimizer.model;

/**
 * Disjoint set (a.k.a. union-find) data structure
 */
public class DisjointSet {

    private DisjointSet parent;
    private int rank;

    public DisjointSet() {
        this.parent = this;
        this.rank = 0;
    }

    public DisjointSet id() {
        if (parent == this) {
            return parent;
        }
        parent = parent.id();
        return parent;
    }

    public void unionWith(DisjointSet other) {
        DisjointSet myRoot = id();
        DisjointSet otherRoot = other.id();

        if (myRoot == otherRoot) {
            return;
        }

        if (myRoot.rank < otherRoot.rank) {
            myRoot.parent = otherRoot;
        } else if (myRoot.rank > otherRoot.rank) {
            otherRoot.parent = myRoot;
        } else {
            otherRoot.parent = myRoot;
            myRoot.rank++;
        }
    }

}
