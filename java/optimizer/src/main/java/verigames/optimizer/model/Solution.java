package verigames.optimizer.model;

import java.util.HashSet;
import java.util.Set;

/**
 * A solution is a set of transformations that a player (or solver) might make
 * to a world. Its name is a bit of a misnomer; it's not necessarily a
 * solution, but just the mappings that could form a solution. Specifically, it
 * specifies a width for each variable ID (narrow or wide) and whether or not
 * each edge has a buzzsaw.
 */
public class Solution {

    /**
     * Set of narrow var IDs. By default, all edges are wide.
     */
    private Set<Integer> narrowEdges;

    /**
     * Set of edges with buzzsaws.
     */
    private Set<Edge> buzzsawEdges;

    /**
     * Empty solution. All edges are wide and there are no buzzsaws.
     */
    public Solution() {
        narrowEdges = new HashSet<>();
        buzzsawEdges = new HashSet<>();
    }

    public void setBuzzsaw(Edge e, boolean buzzsaw) {
        if (buzzsaw)
            buzzsawEdges.add(e);
        else
            buzzsawEdges.remove(e);
    }

    public void setNarrow(Edge e, boolean narrow) {
        if (!e.isEditable())
            return;
        if (narrow)
            narrowEdges.add(e.getVariableID());
        else
            narrowEdges.remove(e.getVariableID());
    }

    public boolean hasBuzzsaw(Edge e) {
        return e != null && buzzsawEdges.contains(e);
    }

    public boolean isNarrow(Edge e) {
        return e != null && (e.isEditable() ? narrowEdges.contains(e.getVariableID()) : e.isNarrow());
    }

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (o == null || getClass() != o.getClass()) return false;
        Solution solution = (Solution) o;
        if (!buzzsawEdges.equals(solution.buzzsawEdges)) return false;
        if (!narrowEdges.equals(solution.narrowEdges)) return false;
        return true;
    }

    @Override
    public int hashCode() {
        int result = narrowEdges.hashCode();
        result = 31 * result + buzzsawEdges.hashCode();
        return result;
    }

    @Override
    public String toString() {
        return "Solution{" +
                "narrowEdges=" + narrowEdges +
                ", buzzsawEdges=" + buzzsawEdges +
                '}';
    }

}
