package verigames.optimizer.model;

import verigames.level.Chute;
import verigames.level.World;

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
    private Set<EdgeID> buzzsawEdges;

    /**
     * Empty solution. All edges are wide and there are no buzzsaws.
     */
    public Solution() {
        narrowEdges = new HashSet<>();
        buzzsawEdges = new HashSet<>();
    }

    /**
     * Load the solution stored in the given world.
     * @param w the world to load from
     */
    public Solution(World w) {
        this();
        for (Chute c : w.getChutes()) {
            if (c.isEditable() && c.isNarrow())
                narrowEdges.add(c.getVariableID());
            if (c.hasBuzzsaw())
                buzzsawEdges.add(new EdgeID(c));
        }
    }

    public void setBuzzsaw(Edge e, boolean buzzsaw) {
        if (buzzsaw)
            buzzsawEdges.add(new EdgeID(e));
        else
            buzzsawEdges.remove(new EdgeID(e));
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
        return e != null && buzzsawEdges.contains(new EdgeID(e));
    }

    public boolean isNarrow(Edge e) {
        return e != null && (e.isEditable() ? narrowEdges.contains(e.getVariableID()) : e.isNarrow());
    }

    public void applyTo(World w) {
        for (Chute c : w.getChutes()) {
            if (c.isEditable())
                c.setNarrow(false);
            c.setBuzzsaw(buzzsawEdges.contains(new EdgeID(c)));
        }
        for (Set<Chute> chutes : w.getLinkedChutes()) {
            // If ANY chute in the edge set is marked narrow, ALL of them get
            // marked narrow. This is an arbitrary but reasonable way to
            // resolve conflicts.
            boolean narrow = false;
            for (Chute c : chutes) {
                if (c.isEditable() && narrowEdges.contains(c.getVariableID()))
                    narrow = true;
            }
            for (Chute c : chutes) {
                if (c.isEditable())
                    c.setNarrow(narrow);
            }
        }
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
