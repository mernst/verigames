package verigames.optimizer.model;

/**
 * Disjoint set (a.k.a. union-find) data structure. Generally used to
 * cluster items into groups. Sample usage:
 * <pre>
 *     Map&lt;MyType, DisjointSet&gt; sets = new HashMap&lt;&gt;();
 *     for (MyType t : collection)
 *         sets.put(t, new DisjointSet());
 *     // ...
 *     // use sets.get(myObj).unionWith(sets.get(other)) to ensure that myObj
 *     // and other are in the same set
 *     // ...
 *     {@link verigames.utilities.MultiMap}&lt;DisjointSet, MyType&gt; clusters = new MultiMap&lt;&gt;();
 *     for (Map.Entry&lt;MyType, DisjointSet&gt; e : sets)
 *         clusters.put(e.getValue(), e.getKey());
 *     // the the "clusters" multimap now groups the elements of our collection
 * </pre>
 */
public class DisjointSet {

    // If you aren't familiar with this kind of structure, "parent"
    // and "rank" are used in pretty arcane ways. For more info,
    // see https://en.wikipedia.org/wiki/Disjoint-set_data_structure

    private DisjointSet parent;
    private int rank;

    public DisjointSet() {
        this.parent = this;
        this.rank = 0;
    }

    /**
     * Get the "canonical" ID for this set. Two DisjointSets are the same set
     * if their IDs are {@code ==} to each other.
     * @return the "ID" for this set
     */
    public DisjointSet id() {
        DisjointSet child = this;
        DisjointSet p = parent;
        while (child != p) {
            child = p;
            p = child.parent;
        }
        return p;
    }

    /**
     * Postcondition: {@code this.id() == other.id()}
     * (and so {@code this.equals(other)})
     * @param other a set to union with
     */
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

    @Override
    public int hashCode() {
        return this == parent ? super.hashCode() : id().hashCode();
    }

    /**
     * Returns true if these are the "same" set (i.e. {@code this.id() == o.id()})
     * @param o the other object to check
     * @return true if these objects are the same set
     */
    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (o == null || getClass() != o.getClass()) return false;
        DisjointSet that = (DisjointSet) o;
        return that.id() == id();
    }
}
