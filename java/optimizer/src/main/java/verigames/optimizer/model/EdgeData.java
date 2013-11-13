package verigames.optimizer.model;

import verigames.level.Chute;

/**
 * Represents all the data that can be associated with an {@link Edge}.
 */
public abstract class EdgeData {

    /**
     * A narrow, immutable chute
     */
    public static final EdgeData NARROW = new EdgeData() {
        @Override public int getVariableID() { return -1; }
        @Override public String getDescription() { return "pinched"; }
        @Override public boolean isNarrow() { return true; }
        @Override public boolean isEditable() { return false; }
        @Override public EdgeSetData getEdgeSetData() { return EdgeSetData.NARROW; }
    };

    /**
     * A wide, immutable chute
     */
    public static final EdgeData WIDE = new EdgeData() {
        @Override public int getVariableID() { return -1; }
        @Override public String getDescription() { return "wide"; }
        @Override public boolean isNarrow() { return false; }
        @Override public boolean isEditable() { return false; }
        @Override public EdgeSetData getEdgeSetData() { return EdgeSetData.WIDE; }
    };

    /**
     * Get an appropriate EdgeData for the given chute.
     * @param c        the chute
     * @param edgeSetData  the edge set that this chute belongs to
     *                     (null indicates that it belongs to its own edge set)
     * @return a matching EdgeData object
     */
    public static EdgeData fromChute(Chute c, final EdgeSetData edgeSetData) {
        if (!c.isEditable())
            return createImmutable(c.isPinched() || c.isNarrow());
        return createMutable(c.getVariableID(), c.getDescription(), edgeSetData);
    }

    /**
     * Create an immutable EdgeData with the given parameters
     * @param narrow  whether the chute is narrow
     * @return a matching EdgeData object
     */
    public static EdgeData createImmutable(boolean narrow) {
        return narrow ? NARROW : WIDE;
    }

    /**
     * Create EdgeData for a mutable edge. (For immutable edges, use one of the
     * static constants.)
     * @param varID        the variable ID
     * @param description  the description
     * @param edgeSetData  the edge set data to link to (or null if the edge is isolated)
     * @return a matching EdgeData object
     */
    public static EdgeData createMutable(final int varID, final String description, final EdgeSetData edgeSetData) {
        return new EdgeData() {
            @Override public int getVariableID() { return varID; }
            @Override public String getDescription() { return description; }
            @Override public boolean isNarrow() { return edgeSetData != null && edgeSetData.isNarrow(); }
            @Override public boolean isEditable() { return true; }
            @Override public EdgeSetData getEdgeSetData() { return edgeSetData; }
        };
    }

    public abstract int getVariableID();
    public abstract String getDescription();
    public abstract boolean isNarrow();
    public abstract boolean isEditable();
    public abstract EdgeSetData getEdgeSetData();

    public Chute toChute() {
        Chute c = new Chute(getVariableID(), getDescription());
        c.setEditable(isEditable());
        c.setPinched(false);
        c.setBuzzsaw(false);
        c.setNarrow(isNarrow());
        return c;
    }

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (o == null || !(o instanceof EdgeData)) return false;
        EdgeData edgeData = (EdgeData) o;
        return edgeData.getVariableID() == getVariableID() &&
                edgeData.getDescription().equals(getDescription()) &&
                edgeData.isNarrow() == isNarrow() &&
                edgeData.isEditable() == isEditable() &&
                edgeData.getEdgeSetData().equals(getEdgeSetData());
    }

    @Override
    public int hashCode() {
        int result = getVariableID();
        result = 31 * result + getDescription().hashCode();
        result = 31 * result + (isNarrow() ? 1 : 0);
        result = 31 * result + (isEditable() ? 1 : 0);
        result = 31 * result + getEdgeSetData().hashCode();
        return result;
    }

    @Override
    public String toString() {
        StringBuffer s = new StringBuffer();
        s.append(getVariableID());
        if (getDescription() == null) {
            s.append(" (no description)");
        } else {
            s.append(" (");
            s.append(getDescription());
            s.append(")");
        }
        s.append(isNarrow() ? ", narrow" : ", wide");
        if (isEditable())
            s.append(", editable");
        return s.toString();
    }

}
