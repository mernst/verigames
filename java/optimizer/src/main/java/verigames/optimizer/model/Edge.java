package verigames.optimizer.model;

/**
 * An edge in a {@link NodeGraph}.
 */
public class Edge {
    private final Node src;
    private final Port srcPort;
    private final NodeGraph.Target target;

    public Edge(Node src, Port srcPort, NodeGraph.Target target) {
        this.src = src;
        this.srcPort = srcPort;
        this.target = target;
    }

    public Node getSrc() {
        return src;
    }

    public Port getSrcPort() {
        return srcPort;
    }

    public NodeGraph.Target getTarget() {
        return target;
    }

    public Node getDst() {
        return target.getDst();
    }

    public Port getDstPort() {
        return target.getDstPort();
    }

    public EdgeData getEdgeData() {
        return target.getEdgeData();
    }

    public int getVariableID() {
        return target.getEdgeData().getVariableID();
    }

    public String getDescription() {
        return target.getEdgeData().getDescription();
    }

    public boolean isNarrow() {
        return target.getEdgeData().isNarrow();
    }

    public boolean isEditable() {
        return target.getEdgeData().isEditable();
    }

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (o == null || getClass() != o.getClass()) return false;

        Edge edge = (Edge) o;

        if (!src.equals(edge.src)) return false;
        if (!srcPort.equals(edge.srcPort)) return false;
        if (!target.equals(edge.target)) return false;

        return true;
    }

    @Override
    public int hashCode() {
        int result = src.hashCode();
        result = 31 * result + srcPort.hashCode();
        result = 31 * result + target.hashCode();
        return result;
    }

    @Override
    public String toString() {
        return "Edge(" + getEdgeData() + ")";
    }

}
