package verigames.optimizer.model;

import verigames.level.Chute;
import verigames.level.World;

/**
 * Unique identifier for an {@link Edge}.
 */
class EdgeID {

    protected final int src;
    protected final String srcPort;
    protected final int dst;
    protected final String dstPort;

    protected EdgeID(int src, String srcPort, int dst, String dstPort) {
        this.src = src;
        this.srcPort = srcPort;
        this.dst = dst;
        this.dstPort = dstPort;
    }

    public EdgeID(Edge e) {
        this(e.getSrc().getIntersection().getUID(),
                e.getSrcPort().getName(),
                e.getDst().getIntersection().getUID(),
                e.getDstPort().getName());
    }

    public EdgeID(Chute c) {
        this(c.getStart().getUID(),
                c.getStartPort(),
                c.getEnd().getUID(),
                c.getEndPort());
    }

    public Edge find(NodeGraph g) {
        for (Edge e : g.getEdges()) {
            if (this.equals(new EdgeID(e)))
                return e;
        }
        return null;
    }

    public Chute find(World w) {
        for (Chute c : w.getChutes()) {
            if (this.equals(new EdgeID(c)))
                return c;
        }
        return null;
    }

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (o == null || getClass() != o.getClass()) return false;
        EdgeID edgeID = (EdgeID) o;
        if (dst != edgeID.dst) return false;
        if (src != edgeID.src) return false;
        if (!dstPort.equals(edgeID.dstPort)) return false;
        if (!srcPort.equals(edgeID.srcPort)) return false;
        return true;
    }

    @Override
    public int hashCode() {
        int result = src;
        result = 31 * result + srcPort.hashCode();
        result = 31 * result + dst;
        result = 31 * result + dstPort.hashCode();
        return result;
    }

    @Override
    public String toString() {
        return "EdgeID{" +
                "src=" + src +
                ", srcPort='" + srcPort + '\'' +
                ", dst=" + dst +
                ", dstPort='" + dstPort + '\'' +
                '}';
    }

}
