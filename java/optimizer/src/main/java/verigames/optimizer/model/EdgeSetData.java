package verigames.optimizer.model;

/**
 * A set of linked edges all point to the same EdgeSetData. This allows us to
 * very efficiently update the width of a set of linked edges. It also helps
 * us enforce the "linked edges have the same width" restriction.
 * <p>
 * Because it is mutable, two EdgeSetDatas are equal if and only if they are
 * exactly the same reference.
 */
public class EdgeSetData {

    public static final EdgeSetData WIDE = new EdgeSetData(false) {
        @Override
        public void setNarrow(boolean narrow) {
            throw new UnsupportedOperationException("Cannot change the width of an immutable wide chute");
        }
    };

    public static final EdgeSetData NARROW = new EdgeSetData(true) {
        @Override
        public void setNarrow(boolean narrow) {
            throw new UnsupportedOperationException("Cannot change the width of an immutable narrow chute");
        }
    };

    private boolean narrow;

    public EdgeSetData() {
        this(false);
    }

    public EdgeSetData(boolean narrow) {
        this.narrow = narrow;
    }

    public boolean isNarrow() {
        return narrow;
    }

    public void setNarrow(boolean narrow) {
        this.narrow = narrow;
    }

}
